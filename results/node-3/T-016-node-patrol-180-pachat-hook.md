# T-016 节点巡逻 180 秒＋Pachat 盯梢 Hook（v2）— Stage A 结果

## 结论先行

- **Stage A 完成，两处改动均已在位并验证通过，未重做改动。** v2 首要任务是核对 v1 落地情况，核对结果：A1 巡逻已是 180 秒、已启用；A2 Pachat 盯梢 Hook 已装、120 秒、已启用，脚本在位且 `bash -n` 通过。两处改动均为 v1 执行轮（2026-11-12 23:24–23:34 CST）落地，v2 本轮只做核对＋dry-run＋结果推送。
- **Stage B 待测。** 已在 1-1 群请总控在总群 @ 我一句（1-1 群 #11，2026-11-12 23:58 CST）；截至本文件推送时尚未收到总群 @，Stage B 跨回合补测，checkpoint 已写（见“续跑”一节）。
- **交付方式说明：** 任务书称“一次 shell 推送”，但 RULES.md R16（2026-11-11 修订）规定 node-3 不用 shell push，写操作走 Muse GitHub 工具层、每推一张审批卡；本次按 R16 走工具层一次推送，与 T-002、T-007 一致。BOARD.md 未改；成功不发 Issue 评论。

## v1 回顾（事实）

- v1 执行轮 2026-11-12 23:24–23:34 CST 因 600 秒超时（worker_timeout）未写完结果、未推送，无 checkpoint 文件；v1 Issue #17 已关闭（总控 23:48 重派 v2，Issue #18，commit 53f68dc）。
- v1 轮内与总控在 1-1 群“总控与3号”沟通过：总控 23:38 问卡在哪一步（#4）；本号 23:45 回复 Stage A 已落地、超时未推送、请总控定重派或手动续跑（#5）；总控 23:47 决定重派，要求等 GitHub 重派后再开工、重派后先核对两处改动（#6）；本号 23:49 确认等待（#7）；总控 23:51 确认（#8），23:52 发 v2 派发通知（#9）。
- 本轮由巡逻 Hook 唤醒：invocation 5b2a4804，2026-11-12 23:51:43 CST，event_id `T-016@v2@38cf9f98f6a34f025841b6366d55371d1238be66`。

## A1：GitHub 巡逻改 180 秒 — 已在位

- 定义文件 `~/hooks/definitions/muse-hub-patrol.json`：`id` muse-hub-patrol，`poll_interval_secs` 180，`enabled` true，`script_timeout_secs` 600，delivery main。文件更新于 2026-11-12 23:30 CST（v1 轮内）。
- 巡逻脚本本身未改：`~/hooks/scripts/patrol-muse-hub.sh` 仍为 PATROL_VERSION 2026-11-11.3，只改了注册 interval，符合任务书禁令。
- 实时运行证据（`~/hooks/logs/muse-hub-patrol.jsonl`，时间 UTC）：invocation 435360fd 15:48:43Z silent、5b2a4804 15:51:43Z wake（本次唤醒）、fda535f1 15:54:43Z silent，相邻启动间隔 180 秒，证明 180 秒轮询在实际运行。
- Dry-run（本轮手动，`HATCH_HOOK_DRY_RUN=1`，2026-11-12 约 23:57 CST）：`{"decision":"silent","reason":"board-unchanged","payload":{"head":"5c687d50b27a17c799560acc7c8ba704a19bacb2","patrol_version":"2026-11-11.3"}}`。dry-run 未写状态，seen 文件内容不变。
- 本轮未使用 hooks.* 平台工具（本 worker 无此工具命名空间）；核对以定义文件＋日志＋手动 dry-run 为准。

## A2：Pachat 盯梢 Hook（120 秒一轮）— 已在位

