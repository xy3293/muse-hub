# T-021：总控审批卡覆盖扩展到工具层卡（研究＋设计）

## 任务信息

- **编号**：T-021
- **标题**：总控审批卡覆盖扩展到工具层卡（研究＋设计）
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：[#23](https://github.com/xy3293/muse-hub/issues/23)
- **合同版本**：`contract_revision` v1
- **运行标识**：`run_id` T-021-node-1-card-coverage-1
- **进展时间戳**：`last_progress_at`（只在实质工作推进时更新，与存活心跳区分）
- **幂等键**：复用 checkpoint-spec §6 账本的 `effect_id`（每个外部副作用操作一个稳定键）
- **预估 worker 秒数**：`estimated_worker_seconds` 900（分 2 回合，每回合 600 秒内）
- **单回合预算**：`time_budget_seconds` 600（主体工作 420–450 秒，收尾至少 90 秒；各阶段预算极值合计不得超过 600 秒）
- **阶段**：`stages` 见下（A 读审批链代码、B 工具层卡 DOM 核查、C 扩展设计＋结论）
- **checkpoint**：`checkpoint_after_each_stage`（每阶段结束后按 `docs/checkpoint-spec.md` 写 checkpoint）
- **阶段产物路径**：`stage_output_paths`（Stage A/B 的中间核查记录写本地，不推；最终设计文档见输出要求）
- **续跑说明**：`resume_instructions`（新 worker 仅凭 checkpoint 和产物继续，不依赖旧 worker 的隐式记忆）
- **外部副作用**：`external_side_effects`（GitHub 推送最终设计文档；Issue 评论按 R7/R8；不触发新审批卡，除非 Stage B 明确需要且已记账）
- **收尾开始时间**：`finalize_before_seconds` 450
- **发布与通知要求**：`publish_and_notify_requirements`（最终设计文档推上远端；完成经快通道报总控，不发已完成 Issue 评论）

## 背景

Chen 2026-11-15 00:29 决定放弃 node-3 shell/gh 通道（R16 已退条），方向改为优化总控审批卡能力。现状：网页 UI 推送卡总控已能按范围自动批（桥 approvals 接口＋director_approve.py，canary-004/005b/006、T-020、卡种测试 f033427 均验证）；工具层卡（首当其冲是 add_issue_comment）总控看不见、批不了（T-020 评论卡桥上 0 卡、超时未批；卡种测试评论卡一弹就挡住桥消息）。R7 总控代发评论是现有绕法，不是覆盖。

## 目标

交付一份扩展设计：总控审批卡覆盖如何延伸到工具层卡（从 add_issue_comment 起），含可行性结论。

## 输入

- 桥审批链代码：`~/workspace/node3-browser-poc/` 下 muse-chat-mcp-test/source（VM 副本）与 approval/（approval_reader.py、director_approve.py、scope_validator.py、approval.patch、real-card-*.json、real-card-t020-final.json）。
- 规则：RULES.md R16（审批卡自动化行）、R18（5 项范围检查）、R7（3 号评论总控代发）；RULINGS/2026-11-14-credential-scope.md。
- 证据：卡种测试记录 f033427（results/node-3/card-kind-test-*.md）；T-020 证据 21489253；node-3 PENDING 记录 3e002845（§3 去卡缺口、§4 卡数）。
- 约束：只研究＋设计，不改代码、不部署桥、不跑任何 gh 命令、不碰凭据；新审批卡能少则少。

## 600 秒执行预算

| 阶段 | 预算 |
|---|---|
| 启动、读取状态、claim | 15–30 秒 |
| 主体工作 | 420–450 秒 |
| checkpoint、结果落盘、校验 | 30–45 秒 |
| GitHub 推送／交接／通知 | 45–75 秒 |
| **合计** | **510–600 秒（各阶段极值合计不得超过 600 秒）** |

## 输出要求

- 文件路径：`results/node-1/T-021-director-card-coverage-design.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。
- 每完成一个可独立验证的阶段，按 `docs/checkpoint-spec.md` 写一次 checkpoint，不要等到整个任务结束才写。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写结果文件、尽早推送，不要等到最后才写。

## 阶段

- Stage A（读审批链）：读桥 approvals 接口与 director_approve.py／scope_validator.py／approval.patch，画出网页 UI 推送卡从 DOM 到总控批卡的完整链路（哪段读 DOM、哪段定 fingerprint、哪段做范围检查、哪段点批），并标出哪一段只认推送卡。
- Stage B（工具层卡 DOM 核查）：核查 add_issue_comment 卡在 Muse 网页 UI 的 DOM 里长什么样（与推送卡同一种审批 UI 还是另一种；能不能被同一段 DOM 读取代码读到）。优先用已有的卡记录与代码推断；非要实测才触发新卡——最多一张，与 node-3 协调（经快通道），由 node-3 触发并抓 DOM，Chen 拒掉该卡；触发前先记账（effect_id），触发后把 DOM 关键片段（选择器、字段）记进设计文档，不贴整页 DOM。
- Stage C（扩展设计＋结论）：写扩展方案（接口、director_approve.py、范围检查各改哪几处；工具层卡的 5 项范围检查怎么写；一次一卡、防重放、超时未决怎么处理），并给可行性结论（可行／有条件可行／不可行＋理由），最后列扩展后总控仍然批不了的卡种（残留缺口）。

## 自主执行（R18）

- 认领后经快通道（Pachat 或桥）报一次 ETA 范围；之后只报状态变化、卡住、完成。不发已领／已完成 Issue 评论。
- 唤醒后先拿本地独占锁，对账当前任务（RUNNING／恢复／PARKED），仅空闲且合格时发现新任务。
- 任务书有实质矛盾或含糊：发一条 SPEC_CONFLICT（Issue 评论，写清任务号、冲突编号、争议条款、阻塞影响、最小修正建议），继续无争议的安全部分；全部被堵则写 checkpoint 后进 PARKED（保留所有权，不空转、不另领任务）。只有总控写 SPEC_DECISION、改任务书版本、改 BOARD.md；恢复时只重跑受影响的预检与验收，不重做已完成阶段。
- 失败先读错定性、对账 checkpoint 与副作用账本，每个失败操作只重试一次；已证明完成的副作用不重放。600 秒是 worker 终止边界；`setsid`＋`nohup` 后台进程可越过（T-018 已验证），巡逻须保留仍在跑的任务。
- 去重：拿不到锁的唤醒直接返回；开始／恢复前对账 run_id、checkpoint、账本、后台进程身份（PID＋启动时间＋run 标识）；推送超时先核远端 HEAD。

## 续跑与副作用

- 超时后恢复是续跑，不是重做：新 worker 从最新有效 checkpoint 的 `next_stage` 继续，不重新执行 checkpoint 已标记完成的阶段。
- 外部副作用（GitHub commit／push、Issue 评论、远端状态更新等）先记账再执行，状态分 `not_started`／`intent_recorded`／`confirmed`／`unknown`；`intent_recorded` 或 `unknown` 时先查远端事实，不得直接重复执行。
- 已有最终结果时只恢复交接／发布，不再执行研究或开发。
- 超时判定以 `muse.db` run 行为准（关联键 `metadata_json.wake_payload.event_id`，终结条件 `failed`＋`worker_timeout`）；巡逻进程打不开数据库，不得把 DB 查询写进巡逻脚本；心跳过期、wake 返回成功均不得单独作为超时或启动证据。

## 验收标准

1. 设计文档说清工具层卡（add_issue_comment）在 DOM 里长什么样（附选择器／字段证据），不是推测。
2. 扩展方案覆盖接口、director_approve.py、范围检查三处改动，并给可行性结论（可行／有条件可行／不可行＋理由）。
3. 列出扩展后总控仍然批不了的卡种（残留缺口），不回避。
4. 只研究＋设计：无代码改动、无桥部署、无 gh 命令、无凭据进仓库／聊天；新审批卡至多一张且已记账。
5. 最终设计文档在授权路径，远端可读；关键结论有来源，未验证的写明未验证。

## 截止

- 期望完成时间：2026-11-15 02:00 +08（认领 5 分钟＋读代码 20 分钟＋DOM 核查 30 分钟＋设计文档 20 分钟＋收尾 10 分钟）。
