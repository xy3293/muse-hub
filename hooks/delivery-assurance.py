#!/usr/bin/env python3
"""Hook 本地交接保障；只用标准库，由现有巡逻驱动，不启动服务。

默认总尝试 3 次（含首次），退避 60s、120s；每次 runtime 超时 10s。
可配置 MUSE_DELIVERY_MAX_ATTEMPTS / MUSE_DELIVERY_BASE_SECONDS /
MUSE_DELIVERY_TIMEOUT_SECONDS。delivered 只表示 runtime 交接，非平台到达。
event_id 不变；已有业务提醒以 reminder:<retry.wakes> / transition 分槽，
防止首次投递去重吞掉原有到期提醒，传输重试不消耗业务提醒预算。
"""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone


def stamp():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def read_rows(path):
    if not path.exists():
        return []
    # 不吞坏行，否则损坏的幂等记录会造成重复投递。
    with path.open() as src:
        return [json.loads(line) for line in src if line.strip()]


def append(path, row):
    with path.open("a") as out:
        out.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")
        out.flush()
        os.fsync(out.fileno())


def key(row):
    return row["event_id"], row["slot"]


def record(row, state, action, **fields):
    row = dict(row, state=state, action=action, at=stamp(), **fields)
    append(JOURNAL, row)
    return row


def positive(name, default):
    value = float(os.environ.get(name, default))
    if not 0 < value <= 86400:
        raise ValueError(f"{name} must be in (0, 86400]")
    return value


def enqueue(latest, request):
    payload = request["payload"]
    events = payload.get("events")
    if events is None:
        raw = json.dumps(request, sort_keys=True, ensure_ascii=False)
        eid = request.get("event_id") or payload.get("event_id")
        events = [{"event_id": eid or "hook:" + hashlib.sha256(raw.encode()).hexdigest()}]
    for event in events:
        eid = event["event_id"]
        if not isinstance(eid, str) or not eid:
            raise ValueError("nonempty event_id required")
        slot = "initial"
        if event.get("is_transition"):
            slot = "transition"
        elif event.get("is_reminder"):
            generation = request.get("reminder_generation")
            if generation is None:
                # 读已有业务提醒代次，不修改事件文件/提醒预算。
                for path in (STATE / "events").glob("*.json"):
                    saved = json.loads(path.read_text())
                    if saved.get("event_id") == eid:
                        generation = saved.get("retry", {}).get("wakes", 0)
                        break
            if generation is None:
                raise ValueError(f"reminder generation missing for {eid}")
            slot = "reminder:" + str(generation)
        old = latest.get((eid, slot))
        if old:
            # wrapper 可补齐 poll 入队时尚未生成的 head/count 等上下文。
            fields = {}
            if old["state"] in ("queued", "failed") and "events" in payload:
                fields["context"] = {k: v for k, v in payload.items() if k != "events"}
            latest[(eid, slot)] = record(old, old["state"], "skipped-duplicate", **fields)
            continue
        attempts = int(os.environ.get("MUSE_DELIVERY_MAX_ATTEMPTS", 3))
        if not 1 <= attempts <= 20:
            raise ValueError("MUSE_DELIVERY_MAX_ATTEMPTS must be in [1, 20]")
        row = dict(event_id=eid, slot=slot, attempt=0, reason=request["reason"],
                   event=event if "events" in payload else None,
                   context={k: v for k, v in payload.items() if k != "events"},
                   max_attempts=attempts, base_seconds=positive("MUSE_DELIVERY_BASE_SECONDS", 60),
                   next_attempt_at_epoch=0)
        latest[key(row)] = record(row, "queued", "enqueued")


def dead(row, dead_keys):
    # 先死信、后终态；若中途被杀，下次 drain 补终态，不重发/不重复死信。
    terminal = dict(row, state="dead", action="attempts-exhausted", at=stamp())
    if key(row) not in dead_keys:
        append(DEAD, terminal)
        dead_keys.add(key(row))
    return record(terminal, "dead", "attempts-exhausted")


def failed(row, error, dead_keys):
    delay = row["base_seconds"] * 2 ** (row["attempt"] - 1)
    row = record(row, "failed", "attempt-failed", error=error[:500],
                 next_attempt_at_epoch=time.time() + delay, retry_delay_seconds=delay)
    if row["attempt"] >= row["max_attempts"]:
        row = dead(row, dead_keys)
    return row


