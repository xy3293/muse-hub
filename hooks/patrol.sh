#!/usr/bin/env bash
# muse-hub 巡逻脚本（Hook 用）
#
# 各号安装方法（见 ONBOARDING.md）：
#   cp ~/workspace/muse-hub/hooks/patrol.sh ~/hooks/scripts/patrol-muse-hub.sh
#   chmod +x ~/hooks/scripts/patrol-muse-hub.sh
#   echo -n 'node-1' > ~/.config/muse-hub/node-id   # 按自己的号写 node-1 / node-2 / node-3
#   再用 hooks.add 注册（poll_interval_secs 建议 300–600），dry_run 通过后启用。
#
# 工作方式：
#   1. 用 git ls-remote 读远端 HEAD（权威、无 CDN 缓存），与本地水位比对；
#      HEAD 没变直接 silent，不再请求 BOARD。
#   2. HEAD 变了才用 api.github.com 拉 BOARD.md，带
#      Accept: application/vnd.github.raw+json，绕开 raw.githubusercontent.com 的 5 分钟缓存。
#      响应可能是 raw 文本，也可能是 JSON（含 base64 的 content 字段），两种都处理。
#   3. 在 BOARD 表格里找派给本号、状态为 待领 的任务；只对未见过的新任务 wake，
#      见过的任务 ID 记在 ~/hooks/state/muse-hub-seen-tasks。
#
# BOARD 表格格式（固定列，改列必须同步改本脚本）：
#   | 编号 | 任务 | 负责人 | 状态 | 任务书 | Issue |
set -euo pipefail
source "$HATCH_HOOK_RUNTIME"

REPO="xy3293/muse-hub"
BRANCH="main"
NODE_FILE="$HOME/.config/muse-hub/node-id"
STATE_DIR="$HOME/hooks/state"
SEEN_FILE="$STATE_DIR/muse-hub-seen-tasks"
HEAD_FILE="$STATE_DIR/muse-hub-last-head"
DRY_RUN="${HATCH_HOOK_DRY_RUN:-0}"

node_id=""
if [[ -f "$NODE_FILE" ]]; then
  node_id="$(tr -d ' \t\r\n' < "$NODE_FILE")"
fi
if [[ -z "$node_id" ]]; then
  silent "node-id-not-configured" '{"hint":"write node-1, node-2 or node-3 into ~/.config/muse-hub/node-id"}'
  exit 0
fi

mkdir -p "$STATE_DIR"

# 1. 远端 HEAD（权威、无缓存）
head_sha="$(git ls-remote "https://github.com/$REPO.git" HEAD 2>/dev/null | awk '{print $1}')" || true
if [[ -z "$head_sha" ]]; then
  log "observation" '{"event":"ls-remote-failed"}'
  silent "ls-remote-failed" '{}'
  exit 0
fi
if [[ -f "$HEAD_FILE" && "$(cat "$HEAD_FILE")" == "$head_sha" ]]; then
  silent "board-unchanged" "{\"head\":\"$head_sha\"}"
  exit 0
fi

# 2. 拉 BOARD.md（api.github.com + raw Accept 头，绕开 raw 域名的 5 分钟缓存）
board_resp="$(curl --fail --silent --show-error --max-time 10 \
  -H "Accept: application/vnd.github.raw+json" \
  "https://api.github.com/repos/$REPO/contents/BOARD.md?ref=$BRANCH" 2>&1)" || {
  log "observation" '{"event":"board-fetch-failed"}'
  silent "board-fetch-failed" '{}'
  exit 0
}
board_text=""
if [[ "$board_resp" == "{"* ]]; then
  # JSON：content 字段是 base64
  board_text="$(printf '%s' "$board_resp" | jq -r '.content // empty' | tr -d '\n' | base64 -d 2>/dev/null)" || board_text=""
else
  board_text="$board_resp"
fi
if [[ -z "$board_text" ]]; then
  log "observation" '{"event":"board-empty-or-unparseable"}'
  silent "board-unparseable" '{}'
  exit 0
fi

# 3. 找派给本号、状态为 待领 的任务
#    表格行格式：| T-001 | 标题 | node-1 | 待领 | ... |
new_tasks=()
while IFS= read -r line; do
  task_id="$(printf '%s' "$line" | awk -F'|' '{gsub(/ /,"",$2); print $2}')"
  owner="$(printf '%s' "$line" | awk -F'|' '{gsub(/ /,"",$4); print $4}')"
  status="$(printf '%s' "$line" | awk -F'|' '{gsub(/ /,"",$5); print $5}')"
  [[ -z "$task_id" ]] && continue
  [[ "$owner" != "$node_id" ]] && continue
  [[ "$status" != "待领" ]] && continue
  if [[ -f "$SEEN_FILE" ]] && grep -qx "$task_id" "$SEEN_FILE"; then
    continue
  fi
  new_tasks+=("$task_id")
done < <(printf '%s\n' "$board_text" | grep -E '^\| T-[0-9]+ \|' || true)

# 更新 HEAD 水位（dry-run 不写状态）
if [[ "$DRY_RUN" != "1" ]]; then
  printf '%s' "$head_sha" > "$HEAD_FILE"
fi

if [[ "${#new_tasks[@]}" -eq 0 ]]; then
  silent "no-new-task-for-me" "{\"node\":\"$node_id\",\"head\":\"$head_sha\"}"
  exit 0
fi

# 记下已唤醒的任务，避免下次重复唤醒（dry-run 不写状态）。
# 注意：如果领了任务后放弃执行，要把该任务 ID 从 seen 文件里删掉，Hook 才会重新唤醒。
if [[ "$DRY_RUN" != "1" ]]; then
  printf '%s\n' "${new_tasks[@]}" >> "$SEEN_FILE"
fi
tasks_json="$(printf '"%s",' "${new_tasks[@]}")"
tasks_json="[${tasks_json%,}]"
wake "new-task-assigned" "{\"node\":\"$node_id\",\"tasks\":$tasks_json}"
