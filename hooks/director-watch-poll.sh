#!/usr/bin/env bash
# 总控轮询脚本 v3（Stage B Step 2）
# 由 director-watch-wrapper.sh 调用。本脚本不直接调用 wake()/silent()，
# 而是输出一行 RESULT JSON，由包装器转成真正的 Hook 决策。
# stdout 只输出 RESULT 行；所有诊断写 stderr。
# 状态：~/hooks/state/muse-hub/（scan.json、events/、receipts/、health.json、logs/）
# 约定：scan.json 的游标只在全部新事件可靠落盘后才推进；API 失败不推进游标。
set -euo pipefail
# Authenticated runs must never trace the bearer token.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then set +x; fi

REPO="${MUSE_HUB_REPO:-xy3293/muse-hub}"
HUB_DIR="${MUSE_HUB_DIR:-$HOME/workspace/muse-hub-git}"
API_BASE="${GITHUB_API_BASE:-https://api.github.com}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${MUSE_HUB_STATE_DIR:-$HOME/hooks/state/muse-hub}"
S3_ADAPTER="$SCRIPT_DIR/../ledger/adapter.py"
DELIVERY_SCRIPT="$SCRIPT_DIR/delivery-assurance.py"
export TMPDIR="$SCRIPT_DIR/../tmp"
export PYTHONDONTWRITEBYTECODE=1
SCAN_FILE="$STATE_DIR/scan.json"
EVENTS_DIR="$STATE_DIR/events"
RECEIPTS_DIR="$STATE_DIR/receipts"
HEALTH_FILE="$STATE_DIR/health.json"
LOGS_DIR="$STATE_DIR/logs"
LOCK_FILE="$STATE_DIR/.lock"
DRY_RUN="${HATCH_HOOK_DRY_RUN:-0}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

