#!/usr/bin/env python3
"""离线故障注入；只写临时 HOME/state，绝不调用桥或生产 wake。"""
import concurrent.futures
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[1] / "hooks"
HEAD = "a" * 40
results = []


def save(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False) + "\n")


def rows(state):
    path = state / "delivery-state.jsonl"
    return [json.loads(s) for s in path.read_text().splitlines()] if path.exists() else []


def check(name):
    results.append(name)
    print("PASS " + name, flush=True)


def call(args, env, data=None, codes=(0,)):
    r = subprocess.run(args, env=env, input=data, capture_output=True, text=True, timeout=35)
    assert r.returncode in codes, (args, r.returncode, r.stdout, r.stderr)
    return r


def snapshot(state):
    return {str(p.relative_to(state)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in state.rglob("*") if p.is_file()}


def main():
    with tempfile.TemporaryDirectory(prefix="t045-") as tmp:
        home = Path(tmp) / "home"
        scripts = home / "hooks/scripts"
        shutil.copytree(SOURCE, scripts)
        state = home / "hooks/state/muse-hub"
        state.mkdir(parents=True)
        runtime = Path(tmp) / "runtime.sh"
        poll = scripts / "director-watch-poll.sh"
        runtime.write_text('wake() { echo "injected delivery failure" >&2; return 23; }\nsilent() { printf \'HATCH_HOOK_RESULT:{"decision":"silent"}\\n\'; exit 0; }\n')
        poll.write_text('#!/bin/bash\nprintf \'RESULT {"decision":"silent","reason":"no-change","payload":{}}\\n\'\n')
        env = dict(os.environ, HOME=str(home), MUSE_HUB_STATE_DIR=str(state),
                   HATCH_HOOK_RUNTIME=str(runtime), HATCH_HOOK_DRY_RUN="0",
                   MUSE_DELIVERY_BASE_SECONDS="1", MUSE_DELIVERY_MAX_ATTEMPTS="3",
                   MUSE_DELIVERY_TIMEOUT_SECONDS="0.2", PYTHONDONTWRITEBYTECODE="1")
        helper = ["python3", str(scripts / "delivery-assurance.py")]
        wrapper = ["bash", str(scripts / "director-watch-wrapper.sh")]

        def enqueue(eid, **extra):
            event = dict(event_id=eid, kind="issue_signal", is_reminder=False, is_transition=False)
            event.update(extra.pop("event", {}))
            request = dict(reason="muse-hub-activity", payload={"events": [event]}, **extra)
            call(helper + ["enqueue"], env, json.dumps(request))

        def wait_due():
            target = max(r["next_attempt_at_epoch"] for r in rows(state)
                         if r["state"] == "failed")
            time.sleep(max(0, target - time.time()) + 0.03)

        eid = "issue:43:T045-injected-failure:2026-11-16"
        enqueue(eid)
        logs = []
        for attempt in range(3):
            if attempt:
                wait_due()
            r = call(wrapper, env)
            logs.append(dict(attempt=attempt + 1, stdout=r.stdout, stderr=r.stderr))
            if attempt == 0:
                call(wrapper, env)
                assert len([r for r in rows(state) if r["action"] == "attempt-started"]) == 1
        history = rows(state)
        assert [r["state"] for r in history] == ["queued", "attempting", "failed", "attempting", "failed", "attempting", "failed", "dead"]
        attempts = [r for r in history if r["action"] == "attempt-started"]
        intervals = [datetime.fromisoformat(attempts[i + 1]["at"].replace("Z", "+00:00")).timestamp()
                     - datetime.fromisoformat(attempts[i]["at"].replace("Z", "+00:00")).timestamp()
                     for i in range(2)]
        assert intervals[0] >= 1 and intervals[1] >= 2, intervals
        dead = [json.loads(s) for s in (state / "dead-letter.jsonl").read_text().splitlines()]
        assert len(dead) == 1 and dead[0]["event_id"] == eid
        report = call(["bash", str(scripts / "dead-letter-summary.sh")], env).stdout
        assert "死信 1 条" in report and eid in report
        shutil.copy2(state / "delivery-state.jsonl", ROOT / "failure-state.jsonl")
        shutil.copy2(state / "dead-letter.jsonl", ROOT / "dead-letter.jsonl")
        save(ROOT / "failure-log.json", {"attempt_intervals_seconds": intervals, "runs": logs})
        (ROOT / "daily-summary.txt").write_text(report)
        check("wrapper silent poll: retry 1s/2s, queued→attempting→failed→dead, dead-letter and daily summary")

        enqueue(eid)
        call(wrapper, env)
        assert len([r for r in rows(state) if r["action"] == "attempt-started"]) == 3
        assert len((state / "dead-letter.jsonl").read_text().splitlines()) == 1
        check("dead event is terminal and is not requeued")

        # 成功用实际已安装 runtime 的原始实现；仍只捕获 stdout，不交给平台。
        runtime.write_text(Path("/home/hatch/hooks/runtime/hatch_hook_runtime.sh").read_text())
        enqueue("T045-recover")
        r = call(wrapper, env)
        assert json.loads(r.stdout.split(":", 1)[1])["decision"] == "wake"
        enqueue("T045-recover")
        call(wrapper, env)
        assert len([r for r in rows(state) if r["event_id"] == "T045-recover" and r["action"] == "attempt-started"]) == 1
        check("real runtime exit() captured; delivered duplicate emits no second wake")

        # 两次并发 drain 只能一次交接；并发 enqueue 也只排一次。
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(lambda _: enqueue("T045-concurrent"), range(2)))
            outputs = list(pool.map(lambda _: call(helper + ["drain"], env, codes=(0, 3)), range(2)))
        assert sum("HATCH_HOOK_RESULT:" in r.stdout for r in outputs) == 1
        assert len([r for r in rows(state) if r["event_id"] == "T045-concurrent" and r["action"] == "attempt-started"]) == 1
        check("concurrent enqueue/drain deduplicated under delivery lock")

        # 保留原业务提醒：同一 event_id，同代次只投一次，新代次仍投。
        event_file = state / "events/reminder.json"
        for generation in (2, 2, 3):
            save(event_file, {"event_id": "T045-recover", "retry": {"wakes": generation}})
            enqueue("T045-recover", event={"is_reminder": True})
            call(helper + ["drain"], env, codes=(0, 3))
        reminders = [r for r in rows(state) if r["event_id"] == "T045-recover" and r["action"] == "attempt-started"]
        assert [r["slot"] for r in reminders] == ["initial", "reminder:2", "reminder:3"]
        check("existing reminder generations retained without changing event_id")

        # 超时/无效回包均失败，随后恢复成功。
        for label, body in (("timeout", 'wake() { sleep 5; }\n'),
                            ("malformed", 'wake() { echo \'HATCH_HOOK_RESULT:{"decision":"silent"}\'; }\n')):
            runtime.write_text(body)
            enqueue("T045-" + label)
            start = time.monotonic()
            call(helper + ["drain"], env, codes=(3,))
            assert time.monotonic() - start < 2
            assert rows(state)[-1]["state"] == "failed"
            runtime.write_text(Path("/home/hatch/hooks/runtime/hatch_hook_runtime.sh").read_text())
            wait_due()
            call(helper + ["drain"], env)
            assert rows(state)[-1]["state"] == "delivered"
        check("timeout kills runtime process group; malformed result fails; retries recover")

        # 模拟在 attempting 后进程中断，下一巡逻恢复为 failed 再按退避重投。
        enqueue("T045-interrupted")
        interrupted = dict(rows(state)[-1], state="attempting", attempt=1)
        with (state / "delivery-state.jsonl").open("a") as dst:
            dst.write(json.dumps(interrupted) + "\n")
        call(helper + ["drain"], env, codes=(3,))
        assert "interrupted" in rows(state)[-1]["error"]
        wait_due()
        call(helper + ["drain"], env)
        check("interrupted attempt recovered on next patrol without resetting attempt budget")

        # 轮询报错时，健康告警走相同队列；一小时告警去重不能阻止失败续投。
        poll.write_text('#!/bin/bash\nexit 7\n')
        original_runtime = Path("/home/hatch/hooks/runtime/hatch_hook_runtime.sh").read_text()
        runtime.write_text(original_runtime + '\nwake() { echo "health handoff failure" >&2; return 23; }\n')
        call(wrapper, env)
        assert rows(state)[-1]["state"] == "failed" and rows(state)[-1]["event"] is None
        runtime.write_text(original_runtime)
        wait_due()
        alarm = json.loads(call(wrapper, env).stdout.split(":", 1)[1])
        assert alarm["reason"] == "script-health" and "exit-code-7" in alarm["payload"]["error"]
        assert rows(state)[-1]["state"] == "delivered"
        poll.write_text('#!/bin/bash\nprintf \'RESULT {"decision":"silent","reason":"no-change","payload":{}}\\n\'\n')
        check("script-health alarm retries through existing health dedupe branch")

        before = snapshot(state)
        dryenv = dict(env, HATCH_HOOK_DRY_RUN="1")
        call(helper + ["enqueue"], dryenv, json.dumps({"reason": "test", "payload": {"event_id": "dry"}}))
        call(helper + ["drain"], dryenv, codes=(3,))
        assert snapshot(state) == before
        defaultenv = dict(env)
        defaultenv.pop("MUSE_HUB_STATE_DIR")
        assert call(["bash", str(scripts / "dead-letter-summary.sh")], defaultenv).stdout == report
        assert json.loads(call(wrapper, defaultenv).stdout.split(":", 1)[1])["decision"] == "silent"
        missingenv = dict(env, MUSE_HUB_STATE_DIR=str(Path(tmp) / "missing"))
        assert "死信 0 条" in call(helper + ["summary"], missingenv).stdout
        assert not Path(missingenv["MUSE_HUB_STATE_DIR"]).exists()
        check("dry-run writes nothing; default state path and override; missing state summary read-only")

        cutoff_state = Path(tmp) / "cutoff-state"
        cutoff_state.mkdir()
        now = datetime.now(timezone.utc)
        with (cutoff_state / "dead-letter.jsonl").open("w") as dst:
            for age in (timedelta(), timedelta(hours=-25), timedelta(hours=1)):
                dst.write(json.dumps(dict(dead[0], at=(now + age).isoformat())) + "\n")
        cutoff_before = snapshot(cutoff_state)
        assert "死信 1 条" in call(helper + ["summary"], dict(env, MUSE_HUB_STATE_DIR=str(cutoff_state))).stdout
        assert snapshot(cutoff_state) == cutoff_before
        check("daily summary filters out expired and future entries without modifying state")

        # 日报完整入口离线演练；桥健康探测由 curl stub 响应。
        bin_dir = Path(tmp) / "bin"
        bin_dir.mkdir()
        curl = bin_dir / "curl"
        curl.write_text('#!/bin/bash\necho \'{"ok":true,"loggedIn":true,"needsApproval":false}\'\n')
        curl.chmod(0o755)
        dailyenv = dict(env, PATH=str(bin_dir) + ":" + env["PATH"], HTTPS_PROXY="http://offline:3128")
        daily = call(["bash", str(scripts / "bridge-watchdog-summary.sh")], dailyenv).stdout
        assert report in daily
        (ROOT / "daily-full.txt").write_text(daily)
        check("existing bridge-watchdog daily entry includes dead-letter summary")

        # 完整 poll：三个节点各一个离线新消息，验证入队在 wrapper 之前持久化。
        shutil.copy2(SOURCE / "director-watch-poll.sh", poll)
        (home / "hooks/tmp").mkdir()
        (home / "hooks/ledger").symlink_to("/home/hatch/hooks/ledger", target_is_directory=True)
        sys.path.insert(0, "/home/hatch/hooks/ledger")
        import ledger
        full_state = Path(tmp) / "full-state"
        for sub in ("events", "receipts", "logs"):
            (full_state / sub).mkdir(parents=True, exist_ok=True)
        ledger.init_ledger(full_state)
        (full_state / ".lock").touch()
        save(full_state / "scan.json", {"scan_cursor": HEAD, "comments": {}})
        save(full_state / "health.json", {})
        for n in (1, 2, 3):
            save(full_state / f"node{n}-watch.json", {"seen_cards": [], "seen_msg_hashes": []})
        (bin_dir / "git").write_text('#!/bin/bash\ncase " $* " in *" fetch "*) exit 0;; *" rev-parse "*) echo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;; *) exit 99;; esac\n')
        (bin_dir / "git").chmod(0o755)
        curl.write_text('''#!/usr/bin/env python3
import json,sys
from pathlib import Path
from urllib.parse import urlsplit
a=sys.argv[1:]; u=urlsplit(a[-1])
if u.path.endswith('/issues/comments'): obj=[]
elif u.path.endswith('/approvals'): obj={'cards':[]}
elif u.path.endswith('/chat'): obj={'messages':[{'role':'assistant','text':'T045 new message '+str(u.port)}]}
else: sys.exit('unexpected URL '+a[-1])
Path(a[a.index('-o')+1]).write_text(json.dumps(obj))
if '-D' in a: Path(a[a.index('-D')+1]).write_text('HTTP/1.1 200 OK\\r\\n')
if '-w' in a: print('200',end='')
''')
        fullenv = dict(dailyenv, MUSE_HUB_STATE_DIR=str(full_state),
                       GITHUB_API_BASE="http://offline.invalid", MUSE_HUB_DIR=str(Path(tmp) / "hub"))
        fullenv.pop("GITHUB_TOKEN", None)
        before = snapshot(full_state)
        call(["bash", str(poll)], dict(fullenv, HATCH_HOOK_DRY_RUN="1"))
        assert snapshot(full_state) == before
        polled = call(["bash", str(poll)], fullenv)
        decision = json.loads(polled.stdout.removeprefix("RESULT "))
        assert decision["decision"] == "wake" and len(decision["payload"]["events"]) == 3
        assert len(rows(full_state)) == 3 and all(r["state"] == "queued" for r in rows(full_state))
        event_hashes = snapshot(full_state / "events")
        delivered = call(wrapper, fullenv)
        assert len(json.loads(delivered.stdout.split(":", 1)[1])["payload"]["events"]) == 3
        assert snapshot(full_state / "events") == event_hashes
        assert len([r for r in rows(full_state) if r["state"] == "delivered"]) == 3
        assert json.loads(call(wrapper, fullenv).stdout.split(":", 1)[1])["decision"] == "silent"
        check("full offline poll→durable queue→next silent poll/wrapper→single wake; event files unchanged; poll dry-run")
        save(ROOT / "summary.json", {"at": datetime.now(timezone.utc).isoformat(),
                                   "passed": len(results), "cases": results})


if __name__ == "__main__":
    main()
