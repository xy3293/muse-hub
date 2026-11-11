# T-002 Step 6b 证据独立复核

## 任务信息

- **编号**：T-002
- **标题**：Step 6b 证据独立复核
- **负责人**：node-3（3 号核查）
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/2

## 背景

Stage B 的 Step 6b（Hook 可靠性改造的真实仓库测试）已完成并交付，结论是 P0 门禁通过。Step 7 交付报告也已写好。总控自己的验收和 Antigravity 的复核都已做过，现在需要一个完全独立的第三方复核，防止自证：只认公开仓库里能查到的事实和证据文件本身，不采信任何人口头说法。

## 目标

一份独立复核报告，对 Step 6b 的结论给出总体 verdict（PASS 或 REJECT），并逐项列出核查结果与发现的问题。

## 输入

- 证据文件（总控已推到本仓库，全部在 `evidence/step6b/` 下）：
- `step6b-test-results.md`：Step 6b 全部结果汇总（主证据）
- `step6b-resume-regression-output.txt`：本地回归输出
- `step6b-exact.diff`：改动 diff
- `step6b-test7-handoff.md`：Test 7 准备记录（注意：该文件本身写着 chain NOT TESTED，是指准备阶段尚未跑链路；链路的实际结果在 `step6b-test-results.md` 的 Test 7 一节，不要误判）
- `muse-hub-delivery-report-2026-11-10.md`：Step 7 交付报告（GPT 模板 8 节）
- 两个公开仓库的远端事实（直接查 GitHub，不要只看证据文件里写的）：
- 测试仓库 https://github.com/xy3293/muse-hub-test（提交、Issue #1、评论）
- 本仓库 https://github.com/xy3293/muse-hub（交付报告与证据文件）
- 本任务书即全部输入；不需要其他聊天记录。

## 输出要求

- 文件路径：`results/node-3/T-002-step6b-evidence-review.md`
- 中文，结论先行；每个关键结论贴来源链接（提交链接、Issue 链接、文件链接）；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源；查不到的写“未查到”，不要猜。
- 每项核查结论分三类写清楚：已核实 / 无法从公开仓库核实（只能采信本地文件）/ 存疑。

## 验收标准

逐项核查，缺一项验收不通过：

1. **远端事实逐项核对**：`step6b-test-results.md` 里列的测试仓库提交 SHA（基线、T-900、T-901、T-902、T-900-v2、T-903、T15、T-904、ACK 提交 `12cb98b7…`）是否真实存在、内容是否与摘要一致；测试仓库 Issue #1 与评论 6762499129 是否存在，时间戳与编辑历史是否与摘要一致；ACK 提交的提交信息是否恰为 MUSE-ACK 行、作者是否为 xy3293、是否只改了 BOARD.md、BOARD 里 T-904 是否为完成。
2. **74 PASS 数字来源**：`step6b-test-results.md` 称本地回归 74 PASS / 0 FAIL，引用的是 `step6b-resume-regression-output.txt`。数一下该文件里的 PASS，判定 74 这个数字是否站得住、引用是否准确。
3. **Test 7 时间线**：收据 SHA/大小/mtime、Worker B 复用无修改、轮询器 ACKED 转换——哪些能从公开仓库核实，哪些只能采信本地文件，如实区分；中断是受控检查点停止、不是 kill 信号，这一点是否在摘要里如实说明。
4. **NOT TESTED 是否诚实**：摘要里列的 4 项 NOT TESTED（T04-delete、T18-real、T02 收据隔离子项、T15 终态保持子项）是否齐全、无遗漏、无夸大；有没有哪项标了 PASS 但实际没测。
5. **交付报告**：8 节是否齐全；Quota 一节是否诚实标了“尚未测得”而没有估算；未解决风险是否只写了那两条、与事实是否相符。
6. **总体 verdict**：PASS 或 REJECT；发现的问题按严重程度列出，严重的要写清楚影响（是否动摇 P0 门禁通过的结论）。

## 截止

- 无硬性截止，越快越好。

## 流程

- 在 Issue #2 下回复已领 → 按任务书执行 → 完成后回复已完成 + 文件链接 → 总控验收。
- 不要动 BOARD.md，不要写别人目录；有问题先在 Issue 里问，不要自己猜。