- 定义文件 `~/hooks/definitions/pachat-inbox-watch.json`：`id` pachat-inbox-watch，`poll_interval_secs` 120，`script_timeout_secs` 60，`enabled` true，delivery main（主聊）。文件创建于 2026-11-12 23:30 CST（v1 轮内）。
- 脚本 `~/hooks/scripts/pachat-inbox-watch.sh`：在位，`bash -n` 通过；`.last-good` 备份在位（与脚本同为 2874 字节）。内容与任务书一致：`set -euo pipefail`，`source "$HATCH_HOOK_RUNTIME"`，每轮 `timeout 20 node $HOME/.pachat/pachat.mjs inbox --json`；wake 条件为任一群 `mentionsYou + repliesToYou + fromYourOwner + recalled > 0`，或 `memberCount == 2 且 unread > 0`；去重状态 `~/hooks/state/pachat/inbox-state.json`，同一群＋同一 lastSeq 一小时内不重复 wake，dry-run 不写状态；wake payload 只含群 id、名称、lastSeq 与计数，不含消息正文；脚本内无秘密，token 由 CLI 自己读 `~/.pachat/token`。grep 未见 `if[[`、`if!` 等写坏模式。
- CLI 可用：`node ~/.pachat/pachat.mjs inbox --json` 正常返回 JSON（本号 Chen Muse[node-3]，两群：“总控与3号”2 人、“总群”4 人）。
- 实时运行证据（`~/hooks/logs/pachat-inbox-watch.jsonl`，时间 UTC）：各轮启动间隔恰为 120 秒；wake 记录三条——501cd8a0 15:48:05Z（1-1 群 lastSeq 6，repliesToYou 1）、524d78a6 15:52:05Z（lastSeq 8）、af0e9848 15:54:05Z（lastSeq 9，memberCount 2、unread 1）；其余轮次 silent no-new-message。去重状态文件与之吻合（seq 4/6/8/9 各记一次）。
- Dry-run（本轮手动，`HATCH_HOOK_DRY_RUN=1`，约 23:57 CST）：`{"decision":"silent","reason":"no-new-message","payload":{}}`；去重状态未被改写。

## Stage B：真消息唤醒实测 — 待测

- 已按任务书 B1 在 1-1 群“总控与3号”发请求（#11，2026-11-12 23:58 CST）：“Pachat Hook 已启用，请总控在总群 @ 我一句做唤醒测试。”
- 截至本文件推送时，总群尚未出现 @ 本号的测试消息；@ 到达时间、wake 日志 invocation_id、群里确认回帖 seq 均暂无。
- 补测方式：总控 @ 到达后，Pachat Hook 应在约 2 分钟内叫醒新一轮；新 worker 凭 checkpoint 做 Stage B，再推一次确认（任务书允许第二个交付轮次）。

## 注意：一次并行重复唤醒

- Pachat Hook 在 2026-11-12 23:54:05 CST 对 1-1 群 #9（v2 派发通知）又唤醒一轮（invocation af0e9848，run event-hook:af0e9848-fa23-4c64-9820-d12552b8a5d1），与本巡逻唤醒轮（5b2a4804，23:51:43）并行，存在重复 worker 的可能。本轮只做 Stage A 核对＋结果推送，未重复执行改动；总控可留意该并行轮是否也写了结果，避免重复推送。

## 未验证

- Issue #18 未另行读取：任务书、BOARD.md 与 1-1 群 #9 派发通知的信息已足够；按新 workflow，Issue 读取须走 call-read-tool，而当前 GitHub 工具目录未提供只读的 issue 读取工具（`issue_read` 在 call-tool 下，会触发审批卡），故未读。
- Stage B 的三项实测数据（@ 到达时间、wake invocation_id、确认回帖 seq）待补测。

## 续跑

- checkpoint 已写：`/home/hatch/hooks/state/task-runtime/tasks/T-016/attempts/attempt-0002/checkpoint/checkpoint.json`（schema_version 1，generation 2），Stage A 两阶段标记完成，`next_stage` 为 stage-b，副作用账本见 checkpoint 内 `side_effects`。
- 远端核对：本轮推送前本地已同步到 5c687d5（总控 T-014 Stage B 验收通过）；推送后须按 commit 读回核验。

## 时间线（CST，UTC+8）

| 时间 | 事件 |
|---|---|
| 2026-11-12 23:24–23:34 | v1 执行轮，Stage A 改动落地，600 秒超时未交付、无 checkpoint |
| 2026-11-12 23:38–23:52 | 1-1 群沟通：总控问询 → 本号说明超时 → 总控决定重派 → 本号确认等待 → 总控发 v2 派发通知（#9） |
| 2026-11-12 23:48 | 总控重派 v2（commit 53f68dc，Issue #18，Issue #17 关闭） |
| 2026-11-12 23:51:43 | 巡逻 Hook 唤醒本轮（invocation 5b2a4804，T-016@v2） |
| 2026-11-12 23:52–23:57 | 核对两处改动在位、读日志、手动 dry-run 均 silent |
| 2026-11-12 23:58 | 1-1 群发 Stage B 测试请求（#11） |
| 2026-11-12 23:59 | 写结果文件＋checkpoint，工具层一次推送 |
