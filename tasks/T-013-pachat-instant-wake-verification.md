# T-013 Pachat 群消息即时唤醒节点核实

## 任务信息

- **编号**：T-013
- **标题**：Pachat 群消息即时唤醒节点核实
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/14
- **预估 worker 秒数**：300
- **单回合预算**：600
- **阶段**：单阶段核实（读官方文档＋核对唤醒机制＋写报告＋推送）
- **checkpoint**：研究笔记完成后按 `docs/checkpoint-spec.md` 写一次 checkpoint（checkpoint_seq 1，attempt-0001，generation 1）
- **阶段产物路径**：`results/node-1/T-013-pachat-instant-wake-verification.md`
- **续跑说明**：新 worker 仅凭 checkpoint 和已写的研究笔记继续，不重新执行 checkpoint 已标记完成的来源核对
- **外部副作用**：GitHub push（结果文件一次推送）
- **收尾开始时间**：450
- **发布与通知要求**：一次 shell 推送；成功不发 Issue 评论，交付靠推送；遇阻塞才按 R8 在 Issue 说明

## 背景

编号说明：Issue #13 为 Pachat × GitHub 规程试行登记，非任务；本任务为 T-013，对应 Issue #14，任务号与 Issue 号自此错一位，后续任务号按任务顺序递增，不跳号。
Chen 于 2026-11-12 21:54 问：Pachat 群里有消息，能不能马上唤醒节点。总控现有认知（待核实，不得直接采信）：总控每小时轮询收件箱，节点靠 Hook 每 300 秒扫 BOARD 唤醒，Pachat listener 未装，且 listener 说明为“跑在主人电脑上的 agent”才适用。目前没有已验证的“群消息→节点即时唤醒”链路。

## 目标

一份核实报告：Pachat 群消息能不能即时唤醒节点，以什么机制、前提、时延、成本；不能的话最接近的可行路径是什么、卡在哪一步。

## 输入

- Pachat 官方接入文档：https://pachat.ai/install.md（以官方文档为准，总控的转述不算证据）
- Pachat CLI 帮助中与唤醒相关的部分：`wake`（含 grok／openclaw／claude_routine／webhook／email 几种）、`listen install／status`、`checkin`、`inbox`——只作核查线索，结论以官方文档和实测说明为准
- 本 hub 现状：`RULES.md`（R6 Hook 巡逻、R7 交付、R16 shell 推送）、`Pachat-GitHub-工作交流与任务交付规程.md`（1.1 立即执行版）、`TASK_TEMPLATE.md`、`docs/checkpoint-spec.md`
- 前置报告：`results/node-1/T-011-ai-agent-group-chat-comparison.md`（Pachat 与同类方案对比）、T-008／T-009 关于 600 秒超时与唤醒 fire-and-forget 的结论
- 禁止事项：不准用总控或任何人的 Pachat token，不准安装 listener，不准改任何账号的 wake／checkin 设置，不准把秘密写进报告、checkpoint 或 Issue（R5）

## 600 秒执行预算

单个 worker execute 回合按 600 秒边界设计，不依赖超时延长。到达约 450 秒时停止新增工作，进入 checkpoint 和交付收尾。

| 阶段 | 预算 |
|---|---|
| 启动、读取状态、claim | 15–30 秒 |
| 主体工作 | 420–450 秒 |
| checkpoint、结果落盘、校验 | 30–45 秒 |
| GitHub 推送／交接／通知 | 45–75 秒 |
| **合计** | **510–600 秒（各阶段极值合计不得超过 600 秒）** |

本任务预估约 300 秒，属小切片：读文档、核对、写报告、推送，分批做、边做边写，不要等到最后才写。

## 输出要求

- 文件路径：`results/node-1/T-013-pachat-instant-wake-verification.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。
- 报告必须逐项回答以下 6 问，每问给明确结论＋证据，不得只写笼统判断：
  1. 群里任意消息能唤醒，还是只有 @ 某节点才唤醒？触发条件是什么？
  2. listener 是什么、前提是什么（机器、系统、常驻、额度、账号）？云端 Muse 能不能用？总控和节点各是什么情况？
  3. `wake` 的 webhook／email 等方式对 Muse 是否适用？要什么前置（URL、secret、服务器、权限）？节点能不能各配一个？
  4. 每个节点是独立 Muse 账号，要即时唤醒，各需要什么（自己的机器／token／额度／设置）？总控能不能替它们装？
  5. 若按最可行的路径，从群消息发出到节点开始干活，全链路时延是多少？逐段拆（Pachat 发现、总控中转、GitHub 派发、Hook 巡逻、worker 启动），每段给实测或官方依据。
  6. 最终 verdict：能做到／不能做到／有条件做到。能做到给具体步骤；不能做到列出阻断点；有条件做到列出条件和成本（额度、机器、审批）。
- 每完成一个可独立验证的来源核对，先写研究笔记并写一次 checkpoint，不要等到整个任务结束才写。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写结果文件、尽早推送，不要等到最后才写。

## 续跑与副作用

- 超时后恢复是续跑，不是重做：新 worker 从最新有效 checkpoint 的 `next_stage` 继续，不重新执行 checkpoint 已标记完成的阶段。
- 外部副作用（GitHub commit／push、Issue 评论、远端状态更新等）先记账再执行，状态分 `not_started`／`intent_recorded`／`confirmed`／`unknown`；`intent_recorded` 或 `unknown` 时先查远端事实，不得直接重复执行。
- 已有最终结果时只恢复交接／发布，不再执行研究。
- 超时判定以 `muse.db` run 行为准（关联键 `metadata_json.wake_payload.event_id`，终结条件 `failed`＋`worker_timeout`）；巡逻进程打不开数据库，不得把 DB 查询写进巡逻脚本；心跳过期、wake 返回成功均不得单独作为超时或启动证据。

## 验收标准

- 6 问逐项有明确结论＋来源链接＋日期＋引用原文或命令输出；无编造数字、无编造来源；未验证的写“未验证”。
- listener 与 webhook／email 等唤醒方式的适用性已按官方文档核对，不只转述总控的说法。
- 未安装 listener、未改任何 wake／checkin 设置；报告、checkpoint、Issue 均无秘密（R5）。
- 结果文件在正确路径，一次 shell 推送交付；checkpoint 符合 `docs/checkpoint-spec.md`。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止；期望 1 天内交付。遇阻塞直接在 Issue 说明，不要静默等待。
