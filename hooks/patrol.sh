#!/usr/bin/env bash
# muse-hub 巡逻脚本（Hook 用）
#
# 各号安装与升级（见 ONBOARDING.md）：
#   覆盖旧副本前，先把旧副本存为 patrol-muse-hub.sh.last-good：
#   cp ~/hooks/scripts/patrol-muse-hub.sh ~/hooks/scripts/patrol-muse-hub.sh.last-good
#   cp ~/workspace/muse-hub/hooks/patrol.sh ~/hooks/scripts/patrol-muse-hub.sh
#   chmod +x ~/hooks/scripts/patrol-muse-hub.sh
#   echo -n 'node-1' > ~/.config/muse-hub/node-id   # 按自己的号写 node-1 / node-2 / node-3
#   再用 hooks.add 注册（poll_interval_secs 建议 300–600），dry_run 通过后启用。
#
# 先 replay pending，再判断远端 HEAD；变了才用 GitHub Contents API
# 读取 BOARD 和候选任务书。raw 文本与 JSON/base64 两种响应都处理。
# 只对派给本号、状态为 待领、未见过的 task_id@vN 唤醒。
# BOARD 固定列：| 编号 | 任务 | 负责人 | 状态 | 任务书 | Issue |
set -euo pipefail
export LC_ALL=C.UTF-8
START_SECONDS=$SECONDS
PATROL_VERSION="2026-11-11.3"
source "$HATCH_HOOK_RUNTIME"

REPO="xy3293/muse-hub"
BRANCH="main"
NODE_FILE="${NODE_FILE:-$HOME/.config/muse-hub/node-id}"
STATE_DIR="$HOME/hooks/state"
SEEN_FILE="$STATE_DIR/muse-hub-seen-tasks"
MIGRATION_FAILURES_FILE="$STATE_DIR/muse-hub-migration-failures"
HEAD_FILE="$STATE_DIR/muse-hub-last-head"
DRY_RUN="${HATCH_HOOK_DRY_RUN:-0}"
PENDING_DIR="$STATE_DIR/pending"

node_id=""
if [[ -f "$NODE_FILE" ]]; then
  node_id="$(tr -d ' \t\r\n' < "$NODE_FILE")"
fi
if [[ -z "$node_id" ]]; then
  silent "node-id-not-configured" "{\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":false,\"hint\":\"write node-1, node-2 or node-3 into ~/.config/muse-hub/node-id\"}"
  exit 0
fi
mkdir -p "$STATE_DIR"

# 非阻塞锁覆盖迁移、replay 和全部状态交接；退出时由内核释放。
LOCK_FILE="$STATE_DIR/muse-hub.patrol.lock"
exec {lock_fd}>>"$LOCK_FILE"
if ! flock -n "$lock_fd"; then
  lock_mtime="$(stat -c %Y "$LOCK_FILE" 2>/dev/null)" || lock_mtime=0
  if [[ "$lock_mtime" -gt 0 && $(( $(date +%s) - lock_mtime )) -gt 600 ]]; then
    log "observation" "$(jq -cn --argjson wait_seconds "$((SECONDS - START_SECONDS))" \
      '{event:"stale-lock-takeover",wait_seconds:$wait_seconds}')"
    rm -f "$LOCK_FILE"
    exec {lock_fd}>&-
    exec {lock_fd}>>"$LOCK_FILE"
    if ! flock -n "$lock_fd"; then
      log "observation" "$(jq -cn --argjson wait_seconds "$((SECONDS - START_SECONDS))" \
        '{event:"lock-busy",wait_seconds:$wait_seconds}')"
      silent "lock-busy" "{\"patrol_version\":\"$PATROL_VERSION\"}"
      exit 0
    fi
  else
    log "observation" "$(jq -cn --argjson wait_seconds "$((SECONDS - START_SECONDS))" \
      '{event:"lock-busy",wait_seconds:$wait_seconds}')"
    silent "lock-busy" "{\"patrol_version\":\"$PATROL_VERSION\"}"
    exit 0
  fi
fi

touch "$LOCK_FILE"

