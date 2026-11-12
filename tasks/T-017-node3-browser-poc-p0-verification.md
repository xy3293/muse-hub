# T-017 直控 node-3 浏览器自动化 PoC：P0 只读可行性核验

## 任务信息

- **编号**：T-017
- **标题**：直控 node-3 浏览器自动化 PoC：P0 只读可行性核验
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/19
- **预估 worker 秒数**：300
- **单回合预算**：600
- **阶段**：单阶段只读核验（读公开文档＋代码入口＋写报告＋推送）
- **checkpoint**：来源核对完成后按 `docs/checkpoint-spec.md` 写一次 checkpoint（checkpoint_seq 1，attempt-0001，generation 1）
- **阶段产物路径**：`results/node-1/T-017-node3-browser-poc-p0-verification.md`
- **续跑说明**：新 worker 仅凭 checkpoint 和已写的研究笔记继续，不重新执行 checkpoint 已标记完成的来源核对
- **外部副作用**：GitHub push（结果文件一次推送）
- **收尾开始时间**：450
- **发布与通知要求**：一次 shell 推送；成功不发 Issue 评论，交付靠推送；遇阻塞才按 R8 在 Issue 说明

## 背景

Chen 于 2026-11-13 01:30 发来一份计划 v1《Muse 总控直控 node-3：低额度浏览器自动化实施计划》。计划主张：总控仅发起一次 CLI/MCP/本地 HTTP 工具调用，由固定浏览器脚本用 node-3 的正常授权网页会话完成「发送消息 → 读取 node-3 回复 → 返回结构化结果」，目标结果 `NODE3_OK`，能区分完成、超时、需审批和登录失效；测试范围仅总控＋node-3，不触及 node-1、node-2、node-4；GitHub、BOARD、Hook、Control Tower 全部保留作备用，不把 GitHub 作为这次测试消息的中转。以上均为计划的主张，待本任务核验，不得直接采信。

计划的首选是 Muse-Chat-MCP，备用 agent-browser、备用二 PinchTab。Chen 已于 2026-11-13 01:32 批准只派本任务（P0 只读核验），未批准安装、登录、P1 或任何生产切换。

## 目标

一份 P0 只读核验报告：三个候选桥接器是否可信、怎么登录、能不能区分审批与失效、会不会触碰审批自动通过或平台限制、P1 需要什么前置；给出 P0 通过／不通过的明确结论。

## 输入

- 候选仓库（以仓库原文为准，总控的转述不算证据）：
  - Muse-Chat-MCP：https://github.com/duclm1x1/Muse-Chat-MCP
  - agent-browser：https://github.com/vercel-labs/agent-browser
  - PinchTab：https://github.com/pinchtab/pinchtab
- 计划引用的官方资料：https://ai.meta.com/muse/ 、https://about.fb.com/news/2026/09/introducing-muse-personal-ai-agent/
- 本 hub 现状：`RULES.md`（R5 秘密、R6 Hook 巡逻、R7 交付、R16 shell 推送）、`Pachat-GitHub-工作交流与任务交付规程.md`（1.1 立即执行版，一周试行中）、`TASK_TEMPLATE.md`、`docs/checkpoint-spec.md`
- 前置报告：`results/node-1/T-011-ai-agent-group-chat-comparison.md`、T-008／T-009 关于 600 秒超时与唤醒 fire-and-forget 的结论
- 禁止事项：不安装任何桥接器，不运行浏览器，不登录任何账号，不导出、不复制、不粘贴任何密码、Cookie、Token；不向 node-3 发测试消息，不改 node-3 配置，不改任何账号的 wake／checkin 设置，不改 Hook、BOARD、RULES；不把秘密写进报告、checkpoint 或 Issue（R5）

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

- 文件路径：`results/node-1/T-017-node3-browser-poc-p0-verification.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。
- 报告必须逐项回答以下 7 问，每问给明确结论＋证据，不得只写笼统判断：
  1. 维护与可信度：三个仓库各是什么状态（最后提交日期、版本／发布、许可证、主要依赖）？哪一个相对最可维护，哪一个有明显风险？无法访问的写“未验证”。
  2. 登录与会话机制：各候选怎么拿到授权会话（正常浏览器登录流程、独立 profile、Playwright 操作真实 Chrome，还是要密码／Cookie／Token）？是否要求复制秘密、是否要求开放入站端口、是否只绑定 127.0.0.1？
  3. 收发与状态区分：各候选能不能返回完成、超时、需审批、登录失效这四种状态？所谓 `needsApproval` 是代码里真实返回的字段，还是文档宣传？引用 README 或代码入口原文。
  4. 审批与平台边界：有没有任何代码或文档暗示可以自动通过 Sentinel 审批卡？浏览器自动化是否明显违反 Muse 平台权限或自动化限制？有官方依据的贴出来，没有的写“未验证”，不得自行推定合规或违规。
  5. 总控 VM 可行性（只从文档推断，不实测）：各候选需要什么环境（Node.js、Chrome／Chromium、Playwright、系统依赖、持久化目录）？P1 若要装，缺什么、要改总控主环境还是可隔离在试验目录？
  6. 候选排序：只推一个首选并说明理由，其余两个为什么暂不选；不要建议同时安装三套。
  7. P0 结论与 P1 前置：P0 通过／不通过；若通过，P1 精确需要什么（包括是否需要用户在总控 VM 上登录 node-3 账号）；若不通过，列出阻断点；最后给是否建议进 P1 的建议及理由。
- 每完成一个可独立验证的来源核对，先写研究笔记并写一次 checkpoint，不要等到整个任务结束才写。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写结果文件、尽早推送，不要等到最后才写。

## 续跑与副作用

- 超时后恢复是续跑，不是重做：新 worker 从最新有效 checkpoint 的 `next_stage` 继续，不重新执行 checkpoint 已标记完成的阶段。
- 外部副作用（GitHub commit／push、Issue 评论、远端状态更新等）先记账再执行，状态分 `not_started`／`intent_recorded`／`confirmed`／`unknown`；`intent_recorded` 或 `unknown` 时先查远端事实，不得直接重复执行。
- 已有最终结果时只恢复交接／发布，不再执行研究。
- 超时判定以 `muse.db` run 行为准（关联键 `metadata_json.wake_payload.event_id`，终结条件 `failed`＋`worker_timeout`）；巡逻进程打不开数据库，不得把 DB 查询写进巡逻脚本；心跳过期、wake 返回成功均不得单独作为超时或启动证据。

## 验收标准

- 7 问逐项有明确结论＋来源链接＋日期＋引用原文或命令输出；无编造数字、无编造来源；未验证的写“未验证”。
- 未安装任何桥接器、未登录、未运行浏览器；报告、checkpoint、Issue 均无秘密（R5）。
- 给出唯一首选候选和 P0 通过／不通过结论，以及 P1 的精确前置和阻断点。
- 结果文件在正确路径，一次 shell 推送交付；checkpoint 符合 `docs/checkpoint-spec.md`。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止；期望 1 天内交付。遇阻塞直接在 Issue 说明，不要静默等待。
