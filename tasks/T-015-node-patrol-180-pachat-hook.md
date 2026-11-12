# T-015 节点巡逻 180 秒＋Pachat 盯梢 Hook

## 任务信息

- **编号**：T-015
- **标题**：节点巡逻 180 秒＋Pachat 盯梢 Hook
- **负责人**：node-2
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/16
- **预估 worker 秒数**：300
- **单回合预算**：600
- **阶段**：Stage A（两处改动＋dry-run＋启用＋推送）／Stage B（真消息唤醒实测）
- **checkpoint**：每阶段结束后按 `docs/checkpoint-spec.md` 写 checkpoint
- **阶段产物路径**：`results/node-2/T-015-node-patrol-180-pachat-hook.md`
- **续跑说明**：新 worker 仅凭 checkpoint 和已写的结果文件继续，不重新执行 checkpoint 已标记完成的阶段
- **外部副作用**：GitHub push（结果文件一次推送，Stage B 补测允许第二次推送）；本号自己的 Hook 注册变更（hooks.update／hooks.add／hooks.enable）；Pachat 群里一条测试确认回复
- **收尾开始时间**：450
- **发布与通知要求**：一次 shell 推送；成功不发 Issue 评论，交付靠推送；遇阻塞才按 R8 在 Issue 说明

## 背景

总控侧巡逻已于 2026-11-12 23:14 改为 180 秒（Chen 批准，dry-run silent 通过）；总控侧 Pachat 盯梢 Hook 已启用，并于 22:55 真消息实测通过（node-1 在总群 @ 总控，Hook 22:55:42 wake，总控群里回 #9）。现将两处改动推广到各节点。本任务为 T-015，对应 Issue #16（预测号，以实际为准；后续任务号按任务顺序递增，不跳号）。

## 目标

两件改动全部落地且可验证：A. GitHub 巡逻 Hook 300→180 秒；B. 新装 Pachat 收件箱盯梢 Hook，120 秒一轮、已启用；Stage B 真消息唤醒实测通过（或明确记录待测原因）。

## 输入

- `RULES.md`（R6a 节点 Hook、R7 交付、R16 shell 推送）、`ONBOARDING.md`（Hook 注册方法）、`docs/checkpoint-spec.md`
- 总控侧实测记录：见本任务书“背景”段（Pachat Hook 22:55 wake 通过；总控巡逻 180 秒 dry-run 通过）
- 禁止事项：不准用总控或任何人的 Pachat token（只用自己号的 CLI 与 token）；不准安装 listener；不准改任何账号的 wake／checkin 设置；不准把秘密写进报告、checkpoint 或 Issue（R5）；不改 GitHub 巡逻脚本本身（只改注册 interval）；不改 RULES／BOARD（那是总控的事）

## 600 秒执行预算

单个 worker execute 回合按 600 秒边界设计，不依赖超时延长。到达约 450 秒时停止新增工作，进入 checkpoint 和交付收尾。

| 阶段 | 预算 |
|---|---|
| 启动、读取状态、claim | 15–30 秒 |
| 主体工作 | 420–450 秒 |
| checkpoint、结果落盘、校验 | 30–45 秒 |
| GitHub 推送／交接／通知 | 45–75 秒 |
| **合计** | **510–600 秒（各阶段极值合计不得超过 600 秒）** |

本任务预估约 300 秒，属小切片：改注册、写脚本、dry-run、启用、写报告、推送，分批做、边做边写，不要等到最后才写。

## 执行步骤

### Stage A1：GitHub 巡逻改 180 秒

1. `hooks.list` 找出自己的 GitHub 巡逻 Hook（扫 BOARD 的那个），记下 id 与当前 interval；若已是 180，直接核对并记录，不重复改。
2. `hooks.update` 改 `poll_interval_secs=180`（enabled 保持不变）。
3. `hooks.dry_run` 验证 silent；`hooks.view` 核对 180 秒＋enabled=true。

### Stage A2：新装 Pachat 盯梢 Hook（120 秒一轮）

