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
API_BASE="${GITHUB_API_BASE:-https://api.github.com}"
STATE_DIR="$HOME/hooks/state/muse-hub"
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
  local dest="$1" tmp="$1.tmp.$$"
  if [[ "$DRY_RUN" == "1"  ]]; then
    return 0
  fi
  printf '%s' "$2" > "$tmp"
  mv -f "$tmp" "$dest"
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

# HEAD（ls-remote，无缓存问题）
HEAD_SHA="$(git ls-remote "https://github.com/$REPO.git" HEAD 2>/dev/null | awk '{print $1}')" || HEAD_SHA=""
if [[ -z "$HEAD_SHA"  ]]; then
  record_api_failure "ls-remote-failed"
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

# 每个新提交的文件列表（逐提交取，避免 Compare files 截断）
: > "$WORKDIR/new_files.txt"
while read -r sha; do
  if [[ -z "$sha"  ]]; then
    continue
  fi
  if ! api_get "$API_BASE/repos/$REPO/commits/$sha" "$WORKDIR/commit.json" "$WORKDIR/commit.hdr"; then
    record_api_failure "commit-fetch-failed"
  fi
  cp "$WORKDIR/commit.json" "$WORKDIR/commit-$sha.json"
  jq -r --arg sha "$sha" '.files[]? | "\($sha)\t\(.filename)"' "$WORKDIR/commit.json" 2>/dev/null >> "$WORKDIR/new_files.txt" || true
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
local eid
eid="$(printf '%s' "$1" | jq -r '.event_id')"
if [[ -z "${WAKE_SET[$eid]:-}" ]]; then
WAKE_SET["$eid"]=1
printf '%s\n' "$1" >> "$WORKDIR/wake_events.jsonl"
fi
}

# --- 新提交 -> 事件 ---
declare -A TRIPLE_PATHS
declare -A TRIPLE_KIND
while IFS=$'\t' read -r sha path; do
if [[ -z "$path" ]]; then
continue
fi
if [[ "$path" =~ ^results/(node-[0-9]+)/ ]]; then
node="${BASH_REMATCH[1]}"
task=""
if [[ "$path" =~ (T-[0-9]+) ]]; then
task="${BASH_REMATCH[1]}"
fi
if [[ -n "$task" ]]; then
key="$task|$node|$sha"
TRIPLE_KIND["$key"]="result"
else
key="unknown|$node|$sha"
TRIPLE_KIND["$key"]="unknown"
fi
TRIPLE_PATHS["$key"]+="$path"$'\n'
fi
done < "$WORKDIR/new_files.txt"

for key in "${!TRIPLE_KIND[@]}"; do
kind="${TRIPLE_KIND[$key]}"
IFS='|' read -r part1 part2 part3 <<< "$key"
paths_json="$(printf '%s' "${TRIPLE_PATHS[$key]}" | jq -R -s 'split("\n") | map(select(length > 0))')"
if [[ "$kind" == "result" ]]; then
task="$part1"; node="$part2"; sha="$part3"
event_id="result:$task:$node:$sha"
event_file="$EVENTS_DIR/result-$task-$node-$sha.json"
if [[ ! -f "$event_file" ]]; then
event_json="$(jq -cn --arg eid "$event_id" --arg task "$task" --arg node "$node" --arg sha "$sha" --argjson paths "$paths_json" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "result_revision", task_id: $task, node_id: $node, source_commit_sha: $sha, source_paths: $paths, state: "DETECTED", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: null}')"
atomic_write "$event_file" "$event_json"
add_wake "$(jq -cn --arg eid "$event_id" --arg task "$task" --arg node "$node" --arg sha "$sha" '{event_id: $eid, kind: "result_revision", task_id: $task, node_id: $node, source_commit_sha: $sha, is_reminder: false, is_transition: false}')"
fi
else
node="$part2"; sha="$part3"
event_id="unknown:$node:$sha"
event_file="$EVENTS_DIR/unknown-$node-$sha.json"
if [[ ! -f "$event_file" ]]; then
event_json="$(jq -cn --arg eid "$event_id" --arg node "$node" --arg sha "$sha" --argjson paths "$paths_json" --arg now "$NOW_ISO" '{schema_version: 1, event_id: $eid, kind: "unknown_result", task_id: null, node_id: $node, source_commit_sha: $sha, source_paths: $paths, state: "NEEDS_RECONCILIATION", review: null, delivery: {status: "NOT_SENT", attempt_count: 0, accepted_at: null}, approval: {status: "NONE", operation_id: null}, main_ack: {acked: false, ack_commit_sha: null, ack_method: null}, retry: {attempt_count: 1, wakes: 1, last_wake_at: $now, next_attempt_at: null}, signals: [], timestamps: {detected_at: $now, review_started_at: null, receipt_saved_at: null, main_acked_at: null}, last_error: "task id not found in result path"}')"
atomic_write "$event_file" "$event_json"
add_wake "$(jq -cn --arg eid "$event_id" --arg node "$node" --arg sha "$sha" '{event_id: $eid, kind: "unknown_result", task_id: null, node_id: $node, source_commit_sha: $sha, is_reminder: false, is_transition: false}')"
fi
fi
done

