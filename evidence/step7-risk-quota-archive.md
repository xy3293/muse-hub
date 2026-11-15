# Step 7 风险台账＋额度归档（A5）

- 归档时间：2026-11-16（UTC 2026-11-15 22:xx，CST 2026-11-16 06:xx）
- 归档人：总控（Kai）
- 来源：A/B 计划（GPT 修订版，Chen 2026-11-11 00:01 确认最终稿）；Step 6b 真实阶段结果（`evidence/step6b/step6b-test-results.md`，2026-11-10）；B 包三节点报告（T-025/T-026/T-027，2026-11-15）。

## Step 7 风险（未决项）

| # | 风险/未决项 | 状态 | 说明 |
|---|---|---|---|
| Q5 | 残余风险偏好（接受 vs 缓解） | 未决（Chen 未答） | A/B 计划遗留问题，见 GOAL.md。 |
| Q6 | NOT TESTED 项（留置 vs 轻量替代测试） | 未决（Chen 未答） | 见下表 NOT TESTED 清单。 |
| T04-delete | 评论删除／删增计数抵消 | NOT TESTED（设计如此） | 完整 live catalogue 无删评论工具；未删、未伪造。 |
| T18-real | 超 100 提交 Compare 分页 | NOT TESTED（设计如此） | 超 20 提交预算；本地 T18-sim 为另证。 |
| T02 子项 | 真实收据隔离／ACKED 字节保留 | NOT TESTED → A4 补测中 | 当时无真实收据、无 ACKED 事件；A4（Codex，总控机隔离）正在补测。 |
| T15 子项 | 终态保留 | NOT TESTED → A4 补测中 | 当时无 ACKED/REJECTED/SUPERSEDED 事件；A4 正在补测。 |
| 延迟监控 | 延迟监控 | 仅设计，未上生产 Hook | A5 明确：不改生产 Hook。 |
| ACK 签名 | ACK 签名 | 另立任务，不在本轮 | A/B 计划原文。 |
| T04-delete / T18-real | 同上 | 留置（Chen 未选缓解） | Q6 未决，故留置。 |

## 额度（Quota，B3 实测，2026-11-15）

| 方 | 额度 | 重置 | 说明 |
|---|---|---|---|
| node-2 | 免费每周额度已用 1%，剩约 99% | 2026-11-22 16:38 CST | 额外 tokens 已用 0%（剩 1B）；未达 ≤30% 停重活线；未遇限流。 |
| node-1 | 不可见，未验证 | — | 本机无 muse CLI、无登录态、无额度环境变量。重活派发前须由能看到用量界面的一方（Chen／总控）先确认。 |
| node-3 | 不可见，未验证 | — | 同 node-1。 |
| 总控 | 稀缺资源（定性） | — | 总控额度为最稀缺项；日常以紧 brief、少协调、批量写保护。 |

## 执行能力结论（B4 已核）

- 三节点均可接轻量本地代码任务（纯 Python/Shell/Node，标准库 unittest，不依赖 pytest、不依赖 Codex/Antigravity）。
- 涉及 Codex 委派或 Antigravity 审阅的任务暂不具备完整执行链，需先补 `agy`、确认 Codex 登录态与 bypass 审批。
- 缺件清单（B5 跟进）：`agy` 全缺（3/3）、`bwrap` 全缺（3/3）、Codex 登录态未验证（3/3，node-3 明确 Not logged in）、node-2 技能软链接缺失。
- 上述缺件的修复需 Chen 介入（Codex 登录走 OAuth／设备码；`agy` 安装走 Google 账号），不由节点自行解决。

## 归档说明

- 本文件为 A5 归档：Step 7 风险与额度快照，写死在此时点；后续变化另起文件，不改本文件。
- A4 补测结果出来后，T02/T15 子项状态在 A4 报告里更新，不回改本文件。