1. 先验证 Pachat CLI 可用：`node ~/.pachat/pachat.mjs inbox --json` 能返回 JSON。若 CLI 或 token 缺失：停止 B 部分，在结果里如实写“未装原因”，不要编造；A 部分照常做。
2. 写盯梢脚本 `~/hooks/scripts/pachat-inbox-watch.sh`：`#!/usr/bin/env bash`，`set -euo pipefail`，`source "$HATCH_HOOK_RUNTIME"`；每轮 `timeout 20 node $HOME/.pachat/pachat.mjs inbox --json`；取消息失败则 log 后 silent；wake 条件：`mentionsYou + repliesToYou + fromYourOwner + recalled > 0`，或 `memberCount == 2` 且 `unread > 0`；其余 silent；去重：同一群＋同一 lastSeq 一小时内不重复 wake，状态文件放 `~/hooks/state/pachat/inbox-state.json`，dry-run 不写状态；wake payload 只含群 id、名称、lastSeq 与计数，不含消息正文；脚本内绝不放秘密，token 由 CLI 自己读 `~/.pachat/token`。
3. `bash -n` 检查脚本；留 `.last-good` 备份；grep 检查写坏模式（`if[[`、`if!`、`"=~ *]]` 等，写文件时空格可能丢失）。
4. `hooks.add` 注册：id 为 `pachat-inbox-watch`，`poll_interval_secs=120`，`script_timeout_secs=60`，delivery 为自己主聊。worker prompt 大意：Pachat 有需处理的新消息，先用 CLI `read` 读消息；需要回的就回（正式任务和验收仍走 GitHub，群里只做快速商量）；需要 Chen 定的转问总控、不要擅自承诺；处理完一句话汇总（哪个群、什么事、回了什么、还有什么要总控定）；若总控侧每小时查收已处理过，直接说明并结束，不重复回消息。
5. `hooks.dry_run` 验证（当时无新消息时应为 silent；记录 invocation 与耗时）。
6. `hooks.enable` 启用（Chen 已批准，不用再问）；`hooks.view` 核对 enabled=true、120 秒。

### Stage B：真消息唤醒实测

1. 在自己与总控的 1-1 单聊发一条消息：“Pachat Hook 已启用，请总控在总群 @ 我一句做唤醒测试。”
2. 等总控在总群 @ 你；你的 Hook 应在约 2 分钟内叫醒你一轮；你读消息后在总群回一句确认。
3. 结果文件里记录：@ 到达时间、wake 日志 invocation_id、回帖 seq。wake 分支实测通过才算 Stage B 完成。
4. 若等不到总控的 @（1 小时内无回应），不要一直等：先按 Stage A 交活，在结果里写“Stage B 待总控发测试 @”，总控后续补测。不要为等 @ 而空耗执行时间。
5. Stage B 可能跨回合：Stage A 完成后先写 checkpoint 并推送 Stage A 结果；总控 @ 到达后，新 worker 凭 checkpoint 做 Stage B，再推一次确认（允许第二个交付轮次）。

## 输出要求

- 文件路径：`results/node-2/T-015-node-patrol-180-pachat-hook.md`
- 格式：中文，结论先行；数据注明时间；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。
- 内容清单：
  - A：改前／改后 `hooks.view` 摘录（id、poll_interval_secs、enabled）、dry-run 结果（invocation、decision、耗时）。
  - B：脚本路径、`bash -n` 通过、`.last-good` 备份、注册值（id、poll 120、timeout 60、delivery）、dry-run 结果、启用后 `hooks.view` 核对（enabled=true、120 秒）。
  - Stage B：测试 @ 到达时间、wake 日志 invocation_id、群里确认回帖 seq；若未完成，写清卡在哪一步。
- 每完成一个可独立验证的阶段，先写结果文件并写一次 checkpoint，不要等到整个任务结束才写。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写结果文件、尽早推送，不要等到最后才写。

## 续跑与副作用

- 超时后恢复是续跑，不是重做：新 worker 从最新有效 checkpoint 的 `next_stage` 继续，不重新执行 checkpoint 已标记完成的阶段。
- 外部副作用（GitHub commit／push、Hook 注册变更、Pachat 回帖等）先记账再执行，状态分 `not_started`／`intent_recorded`／`confirmed`／`unknown`；`intent_recorded` 或 `unknown` 时先查远端事实，不得直接重复执行。
- 已有最终结果时只恢复交接／发布，不再执行改动。
- 超时判定以 `muse.db` run 行为准（关联键 `metadata_json.wake_payload.event_id`，终结条件 `failed`＋`worker_timeout`）；巡逻进程打不开数据库，不得把 DB 查询写进巡逻脚本；心跳过期、wake 返回成功均不得单独作为超时或启动证据。

## 验收标准

- A：`hooks.view` 摘录显示 180 秒＋enabled；dry-run silent。
- B：脚本在位、`bash -n` 通过、注册 120 秒、enabled=true、dry-run silent；脚本与结果文件无秘密。
- Stage B：Hook 日志有 wake 记录（invocation_id），或结果文件明确写待测原因。
- 结果文件在正确路径，一次 shell 推送交付（Stage B 补测允许第二次推送）；checkpoint 符合 `docs/checkpoint-spec.md`。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止；期望 1 天内交付（Stage A）；Stage B 随总控测试 @ 到达后补。遇阻塞直接在 Issue 说明，不要静默等待。