# --- MUSE-ACK：只处理本次 Compare 枚举的提交 ---
ack_warning() {
if [[ "$DRY_RUN" != "1" ]]; then
jq -cn --arg at "$NOW_ISO" --arg sha "$ack_sha" --arg eid "$ack_event" --arg condition "$1" --arg detail "$2" '{at: $at, ack_commit_sha: $sha, event_id: $eid, failed_condition: $condition, detail: $detail}' >> "$LOGS_DIR/ack-warnings.jsonl"
fi
}
ack_pattern='^MUSE-ACK task=([^[:space:]]+) node=([^[:space:]]+) event=(result:([^:[:space:]]+):([^:[:space:]]+):([0-9a-f]{40})) verdict=(PASS|REJECT)$'
while IFS= read -r ack_sha; do
[[ -n "$ack_sha" ]] || continue
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
if jq -e '.state == "ACKED" or .state == "REJECTED" or .state == "SUPERSEDED"' "$ack_file" >/dev/null; then
continue
fi
if ! jq -e 'any(.files[]?; .filename == "BOARD.md")' "$WORKDIR/commit-$ack_sha.json" >/dev/null; then
ack_warning "4" "commit does not change BOARD.md"
continue
fi
if ! api_get "$API_BASE/repos/$REPO/contents/BOARD.md?ref=$ack_sha" "$WORKDIR/ack-board.json" "$WORKDIR/ack-board.hdr"; then
release_lock
record_api_failure "ack-board-fetch-failed"
fi
# Match a unique Markdown row by its exact task cell and exact status cell.
if ! jq -er '.content // "" | gsub("\\s"; "") | @base64d' "$WORKDIR/ack-board.json" > "$WORKDIR/ack-board.md" 2>/dev/null ||
   ! jq -Re --slurp --arg task "$ack_task" --arg verdict "$ack_verdict" '
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
done < "$WORKDIR/new_commits.txt"

# --- 评论 -> 事件/挂接 ---
COMMENTS_INDEX="$(jq -c '.comments // {}' "$SCAN_FILE" 2>/dev/null)" || COMMENTS_INDEX="{}"
latest_unacked_result() {
local task="$1" node="$2" best="" best_det="" f st det
for f in "$EVENTS_DIR"/result-"$task"-"$node"-*.json; do
if [[ ! -f "$f" ]]; then
continue
fi
st="$(jq -r '.state // empty' "$f" 2>/dev/null)"
if [[ "$st" != "ACKED" && "$st" != "REJECTED" && "$st" != "SUPERSEDED" ]]; then
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
    ACKED|REJECTED|SUPERSEDED)
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
merged_scan="$(jq --arg cursor "$HEAD_SHA" --arg now "$NOW_ISO" --argjson comments "$COMMENTS_INDEX" '.scan_cursor = $cursor | .scan_cursor_updated_at = $now | .comments = $comments' "$SCAN_FILE" 2>/dev/null)" || merged_scan="$(jq -n --arg cursor "$HEAD_SHA" --arg now "$NOW_ISO" --argjson comments "$COMMENTS_INDEX" '{schema_version: 1, scan_cursor: $cursor, scan_cursor_updated_at: $now, comments: $comments}')"
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
