# T-014 节点巡逻 180 秒＋Pachat 盯梢 Hook（Stage A 完成，Stage B 重测：Hook 约 2 分钟内叫醒，待总控定）

## 结论

- Stage A 两件改动全部落地且 dry-run 均为 silent：A. GitHub 巡逻 Hook 注册由 300 秒改为 180 秒（enabled 保持 true）；B. 新装 Pachat 收件箱盯梢 Hook `pachat-inbox-watch`，120 秒一轮、已启用。
- Stage B 未完成：待总控在总群 @ 我一句做真消息唤醒实测。本报告推送后，我会在总控与 1 号的 1-1 单聊发消息请总控发测试 @；总控 @ 到达后，新 worker 凭 checkpoint 做 Stage B，允许第二次推送。
- Stage B 重测（2026-11-12 15:41–15:43 UTC，总群 #16→#17）：见下文“Stage B：真消息唤醒实测（重测）”。原测试 #10 未能证明 Hook（见该节）；重测证明 Hook 在约 2 分钟内叫醒一轮，wake 记录 invocation_id `808946e8-7a96-40a5-83fd-dcc304924ee9`。Stage B 是否通过由总控定。
- 重要说明：本 worker 运行环境里没有 `hooks.*` 工具（无 hooks 命名空间，`hatch` 二进制也没有 hooks 子命令），因此注册改动是直接编辑运行时读取的定义文件 `~/hooks/definitions/*.json` 完成的，字段与 `hooks.add`／`hooks.update` 应设置的完全一致；`hooks.view` 的核对本次无法执行，请总控或主聊用 `hooks.view` 复核两处注册（见“未验证”）。

## 任务来源

- 派发：Pachat 总控与 1 号 #11，2026-11-12 15:20 UTC（23:20 CST），总控（Chen 总控 muse）[DISPATCH] T-014。
- 任务书：`tasks/T-014-node-patrol-180-pachat-hook.md`（v1），Issue #15；BOARD.md 第 22 行：T-014 node-1 待领。
- 执行方式：本次运行是 `pachat-inbox-check` 定时轮询（23:24:48 CST 触发），读到派发后直接执行，未等巡逻 Hook 唤醒——与 T-013 的做法一致（总控群内派发后直接做，正式任务仍以 GitHub 为准）。
- 远端基线：执行前 `git pull`，HEAD 为 b332ed1（总控派 T-014/015/016 的提交）。

## Stage A1：GitHub 巡逻改 180 秒

- 改前：`~/hooks/definitions/muse-hub-patrol.json`，`poll_interval_secs: 300`，`enabled: true`，`script_timeout_secs: 600`，`id: muse-hub-patrol`。
- 备份：`~/hooks/archive/muse-hub-patrol-20261112-2328.json`（改前完整复制）。
- 改后：`poll_interval_secs: 180`，其余字段不变（`enabled: true`，`script_timeout_secs: 600`，prompt、script_path 均未动）；`updated_at_ms: 1794497312965`。巡逻脚本本身未改（`~/hooks/scripts/patrol-muse-hub.sh`，PATROL_VERSION 2026-11-11.3）。
- dry-run：invocation `dryrun-t014-a1`，耗时 867 ms，`HATCH_HOOK_RESULT: {"decision":"silent","reason":"board-unchanged","payload":{"head":"b332ed1997df0ca151ad953bcb70c717f574b442","patrol_version":"2026-11-11.3"}}`。执行环境：`HATCH_HOOK_DRY_RUN=1`，直接运行脚本。
- 核对（文件摘录，非 `hooks.view`）：`enabled: true`，`poll_interval_secs: 180`。

## Stage A2：新装 Pachat 盯梢 Hook（120 秒一轮）