note() { printf '%s\n' "$*" >&2; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
now_epoch() { date +%s; }

# --- state helpers ---
# atomic_write DEST CONTENT: tmp + mv（同文件系统原子改名）。dry-run 时不写。
atomic_write() {
  local dest="$1"
  if [[ "$DRY_RUN" == "1"  ]]; then
    return 0
  fi
  printf '%s' "$2" | python3 "$S3_ADAPTER" --atomic "$dest" || exit 2
}

acquire_lock() {
  exec 9>"$LOCK_FILE"
  if ! flock -w 10 9; then
    exec 9>&- 2>/dev/null || true
    note "ERROR cannot acquire state lock"
    return 1
  fi
  return 0
}

release_lock() {
  flock -u 9 2>/dev/null || true
  exec 9>&- 2>/dev/null || true
}

# health_merge FRAGMENT_JSON: 把 fragment 深合并进 health.json（文件缺失/损坏时退化为 fragment 本身）。
health_merge() {
  local fragment="$1" current="{}"
  if [[ "$DRY_RUN" == "1"  ]]; then
    return 0
  fi
  if [[ -f "$HEALTH_FILE"  ]]; then
    current="$(cat "$HEALTH_FILE" 2>/dev/null)" || current="{}"
  fi
  local merged
  if ! merged="$(printf '%s' "$current" | jq -s --argjson frag "$fragment" '.[0] * $frag' 2>/dev/null)"; then
    note "WARN health.json unreadable, resetting to fragment"
    merged="$fragment"
  fi
  atomic_write "$HEALTH_FILE" "$merged"
}

emit() {
  printf 'RESULT {"decision":"%s","reason":"%s","payload":%s}\n' "$1" "$2" "$3"
}

# --- git-backed BOARD read (2026-11-16: replaces API fetch for BOARD.md) ---
# git_board_at REF OUT: write BOARD.md at REF into OUT via local git.
# Returns 0 on success. Falls back to the GitHub contents API only when the
# local git path is unavailable (Chen 2026-11-16: note the fallback in the daily report).
GIT_BOARD_FALLBACK=0
git_board_at() {
  local ref="$1" out="$2"
  if git -C "$HUB_DIR" show "$ref:BOARD.md" > "$out" 2>/dev/null; then
    return 0
  fi
  GIT_BOARD_FALLBACK=1
  note "WARN git show $ref:BOARD.md failed, falling back to API"
  local hdr="$WORKDIR/git-fallback.hdr"
  if ! api_get "$API_BASE/repos/$REPO/contents/BOARD.md?ref=$ref" "$WORKDIR/git-fallback.json" "$hdr"; then
    return 1
  fi
  jq -er '.content | gsub("\\s"; "") | @base64d' "$WORKDIR/git-fallback.json" > "$out" || return 1
  return 0
}

# --- api ---
API_CODE=""
API_RETRY_AFTER=""
RATE_REMAINING=""
RATE_RESET=""
api_get() {
  local url="$1" body="$2" headers="$3"
  local err="$WORKDIR/curl_err.txt"
  if [[ -n "${GITHUB_TOKEN:-}" && "$url" == https://api.github.com/* ]]; then
    API_CODE="$(curl -sS --header @- -o "$body" -D "$headers" -w "%{http_code}" --max-time 10 "$url" <<< "Authorization: Bearer $GITHUB_TOKEN" 2>"$err")" || API_CODE="000"
  else
  API_CODE="$(curl -sS -o "$body" -D "$headers" -w "%{http_code}" --max-time 10 "$url" 2>"$err")" || API_CODE="000"
  fi
  API_RETRY_AFTER="$(grep -i '^retry-after:' "$headers" 2>/dev/null | tr -d '\r' | awk '{print $2}')" || API_RETRY_AFTER=""
  local rem rst
  rem="$(grep -i '^x-ratelimit-remaining:' "$headers" 2>/dev/null | tr -d '\r' | awk '{print $2}')" || rem=""
  rst="$(grep -i '^x-ratelimit-reset:' "$headers" 2>/dev/null | tr -d '\r' | awk '{print $2}')" || rst=""
  if [[ -n "$rem"  ]]; then
    RATE_REMAINING="$rem"
  fi
  if [[ -n "$rst"  ]]; then
    RATE_RESET="$rst"
  fi
  if [[ "$API_CODE" == "000"  ]]; then
    note "ERROR curl failed for $url: $(cat "$err" 2>/dev/null)"
    return 1
  fi
  if [[ "$API_CODE" == 2*  ]]; then
    return 0
  fi
  return 1
}

# record_api_failure KIND: 连续 API 失败计数 +1，记健康日志；第 2 次起写异常记录；输出 silent，不推进游标。
record_api_failure() {
  local kind="$1" now count frag
  now="$(now_iso)"
  if acquire_lock; then
    count="$(jq -r '.consecutive_api_failures // 0' "$HEALTH_FILE" 2>/dev/null)" || count=0
    if [[ -z "$count"  ]]; then
      count=0
    fi
    count=$((count + 1))
    frag="$(jq -cn --arg now "$now" --arg kind "$kind" --argjson count "$count" '{last_attempt_at: $now, consecutive_api_failures: $count, last_error: $kind}')"
    health_merge "$frag"
    if [[ "$DRY_RUN" != "1" && "$count" -ge 2 ]]; then
      printf '%s\n' "$(jq -cn --arg now "$now" --arg kind "$kind" --argjson count "$count" '{at: $now, kind: $kind, consecutive_api_failures: $count}')" >> "$LOGS_DIR/health-exceptions.jsonl"
    fi
    release_lock
  fi
  emit "silent" "api-failure" "{\"kind\":\"$kind\"}"
  exit 0
}

# --- fetch phase (no state writes) ---
mkdir -p "$STATE_DIR" "$EVENTS_DIR" "$RECEIPTS_DIR" "$LOGS_DIR"

if [[ ! -f "$SCAN_FILE"  ]]; then
  note "ERROR scan.json missing at $SCAN_FILE"
  exit 2
fi
SCAN_CURSOR="$(jq -r '.scan_cursor // empty' "$SCAN_FILE" 2>/dev/null)" || {
  note "ERROR scan.json unreadable"
  exit 2
}
if [[ -z "$SCAN_CURSOR"  ]]; then
  note "ERROR scan_cursor empty"
  exit 2
fi

# BOARD 读优先走本地 git（2026-11-16：实时、零卡）；fetch 失败时 git_board_at
# 会在每次调用时退回 API 并记 GIT_BOARD_FALLBACK，日报据此记一次原因。
if git -C "$HUB_DIR" fetch -q origin 2>/dev/null; then
  note "git fetch ok: $(git -C "$HUB_DIR" rev-parse --short origin/main 2>/dev/null)"
else
  note "WARN git fetch failed, BOARD reads will fall back to API"
  GIT_BOARD_FALLBACK=1
fi

# HEAD 优先走本地 git（2026-11-16：实时、零卡，与 BOARD 读同理）；git 失败时退回 API。
HEAD_SHA="$(git -C "$HUB_DIR" rev-parse origin/main 2>/dev/null)"
if [[ -z "$HEAD_SHA" ]] || ! [[ "$HEAD_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  note "WARN git rev-parse failed, HEAD falls back to API"
  if ! api_get "$API_BASE/repos/$REPO/git/ref/heads/main" "$WORKDIR/head.json" "$WORKDIR/head.hdr"; then
    record_api_failure "head-fetch-failed"
  fi
  HEAD_SHA="$(jq -er '.object.sha | select(test("^[0-9a-f]{40}$"))' "$WORKDIR/head.json")" || record_api_failure "invalid-head"
fi

# Compare：枚举 scan_cursor..HEAD 之间的全部提交（分页处理）
: > "$WORKDIR/new_commits.txt"
COMPARE_STATUS=""
if [[ "$HEAD_SHA" != "$SCAN_CURSOR"  ]]; then
  url="$API_BASE/repos/$REPO/compare/$SCAN_CURSOR...$HEAD_SHA?per_page=100"
  : > "$WORKDIR/compare_commits.txt"
  while [[ -n "$url"  ]]; do
    if ! api_get "$url" "$WORKDIR/compare.json" "$WORKDIR/compare.hdr"; then
      record_api_failure "compare-fetch-failed"
    fi
    COMPARE_STATUS="$(jq -r '.status // empty' "$WORKDIR/compare.json" 2>/dev/null)"
    jq -r '.commits[]?.sha' "$WORKDIR/compare.json" 2>/dev/null >> "$WORKDIR/compare_commits.txt" || true
    url="$(grep -i '^link:' "$WORKDIR/compare.hdr" 2>/dev/null | tr -d '\r' | tr ',' '\n' | grep 'rel="next"' | sed -e 's/.*<\(.*\)>.*/\1/')" || url=""
  done
  if [[ "$COMPARE_STATUS" == "diverged"  ]]; then
    note "ERROR compare diverged; not advancing cursor"
    emit "silent" "scan-error-diverged" "{\"head\":\"$HEAD_SHA\",\"cursor\":\"$SCAN_CURSOR\"}"
    exit 0
  fi
  cp "$WORKDIR/compare_commits.txt" "$WORKDIR/new_commits.txt"
fi

# Fetch complete per-commit path/status evidence and its first-parent assignment snapshot.
while read -r sha; do
  [[ -n "$sha" ]] || continue
  url="$API_BASE/repos/$REPO/commits/$sha?per_page=100"
  first=1
  while [[ -n "$url" ]]; do
    if ! api_get "$url" "$WORKDIR/page.json" "$WORKDIR/commit.hdr"; then
      record_api_failure "commit-fetch-failed"
    fi
    if ! jq -e --arg sha "$sha" '.sha == $sha and (.files | type == "array") and (.parents | type == "array")' "$WORKDIR/page.json" >/dev/null; then
      record_api_failure "invalid-commit"
    fi
    if [[ "$first" == 1 ]]; then
      cp "$WORKDIR/page.json" "$WORKDIR/commit-$sha.json"
      first=0
    else
      jq -s '.[0].files += .[1].files | .[0]' "$WORKDIR/commit-$sha.json" "$WORKDIR/page.json" > "$WORKDIR/merged.json"
      mv "$WORKDIR/merged.json" "$WORKDIR/commit-$sha.json"
    fi
    url="$(grep -i '^link:' "$WORKDIR/commit.hdr" | tr -d '\r' | tr ',' '\n' | grep 'rel="next"' | sed -e 's/.*<\(.*\)>.*/\1/')" || url=""
  done
  parent="$(jq -r '.parents[0].sha // empty' "$WORKDIR/commit-$sha.json")"
  : > "$WORKDIR/board-$sha.md"
  if [[ -n "$parent" ]]; then
    if ! git_board_at "$parent" "$WORKDIR/board-$sha.md"; then
      record_api_failure "assignment-fetch-failed"
    fi
  fi
done < "$WORKDIR/new_commits.txt"

# 评论：仓库级列表，sort=updated asc，全部分页；since 用索引里最新 updated_at 减 10 分钟重叠
MAX_UPDATED="$(jq -r '[.comments // {} | .[] | .[] | .updated_at] | max // empty' "$SCAN_FILE" 2>/dev/null)" || MAX_UPDATED=""
SINCE_PARAM=""
if [[ -n "$MAX_UPDATED"  ]]; then
  since_val="$(date -u -d "$MAX_UPDATED - 600 seconds" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" || since_val=""
  if [[ -n "$since_val"  ]]; then
    SINCE_PARAM="&since=$since_val"
  fi
fi
: > "$WORKDIR/comments.jsonl"
url="$API_BASE/repos/$REPO/issues/comments?sort=updated&direction=asc&per_page=100$SINCE_PARAM"
while [[ -n "$url"  ]]; do
  if ! api_get "$url" "$WORKDIR/comments.json" "$WORKDIR/comments.hdr"; then
    record_api_failure "comments-fetch-failed"
  fi
  jq -c '.[] | {id: .id, updated_at: .updated_at, issue_url: .issue_url, body: .body}' "$WORKDIR/comments.json" 2>/dev/null >> "$WORKDIR/comments.jsonl" || true
  url="$(grep -i '^link:' "$WORKDIR/comments.hdr" 2>/dev/null | tr -d '\r' | tr ',' '\n' | grep 'rel="next"' | sed -e 's/.*<\(.*\)>.*/\1/')" || url=""
done

# --- mutation phase (under lock) ---
NOW_ISO="$(now_iso)"
NOW_EPOCH="$(now_epoch)"
MAX_WAKES=12

if ! acquire_lock; then
note "ERROR cannot acquire state lock for mutation"
exit 2
fi

# 锁内重读游标：若取数期间游标已被推进（并发轮询），本次不做任何改动
SCAN_CURSOR_LOCKED="$(jq -r '.scan_cursor // empty' "$SCAN_FILE" 2>/dev/null)" || SCAN_CURSOR_LOCKED=""
if [[ "$SCAN_CURSOR_LOCKED" != "$SCAN_CURSOR" ]]; then
note "WARN scan_cursor changed during fetch; aborting without changes"
release_lock
emit "silent" "cursor-moved" "{\"head\":\"$HEAD_SHA\"}"
exit 0
fi

: > "$WORKDIR/wake_events.jsonl"
: > "$WORKDIR/needs_attention.jsonl"
declare -A WAKE_SET
add_wake() {
local eid reason
eid="$(printf '%s' "$1" | jq -r '.event_id')"
if [[ -z "${WAKE_SET[$eid]:-}" ]]; then
# 在游标/评论索引推进前持久入队；wrapper 中断或后续轮询 silent 也能续投。
reason="muse-hub-activity"
if jq -e '.is_reminder == true' <<< "$1" >/dev/null; then
  reason="muse-hub-activity-reminder"
fi
if [[ "$DRY_RUN" != "1" ]]; then
  jq -cn --argjson event "$1" --arg reason "$reason" \
    '{reason: $reason, payload: {events: [$event]}}' \
    | python3 "$DELIVERY_SCRIPT" enqueue || exit 2
fi
WAKE_SET["$eid"]=1
printf '%s\n' "$1" >> "$WORKDIR/wake_events.jsonl"
fi
}

# --- S3: pending candidates are reevaluated independently of remote HEAD ---
S3_FLAGS=()
[[ "$DRY_RUN" != "1" ]] || S3_FLAGS+=(--dry-run)
s3_response="$(python3 "$S3_ADAPTER" --state "$STATE_DIR" "${S3_FLAGS[@]}")" || exit 2
s3_result() {
  S3_AVAILABLE="$(jq -r '.ledger_available' <<< "$s3_response")"
  S3_WATERMARK="$(jq -c '.watermark' <<< "$s3_response")"
  health_merge "$(jq -c '{s3: {ledger_available: .ledger_available, error: .error}}' <<< "$s3_response")"
  while IFS= read -r item; do
    add_wake "$item"
  done < <(jq -c '.wakes[]' <<< "$s3_response")
}
s3_result
S3_CAN_ADVANCE="$S3_AVAILABLE"

# --- MUSE-ACK：只处理本次 Compare 枚举的提交 ---
ack_warning() {
if [[ "$DRY_RUN" != "1" ]]; then
jq -cn --arg at "$NOW_ISO" --arg sha "$ack_sha" --arg eid "$ack_event" --arg condition "$1" --arg detail "$2" '{at: $at, ack_commit_sha: $sha, event_id: $eid, failed_condition: $condition, detail: $detail}' >> "$LOGS_DIR/ack-warnings.jsonl"
fi
}
ack_pattern='^MUSE-ACK task=([^[:space:]]+) node=([^[:space:]]+) event=(result:([^:[:space:]]+):([^:[:space:]]+):([0-9a-f]{40})) verdict=(PASS|REJECT)$'
while IFS= read -r ack_sha; do
[[ -n "$ack_sha" ]] || continue
S3_COMPLETE=()
# GitHub's per-commit file cap cannot prove completeness at 3000 files.
if [[ "$(jq '.files | length' "$WORKDIR/commit-$ack_sha.json")" -ge 3000 ]]; then
  S3_COMPLETE+=(--incomplete)
fi
s3_response="$(python3 "$S3_ADAPTER" --state "$STATE_DIR" --commit "$WORKDIR/commit-$ack_sha.json" --board "$WORKDIR/board-$ack_sha.md" "${S3_FLAGS[@]}" "${S3_COMPLETE[@]}")" || exit 2
s3_result
# ACK handling remains independent of the commit's result classification.
while IFS= read -r ack_line; do
ack_event=""
if [[ ! "$ack_line" =~ $ack_pattern ]]; then
ack_warning "format" "invalid MUSE-ACK line"
continue
fi
ack_task="${BASH_REMATCH[1]}"; ack_node="${BASH_REMATCH[2]}"
ack_event="${BASH_REMATCH[3]}"; ack_source="${BASH_REMATCH[6]}"; ack_verdict="${BASH_REMATCH[7]}"
ack_file=""
for f in "$EVENTS_DIR"/*.json; do
[[ -f "$f" ]] || continue
if jq -e --arg eid "$ack_event" '.event_id == $eid' "$f" >/dev/null; then
ack_file="$f"
break
fi
done
if [[ -z "$ack_file" ]]; then
ack_warning "1" "event_id not found"
continue
fi
if ! jq -e --arg task "$ack_task" --arg node "$ack_node" --arg sha "$ack_source" '.task_id == $task and .node_id == $node and .source_commit_sha == $sha' "$ack_file" >/dev/null; then
ack_warning "2" "task, node or source SHA mismatch"
continue
fi
# Condition 3 holds by construction: ack_sha comes only from new_commits.txt.
if jq -e '.state == "ACKED" or .state == "REJECTED" or .state == "SUPERSEDED" or .state == "CLOSED_INTERNAL"' "$ack_file" >/dev/null; then
continue
fi
if ! jq -e 'any(.files[]?; .filename == "BOARD.md")' "$WORKDIR/commit-$ack_sha.json" >/dev/null; then
ack_warning "4" "commit does not change BOARD.md"
continue
fi
if ! git_board_at "$ack_sha" "$WORKDIR/ack-board.md"; then
release_lock
record_api_failure "ack-board-fetch-failed"
fi
# Match a unique Markdown row by its exact task cell and exact status cell.
if ! jq -Re --slurp --arg task "$ack_task" --arg verdict "$ack_verdict" '
[split("\n")[] | split("|") | map(gsub("^\\s+|\\s+$"; "")) | select(index($task))] |
length == 1 and (.[0] | if $verdict == "PASS" then index("完成") != null
else index("完成") == null and (index("拒收") != null or index("返工") != null) end)' "$WORKDIR/ack-board.md" >/dev/null; then
ack_warning "5" "BOARD.md task row does not match verdict"
continue
fi
# Message/author alone is not strong identity authentication (operation-level check only).
if [[ "$(jq -r '.author.login // empty' "$WORKDIR/commit-$ack_sha.json")" != "xy3293" ]]; then
ack_warning "6" "commit author login is not xy3293"
continue
fi
updated="$(jq --arg sha "$ack_sha" --arg verdict "$ack_verdict" --arg now "$NOW_ISO" '
.state = (if $verdict == "PASS" then "ACKED" else "REJECTED" end) |
.main_ack = {acked: ($verdict == "PASS"), ack_commit_sha: $sha, ack_method: "muse-ack-commit", verdict: $verdict} |
.timestamps.main_acked_at = $now' "$ack_file")"
atomic_write "$ack_file" "$updated"
done < <(jq -r '.commit.message // "" | split("\n")[] | sub("\\r$"; "") | select(test("^MUSE-ACK([[:space:]]|$)"))' "$WORKDIR/commit-$ack_sha.json")
# Commit cursor only after its candidates, ACK effects, and health are durable.
if [[ "$S3_AVAILABLE" != "true" ]]; then
  S3_CAN_ADVANCE=false
fi
if [[ "$S3_CAN_ADVANCE" == "true" ]]; then
checkpoint_scan="$(jq --arg cursor "$ack_sha" --arg now "$NOW_ISO" --argjson watermark "$S3_WATERMARK" '.scan_cursor = $cursor | .scan_cursor_updated_at = $now | .s3_ledger = $watermark' "$SCAN_FILE")"
atomic_write "$SCAN_FILE" "$checkpoint_scan"
fi
done < "$WORKDIR/new_commits.txt"

# --- alerts/ -> bridge_alert / bridge_recover 事件（R6b，2026-11-15） ---
# ALERT 文件 -> bridge_alert 事件（severity high，事件键=文件名，不重复建）；
# RECOVER 文件 -> bridge_recover 事件，并关闭最近一条未关闭的 bridge_alert；
# 无对应 alert 时记孤立 recover（只留痕，不报警）。
# 事件不要求 ACK、不进验收、不计入节点交付；未关闭的 bridge_alert 由重试扫描
# 按 DETECTED 窗口重唤（900s，最多 12 次）。alerts/ 文件只读，不修改不删除。
alert_table_json() {
  local f="$1" out
  if [[ ! -f "$f" ]]; then
    printf '[]'
    return 0
  fi
  out="$(jq -R -s 'split("\n") | map(select(test("^\\|"))) | map(ltrimstr("|") | rtrimstr("|") | split("|") | map(gsub("^\\s+|\\s+$"; ""))) | map(select(.[0] != "目标" and (.[0] | test("^--+$") | not))) | map({target: .[0], cdp: .[1], api: .[2], details: (.[3] // "")})' "$f" 2>/dev/null)" || out=""
  if [[ -z "$out" ]] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    printf '[]'
  else
    printf '%s' "$out"
  fi
}

alert_detected_iso() {
  local base="$1"
  if [[ "$base" =~ ^(ALERT|RECOVER)-([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2})-([0-9]{2})-([0-9]{2})\.md$ ]]; then
    printf '%s-%s-%sT%s:%s:%sZ' "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" "${BASH_REMATCH[7]}"
  fi
}

latest_unclosed_bridge_alert() {
  local best="" best_det="" f st det
  for f in "$EVENTS_DIR"/bridge_alert-*.json; do
    [[ -f "$f" ]] || continue
    st="$(jq -r '.state // empty' "$f" 2>/dev/null)" || st=""
    [[ "$st" == "DETECTED" ]] || continue
    det="$(jq -r '.alert.detected_at // .timestamps.detected_at // empty' "$f" 2>/dev/null)" || det=""
    if [[ -z "$best" || "$det" > "$best_det" ]]; then
      best="$f"
      best_det="$det"
    fi
  done
  printf '%s' "$best"
}

while IFS= read -r alert_sha; do
  [[ -n "$alert_sha" ]] || continue
  [[ -f "$WORKDIR/commit-$alert_sha.json" ]] || continue
  while IFS= read -r alert_path; do
    [[ -n "$alert_path" ]] || continue
    alert_file="${alert_path##*/}"
    if [[ "$alert_file" == ALERT-*.md ]]; then
      event_file="$EVENTS_DIR/bridge_alert-$alert_file.json"
      [[ -f "$event_file" ]] && continue
      table_json='[]'
      if api_get "$API_BASE/repos/$REPO/contents/alerts/$alert_file?ref=$alert_sha" "$WORKDIR/alert-fetch.json" "$WORKDIR/alert-fetch.hdr"; then
        if jq -er '.content | gsub("\\s"; "") | @base64d' "$WORKDIR/alert-fetch.json" > "$WORKDIR/alert-content.txt" 2>/dev/null; then
          table_json="$(alert_table_json "$WORKDIR/alert-content.txt")"
        else
          note "WARN alert table decode failed for $alert_file"
        fi
      else
        note "WARN alert file fetch failed for $alert_file, using filename-only payload"
      fi
      detected_iso="$(alert_detected_iso "$alert_file")"
      down_target="$(printf '%s' "$table_json" | jq -r 'map(select(.cdp == "DOWN" or .api == "DOWN")) | .[0].target // empty' 2>/dev/null)" || down_target=""
      case "$down_target" in
        node-1|node-2|node-3) alert_node="$down_target" ;;
        *) alert_node="" ;;
      esac
      event_id="bridge_alert:$alert_file"
      event_json="$(jq -cn --arg eid "$event_id" --arg sha "$alert_sha" --arg path "$alert_path" --arg file "$alert_file" --arg det "$detected_iso" --argjson table "$table_json" --arg node "$alert_node" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "bridge_alert", task_id: null, node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: $sha, source_paths: [$path], state: "DETECTED", severity: "high", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, alert: {filename: $file, detected_at: (if ($det | length) > 0 then $det else $now end), status_table: $table, closed_by: null, closed_at: null}}')"
      atomic_write "$event_file" "$event_json"
      add_wake "$(jq -cn --arg eid "$event_id" --arg sha "$alert_sha" --arg node "$alert_node" '{event_id: $eid, kind: "bridge_alert", task_id: null, node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: $sha, is_reminder: false, is_transition: false}')"
    elif [[ "$alert_file" == RECOVER-*.md ]]; then
      event_file="$EVENTS_DIR/bridge_recover-$alert_file.json"
      [[ -f "$event_file" ]] && continue
      unclosed="$(latest_unclosed_bridge_alert)"
      closed_eid=""
      closed_node=""
      orphan="true"
      if [[ -n "$unclosed" ]]; then
        closed_eid="$(jq -r '.event_id // empty' "$unclosed" 2>/dev/null)" || closed_eid=""
        closed_node="$(jq -r '.node_id // empty' "$unclosed" 2>/dev/null)" || closed_node=""
        if updated="$(jq --arg now "$NOW_ISO" --arg by "$alert_file" '.state = "CLOSED_INTERNAL" | .alert.closed_by = $by | .alert.closed_at = $now' "$unclosed" 2>/dev/null)"; then
          orphan="false"
          atomic_write "$unclosed" "$updated"
        else
          note "WARN cannot close bridge_alert $unclosed, treating recover as orphan"
          closed_eid=""
          closed_node=""
          orphan="true"
        fi
      fi
      recovered_iso="$(alert_detected_iso "$alert_file")"
      event_id="bridge_recover:$alert_file"
      event_json="$(jq -cn --arg eid "$event_id" --arg sha "$alert_sha" --arg path "$alert_path" --arg file "$alert_file" --arg rec "$recovered_iso" --arg closed "$closed_eid" --argjson orphan "$orphan" --arg node "$closed_node" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "bridge_recover", task_id: null, node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: $sha, source_paths: [$path], state: "CLOSED_INTERNAL", severity: "info", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, recover: {filename: $file, recovered_at: (if ($rec | length) > 0 then $rec else $now end), closed_alert_event_id: (if ($closed | length) > 0 then $closed else null end), orphan: $orphan}}')"
      atomic_write "$event_file" "$event_json"
      add_wake "$(jq -cn --arg eid "$event_id" --arg sha "$alert_sha" --arg node "$closed_node" '{event_id: $eid, kind: "bridge_recover", task_id: null, node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: $sha, is_reminder: false, is_transition: false}')"
    fi
  done < <(jq -r '.files[]?.filename | select(test("^alerts/(ALERT|RECOVER)-.*\\.md$"))' "$WORKDIR/commit-$alert_sha.json" 2>/dev/null | sort -u)
done < "$WORKDIR/new_commits.txt"

# --- node-3 桥直通：新消息 / 新审批卡 -> 唤醒总控（Chen 2026-11-15 直令） ---
# node-3 经桥发消息或弹审批卡时，聊天本身不唤醒总控（R21），卡 30 分钟过期。
# 本节每轮轮询 node-3 桥（8787）：新卡（approval_id 未见过）与新消息
# （assistant 文本 hash 未见过）各建一个事件并 add_wake。桥不可达时只记 WARN，
# 不杀死本轮轮询。状态文件：$STATE_DIR/node3-watch.json
# （seen_cards: [approval_id...], seen_msg_hashes: [sha256...]，各保留最近 50 条）。
NODE3_WATCH_FILE="$STATE_DIR/node3-watch.json"
NODE3_BRIDGE_BASE="http://100.118.194.61:8787"
bridge_get() {
  local url="$1" out="$2"
  local proxy="${HTTPS_PROXY%:*}:3130"
  curl -sS --proxy "$proxy" --max-time 10 -o "$out" "$url" 2>/dev/null
}
node3_watch_init=""
if [[ -f "$NODE3_WATCH_FILE" ]]; then
  node3_watch_init="$(cat "$NODE3_WATCH_FILE" 2>/dev/null)" || node3_watch_init=""
fi
if ! printf '%s' "$node3_watch_init" | jq -e '.seen_cards and .seen_msg_hashes' >/dev/null 2>&1; then
  node3_watch_init='{"seen_cards": [], "seen_msg_hashes": []}'
fi
node3_watch_updated="$node3_watch_init"
# --- 新审批卡 ---
if bridge_get "$NODE3_BRIDGE_BASE/v1/muse/approvals" "$WORKDIR/node3-approvals.json"; then
  if jq -e '.cards | type == "array"' "$WORKDIR/node3-approvals.json" >/dev/null 2>&1; then
    while IFS= read -r card_json; do
      [[ -n "$card_json" ]] || continue
      card_id="$(printf '%s' "$card_json" | jq -r '.approval_id // empty' 2>/dev/null)" || card_id=""
      [[ -n "$card_id" ]] || continue
      if printf '%s' "$node3_watch_updated" | jq -e --arg id "$card_id" '.seen_cards | index($id) != null' >/dev/null 2>&1; then
        continue
      fi
      card_action="$(printf '%s' "$card_json" | jq -r '.action // empty' 2>/dev/null)" || card_action=""
      card_fp="$(printf '%s' "$card_json" | jq -r '.fingerprint // empty' 2>/dev/null)" || card_fp=""
      card_short="${card_id:0:12}"
      event_id="node3_approval:$card_id"
      event_file="$EVENTS_DIR/node3_approval-$card_short.json"
      if [[ ! -f "$event_file" ]]; then
        event_json="$(jq -cn --arg eid "$event_id" --arg cid "$card_id" --arg act "$card_action" --arg fp "$card_fp" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "node3_approval", task_id: null, node_id: "node-3", source_commit_sha: null, source_paths: [], state: "DETECTED", severity: "high", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, node3_approval: {approval_id: $cid, action: $act, fingerprint: $fp}}')"
        atomic_write "$event_file" "$event_json"
      fi
      add_wake "$(jq -cn --arg eid "$event_id" '{event_id: $eid, kind: "node3_approval", task_id: null, node_id: "node-3", source_commit_sha: null, is_reminder: false, is_transition: false}')"
      node3_watch_updated="$(printf '%s' "$node3_watch_updated" | jq -c --arg id "$card_id" '.seen_cards = ((.seen_cards + [$id]) | unique | .[-50:])')"
    done < <(jq -c '.cards[]' "$WORKDIR/node3-approvals.json" 2>/dev/null)
  else
    note "WARN node-3 approvals response not an array, skipping"
  fi
else
  note "WARN node-3 approvals fetch failed, skipping"
fi
# --- 新消息（assistant 文本 hash 未见过） ---
if bridge_get "$NODE3_BRIDGE_BASE/v1/muse/chat?limit=20" "$WORKDIR/node3-chat.json"; then
  if jq -e '.messages | type == "array"' "$WORKDIR/node3-chat.json" >/dev/null 2>&1; then
    while IFS= read -r msg_json; do
      [[ -n "$msg_json" ]] || continue
      msg_role="$(printf '%s' "$msg_json" | jq -r '.role // empty' 2>/dev/null)" || msg_role=""
      [[ "$msg_role" == "assistant" ]] || continue
      msg_text="$(printf '%s' "$msg_json" | jq -r '.text // empty' 2>/dev/null)" || msg_text=""
      [[ -n "$msg_text" ]] || continue
      msg_hash="$(printf '%s' "$msg_text" | sha256sum 2>/dev/null | awk '{print $1}')" || msg_hash=""
      [[ -n "$msg_hash" ]] || continue
      if printf '%s' "$node3_watch_updated" | jq -e --arg h "$msg_hash" '.seen_msg_hashes | index($h) != null' >/dev/null 2>&1; then
        continue
      fi
      msg_short="${msg_hash:0:12}"
      msg_snip="$(printf '%s' "$msg_text" | head -c 200)"
      event_id="node3_message:$msg_hash"
      event_file="$EVENTS_DIR/node3_message-$msg_short.json"
      if [[ ! -f "$event_file" ]]; then
        event_json="$(jq -cn --arg eid "$event_id" --arg h "$msg_hash" --arg snip "$msg_snip" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "node3_message", task_id: null, node_id: "node-3", source_commit_sha: null, source_paths: [], state: "DETECTED", severity: "info", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, node3_message: {hash: $h, snippet: $snip}}')"
        atomic_write "$event_file" "$event_json"
        # T-036: 事件文件在 hash 淘汰后仍用于去重；到期提醒由重试扫描处理。
        add_wake "$(jq -cn --arg eid "$event_id" '{event_id: $eid, kind: "node3_message", task_id: null, node_id: "node-3", source_commit_sha: null, is_reminder: false, is_transition: false}')"
      fi
      node3_watch_updated="$(printf '%s' "$node3_watch_updated" | jq -c --arg h "$msg_hash" '.seen_msg_hashes = ((.seen_msg_hashes + [$h]) | unique | .[-50:])')"
    done < <(jq -c '.messages[]' "$WORKDIR/node3-chat.json" 2>/dev/null)
  else
    note "WARN node-3 chat response not an array, skipping"
  fi
else
  note "WARN node-3 chat fetch failed, skipping"
fi
atomic_write "$NODE3_WATCH_FILE" "$node3_watch_updated"

# --- node-1 桥直通：新消息 / 新审批卡 -> 唤醒总控（Chen 2026-11-15 直令，2026-11-15 扩至三桥） ---
# node-1 经桥发消息或弹审批卡时，聊天本身不唤醒总控（R21），卡 30 分钟过期。
# 本节每轮轮询 node-1 桥（8788）：新卡（approval_id 未见过）与新消息
# （assistant 文本 hash 未见过）各建一个事件并 add_wake。桥不可达时只记 WARN，
# 不杀死本轮轮询。状态文件：$STATE_DIR/node1-watch.json
# （seen_cards: [approval_id...], seen_msg_hashes: [sha256...]，各保留最近 50 条）。
NODE1_WATCH_FILE="$STATE_DIR/node1-watch.json"
NODE1_BRIDGE_BASE="http://100.118.194.61:8788"
bridge_get() {
  local url="$1" out="$2"
  local proxy="${HTTPS_PROXY%:*}:3130"
  curl -sS --proxy "$proxy" --max-time 10 -o "$out" "$url" 2>/dev/null
}
node1_watch_init=""
if [[ -f "$NODE1_WATCH_FILE" ]]; then
  node1_watch_init="$(cat "$NODE1_WATCH_FILE" 2>/dev/null)" || node1_watch_init=""
fi
if ! printf '%s' "$node1_watch_init" | jq -e '.seen_cards and .seen_msg_hashes' >/dev/null 2>&1; then
  node1_watch_init='{"seen_cards": [], "seen_msg_hashes": []}'
fi
node1_watch_updated="$node1_watch_init"
# --- 新审批卡 ---
if bridge_get "$NODE1_BRIDGE_BASE/v1/muse/approvals" "$WORKDIR/node1-approvals.json"; then
  if jq -e '.cards | type == "array"' "$WORKDIR/node1-approvals.json" >/dev/null 2>&1; then
    while IFS= read -r card_json; do
      [[ -n "$card_json" ]] || continue
      card_id="$(printf '%s' "$card_json" | jq -r '.approval_id // empty' 2>/dev/null)" || card_id=""
      [[ -n "$card_id" ]] || continue
      if printf '%s' "$node1_watch_updated" | jq -e --arg id "$card_id" '.seen_cards | index($id) != null' >/dev/null 2>&1; then
        continue
      fi
      card_action="$(printf '%s' "$card_json" | jq -r '.action // empty' 2>/dev/null)" || card_action=""
      card_fp="$(printf '%s' "$card_json" | jq -r '.fingerprint // empty' 2>/dev/null)" || card_fp=""
      card_short="${card_id:0:12}"
      event_id="node1_approval:$card_id"
      event_file="$EVENTS_DIR/node1_approval-$card_short.json"
      if [[ ! -f "$event_file" ]]; then
        event_json="$(jq -cn --arg eid "$event_id" --arg cid "$card_id" --arg act "$card_action" --arg fp "$card_fp" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "node1_approval", task_id: null, node_id: "node-1", source_commit_sha: null, source_paths: [], state: "DETECTED", severity: "high", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, node1_approval: {approval_id: $cid, action: $act, fingerprint: $fp}}')"
        atomic_write "$event_file" "$event_json"
      fi
      add_wake "$(jq -cn --arg eid "$event_id" '{event_id: $eid, kind: "node1_approval", task_id: null, node_id: "node-1", source_commit_sha: null, is_reminder: false, is_transition: false}')"
      node1_watch_updated="$(printf '%s' "$node1_watch_updated" | jq -c --arg id "$card_id" '.seen_cards = ((.seen_cards + [$id]) | unique | .[-50:])')"
    done < <(jq -c '.cards[]' "$WORKDIR/node1-approvals.json" 2>/dev/null)
  else
    note "WARN node-1 approvals response not an array, skipping"
  fi
else
  note "WARN node-1 approvals fetch failed, skipping"
fi
# --- 新消息（assistant 文本 hash 未见过） ---
if bridge_get "$NODE1_BRIDGE_BASE/v1/muse/chat?limit=20" "$WORKDIR/node1-chat.json"; then
  if jq -e '.messages | type == "array"' "$WORKDIR/node1-chat.json" >/dev/null 2>&1; then
    while IFS= read -r msg_json; do
      [[ -n "$msg_json" ]] || continue
      msg_role="$(printf '%s' "$msg_json" | jq -r '.role // empty' 2>/dev/null)" || msg_role=""
      [[ "$msg_role" == "assistant" ]] || continue
      msg_text="$(printf '%s' "$msg_json" | jq -r '.text // empty' 2>/dev/null)" || msg_text=""
      [[ -n "$msg_text" ]] || continue
      msg_hash="$(printf '%s' "$msg_text" | sha256sum 2>/dev/null | awk '{print $1}')" || msg_hash=""
      [[ -n "$msg_hash" ]] || continue
      if printf '%s' "$node1_watch_updated" | jq -e --arg h "$msg_hash" '.seen_msg_hashes | index($h) != null' >/dev/null 2>&1; then
        continue
      fi
      msg_short="${msg_hash:0:12}"
      msg_snip="$(printf '%s' "$msg_text" | head -c 200)"
      event_id="node1_message:$msg_hash"
      event_file="$EVENTS_DIR/node1_message-$msg_short.json"
      if [[ ! -f "$event_file" ]]; then
        event_json="$(jq -cn --arg eid "$event_id" --arg h "$msg_hash" --arg snip "$msg_snip" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "node1_message", task_id: null, node_id: "node-1", source_commit_sha: null, source_paths: [], state: "DETECTED", severity: "info", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, node1_message: {hash: $h, snippet: $snip}}')"
        atomic_write "$event_file" "$event_json"
        # T-036: 事件文件在 hash 淘汰后仍用于去重；到期提醒由重试扫描处理。
        add_wake "$(jq -cn --arg eid "$event_id" '{event_id: $eid, kind: "node1_message", task_id: null, node_id: "node-1", source_commit_sha: null, is_reminder: false, is_transition: false}')"
      fi
      node1_watch_updated="$(printf '%s' "$node1_watch_updated" | jq -c --arg h "$msg_hash" '.seen_msg_hashes = ((.seen_msg_hashes + [$h]) | unique | .[-50:])')"
    done < <(jq -c '.messages[]' "$WORKDIR/node1-chat.json" 2>/dev/null)
  else
    note "WARN node-1 chat response not an array, skipping"
  fi
else
  note "WARN node-1 chat fetch failed, skipping"
fi
atomic_write "$NODE1_WATCH_FILE" "$node1_watch_updated"

# --- node-2 桥直通：新消息 / 新审批卡 -> 唤醒总控（Chen 2026-11-15 直令，2026-11-15 扩至三桥） ---
# node-2 经桥发消息或弹审批卡时，聊天本身不唤醒总控（R21），卡 30 分钟过期。
# 本节每轮轮询 node-2 桥（8789）：新卡（approval_id 未见过）与新消息
# （assistant 文本 hash 未见过）各建一个事件并 add_wake。桥不可达时只记 WARN，
# 不杀死本轮轮询。状态文件：$STATE_DIR/node2-watch.json
# （seen_cards: [approval_id...], seen_msg_hashes: [sha256...]，各保留最近 50 条）。
NODE2_WATCH_FILE="$STATE_DIR/node2-watch.json"
NODE2_BRIDGE_BASE="http://100.118.194.61:8789"
bridge_get() {
  local url="$1" out="$2"
  local proxy="${HTTPS_PROXY%:*}:3130"
  curl -sS --proxy "$proxy" --max-time 10 -o "$out" "$url" 2>/dev/null
}
node2_watch_init=""
if [[ -f "$NODE2_WATCH_FILE" ]]; then
  node2_watch_init="$(cat "$NODE2_WATCH_FILE" 2>/dev/null)" || node2_watch_init=""
fi
if ! printf '%s' "$node2_watch_init" | jq -e '.seen_cards and .seen_msg_hashes' >/dev/null 2>&1; then
  node2_watch_init='{"seen_cards": [], "seen_msg_hashes": []}'
fi
node2_watch_updated="$node2_watch_init"
# --- 新审批卡 ---
if bridge_get "$NODE2_BRIDGE_BASE/v1/muse/approvals" "$WORKDIR/node2-approvals.json"; then
  if jq -e '.cards | type == "array"' "$WORKDIR/node2-approvals.json" >/dev/null 2>&1; then
    while IFS= read -r card_json; do
      [[ -n "$card_json" ]] || continue
      card_id="$(printf '%s' "$card_json" | jq -r '.approval_id // empty' 2>/dev/null)" || card_id=""
      [[ -n "$card_id" ]] || continue
      if printf '%s' "$node2_watch_updated" | jq -e --arg id "$card_id" '.seen_cards | index($id) != null' >/dev/null 2>&1; then
        continue
      fi
      card_action="$(printf '%s' "$card_json" | jq -r '.action // empty' 2>/dev/null)" || card_action=""
      card_fp="$(printf '%s' "$card_json" | jq -r '.fingerprint // empty' 2>/dev/null)" || card_fp=""
      card_short="${card_id:0:12}"
      event_id="node2_approval:$card_id"
      event_file="$EVENTS_DIR/node2_approval-$card_short.json"
      if [[ ! -f "$event_file" ]]; then
        event_json="$(jq -cn --arg eid "$event_id" --arg cid "$card_id" --arg act "$card_action" --arg fp "$card_fp" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "node2_approval", task_id: null, node_id: "node-2", source_commit_sha: null, source_paths: [], state: "DETECTED", severity: "high", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, node2_approval: {approval_id: $cid, action: $act, fingerprint: $fp}}')"
        atomic_write "$event_file" "$event_json"
      fi
      add_wake "$(jq -cn --arg eid "$event_id" '{event_id: $eid, kind: "node2_approval", task_id: null, node_id: "node-2", source_commit_sha: null, is_reminder: false, is_transition: false}')"
      node2_watch_updated="$(printf '%s' "$node2_watch_updated" | jq -c --arg id "$card_id" '.seen_cards = ((.seen_cards + [$id]) | unique | .[-50:])')"
    done < <(jq -c '.cards[]' "$WORKDIR/node2-approvals.json" 2>/dev/null)
  else
    note "WARN node-2 approvals response not an array, skipping"
  fi
else
  note "WARN node-2 approvals fetch failed, skipping"
fi
# --- 新消息（assistant 文本 hash 未见过） ---
if bridge_get "$NODE2_BRIDGE_BASE/v1/muse/chat?limit=20" "$WORKDIR/node2-chat.json"; then
  if jq -e '.messages | type == "array"' "$WORKDIR/node2-chat.json" >/dev/null 2>&1; then
    while IFS= read -r msg_json; do
      [[ -n "$msg_json" ]] || continue
      msg_role="$(printf '%s' "$msg_json" | jq -r '.role // empty' 2>/dev/null)" || msg_role=""
      [[ "$msg_role" == "assistant" ]] || continue
      msg_text="$(printf '%s' "$msg_json" | jq -r '.text // empty' 2>/dev/null)" || msg_text=""
      [[ -n "$msg_text" ]] || continue
      msg_hash="$(printf '%s' "$msg_text" | sha256sum 2>/dev/null | awk '{print $1}')" || msg_hash=""
      [[ -n "$msg_hash" ]] || continue
      if printf '%s' "$node2_watch_updated" | jq -e --arg h "$msg_hash" '.seen_msg_hashes | index($h) != null' >/dev/null 2>&1; then
        continue
      fi
      msg_short="${msg_hash:0:12}"
      msg_snip="$(printf '%s' "$msg_text" | head -c 200)"
      event_id="node2_message:$msg_hash"
      event_file="$EVENTS_DIR/node2_message-$msg_short.json"
      if [[ ! -f "$event_file" ]]; then
        event_json="$(jq -cn --arg eid "$event_id" --arg h "$msg_hash" --arg snip "$msg_snip" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "node2_message", task_id: null, node_id: "node-2", source_commit_sha: null, source_paths: [], state: "DETECTED", severity: "info", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null, node2_message: {hash: $h, snippet: $snip}}')"
        atomic_write "$event_file" "$event_json"
        # T-036: 事件文件在 hash 淘汰后仍用于去重；到期提醒由重试扫描处理。
        add_wake "$(jq -cn --arg eid "$event_id" '{event_id: $eid, kind: "node2_message", task_id: null, node_id: "node-2", source_commit_sha: null, is_reminder: false, is_transition: false}')"
      fi
      node2_watch_updated="$(printf '%s' "$node2_watch_updated" | jq -c --arg h "$msg_hash" '.seen_msg_hashes = ((.seen_msg_hashes + [$h]) | unique | .[-50:])')"
    done < <(jq -c '.messages[]' "$WORKDIR/node2-chat.json" 2>/dev/null)
  else
    note "WARN node-2 chat response not an array, skipping"
  fi
else
  note "WARN node-2 chat fetch failed, skipping"
fi
atomic_write "$NODE2_WATCH_FILE" "$node2_watch_updated"

# --- 评论 -> 事件/挂接 ---
COMMENTS_INDEX="$(jq -c '.comments // {}' "$SCAN_FILE" 2>/dev/null)" || COMMENTS_INDEX="{}"
latest_unacked_result() {
local task="$1" node="$2" best="" best_det="" f st det
for f in "$EVENTS_DIR"/result-"$task"-"$node"-*.json; do
if [[ ! -f "$f" ]]; then
continue
fi

if jq -e 'has("s3") and .s3.decision.kind != "DELIVERY"' "$f" >/dev/null; then
continue
fi
st="$(jq -r '.state // empty' "$f" 2>/dev/null)"
if [[ "$st" != "ACKED" && "$st" != "REJECTED" && "$st" != "SUPERSEDED" && "$st" != "CLOSED_INTERNAL" ]]; then
det="$(jq -r '.timestamps.detected_at // empty' "$f" 2>/dev/null)"
if [[ -z "$best" || "$det" > "$best_det" ]]; then
best="$f"
best_det="$det"
fi
fi
done
printf '%s' "$best"
}

while IFS= read -r line; do
if [[ -z "$line" ]]; then
continue
fi
cid="$(printf '%s' "$line" | jq -r '.id // empty')"
cupd="$(printf '%s' "$line" | jq -r '.updated_at // empty')"
curl_issue="$(printf '%s' "$line" | jq -r '.issue_url // empty')"
cbody="$(printf '%s' "$line" | jq -r '.body // empty')"
if [[ -z "$cid" || -z "$cupd" || -z "$curl_issue" ]]; then
continue
fi
issue="${curl_issue##*/}"
if [[ ! "$issue" =~ ^[0-9]+$ ]]; then
continue
fi
existing="$(printf '%s' "$COMMENTS_INDEX" | jq -r --arg i "$issue" --argjson id "$cid" '.[$i] // [] | map(select(.id == $id)) |.[0] // empty')"
existing_upd=""
if [[ -n "$existing" ]]; then
existing_upd="$(printf '%s' "$existing" | jq -r '.updated_at // empty')"
fi
# 索引 upsert（新评论或编辑都更新）
COMMENTS_INDEX="$(printf '%s' "$COMMENTS_INDEX" | jq -c --arg i "$issue" --argjson id "$cid" --arg upd "$cupd" '.[$i] = ((.[$i] // []) | map(select(.id != $id)) + [{id: $id, updated_at: $upd, processed: true}])')"
if [[ -n "$existing" && "$existing_upd" == "$cupd" ]]; then
continue
fi
# 从正文提取 task / node
ctask=""; cnode=""
if [[ "$cbody" =~ (T-[0-9]+) ]]; then
ctask="${BASH_REMATCH[1]}"
fi
if [[ "$cbody" =~ ([0-9]+)号 ]]; then
cnode="node-${BASH_REMATCH[1]}"
elif [[ "$cbody" =~ node-([0-9]+) ]]; then
cnode="node-${BASH_REMATCH[1]}"
fi
sig_json="$(jq -cn --argjson cid "$cid" --arg upd "$cupd" --argjson iss "$issue" '{comment_id: $cid, updated_at: $upd, issue: $iss}')"
linked=""
if [[ -n "$ctask" && -n "$cnode" ]]; then
linked="$(latest_unacked_result "$ctask" "$cnode")"
fi
if [[ -n "$linked" ]]; then
# 挂接到已有的结果事件（不新建事件）；若该事件未在本次唤醒里，补进唤醒
updated="$(jq --argjson sig "$sig_json" '.signals += [$sig]' "$linked")"
atomic_write "$linked" "$updated"
le_id="$(jq -r '.event_id // empty' "$linked")"
le_kind="$(jq -r '.kind // empty' "$linked")"
le_task="$(jq -r '.task_id // empty' "$linked")"
le_node="$(jq -r '.node_id // empty' "$linked")"
le_sha="$(jq -r '.source_commit_sha // empty' "$linked")"
add_wake "$(jq -cn --arg eid "$le_id" --arg kind "$le_kind" --arg task "$le_task" --arg node "$le_node" --arg sha "$le_sha" '{event_id: $eid, kind: $kind, task_id: $task, node_id: $node, source_commit_sha: $sha, is_reminder: false, is_transition: false}')"
elif [[ -z "$existing" ]]; then
# 全新独立评论信号
event_id="issue:$issue:$cid:$cupd"
event_file="$EVENTS_DIR/issue-$issue-$cid.json"
if [[ ! -f "$event_file" ]]; then
event_json="$(jq -cn --arg eid "$event_id" --arg task "$ctask" --arg node "$cnode" --argjson sig "$sig_json" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "issue_signal", task_id: (if ($task | length) > 0 then $task else null end), node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: null, source_paths: [], state: "DETECTED", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [$sig], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null}')"
atomic_write "$event_file" "$event_json"
add_wake "$(jq -cn --arg eid "$event_id" --arg task "$ctask" --arg node "$cnode" '{event_id: $eid, kind: "issue_signal", task_id: (if ($task | length) > 0 then $task else null end), node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: null, is_reminder: false, is_transition: false}')"
fi
else
# 已有评论被编辑：若原事件是独立信号，更新其 event_id/updated_at，不重新唤醒
event_file="$EVENTS_DIR/issue-$issue-$cid.json"
if [[ -f "$event_file" ]]; then
updated="$(jq --arg eid "issue:$issue:$cid:$cupd" --argjson sig "$sig_json" '.event_id = $eid | .signals = [$sig]' "$event_file")"
atomic_write "$event_file" "$updated"
fi
fi
done < "$WORKDIR/comments.jsonl"

# --- 重试扫描：未确认事件到期重唤；超 12 次转 NEEDS_ATTENTION ---
UNACKED_COUNT=0
NEEDS_ATTENTION_COUNT=0
for f in "$EVENTS_DIR"/*.json; do
  if [[ ! -f "$f"  ]]; then
    continue
  fi
  st="$(jq -r '.state // empty' "$f" 2>/dev/null)" || {
    note "WARN unreadable event file $f; skipping"
    UNACKED_COUNT=$((UNACKED_COUNT + 1))
    continue
  }
  case "$st" in
    ACKED|REJECTED|SUPERSEDED|CLOSED_INTERNAL)
      continue
      ;;
    NEEDS_ATTENTION)
      NEEDS_ATTENTION_COUNT=$((NEEDS_ATTENTION_COUNT + 1))
      eid="$(jq -r '.event_id // empty' "$f")"
      printf '%s\n' "$(jq -cn --arg eid "$eid" '{event_id: $eid}')" >> "$WORKDIR/needs_attention.jsonl"
      continue
      ;;
    WAITING_APPROVAL|NEEDS_RECONCILIATION)
      UNACKED_COUNT=$((UNACKED_COUNT + 1))
      continue
      ;;
  esac
  UNACKED_COUNT=$((UNACKED_COUNT + 1))
  wakes="$(jq -r '.retry.wakes // 0' "$f" 2>/dev/null)" || wakes=0
  if [[ -z "$wakes" || "$wakes" == "null" ]]; then
    wakes=0
  fi
  case "$st" in
    DETECTED) RETRY_WINDOW_SECS=900 ;;
    FAILED_RETRYABLE) RETRY_WINDOW_SECS=14400 ;;
    *) RETRY_WINDOW_SECS=3600 ;;
  esac
  last_wake="$(jq -r '.retry.last_wake_at // empty' "$f" 2>/dev/null)" || last_wake=""
  due=1
  if [[ -n "$last_wake"  ]]; then
    last_epoch="$(date -d "$last_wake" +%s 2>/dev/null)" || last_epoch=""
    if [[ -n "$last_epoch"  ]] && [[ $((NOW_EPOCH - last_epoch)) -lt $RETRY_WINDOW_SECS  ]]; then
      due=0
    fi
  fi
  if [[ "$due" -eq 0  ]]; then
    continue
  fi
  eid="$(jq -r '.event_id // empty' "$f")"
  kind="$(jq -r '.kind // empty' "$f")"
  task="$(jq -r '.task_id // empty' "$f")"
  node="$(jq -r '.node_id // empty' "$f")"
  sha="$(jq -r '.source_commit_sha // empty' "$f")"
  retry_kind="full"
  receipt_path="$(jq -r '.review.receipt_path // empty' "$f")"
  delivery_status="$(jq -r '.delivery.status // empty' "$f")"
  if [[ "$st" == "REVIEWED" && -n "$receipt_path" && -f "$receipt_path" && ( "$delivery_status" == "FAILED" || "$delivery_status" == "UNKNOWN" ) ]]; then
    retry_kind="notify-only"
  fi
  if [[ "$wakes" -ge "$MAX_WAKES"  ]]; then
    updated="$(jq --arg now "$NOW_ISO" '.state = "NEEDS_ATTENTION" | .timestamps.needs_attention_at = $now' "$f")"
    atomic_write "$f" "$updated"
    NEEDS_ATTENTION_COUNT=$((NEEDS_ATTENTION_COUNT + 1))
    printf '%s\n' "$(jq -cn --arg eid "$eid" '{event_id: $eid}')" >> "$WORKDIR/needs_attention.jsonl"
    add_wake "$(jq -cn --arg eid "$eid" --arg kind "$kind" --arg task "$task" --arg node "$node" --arg sha "$sha" --arg retry_kind "$retry_kind" '{event_id: $eid, kind: $kind, task_id: (if ($task | length) > 0 then $task else null end), node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: (if ($sha | length) > 0 then $sha else null end), retry_kind: $retry_kind, is_reminder: true, is_transition: true}')"
  else
    updated="$(jq --arg now "$NOW_ISO" '.retry.wakes = ((.retry.wakes // 0) + 1) | .retry.last_wake_at = $now | .retry.attempt_count = ((.retry.attempt_count // 0) + 1)' "$f")"
    atomic_write "$f" "$updated"
    add_wake "$(jq -cn --arg eid "$eid" --arg kind "$kind" --arg task "$task" --arg node "$node" --arg sha "$sha" --arg retry_kind "$retry_kind" '{event_id: $eid, kind: $kind, task_id: (if ($task | length) > 0 then $task else null end), node_id: (if ($node | length) > 0 then $node else null end), source_commit_sha: (if ($sha | length) > 0 then $sha else null end), retry_kind: $retry_kind, is_reminder: true, is_transition: false}')"
  fi
done

# --- 推进游标（全部新事件已落盘）+ 健康状态 ---
COMMENTS_TOTAL="$(printf '%s' "$COMMENTS_INDEX" | jq -r '[.[] | length] | add // 0')"
FINAL_CURSOR="$(jq -r '.scan_cursor' "$SCAN_FILE")"
if [[ "$S3_CAN_ADVANCE" == "true" ]]; then
  FINAL_CURSOR="$HEAD_SHA"
fi
merged_scan="$(jq --arg cursor "$FINAL_CURSOR" --arg now "$NOW_ISO" --argjson comments "$COMMENTS_INDEX" --argjson watermark "$S3_WATERMARK" '.scan_cursor = $cursor | .scan_cursor_updated_at = $now | .comments = $comments | if $watermark != null then .s3_ledger = $watermark else . end' "$SCAN_FILE")"
last_success="$(jq -r '.last_success_at // empty' "$HEALTH_FILE" 2>/dev/null)" || last_success=""
if [[ -n "$last_success"  ]]; then
  ls_epoch="$(date -d "$last_success" +%s 2>/dev/null)" || ls_epoch=""
  if [[ -n "$ls_epoch"  ]] && [[ $((NOW_EPOCH - ls_epoch)) -gt 1800  ]]; then
    note "INFO recovered after stale success gap ($((NOW_EPOCH - ls_epoch))s)"
  fi
fi
health_frag="$(jq -cn --arg now "$NOW_ISO" '{last_success_at: $now, consecutive_api_failures: 0, last_attempt_at: $now}')"
if [[ -n "$RATE_REMAINING" && -n "$RATE_RESET" && "$RATE_REMAINING" =~ ^[0-9]+$ && "$RATE_RESET" =~ ^[0-9]+$ ]]; then
  if rate_frag="$(jq -cn --argjson rem "$RATE_REMAINING" --argjson rst "$RATE_RESET" --arg now "$NOW_ISO" '{rate: {remaining: $rem, reset: $rst, checked_at: $now}}' 2>/dev/null)"; then
    health_frag="$(printf '%s' "$health_frag" | jq -c --argjson r "$rate_frag" '. * $r' 2>/dev/null || printf '%s' "$health_frag")"
  fi
fi
health_merge "$health_frag"
atomic_write "$SCAN_FILE" "$merged_scan"
release_lock

# --- 决策 ---
wake_json="$(jq -s -c '.' "$WORKDIR/wake_events.jsonl" 2>/dev/null)" || wake_json="[]"
na_json="$(jq -s -c '.' "$WORKDIR/needs_attention.jsonl" 2>/dev/null)" || na_json="[]"
if [[ -s "$WORKDIR/wake_events.jsonl"  ]]; then
  has_new="$(jq -s -r '[.[] | select(.is_reminder == false)] | length' "$WORKDIR/wake_events.jsonl" 2>/dev/null)" || has_new=0
  payload="$(jq -cn --argjson ev "$wake_json" --argjson na "$na_json" --arg head "$HEAD_SHA" --argjson unacked "$UNACKED_COUNT" --argjson na_count "$NEEDS_ATTENTION_COUNT" '{events: $ev, needs_attention: $na, head: $head, unacked_count: $unacked, needs_attention_count: $na_count}')"
  if [[ "$has_new" -gt 0  ]]; then
    emit "wake" "muse-hub-activity" "$payload"
  else
    emit "wake" "muse-hub-activity-reminder" "$payload"
  fi
else
  payload="$(jq -cn --arg head "$HEAD_SHA" --argjson unacked "$UNACKED_COUNT" --argjson na_count "$NEEDS_ATTENTION_COUNT" --argjson ctotal "$COMMENTS_TOTAL" '{head: $head, unacked_count: $unacked, needs_attention_count: $na_count, comments_total: $ctotal}')"
  emit "silent" "no-change" "$payload"
fi