write_migration_counter() {
  if ! printf '%s\n' "$1" > "$MIGRATION_FAILURES_FILE"; then
    log "observation" "$(jq -cn --argjson failure_count "$1" \
      '{event:"seen-migration-counter-write-failed",reason:"counter-write-failed",failure_count:$failure_count}')"
  fi
}

# 旧 seen 在读取和 HEAD 提前返回之前迁移；dry-run 不写状态。
if [[ "$DRY_RUN" != "1" && -f "$SEEN_FILE" ]] && grep -qv '@' "$SEEN_FILE"; then
  migration_tmp=""
  migration_reason=""
  if ! migration_tmp="$(mktemp "$SEEN_FILE.tmp.XXXXXX")"; then
    migration_reason="write-failed"
  elif ! awk '
      { sub(/\r$/, "") }
      /^[[:space:]]*$/ { next }
      /^T-[0-9]+$/ { print $0 "@v1"; next }
      /^T-[0-9]+@v[0-9]+$/ { print; next }
      { exit 1 }
    ' "$SEEN_FILE" > "$migration_tmp"; then
    migration_reason="awk-failed"
  else
    old_eff="$(tr -d '\r' < "$SEEN_FILE" | grep -cE '^T-[0-9]+(@v[0-9]+)?$' || true)"
    new_eff="$(tr -d '\r' < "$migration_tmp" | grep -cE '^T-[0-9]+@v[0-9]+$' || true)"
    if [[ "$old_eff" != "$new_eff" ]]; then
      migration_reason="line-count-mismatch"
    elif ! cp "$SEEN_FILE" "$SEEN_FILE.bak" || ! mv "$migration_tmp" "$SEEN_FILE"; then
      migration_reason="write-failed"
    fi
  fi
  if [[ -n "$migration_reason" ]]; then
    [[ -z "$migration_tmp" ]] || rm -f "$migration_tmp"
    migration_failures="$(cat "$MIGRATION_FAILURES_FILE" 2>/dev/null)" || migration_failures=0
    [[ "$migration_failures" =~ ^[0-9]+$ ]] || migration_failures=0
    migration_failures=$((10#$migration_failures + 1))
    write_migration_counter "$migration_failures"
    seen_line_count="$(awk 'END { print NR+0 }' "$SEEN_FILE")"
    migration_payload="$(jq -cn --arg reason "$migration_reason" \
      --argjson failure_count "$migration_failures" --argjson seen_line_count "$seen_line_count" \
      --arg patrol_version "$PATROL_VERSION" \
      '{reason:$reason,failure_count:$failure_count,seen_line_count:$seen_line_count,patrol_version:$patrol_version,legacy:false}')"
    log "observation" "$(jq -cn --argjson payload "$migration_payload" \
      '$payload + {event:"seen-migration-failed"}')"
    if [[ "$migration_failures" -ge 3 ]]; then
      wake "seen-migration-failed-3x" "$migration_payload"
    else
      silent "seen-migration-failed" "$migration_payload"
    fi
    exit 0
  fi
  write_migration_counter 0
fi

# 失败诊断只记录指定元数据，不记录 body、正文或其它响应头。
# patrol 不带 Authorization 头，后人不要加。
# 返回码把 error_category 带出命令替换，避免失败与空内容混淆。
fetch_content() {
  local url_path="$1" body_file headers_file http_status curl_exit_code=0
  local remaining reset error_category="" response decoded="" failure_code=1
  body_file="$(mktemp)"
  headers_file="$(mktemp)"
  http_status="$(curl --silent --show-error --max-time 10 \
    -H "Accept: application/vnd.github.raw+json" \
    -o "$body_file" -D "$headers_file" -w "%{http_code}" \
    "https://api.github.com$url_path" 2>/dev/null)" || curl_exit_code=$?
  if [[ "$curl_exit_code" -ne 0 || "$http_status" != 2* ]]; then
    remaining="$(awk 'tolower($1) == "x-ratelimit-remaining:" { gsub(/\r/, "", $2); value=$2 } END { print value }' "$headers_file")"
    reset="$(awk 'tolower($1) == "x-ratelimit-reset:" { gsub(/\r/, "", $2); value=$2 } END { print value }' "$headers_file")"
    error_category="network"
    if [[ "$curl_exit_code" -eq 28 ]]; then
      error_category="timeout"; failure_code=2
    elif [[ "$curl_exit_code" -ne 0 ]]; then
      error_category="network"
    elif [[ "$http_status" == "429" || ( "$http_status" == "403" && "$remaining" == "0" ) ]]; then
      error_category="rate_limited"; failure_code=5
    elif [[ "$http_status" == 4* ]]; then
      error_category="http_4xx"; failure_code=3
    elif [[ "$http_status" == 5* ]]; then
      error_category="http_5xx"; failure_code=4
    fi
  else
    response="$(cat "$body_file")"
    if [[ "$response" == "{"* ]]; then
      if ! decoded="$(printf '%s' "$response" | jq -er 'select(.encoding == "base64") | .content | strings' | tr -d '\n' | base64 -d 2>/dev/null)"; then
        error_category="parse"; failure_code=6
      fi
    else
      decoded="$response"
    fi
  fi
  if [[ -n "$error_category" ]]; then
    if [[ "$DRY_RUN" != "1" ]]; then
      mkdir -p "$STATE_DIR/logs"
      local diagnostics="$STATE_DIR/logs/api-diagnostics.jsonl"
      # 当前文件 + 3 个归档 ≈ 20MB 上限；每条写入前检查，不采样。
      if [[ -f "$diagnostics" && "$(stat -c %s "$diagnostics")" -gt 5242880 ]]; then
        rm -f "$diagnostics.3"
        [[ ! -f "$diagnostics.2" ]] || mv "$diagnostics.2" "$diagnostics.3"
        [[ ! -f "$diagnostics.1" ]] || mv "$diagnostics.1" "$diagnostics.2"
        mv "$diagnostics" "$diagnostics.1"
      fi
      jq -cn --arg http_status "$http_status" \
        --arg rate_limit_remaining "${remaining:-}" --arg rate_limit_reset "${reset:-}" \
        --arg error_category "$error_category" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg account "$node_id" --arg url_path "$url_path" --argjson curl_exit_code "$curl_exit_code" \
        '{http_status:$http_status,rate_limit_remaining:$rate_limit_remaining,rate_limit_reset:$rate_limit_reset,error_category:$error_category,timestamp:$timestamp,account:$account,url_path:$url_path,curl_exit_code:$curl_exit_code}' \
        >> "$diagnostics"
    fi
    rm -f "$body_file" "$headers_file"
    return "$failure_code"
  fi
  rm -f "$body_file" "$headers_file"
  printf '%s' "$decoded"
}

fetch_error_category() {
  case "$1" in
    2) printf timeout ;; 3) printf http_4xx ;; 4) printf http_5xx ;;
    5) printf rate_limited ;; 6) printf parse ;; *) printf network ;;
  esac
}

