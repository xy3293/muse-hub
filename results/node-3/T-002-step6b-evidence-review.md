# T-002 Step 6b 证据独立复核报告

- **任务**：T-002 Step 6b 证据独立复核
- **复核人**：node-3（3 号核查）
- **复核日期**：2026-11-10（UTC；北京时间 2026-11-10 17:xx）
- **总体 verdict：PASS**
- **复核对象**：`evidence/step6b/` 下 5 个证据文件（以 muse-hub 仓库提交 `4252914027c0a5ff6a5d65849b08dc7c56813eec` 为准）与两个公开仓库的远端事实
- **方法**：只认公开仓库可查事实与证据文件本身，不采信口头说法。远端事实直接查 GitHub REST API（`api.github.com`，公开仓库未鉴权读取）与仓库内容逐项比对；本地文件逐行计数、逐项核对。

## 结论先行

**PASS。** 可从公开仓库核实的部分全部属实，无一处矛盾：9 个提交 SHA 全部存在且内容与摘要一致；测试仓库 Issue #1（ID 6303007785）与评论 6762499129 存在，时间戳与摘要一致；ACK 提交 `12cb98b7…` 的提交信息恰为 MUSE-ACK 行、作者为 xy3293、仅改 BOARD.md，ACK 后 BOARD 中 T-904 为完成、其余行不变；回归输出文件经独立计数确为 74 行 PASS、0 行 FAIL；4 项 NOT TESTED 齐全、无遗漏、无夸大，未发现标 PASS 但实际未测的项；交付报告 8 节齐全，Quota 诚实标"尚未测得"，未解决风险恰为两条。

**但有一个中等级别的证据缺口（见问题 1）：** Test 7 链路的核心内部证据——收据文件、轮询器 ACKED 转换的原始 JSON、审批记录——所引用的本地文件均未收入仓库，且本机不存在所引路径，独立复核无法重新验证，只能采信摘要转述。远端可验证的终态全部一致，因此该缺口不直接动摇 P0 门禁通过的结论，但"收据复用无修改"这一关键断言缺乏可独立复查的证据。建议总控将这批本地证据文件归档入仓，否则下一次复核仍只能采信转述。

## 1. 远端事实逐项核对

### 1.1 测试仓库提交 SHA（xy3293/muse-hub-test，2026-11-10 核查时共 10 个提交）

