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
# git ls-remote 读远端 HEAD；未变直接 silent，变了才用 GitHub Contents API
# 读取 BOARD 和候选任务书。raw 文本与 JSON/base64 两种响应都处理。
# 只对派给本号、状态为 待领、未见过的 task_id@vN 唤醒。
# BOARD 固定列：| 编号 | 任务 | 负责人 | 状态 | 任务书 | Issue |
set -euo pipefail
PATROL_VERSION="2026-11-11.1"
source "$HATCH_HOOK_RUNTIME"

REPO="xy3293/muse-hub"
BRANCH="main"
NODE_FILE="${NODE_FILE:-$HOME/.config/muse-hub/node-id}"
STATE_DIR="$HOME/hooks/state"
SEEN_FILE="$STATE_DIR/muse-hub-seen-tasks"
HEAD_FILE="$STATE_DIR/muse-hub-last-head"
DRY_RUN="${HATCH_HOOK_DRY_RUN:-0}"
legacy=false

node_id=""
if [[ -f "$NODE_FILE" ]]; then
  node_id="$(tr -d ' \t\r\n' < "$NODE_FILE")"
fi
if [[ -z "$node_id" ]]; then
  silent "node-id-not-configured" "{\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy,\"hint\":\"write node-1, node-2 or node-3 into ~/.config/muse-hub/node-id\"}"
  exit 0
fi
mkdir -p "$STATE_DIR"

# 旧 seen 在读取和 HEAD 提前返回之前迁移；dry-run 不写状态。
if [[ "$DRY_RUN" != "1" && -f "$SEEN_FILE" ]] && grep -qv '@' "$SEEN_FILE"; then
  migration_tmp=""
  if migration_tmp="$(mktemp "$SEEN_FILE.tmp.XXXXXX")" &&
    awk '
      /^T-[0-9]+$/ { print $0 "@v1"; next }
      /^T-[0-9]+@v[0-9]+$/ { print; next }
      { exit 1 }
    ' "$SEEN_FILE" > "$migration_tmp" &&
    [[ "$(awk 'END { print NR }' "$SEEN_FILE")" == "$(awk 'END { print NR }' "$migration_tmp")" ]] &&
    cp "$SEEN_FILE" "$SEEN_FILE.bak" &&
    mv "$migration_tmp" "$SEEN_FILE"; then
    :
  else
    [[ -z "$migration_tmp" ]] || rm -f "$migration_tmp"
    silent "seen-migration-failed" "{\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
    exit 0
  fi
fi

# 失败诊断只记录指定元数据，不记录 body、正文或其它响应头。
# patrol 不带 Authorization 头，后人不要加。
fetch_content() {
  local url_path="$1" body_file headers_file http_status curl_exit_code=0
  local remaining reset error_category response
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
      error_category="timeout"
    elif [[ "$curl_exit_code" -eq 6 || "$curl_exit_code" -eq 7 ]]; then
      error_category="network"
    elif [[ "$http_status" == "429" || ( "$http_status" == "403" && "$remaining" == "0" ) ]]; then
      error_category="rate_limited"
    elif [[ "$http_status" == 4* ]]; then
      error_category="http_4xx"
    elif [[ "$http_status" == 5* ]]; then
      error_category="http_5xx"
    fi
    mkdir -p "$STATE_DIR/logs"
    jq -cn --arg http_status "$http_status" \
      --arg rate_limit_remaining "$remaining" --arg rate_limit_reset "$reset" \
      --arg error_category "$error_category" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg account "$node_id" --arg url_path "$url_path" --argjson curl_exit_code "$curl_exit_code" \
      '{http_status:$http_status,rate_limit_remaining:$rate_limit_remaining,rate_limit_reset:$rate_limit_reset,error_category:$error_category,timestamp:$timestamp,account:$account,url_path:$url_path,curl_exit_code:$curl_exit_code}' \
      >> "$STATE_DIR/logs/api-diagnostics.jsonl"
    rm -f "$body_file" "$headers_file"
    return 1
  fi
  response="$(cat "$body_file")"
  rm -f "$body_file" "$headers_file"
  if [[ "$response" == "{"* ]]; then
    printf '%s' "$response" | jq -r '.content // empty' | tr -d '\n' | base64 -d 2>/dev/null
  else
    printf '%s' "$response"
  fi
}

# 1. 远端 HEAD（权威、无缓存）
head_sha="$(git ls-remote "https://github.com/$REPO.git" HEAD 2>/dev/null | awk '{print $1}')" || true
if [[ -z "$head_sha" ]]; then
  log "observation" '{"event":"ls-remote-failed"}'
  silent "ls-remote-failed" "{\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
  exit 0
fi
if [[ -f "$HEAD_FILE" && "$(cat "$HEAD_FILE")" == "$head_sha" ]]; then
  silent "board-unchanged" "{\"head\":\"$head_sha\",\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
  exit 0
fi

# 2. BOARD 与任务书共用 API、Accept 头、解码及失败诊断。
board_text="$(fetch_content "/repos/$REPO/contents/BOARD.md?ref=$BRANCH")" || {
  silent "board-fetch-failed" "{\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
  exit 0
}
if [[ -z "$board_text" ]]; then
  silent "board-unparseable" "{\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
  exit 0
fi

# 3. 每个候选先取版本，再用 task_id@vN 去重。
new_tasks=()
new_keys=()
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
  task_text=""
  if [[ -n "$task_file" ]]; then
    task_text="$(fetch_content "/repos/$REPO/contents/$task_file?ref=$BRANCH")" || task_text=""
  fi
  version="$(printf '%s\n' "$task_text" | grep -m1 '版本' | grep -oE 'v[0-9]+' | sed -n '1p')" || version=""
  # 防御条款：没有版本字段时按 v1 处理，不能因此不唤醒。
  if [[ -z "$version" ]]; then
    version="v1"
    legacy=true
  fi
  seen_key="$task_id@$version"
  if [[ -f "$SEEN_FILE" ]] && grep -Fxq "$seen_key" "$SEEN_FILE"; then
    continue
  fi
  new_tasks+=("$task_id")
  new_keys+=("$seen_key")
done < <(printf '%s\n' "$board_text" | grep -E '^\| T-[0-9]+ \|' || true)

# dry-run 不写 HEAD 和 seen。
if [[ "$DRY_RUN" != "1" ]]; then
  printf '%s' "$head_sha" > "$HEAD_FILE"
fi
if [[ "${#new_tasks[@]}" -eq 0 ]]; then
  silent "no-new-task-for-me" "{\"node\":\"$node_id\",\"head\":\"$head_sha\",\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
  exit 0
fi

# 同一版本只唤醒一次；任务书实质变更升版后可再次唤醒。
if [[ "$DRY_RUN" != "1" ]]; then
  printf '%s\n' "${new_keys[@]}" >> "$SEEN_FILE"
fi
tasks_json="$(printf '"%s",' "${new_tasks[@]}")"
tasks_json="[${tasks_json%,}]"
wake "new-task-assigned" "{\"node\":\"$node_id\",\"tasks\":$tasks_json,\"patrol_version\":\"$PATROL_VERSION\",\"legacy\":$legacy}"