- CLI 验证：`node ~/.pachat/pachat.mjs inbox --json` 正常返回 JSON，`you.name` 为 `Chen Muse[node-1]`（member id vf0qiRLQtDsTroQb），与收件箱核对一致。
- 脚本：`~/hooks/scripts/pachat-inbox-watch.sh`（已 `chmod +x`）。
- 内容：`#!/usr/bin/env bash`，`set -euo pipefail`，`source "$HATCH_HOOK_RUNTIME"`；每轮 `timeout 20 node $HOME/.pachat/pachat.mjs inbox --json`；取消息失败则 log 后 silent；wake 条件为 `mentionsYou + repliesToYou + fromYourOwner + recalled > 0`，或 2 人群且 `unread > 0`；去重为同一群＋同一 lastSeq 一小时内不重复 wake，状态文件 `~/hooks/state/pachat/inbox-state.json`，dry-run 不写状态；wake payload 只含群 id、名称、lastSeq 与计数，不含消息正文；脚本内无秘密，token 由 CLI 自己读 `~/.pachat/token`。
- 检查：`bash -n` 通过；`.last-good` 备份 `~/hooks/scripts/pachat-inbox-watch.sh.last-good` 已留；grep 未发现写坏模式（`if[[`、`if!`、`"=~ *]]`）；grep 未发现秘密（token／密钥类字样仅出现在说明 token 由 CLI 读取的注释中）。
- 注册：`~/hooks/definitions/pachat-inbox-watch.json`，`id: pachat-inbox-watch`，`poll_interval_secs: 120`，`script_timeout_secs: 60`，`delivery: {surface: main}`，`presentation_locale: zh-CN`，`created_at_ms / updated_at_ms: 1794497326895`。注册时先 `enabled: false`，dry-run 通过后再改为 `enabled: true`（`updated_at_ms` 随之更新）。
- dry-run：invocation `dryrun-t014-b1`，耗时 684 ms，`HATCH_HOOK_RESULT: {"decision":"silent","reason":"no-pachat-action-needed","payload":{"hook":"pachat-inbox-watch"}}`。dry-run 后 `~/hooks/state/pachat/` 不存在，确认 dry-run 未写状态。
- wake 分支逻辑验证（推断，非真消息实测）：用一份仿造的 inbox JSON 跑 wake 条件 jq 表达式，`mentionsYou=1` 的 2 人群被选中、无新消息的群未被选中；真消息唤醒实测留待 Stage B。
- 启用后核对（文件摘录，非 `hooks.view`）：`enabled: true`，`poll_interval_secs: 120`，`script_timeout_secs: 60`。

## Stage B：真消息唤醒实测（重测，2026-11-12 15:41–15:43 UTC）

### 原测试 #10（15:33 UTC）：Hook 没有叫醒，不能证明

- 总控总群 #10（15:33 UTC）@ 我做 Stage B 测试；我回 #12（15:35 UTC）称“23:34 定时巡查看到”。
- 总控 #15（15:39 UTC）更正 #13：#11/#12/#14 三句都是定时巡查看到，不是 Hook 叫醒；Stage B 是否通过要以 1 号 Hook 日志里的 wake 记录为准。
- Hook 日志 `~/hooks/logs/pachat-inbox-watch.jsonl`（本 worker 实查，全量 8 条，Hook 启用后的全部轮次）：
  - 15:29:17 `aa0d71e2-87dc-4961-ba98-d82821b8c69e` silent，15:31:17 `dc4f9231-5765-4704-9308-315984d1f124` silent，15:33:17 `6ce01ae6-acca-4fbd-a66f-a38f85220405` silent，15:35:17 `a0be9f57-931b-4b78-889d-0847cc418e5f` silent，15:37:17 `a53b5518-0871-4065-8ca8-b46ebedf7e59` silent，15:39:17 `b1ee61a4-2b45-4a14-9754-67c6e565addd` silent，15:41:17 `72b0103f-69da-431f-963a-6d02549eff3b` silent——#10 到达前后五轮全是 `no-pachat-action-needed`，无 wake。
  - 原因（推断，有证据支撑）：23:34 CST（15:34 UTC）`pachat-inbox-check` 定时轮询先读到了 #10 并触发 #12 回帖，`read` 标记已读后 Hook 再轮询时已无未读 @；Hook 的 120 秒轮询在与 10 分钟定时巡查的竞跑中输了。#10 本身在 15:33:17 那轮也未被捕获（@ 到达时间在该轮启动之后或 inbox 接口有延迟，分钟级精度无法区分）。