# runtime 的 wake 可能 exit；在子 shell 中调用以便按返回码清理 pending。
# 先恢复持久化载荷，即使 HEAD 相同或 seen 已存在也必须尝试。
# 记录本轮尝试过的 ID（包括失败），解析阶段不再次主动投递。
declare -A replayed_events=()
seen_keys_to_record=()
delivered=false
if [[ "$DRY_RUN" != "1" ]]; then
  for pending_file in "$PENDING_DIR"/*.json; do
    [[ -f "$pending_file" ]] || continue
    if ! record="$(jq -ce 'select((.event_id | type == "string") and
      (.task_id | type == "string") and (.version | type == "string") and
      (.payload | type == "object"))' "$pending_file")"; then
      log "observation" '{"event":"invalid-pending-record"}'
      continue
    fi
    event_id="$(jq -r '.event_id' <<< "$record")"
    payload="$(jq -c '.payload' <<< "$record")"
    replayed_events["$event_id"]=1
    # 修复在 pending 之后、seen 之前中断的状态；稍后统一追加 seen。
    seen_keys_to_record+=("$(jq -r '.task_id + "@" + .version' <<< "$record")")
    if (wake "new-task-assigned" "$payload"); then
      rm -f "$pending_file"
      delivered=true
    fi
  done
fi

# 远端 HEAD（权威、无缓存）；replay 必须早于这里的快速退出。
head_sha="$(git ls-remote "https://github.com/$REPO.git" HEAD 2>/dev/null | awk '{print $1}')" || true
if [[ -z "$head_sha" ]]; then
  log "observation" '{"event":"ls-remote-failed"}'
  silent "ls-remote-failed" "{\"patrol_version\":\"$PATROL_VERSION\"}"
  exit 0
fi
if [[ -f "$HEAD_FILE" && "$(cat "$HEAD_FILE")" == "$head_sha" ]]; then
  [[ "$delivered" == false ]] || exit 0
  silent "board-unchanged" "{\"head\":\"$head_sha\",\"patrol_version\":\"$PATROL_VERSION\"}"
  exit 0
fi

# BOARD 与任务书固定在本轮 HEAD，避免读到不同提交的内容。
board_fetch_rc=0
board_text="$(fetch_content "/repos/$REPO/contents/BOARD.md?ref=$head_sha")" || board_fetch_rc=$?
if [[ "$board_fetch_rc" -ne 0 ]]; then
  log "observation" "$(jq -cn --arg error_category "$(fetch_error_category "$board_fetch_rc")" \
    '{event:"board-fetch-failed",error_category:$error_category}')"
  silent "board-fetch-failed" "{\"patrol_version\":\"$PATROL_VERSION\"}"
  exit 0
fi
if [[ -z "$board_text" ]]; then
  silent "board-unparseable" "{\"patrol_version\":\"$PATROL_VERSION\"}"
  exit 0
fi

# 每个候选先独立取版本，再用 task_id@vN 去重。
new_keys=()
new_events=()
new_payloads=()
retry_tasks=false
while IFS= read -r line; do
  task_id="$(printf '%s' "$line" | awk -F'|' '{gsub(/ /,"",$2); print $2}')"
  owner="$(printf '%s' "$line" | awk -F'|' '{gsub(/ /,"",$4); print $4}')"
  status="$(printf '%s' "$line" | awk -F'|' '{gsub(/ /,"",$5); print $5}')"
  [[ -z "$task_id" ]] && continue
  [[ "$owner" != "$node_id" ]] && continue
  [[ "$status" != "待领" ]] && continue
  task_file="$(printf '%s' "$line" | awk -F'|' '{print $6}' | grep -oE 'tasks/[^)|]+\.md' | sed -n '1p')" || task_file=""
  if [[ -z "$task_file" ]]; then
    task_file="$(printf '%s' "$line" | grep -oE 'tasks/[^)|]+\.md' | sed -n '1p')" || task_file=""
  fi
  task_fetch_rc=0
  if [[ -n "$task_file" ]]; then
    task_text="$(fetch_content "/repos/$REPO/contents/$task_file?ref=$head_sha")" || task_fetch_rc=$?
  else
    task_fetch_rc=6
  fi
  if [[ "$task_fetch_rc" -ne 0 ]]; then
    log "observation" "$(jq -cn --arg task_id "$task_id" \
      --arg error_category "$(fetch_error_category "$task_fetch_rc")" \
      '{event:"task-fetch-failed",task_id:$task_id,error_category:$error_category}')"
    retry_tasks=true
    continue
  fi
  task_prefix="$(printf '%s\n' "$task_text" | sed -n '1,15p')"
  version_lines="$(printf '%s\n' "$task_prefix" | grep -E '^版本[:：][[:space:]]*v[0-9]+$' || true)"
  version_count="$(printf '%s\n' "$version_lines" | grep -c '^版本' || true)"
  task_legacy=false
  if [[ "$version_count" -ge 2 ]]; then
    version_error="ambiguous-version"
  elif [[ "$version_count" -eq 1 ]]; then
    version="$(printf '%s\n' "$version_lines" | grep -oE 'v[0-9]+$')"
    version_error=""
  elif [[ "$task_prefix" == *版本* ]]; then
    version_error="malformed-version"
  else
    version="v1"
    task_legacy=true
    version_error=""
  fi
  if [[ -n "$version_error" ]]; then
    if [[ "$version_error" == "malformed-version" ]]; then
      malformed_line="$(printf '%s\n' "$task_prefix" | sed -n '/版本/{p;q;}')"
      log "observation" "$(jq -cn --arg event "$version_error" --arg task_id "$task_id" \
        --arg line "${malformed_line:0:60}" '{event:$event,task_id:$task_id,line:$line}')"
    else
      log "observation" "$(jq -cn --arg event "$version_error" --arg task_id "$task_id" \
        '{event:$event,task_id:$task_id}')"
    fi
    retry_tasks=true
    continue
  fi
  seen_key="$task_id@$version"
  event_id="$seen_key@$head_sha"
  [[ -z "${replayed_events[$event_id]:-}" ]] || continue
  if [[ -f "$SEEN_FILE" ]] && grep -Fxq "$seen_key" "$SEEN_FILE"; then
    continue
  fi
  # BOARD 若重复列出同一任务，本轮也只生成一个事件。
  [[ " ${new_events[*]} " != *" $event_id "* ]] || continue
  new_keys+=("$seen_key")
  new_events+=("$event_id")
  new_payloads+=("$(jq -cn --arg node "$node_id" --arg event_id "$event_id" \
    --arg task_id "$task_id" --arg version "$version" --arg head_sha "$head_sha" \
    --arg patrol_version "$PATROL_VERSION" --argjson legacy "$task_legacy" \
    '{event_id:$event_id,node:$node,head_sha:$head_sha,patrol_version:$patrol_version,
      tasks:[{task_id:$task_id,version:$version,legacy:$legacy}]}')")
done < <(printf '%s\n' "$board_text" | grep -E '^\| T-[0-9]+ \|' || true)

if [[ "$DRY_RUN" != "1" ]]; then
  # 所有事件先原子发布完整 pending；已有同名记录绝不覆盖。
  for i in "${!new_events[@]}"; do
    event_id="${new_events[$i]}"
    pending_file="$PENDING_DIR/$event_id.json"
    mkdir -p "$PENDING_DIR"
    if [[ ! -e "$pending_file" ]]; then
      pending_tmp="$(mktemp "$PENDING_DIR/.pending.XXXXXX")"
      jq -cn --arg event_id "$event_id" --arg task_id "${new_keys[$i]%@*}" \
        --arg version "${new_keys[$i]##*@}" --arg head_sha "$head_sha" --arg node "$node_id" \
        --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson payload "${new_payloads[$i]}" \
        '{event_id:$event_id,task_id:$task_id,version:$version,head_sha:$head_sha,
          node:$node,created_at:$created_at,payload:$payload}' > "$pending_tmp"
      ln "$pending_tmp" "$pending_file"
      rm -f "$pending_tmp"
    fi
  done
  # 顺序不能倒置：pending → seen → HEAD → wake → 删除 pending。
  seen_keys_to_record+=("${new_keys[@]}")
  for seen_key in "${seen_keys_to_record[@]}"; do
    if [[ ! -f "$SEEN_FILE" ]] || ! grep -Fxq "$seen_key" "$SEEN_FILE"; then
      printf '%s\n' "$seen_key" >> "$SEEN_FILE"
    fi
  done
  # 读取/版本失败必须让同一 HEAD 下轮重试，不能被快速退出吞掉。
  if [[ "$retry_tasks" == false ]]; then
    printf '%s' "$head_sha" > "$HEAD_FILE"
  fi
fi
if [[ "${#new_events[@]}" -eq 0 ]]; then
  [[ "$delivered" == false ]] || exit 0
  silent "no-new-task-for-me" "{\"node\":\"$node_id\",\"head\":\"$head_sha\",\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":false}"
  exit 0
fi

for i in "${!new_events[@]}"; do
  if [[ "$DRY_RUN" == "1" ]]; then
    (wake "new-task-assigned" "${new_payloads[$i]}")
  else
    pending_file="$PENDING_DIR/${new_events[$i]}.json"
    payload="$(jq -c '.payload' "$pending_file")"
    if (wake "new-task-assigned" "$payload"); then
      rm -f "$pending_file"
    fi
  fi
done
