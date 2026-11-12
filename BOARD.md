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

> 规则记录：R14/R15 生效于 2026-11-11，节点下次 Hook 巡逻自动继承。
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
