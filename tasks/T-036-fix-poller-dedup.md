# T-036：修轮询去重——旧消息重复唤醒

- 任务号：T-036
- 派给：Codex（总控机本地改脚本，Antigravity 复核）
- Issue：待建（#38）
- 来源：总控自维护（2026-11-16 06:30，Hook worker 上报，维护日志⑫）。3 条 node-1 旧消息（T-021/T-025/T-028）各被重复唤醒 12 次。

## 故障点
`~/hooks/scripts/director-watch-poll.sh`（或 node-watch）中 `seen_msg_hashes` 仅保留最近 50 条；旧消息 hash 掉出窗口后，轮询每轮将其当作新消息重新唤醒。

## 做什么
1. 定位去重逻辑（seen_msg_hashes 的保留量与 add_wake 判定）。
2. 二选一（选改动最小且可靠者）：① 扩大保留量至 200（与 Plan D 的 200 个 approval_id 对齐）；② 事件文件已存在时不再重复 add_wake。
3. 改完 `bash -n` 过；跑一轮 dry-run 验证无新事件误唤醒、无语法错。
4. 报告写进 `~/workspace/muse-hub-tests/` 或任务交付路径（说明改了哪行、验证结果），不推生产仓库（Hook 脚本在总控本地，改完由总控自行启用）。

## 不做什么
- 不改唤醒投递逻辑（平台侧问题，不动）。
- 不碰 `alerts/` 审计文件。
- 不改 BOARD/Issue 流程。

## 验收
- 脚本 `bash -n` 过；dry-run 一轮无重复唤醒；Antigravity 复核 PASS。
