#!/usr/bin/env bash
# 总控盯梢包装器（Stage B）：稳定的最小入口。
# 职责：记录尝试、语法检查轮询脚本、运行轮询脚本并捕获退出码/超时、
# 更新健康状态、把轮询脚本的 RESULT 转成真正的 Hook 决策。
# 本文件极少改动；改轮询脚本前必须 bash -n，并保留上一个工作版本。
set -euo pipefail
source "$HATCH_HOOK_RUNTIME"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
POLL_SCRIPT="$SCRIPT_DIR/director-watch-poll.sh"
DELIVERY_SCRIPT="$SCRIPT_DIR/delivery-assurance.py"
STATE_DIR="${MUSE_HUB_STATE_DIR:-$HOME/hooks/state/muse-hub}"
export MUSE_HUB_STATE_DIR="$STATE_DIR"
HEALTH_FILE="$STATE_DIR/health.json"
DRY_RUN="${HATCH_HOOK_DRY_RUN:-0}"
HEALTH_WAKE_DEDUPE_SECS=3600
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

note() { printf '%s\n' "$*" >&2; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
now_epoch() { date +%s; }

# drain: 0=已输出一次 wake，3=暂无到期投递/本轮失败；其余错误不吞掉。
delivery_drain() {
  local rc=0
  python3 "$DELIVERY_SCRIPT" drain || rc=$?
  if [[ "$rc" -eq 0 ]]; then return 0; fi
  if [[ "$rc" -eq 3 ]]; then return 1; fi
  exit "$rc"
}

delivery_enqueue() {
  jq -cn --arg reason "$1" --argjson payload "$2" --arg eid "${3:-}" \
    '{reason: $reason, payload: $payload, event_id: $eid}' \
    | python3 "$DELIVERY_SCRIPT" enqueue
}

# health_merge FRAGMENT_JSON: 深合并进 health.json（缺失/损坏时退化为 fragment；dry-run 不写）
health_merge() {
  local fragment="$1" current="{}"
  if [[ "$DRY_RUN" == "1" ]]; then
    return 0
  fi
  mkdir -p "$STATE_DIR"
  exec 9>"$STATE_DIR/.lock"
  if ! flock -w 10 9; then
    exec 9>&- 2>/dev/null || true
    note "WARN wrapper cannot acquire lock for health update"
    return 1
  fi
  if [[ -f "$HEALTH_FILE" ]]; then
    current="$(cat "$HEALTH_FILE" 2>/dev/null)" || current="{}"
  fi
  local merged
  if ! merged="$(printf '%s' "$current" | jq -s --argjson frag "$fragment" '.[0] * $frag' 2>/dev/null)"; then
    note "WARN health.json unreadable, resetting to fragment"
    merged="$fragment"
  fi
  printf '%s' "$merged" > "$HEALTH_FILE.tmp.$$"
  mv -f "$HEALTH_FILE.tmp.$$" "$HEALTH_FILE"
  flock -u 9
  exec 9>&-
  return 0
}

# script_health ERROR: 记录脚本故障；同一错误 1 小时内只唤醒一次，其余静默去重
script_health() {
  local err="$1" now now_epoch_val last_wake last_err count frag payload
  now="$(now_iso)"
  now_epoch_val="$(now_epoch)"
  last_wake="$(jq -r '.last_health_wake_at_epoch // 0' "$HEALTH_FILE" 2>/dev/null)" || last_wake=0
  if [[ -z "$last_wake" || "$last_wake" == "null" ]]; then
    last_wake=0
  fi
  last_err="$(jq -r '.last_error // empty' "$HEALTH_FILE" 2>/dev/null)" || last_err=""
  count="$(jq -r '.consecutive_script_failures // 0' "$HEALTH_FILE" 2>/dev/null)" || count=0
  if [[ -z "$count" || "$count" == "null" ]]; then
    count=0
  fi
  count=$((count + 1))
  frag="$(jq -cn --arg now "$now" --arg err "$err" --argjson count "$count" '{last_attempt_at: $now, consecutive_script_failures: $count, last_error: $err}')"
  health_merge "$frag"
  if [[ "$DRY_RUN" != "1" ]]; then
    mkdir -p "$STATE_DIR/logs"
    (
      flock -w 10 9 || exit 1
      jq -cn --arg at "$now" --arg error "$err" --arg script "$POLL_SCRIPT" --argjson count "$count" '{at: $at, kind: "script-health", error: $error, script: $script, consecutive_script_failures: $count}' >> "$STATE_DIR/logs/health-exceptions.jsonl"
    ) 9>"$STATE_DIR/.lock" || note "WARN wrapper cannot acquire lock for health exceptions"
  fi
  if [[ "$last_err" == "$err" ]] && [[ $((now_epoch_val - last_wake)) -lt $HEALTH_WAKE_DEDUPE_SECS ]]; then
    payload="$(jq -cn --arg err "$err" '{error: $err}')"
    if [[ "$DRY_RUN" != "1" ]] && delivery_drain; then exit 0; fi
    silent "script-health-duplicate" "$payload"
    exit 0
  fi
  frag="$(jq -cn --argjson epoch "$now_epoch_val" '{last_health_wake_at_epoch: $epoch}')"
  health_merge "$frag"
  payload="$(jq -cn --arg err "$err" --arg script "$POLL_SCRIPT" '{error: $err, script: $script}')"
  if [[ "$DRY_RUN" == "1" ]]; then wake "script-health" "$payload"; fi
  delivery_enqueue "script-health" "$payload" "script-health:$now_epoch_val"
  if delivery_drain; then exit 0; fi
  silent "delivery-pending" "$payload"
  exit 0
}

mkdir -p "$STATE_DIR"
health_merge "$(jq -cn --arg now "$(now_iso)" '{last_attempt_at: $now}')"

# 部署前语法检查：不通过则禁止运行（由包装器捕获，而非静默丢轮询）
if ! bash -n "$POLL_SCRIPT" 2>"$WORKDIR/syntax_err.txt"; then
  script_health "syntax-error: $(head -c 500 "$WORKDIR/syntax_err.txt" | tr '\n' ' ')"
fi

# 运行轮询脚本（120 秒上限），捕获 stdout
OUT="$WORKDIR/poll.out"
ERR="$WORKDIR/poll.err"
set +e
timeout 120 bash "$POLL_SCRIPT" > "$OUT" 2> "$ERR"
POLL_RC=$?
set -e
if [[ "$POLL_RC" -eq 124 ]]; then
  script_health "timeout-after-120s"
fi
if [[ "$POLL_RC" -ne 0 ]]; then
  script_health "exit-code-$POLL_RC: $(head -c 500 "$ERR" | tr '\n' ' ')"
fi
RESULT_LINE="$(grep '^RESULT ' "$OUT" | head -n 1)" || RESULT_LINE=""
if [[ -z "$RESULT_LINE" ]]; then
  script_health "no-result-line: $(head -c 500 "$ERR" | tr '\n' ' ')"
fi
RESULT_JSON="${RESULT_LINE#RESULT }"
DECISION="$(printf '%s' "$RESULT_JSON" | jq -r '.decision // empty' 2>/dev/null)" || DECISION=""
REASON="$(printf '%s' "$RESULT_JSON" | jq -r '.reason // empty' 2>/dev/null)" || REASON=""
PAYLOAD="$(printf '%s' "$RESULT_JSON" | jq -c '.payload // {}' 2>/dev/null)" || PAYLOAD="{}"
if [[ -z "$DECISION" || -z "$REASON" ]]; then
  script_health "malformed-result-line"
fi
# 轮询成功：脚本故障计数清零（仅非 API 故障时记录 last_success_at）
if [[ "$REASON" != "api-failure" && "$REASON" != "scan-error-diverged" ]]; then
  health_merge "$(jq -cn --arg now "$(now_iso)" '{last_success_at: $now, consecutive_script_failures: 0}')"
else
  health_merge "$(jq -cn '{consecutive_script_failures: 0}')"
fi
if [[ "$DECISION" == "wake" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then wake "$REASON" "$PAYLOAD"; fi
  # poll 已按 event_id/提醒代次入队；幂等检查并补齐 head/count 等上下文。
  delivery_enqueue "$REASON" "$PAYLOAD"
fi
if [[ "$DRY_RUN" != "1" ]] && delivery_drain; then exit 0; fi
silent "$REASON" "$PAYLOAD"