def drain(latest):
    dead_keys = {key(row) for row in read_rows(DEAD)}
    due = []
    for row in latest.values():
        if row["state"] == "attempting":
            # drain 全程持独立锁；拿到锁时旧 attempting 已无活跃投递者。
            row = failed(row, "interrupted runtime handoff; recovered on next patrol", dead_keys)
        if row["state"] == "failed" and row["attempt"] >= row["max_attempts"]:
            row = dead(row, dead_keys)
        if row["state"] not in ("queued", "failed"):
            continue
        if row["next_attempt_at_epoch"] > time.time():
            continue
        due.append(row)
    if not due:
        return 3
    # Hook 每轮只输出一个决策；待投递事件合并为一批，event_id/事件字段不变。
    # 无 events 的 script-health 告警单独交接，其余留待后续巡逻。
    if due[0]["event"] is None:
        due = due[:1]
    else:
        due = [row for row in due if row["event"] is not None]
    active = [record(row, "attempting", "attempt-started", attempt=row["attempt"] + 1,
                     error=None) for row in due]
    payload = dict(active[-1]["context"])
    if active[0]["event"] is not None:
        payload["events"] = [row["event"] for row in active]
        reason = ("muse-hub-activity" if any(not r["event"].get("is_reminder") for r in active)
                  else "muse-hub-activity-reminder")
    else:
        reason = active[0]["reason"]
    error = None
    result_line = None
    try:
        # runtime 的 wake() 会 exit，因此必须在子进程中调用并捕获返回码。
        process = subprocess.Popen(
            ["bash", "-c", 'source "$HATCH_HOOK_RUNTIME"; wake "$1" "$2"',
             "delivery-runtime", reason, json.dumps(payload, ensure_ascii=False)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True)
        try:
            stdout, stderr = process.communicate(timeout=positive("MUSE_DELIVERY_TIMEOUT_SECONDS", 10))
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            raise
        if process.returncode:
            error = f"runtime exit {process.returncode}: {stderr.strip()}"
        else:
            lines = [line for line in stdout.splitlines() if line.startswith("HATCH_HOOK_RESULT:")]
            if len(lines) != 1:
                raise ValueError("runtime must return exactly one HATCH_HOOK_RESULT")
            decision = json.loads(lines[0].split(":", 1)[1])
            if (decision.get("decision"), decision.get("reason"), decision.get("payload")) != ("wake", reason, payload):
                raise ValueError("runtime result does not match requested wake")
            result_line = lines[0]
    except subprocess.TimeoutExpired:
        error = "runtime timeout"
    except (OSError, ValueError) as exc:
        error = str(exc)
    if error is None:
        try:
            print(result_line, flush=True)
        except OSError as exc:
            error = f"stdout handoff failed: {exc}"
    for row in active:
        if error is not None:
            failed(row, error, dead_keys)
        else:
            record(row, "delivered", "runtime-handoff", next_attempt_at_epoch=None)
    if error:
        print(f"delivery failed ({len(active)} events): {error[:500]}", file=sys.stderr)
        return 3
    return 0


def summary():
    cutoff = time.time() - 86400
    rows = [row for row in read_rows(DEAD)
            if cutoff <= datetime.fromisoformat(row["at"].replace("Z", "+00:00")).timestamp() <= time.time()]
    ids = sorted({row["event_id"] for row in rows})
    print(f"唤醒投递(过去24h): 死信 {len(rows)} 条; event_id: {', '.join(ids) or '(无)'}")


STATE = Path(os.environ.get("MUSE_HUB_STATE_DIR", str(Path.home() / "hooks/state/muse-hub")))
JOURNAL = STATE / "delivery-state.jsonl"
DEAD = STATE / "dead-letter.jsonl"


def main():
    command = sys.argv[1]
    if command == "summary":
        summary()
        return 0
    if os.environ.get("HATCH_HOOK_DRY_RUN", "0") == "1":
        return 3 if command == "drain" else 0
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / ".delivery.lock").open("a") as lock:
        # 独立于 poll 的 .lock，避免在 add_wake 入队时重入同一把锁。
        fcntl.flock(lock, fcntl.LOCK_EX)
        latest = {key(row): row for row in read_rows(JOURNAL)}
        if command == "enqueue":
            enqueue(latest, json.load(sys.stdin))
            return 0
        if command == "drain":
            return drain(latest)
        raise ValueError(f"unknown command: {command}")


if __name__ == "__main__":
    sys.exit(main())