| 推送 | 摘要所列 SHA | 远端核实 | 内容一致性 |
|---|---|---|---|
| provider 初始提交 | `b7cc93baceed7fa3a708bf0d1908f9ac624a3901` | 已核实 | Initial commit，仅新增 README.md |
| baseline | `943a91b2b297ec71a899a50da8825c2dc25d0524` | 已核实 | 2026-11-10T08:14:41Z，新增 BOARD.md、修改 README.md；该提交树下仅有 BOARD.md 与 README.md 两个文件，与"README.md + BOARD.md only"一致 |
| T-900 | `d62c24d7adf40c99d9fbdb1beca07c356e5874c1` | 已核实 | 08:15:57Z，新增 `results/node-1/T-900-step6b.md`，内容 task=T-900、node=node-1、version=1 |
| T-901 | `1b2cf75aeeb92f0b60349c24cb1a01a516641cc4` | 已核实 | 08:16:17Z，新增 `results/node-1/T-901-step6b.md`，version=1 |
| T-902 | `01873dc5d12224ad80559203942e274a813a4d43` | 已核实 | 08:16:33Z，新增 `results/node-1/T-902-step6b.md`，version=1 |
| T-900-v2 | `7b84059db2379ad1ba093b82c47dd4db43f0e9a5` | 已核实 | 08:17:11Z，修改同一文件 `results/node-1/T-900-step6b.md`，内容变为 version=2，task/node 不变；与"版本身份"说法一致 |
| T-903 | `94f03f6465070dfbfa71e9da989953eb525d666e` | 已核实 | 08:17:59Z，新增 `results/node-1/T-903-step6b.md`，version=1 |
| T15 | `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` | 已核实 | 08:19:35Z，作者 xy3293，仅修改 BOARD.md，diff 只追加一行 `Step 6b T15: unrelated director note; no acknowledgement.`，无 MUSE-ACK 行 |
| T-904 | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` | 已核实 | 08:20:11Z，新增 `results/node-1/T-904-step6b.md`，version=1 |
| ACK 提交 | `12cb98b7079763700557be79ee98652a900eb515` | 已核实 | 见 1.3 |

提交顺序与时间顺序一致，全部作者均为 xy3293。来源：提交列表 https://github.com/xy3293/muse-hub-test/commits/main ，各提交链接形如 https://github.com/xy3293/muse-hub-test/commit/12cb98b7079763700557be79ee98652a900eb515 。

### 1.2 测试仓库 Issue #1 与评论

- Issue #1：https://github.com/xy3293/muse-hub-test/issues/1 ，ID **6303007785**，状态 open，创建于 2026-11-10T08:17:39Z，更新于 2026-11-10T08:18:47Z，作者 xy3293。**已核实**。该仓库全部 Issue 恰为 1 个，与摘要"Exactly one Issue"一致。
- 评论 6762499129：https://github.com/xy3293/muse-hub-test/issues/1#issuecomment-6762499129 ，作者 xy3293，创建于 2026-11-10T08:18:12Z，更新于 2026-11-10T08:18:47Z；当前正文为 `T-903 node-1 version=94f03f6465070dfbfa71e9da989953eb525d666e edit-marker=step6b-T04`。**已核实**：评论数恰为 1 条；创建/更新时间戳与摘要一致（创建 08:18:12Z、编辑后 08:18:47Z）。
- 存疑点（低）：评论**编辑前**的正文无法通过公开 API 查到（GitHub REST 不暴露 Issue 评论的编辑历史），只能从当前正文含 `edit-marker=step6b-T04` 且 updated_at 晚于 created_at 推断编辑发生过一次。现有证据与摘要一致，但属于"与证据一致、无法完全独立还原"，不是已核实。

### 1.3 ACK 提交（Test 7）

提交 https://github.com/xy3293/muse-hub-test/commit/12cb98b7079763700557be79ee98652a900eb515 ，2026-11-10T08:28:51Z：

- 提交信息恰为单行 `MUSE-ACK task=T-904 node=node-1 event=result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9 verdict=PASS`，无多余行。**已核实**。
- 作者与提交者 login 均为 xy3293。**已核实**。
- 仅修改 BOARD.md 一个文件（1 增 1 删）。**已核实**。
- ACK 后远端 BOARD：T-904 为"完成"，T-900/T-901/T-902/T-903 仍为"待验收"，T15 备注行完整保留。**已核实**。
- ACK 前（T-904 提交处）BOARD：T-904 为"待验收"，其余相同。**已核实**。
- 提交总数：ACK 后共 10 个提交（9 个在前 + 1 个 ACK 推送），与摘要一致。**已核实**。

### 1.4 本仓库（xy3293/muse-hub）远端事实

- `evidence/step6b/` 目录远端存在全部 5 个文件：`muse-hub-delivery-report-2026-11-10.md`、`step6b-exact.diff`、`step6b-resume-regression-output.txt`、`step6b-test-results.md`、`step6b-test7-handoff.md`。**已核实**。
- 交付报告中"Step 7 Hook 重开与对账"一节称当时远端 HEAD 为 `fd0ba0c8`、Issue #1 评论恰为 2 条（ID 6747509854、6747528416）：经查 muse-hub Issue #1 评论确为 2 条，ID 与之相符（创建于 2026-11-09T17:59:43Z 与 18:00:37Z）；`fd0ba0c8628af1b8f30bfd140634a8cb335e3920` 确为 T-001 验收提交，且 T-002 派发提交（2026-11-10 17:10:24 +08）晚于报告所述重开时间（16:50 +08），因此报告所述"Compare 0 个新提交、游标未移动"在其成文时点成立。**已核实**（Hook 本身是否启用、dry_run 结果为本地状态，无法从公开仓库核实）。

## 2. 74 PASS 数字来源

证据文件：`evidence/step6b/step6b-resume-regression-output.txt`（210 行，2026-11-10）。

- 独立计数：以 `PASS ` 开头的行恰为 **74 行**，以 `FAIL ` 开头的行恰为 **0 行**；全文仅一处出现 "FAIL"，即第 209 行 `FAULT SUMMARY: 20 PASS, 0 FAIL, 7 NOT TESTED` 中的 "0 FAIL"。**已核实**：74 PASS / 0 FAIL 的数字站得住。
- 74 个 PASS 测试名无重复。**已核实**。
- 引用准确性（低级别说明）：该文件本身没有自带"74 PASS"总计数行，74 是数 PASS 行得出的；摘要的引用方式是计数而非转述文件自述总数，数字本身无误。文件内 FAULT SUMMARY 的 "20 PASS" 是其中故障注入子集的计数，与总数 74 不冲突。
- 范围说明：该回归运行于远端写入之前，文件内 7 行 NOT TESTED（T01、T02、T03、T04、T15、T18-real、real-worker-interrupt-receipt-ACK-chain）描述的是本地 harness 状态；摘要开篇已明确说明这一点，真实阶段证据在摘要正文，不构成误导。文件中回归用例使用占位 SHA（如 `aaaaaaaa…`），属于本地模拟，摘要未将其冒充为真实仓库运行。**已核实**。
- 退出码 exit 0：回归文件本身不记录总退出码，该断言只能采信摘要转述。**无法从公开仓库核实**。

## 3. Test 7 时间线

| 断言 | 分类 | 核查结果 |
|---|---|---|
| T-904 源提交 `bc3206e9…`、event_id `result:T-904:node-1:bc3206e9…` | 已核实 | 提交存在，内容一致（见 1.1） |
| 收据 SHA-256 `9f4d2d76…`、mtime 2026-11-10 08:26:54.780583565 +0000、998 字节、verdict PASS | 无法从公开仓库核实 | 收据文件位于本地 real-home 路径，不在仓库内；本机不存在 `/home/hatch/workspace/muse-hub-tests/`，无法重新验证哈希/mtime/大小 |
| Worker B 复用同一收据、无修改、无重复语义验收、无新收据 | 无法从公开仓库核实 | 同上；所引用的收据与事件文件均不在仓库内 |
| 轮询器 ACKED 转换：DETECTED → ACKED，`main_ack.acked=true`，`ack_method=muse-ack-commit`，`main_acked_at=2026-11-10T08:29:50Z`，游标推进至 ACK 提交，`unacked_count 6 → 5` | 无法从公开仓库核实 | 所引 `step6b-real-ack.{before,after}.json` 等文件不在仓库内；但转换的远端终态（ACK 提交、BOARD、HEAD）已核实，与所述转换一致 |
| 中断是受控检查点停止、不是 kill 信号 | 已核实（就"如实说明"而言） | 摘要 Test 7 一行明确写有 Caveat："the interruption was a controlled checkpoint stop (Worker A was briefed to stop after SAVE_RECEIPT), not a kill signal"；交付报告时间线亦写"随后在 SAVE_RECEIPT 检查点受控停止，不是 kill 信号"。说明诚实，未夸大为 kill 信号恢复 |
| `step6b-test7-handoff.md` 写 chain NOT TESTED | 已核实 | 该文件标题与末尾均写明准备阶段链路 NOT TESTED、协调员另行执行；摘要将其作为准备记录引用，并称链路实际结果在摘要 Test 7 一节，两者无矛盾，未误判 |
| 审批 13 张（恢复运行 12 张 + Test 7 BOARD 推送 1 张） | 无法从公开仓库核实 | 所引 `step6b-resume-write-requests.jsonl` 与审批记录 `connector-attempt-df1b8c…` 不在仓库内；handoff 所述准备阶段 12 张（8 推送 + Issue + 评论增/改 + 1 次需审批读取）与摘要的 12 张在构成上自洽，但均无法从公开仓库独立核对 |

补充：摘要与交付报告均主动披露"Worker B 与推送的独立时间戳未在主证据给出"，属于诚实的缺口标注，不是隐瞒。

## 4. NOT TESTED 是否诚实

摘要表中共列 4 项 NOT TESTED：T02 收据隔离子项、T04-delete、T15 终态保持子项、T18-real；交付报告表所列 NOT TESTED 与之一致。**已核实**：

- 4 项齐全，无遗漏：逐一对照回归输出与交付报告，未发现第 5 项应列未列的未测项。
- 无夸大：每一项都写明了未测原因（无真实 worker 收据/无 ACKED 事件；无 delete-comment 工具；Compare 分页超 20-commit 预算），与任务背景相符。
- 未发现标 PASS 但实际未测的项：表内每一 PASS 行均有对应的真实阶段动作或本地回归证据；本地回归文件中的 7 行 NOT TESTED 是回归运行于远端写入之前的状态，摘要开篇已说明，不属于漏标。
- `step6b-test7-handoff.md` 的 "chain NOT TESTED" 是指准备阶段尚未跑链路，摘要已按任务书提醒正确处理，未将其误判为链路失败。

## 5. 交付报告

文件：`evidence/step6b/muse-hub-delivery-report-2026-11-10.md`（2026-11-10）。

- 8 节齐全：，共 8 节。**已核实**。
- Quota 一节诚实标了"尚未测得"：agent turns / 重复验收次数、额度节约幅度均写"尚未测得"，未做任何估算；并明确写 Test 7 的收据复用不作为前后对照测量。**已核实**。
- 未解决风险恰为两条：Muse 投递延迟仍不可控；author-login ACK 认证本身较弱（设计如此，无 GPG/签名校验）。两条均与事实相符（前者无反证，后者与 Test 7 仅凭 author-login + BOARD 变更 + MUSE-ACK 行即 ACK 的机制一致）。**已核实**。
- 报告表与摘要一致，包括 4 项 NOT TESTED 的表述一致。**已核实**。
- 报告所述 Hook 重开与对账（16:50 +08，HEAD `fd0ba0c8`、Issue #1 评论 2 条、游标未移动、唯一事件 T-001 为 ACKED）：其中可从公开仓库核实的部分（HEAD 提交存在且时序一致、Issue #1 评论数与 ID）已核实；Hook 启用状态与 dry_run 结果为本地状态，无法从公开仓库核实。

## 6. 总体 verdict 与问题清单

**Verdict：PASS。** P0 门禁通过的结论成立：本地回归 74 PASS / 0 FAIL 经独立计数属实；全部远端事实逐项核实无矛盾；NOT TESTED 诚实完整；交付报告 8 节齐全、Quota 与风险如实陈述；Test 7 中断性质如实说明为受控检查点停止。

### 问题清单（按严重程度）

1. **[中] Test 7 链路核心证据未入仓，无法独立复查。** 收据文件、事件文件、`step6b-real-ack.{before,after}.json`、轮询输出、`step6b-resume-write-requests.jsonl` 等均未收入 `evidence/step6b/`，且本机不存在所引 real-home 路径。影响：收据复用无修改、轮询器 ACKED 转换、13 张审批这三项断言只能采信转述；远端终态（ACK 提交信息/作者/仅改 BOARD、BOARD T-904 完成、HEAD 为 ACK 提交、共 10 提交）全部一致，因此**不直接动摇 P0 结论**，但链路内部的关键断言缺乏可独立复查的证据。建议：总控将这批本地证据文件（收据、事件、轮询 before/after、审批记录）归档入仓，或在报告中明确标注其保存位置与保留期限。
2. **[低] 74 PASS 是计数得出的总数，文件无自述总行。** 回归输出文件本身没有"74 PASS"总计数行；独立计数确认 74 行 `PASS `、0 行 `FAIL `，数字无误。影响：无，仅引用方式说明。
3. **[低] 评论 6762499129 的编辑前正文无法从公开 API 还原。** GitHub REST 不暴露 Issue 评论编辑历史；只能从当前正文含 `edit-marker=step6b-T04` 且 updated_at（08:18:47Z）晚于 created_at（08:18:12Z）推断编辑过一次。现有证据与摘要一致，影响：无。
4. **[低] `step6b-exact.diff` 不是标准 git diff 且含 NUL 字节。** 核查确认：该文件为无 `diff --git` 头的 unified diff，共 23 个 hunks、272 增 1 删；NUL 字节位于 NUL 分隔的推送清单（`.paths`）内容中，与摘要所述清单格式一致，不是损坏。diff 覆盖范围：poll 脚本改 1 行（REPO 环境变量化）+ 新增驱动、文档、夹具与测试仓库文件；全文扫描未见密钥、Token 或私钥。影响：无，但建议以后用标准 `git diff` 格式归档以便直接校验。
5. **[信息] 摘要与交付报告均主动披露了证据缺口。** 包括"Worker B 与推送的独立时间戳未在主证据给出"、Quota"尚未测得"、审批"CLI 不提供审批操作 ID/UI 收据，无法独立目视核对卡片数"。这些诚实标注增加了报告可信度。

## 附录：核查分类汇总

- **已核实**：9 个提交 SHA 与内容、Issue #1 与评论 6762499129 的存在与时间戳、ACK 提交信息/作者/仅改 BOARD.md、ACK 前后 BOARD 状态、提交总数 10、74 PASS / 0 FAIL 计数、4 项 NOT TESTED 的完整性、交付报告 8 节/Quota/两条风险、受控中断的如实说明、本仓库 evidence 目录 5 个文件齐全、muse-hub Issue #1 评论 2 条与 ID、gate reset 时间戳换算（1794300474 = 2026-11-10 08:47:54 UTC，与摘要一致）。
- **无法从公开仓库核实（只能采信本地文件）**：收据哈希/mtime/大小与复用过程、轮询器 ACKED 转换细节与游标/health 数值、Token 门禁与空仓库检查、13 张审批记录、回归总退出码、Hook 重开与 dry_run 结果。
- **存疑**：无实质存疑项；仅第 3 项（评论编辑前正文）与第 1 项（Test 7 内部证据缺失）属于"无法完全独立还原"，已在上文分别说明。

---

复核人：node-3（3 号核查），2026-11-10。任务书：`tasks/T-002-step6b-evidence-review.md`；Issue：https://github.com/xy3293/muse-hub/issues/2 。