- 结论：原测试 #10 的 Stage B 不通过——不是 Hook 坏了，而是没有产生 wake 记录；#12 不能作为 Stage B 证据。

### 重测 #16（15:41 UTC）：Hook 约 2 分钟内叫醒

- 总控总群 #16（15:41 UTC）@ 我：T-014 Stage B 重测，请确认 Hook 是否在约 2 分钟内叫醒一轮，并把 wake 记录的 invocation_id 记下来。
- Hook 日志：15:43:17 UTC，invocation_id `808946e8-7a96-40a5-83fd-dcc304924ee9`，`outcome: wake`，`reason: pachat-inbox-needs-you`，payload 为总群 lastSeq 16、unread 3、mentionsYou 1；本 worker 的 run_id 即 `event-hook:808946e8-7a96-40a5-83fd-dcc304924ee9`。
- 时延：#16 发送于 15:41（分钟级精度），wake 轮次启动于 15:43:17，约 2 分钟内，符合 120 秒轮询间隔的预期（最坏约 2 分钟＋抓取耗时）；15:41:17 那轮仍为 silent，系 #16 到达在其启动之后或 inbox 延迟。
- 群内确认：我回总群 #17（回复 #16），说明原测试未叫醒、重测 15:43:17 叫醒并附 invocation_id，Stage B 结果补推 GitHub、请总控定。
- 诚实备注：本次 wake 的触发消息是 #16 本身（@ 我），wake 发生后本 worker 才读到 #14/#15/#16；#15 的更正内容（Stage B 判定标准）由本 worker 在 wake 后读到，不是 wake 前已知。

## 未验证

- `hooks.view` 复核：本 worker 无 `hooks.*` 工具，未能执行 `hooks.view`／`hooks.list`；上述“核对”均为定义文件原文摘录。注册文件是运行时读取的同一份定义，但调度器是否已按新间隔排程未直接观测到——请总控或主聊用 `hooks.view` 确认 `muse-hub-patrol` 为 180 秒＋enabled、`pachat-inbox-watch` 为 120 秒＋enabled。
- Stage B：原测试 #10 未叫醒（五轮 silent，见上节），重测 #16 于 15:43:17 叫醒，invocation_id `808946e8-7a96-40a5-83fd-dcc304924ee9`，群内确认回帖为总群 #17。Stage B 是否通过由总控定。
- 未改动：BOARD.md、RULES.md、巡逻脚本、任何账号的 wake／checkin 设置、listener（未安装）。

## 副作用账本

| 副作用 | 状态 | 证据 |
|---|---|---|
| A1 巡逻注册 300→180 秒 | confirmed（文件级） | 定义文件改后值 180＋enabled，备份在 `~/hooks/archive/` |
| A2 盯梢脚本写入 | confirmed | `bash -n` 通过，`.last-good` 已留 |
| A2 盯梢 Hook 注册＋启用 | confirmed（文件级） | 定义文件 120 秒＋enabled=true |
| GitHub push（本结果文件） | intent_recorded → 待推送后核验 | 见 checkpoint effect-001 |
| Pachat 1-1 请总控发测试 @ | not_started（推送后执行） | 见 checkpoint effect-002 |
| Stage B 原测试 #10 | failed_to_prove（Hook 未叫醒） | 15:33–15:41 五轮 silent，见 Stage B 节 |
| Stage B 重测 #16 | confirmed（Hook 15:43:17 叫醒，约 2 分钟内） | invocation_id `808946e8-7a96-40a5-83fd-dcc304924ee9`，总群确认回帖 #17 |
| Stage B 总群确认回帖 | confirmed | 总群 #17（回复 #16） |

## checkpoint

本地 checkpoint：`~/hooks/state/task-runtime/tasks/T-014/attempt-0001/checkpoint/`，seq 1，generation 1，next_stage stage-b（凭 checkpoint 续跑 Stage B，不重做 Stage A）。Stage B 已由本次 worker（attempt-0001 续跑）完成并随本文件补推；checkpoint 不推送到 GitHub。
