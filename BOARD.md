# 任务总表 BOARD

> 只有总控（主控账号）能修改本表。其他号只读，领任务靠 Hook 巡逻本表。
> 本表是总控手动维护的状态表，不是实时事实；任务状态以远端提交和收据为准，表的状态可能滞后数小时。
> 表格列顺序固定，Hook 巡逻脚本按列解析，改列必须同步改 `hooks/patrol.sh`。

| 编号 | 任务 | 负责人 | 状态 | 任务书 | Issue |
|---|---|---|---|---|---|
| T-001 | 代币化美股研究 | node-1 | 完成 | tasks/T-001-tokenized-us-stocks.md | [#1](https://github.com/xy3293/muse-hub/issues/1) |
| T-002 | Step 6b 证据独立复核 | node-3 | 完成 | tasks/T-002-step6b-evidence-review.md | [#2](https://github.com/xy3293/muse-hub/issues/2) |
| T-003 | Kaggle 免费 GPU 接入 Muse 研究 | node-1 | 完成 | tasks/T-003-kaggle-free-gpu-for-muse.md | [#3](https://github.com/xy3293/muse-hub/issues/3) |
| T-004 | 免费资源盘点：对 Chen 真正有用的有哪些 | node-1 | 完成 | tasks/T-004-free-resources-for-chen.md | [#4](https://github.com/xy3293/muse-hub/issues/4) |
| T-005 | 规则一致性核查 | node-1 | 完成 | tasks/T-005-rule-consistency-audit.md | [#5](https://github.com/xy3293/muse-hub/issues/5) |
| T-006 | Control Tower 数据结构调查 | node-1 | 完成 | tasks/T-006-control-tower-data-survey.md | [#6](https://github.com/xy3293/muse-hub/issues/6) |
| T-007 | Control Tower 架构风险审查 | node-3 | 完成 | tasks/T-007-control-tower-architecture-review.md | [#7](https://github.com/xy3293/muse-hub/issues/7) |
| T-008 | 工人丢失修复 Stage 0：运行时能力探测 | node-1 | 完成 | tasks/T-008-worker-loss-stage0-capability-probe.md | [#8](https://github.com/xy3293/muse-hub/issues/8) |
| T-009 | 工人丢失修复 v2 Stage 0：DB 关联与巡逻可见性探测 | node-1 | 完成 | tasks/T-009-v2-stage0-db-patrol-probe.md | [#9](https://github.com/xy3293/muse-hub/issues/9) |
| T-010 | Checkpoint 续跑验证 Stage A：写 checkpoint（小型） | node-1 | 完成 | tasks/T-010-checkpoint-resume-validation.md | [#10](https://github.com/xy3293/muse-hub/issues/10) |
| T-011 | AI agent 群聊产品对比：Pachat 与同类方案 | node-1 | 完成 | tasks/T-011-ai-agent-group-chat-comparison.md | [#11](https://github.com/xy3293/muse-hub/issues/11) |
| T-012 | Checkpoint 续跑验证 Stage B：新 worker 凭 checkpoint 续跑 | node-1 | 完成 | tasks/T-012-checkpoint-stage-b-resume.md | [#12](https://github.com/xy3293/muse-hub/issues/12) |
| T-013 | Pachat 群消息即时唤醒节点核实 | node-1 | 完成 | tasks/T-013-pachat-instant-wake-verification.md | [#14](https://github.com/xy3293/muse-hub/issues/14) |
| T-014 | 节点巡逻 180 秒＋Pachat 盯梢 Hook | node-1 | 完成 | tasks/T-014-node-patrol-180-pachat-hook.md | [#15](https://github.com/xy3293/muse-hub/issues/15) |
| T-015 | 节点巡逻 180 秒＋Pachat 盯梢 Hook | node-2 | 完成 | tasks/T-015-node-patrol-180-pachat-hook.md | [#16](https://github.com/xy3293/muse-hub/issues/16) |
| T-016 | 节点巡逻 180 秒＋Pachat 盯梢 Hook | node-3 | 完成 | tasks/T-016-node-patrol-180-pachat-hook.md | [#18](https://github.com/xy3293/muse-hub/issues/18) |
| T-017 | 直控 node-3 浏览器自动化 PoC：P0 只读可行性核验 | node-1 | 完成 | tasks/T-017-node3-browser-poc-p0-verification.md | [#19](https://github.com/xy3293/muse-hub/issues/19) |
| T-018 | node-1 后台进程 600 秒存活验证 | node-1 | 完成 | tasks/T-018-node1-background-survival.md | [#20](https://github.com/xy3293/muse-hub/issues/20) |
| T-019 | node-2 自治对等节点最小验证 | node-2 | 完成 | tasks/T-019-node2-autonomous-peer-proof.md | [#21](https://github.com/xy3293/muse-hub/issues/21) |
| T-020 | node-3 自治对等节点最小验证 | node-3 | 完成 | tasks/T-020-node3-autonomous-peer-proof.md | [#22](https://github.com/xy3293/muse-hub/issues/22) |
| T-021 | 总控审批卡覆盖扩展到工具层卡（研究＋设计） | node-1 | 待领 | tasks/T-021-node1-director-card-coverage.md | [#23](https://github.com/xy3293/muse-hub/issues/23) |

> 试行记录：Pachat × GitHub 规程 1.1 立即执行版已于 2026-11-12 发布（Chen 批准），替代 1.0 新增通信流程；一周仅作后续观察，不作为开工或继续实现的门槛。登记见 Issue #13。GitHub 仍是唯一任务状态权威；v2 软件上线与通信观察分别记录。

> 规则记录：R14/R15 生效于 2026-11-11，节点下次 Hook 巡逻自动继承。
> 规则记录：R18 对等节点自主执行生效于 2026-11-14（Chen 批准推行）；R6a/R6b 巡逻周期同步为生产值 60 秒（2026-11-14 20:43 已改，RULES 本次同步）；R16 审批卡说明同步（总控按范围批卡已 live）；checkpoint-spec 增加 §12 v1.1 增补，TASK_TEMPLATE 增加任务书 v2 字段。
> 规则记录：Chen 2026-11-14 裁决（6e01db8，登记 ab16c73）：snapshot-push.md:10-11 采窄读，禁令约束「发起认证的一方」，不约束「消费所有者预置凭据的一方」；R16 修订 node-3 入适用名单（通道验证 24h，2026-11-15 23:31:32 CST 到期，未成则退条）；新增 R19 文档范围争议；R7 增 node-3 Issue 评论由总控代发。
> 规则记录：Chen 2026-11-15 00:29 决定放弃 node-3 shell 通道，总控提前执行 R16 退条（不等 24h 到期）：node-3 移出适用名单，回退工具层＋R7 总控代发评论；原因无合规投放通道（卡种测试 f033427 实测本机无凭据），非 node-3 失败。方向改为优化总控审批卡能力（T-021 已派 node-1 研究工具层卡覆盖）。
> 规则记录：R19 补终局效力（Chen 6ab2798）：Chen 签发、落库、带 SHA 的 RULINGS 对范围解释有终局效力；R7 增 node-3 Issue 评论由总控代发（总控 354197e，含 BOARD 裁决补记）。
> 规则记录：Chen 2026-11-15 规则重基（32029ff）：R12 改规则权归 Chen（总控只落库附 SHA，不负责同意）、R17 授权来源单线（Chen 直令／节点私聊／总控原样转达均有效，一次授权持续有效；卡是产品行为、不是授权来源）、R19 平台文档与仓库规则按域划界、R20 单一真源（RULES.md＋RULINGS/ 为准，记忆里规则条文改写成指针）；R20 补（a10ce28）：实测事实与义务句分开，实测不改指针；新增 RULINGS 卡机制现场记录（db15d47，node-3 00:16–00:40 实测，经其同意，R17 注脚）。
> 规则记录：R18 批卡流程补（Chen 2026-11-15 直令）：总控独家批卡，覆盖推送卡与工具层卡（首批只开 add_issue_comment）；批前仍查五项，新增 extraction_status=partial 时必须读 snapshot.body_text 原文再决定；批后记入总控本地 director-decisions.jsonl，批卡不等于验收，批后核对执行结果。
> 规则记录：R6a/R6b 巡逻周期 2026-11-12 改为 180 秒（Chen 批准）；总控侧注册已改，RULES／ONBOARDING／README 已同步，各节点注册由 T-014/015/016 改。
> 凭据记录：推送 PAT 已于 2026-11-11 轮换，新 PAT 生效；旧 PAT 因在聊天明文出现过，Chen 随后撤销。

## 状态说明

- **待领**：任务书已写好，等负责人 Hook 发现并领取。
- **进行中**：任务已派发，节点 Hook 已唤醒并开始执行；不以评论为准。
- **待验收**：结果已交到 `results/<负责人>/`，等总控验收。
- **完成**：总控验收通过，已合入主项目。
- **失败**：执行失败或验收不通过，原因写在 Issue 里，等总控重派。
- **拒收**：总控验收不通过（REJECT），等待升版重派。总控在任务书生成新版本并写明变更或重派原因，核对负责人，再将 BOARD 状态改为“待领”；仅当“新版本＋派给该节点＋待领”同时成立且该版本未见过时，支持版本键的节点才会重新唤醒。内容不变但确需重派也可升版；未升级节点先升级。正常流程不删除 seen，损坏状态只按 [故障恢复说明](docs/state-recovery.md) 定点修复。

## 图例

- 负责人只写 `node-1` / `node-2` / `node-3` 三种，不要写人名或账号名。
- 一行一个任务，不要合行、不要在表里写长文，细节写任务书里。
