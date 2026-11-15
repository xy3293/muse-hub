# T-028 Step 6b 证据脱敏副本独立复核报告

- **任务**：T-028（Issue [#26](https://github.com/xy3293/muse-hub/issues/26)）
- **复核对象**：`evidence/step6b/` 下 5 份脱敏证据（总控 A1 推送，提交 `4252914`，2026-11-10 17:10 +08）
- **复核时间**：2026-11-15（CST）
- **复核基准**：公开仓库可查事实 + 证据文件本身；总控本地 real-home 原件不在本复核可及范围
- **任务书**：`tasks/T-028-step6b-evidence-review-node1.md`；关联任务 T-002（Issue [#2](https://github.com/xy3293/muse-hub/issues/2)）

## 结论：PASS

- **脱敏**：5 份文件逐一扫描，未发现 Token、PAT、密钥、Cookie、Authorization 值、私人信息残留。
- **关联一致**：`step6b-test-results.md` 所列 9 个测试仓库提交 SHA 全部在 [xy3293/muse-hub-test](https://github.com/xy3293/muse-hub-test) 远端真实存在且提交信息一致；ACK 提交 `12cb98b7…` 的提交信息恰为 MUSE-ACK 行、作者为 xy3293、仅改 `BOARD.md`、BOARD 中 T-904 为完成；测试 Issue #1 评论 `6762499129` 的正文与创建/编辑时间戳与摘要一致；生产仓库 Issue #1 的 2 条评论 ID 与摘要一致。
- **原件未上传**：`evidence/step6b/` 恰为 T-002 任务书列出的 5 份文件，无多余文件；证据中引用的 30 余份原始文件（`step6b-real-*.json`、`step6b-resume-*.json/log`、收据、事件文件、`step6b-resume-write-requests.jsonl` 等）在公开仓库中均不存在。
- **数字核实**：回归输出中 `^PASS` 行数为 74，与“74 PASS / 0 FAIL”一致；唯一含 `FAIL` 的行是 `FAULT SUMMARY: 20 PASS, 0 FAIL`。
- **残留观察**（不影响 PASS，见末节）：文件内残留本地路径 `/home/hatch/...`；`step6b-test7-handoff.md` 与 `step6b-exact.diff` 内含执行前的 NOT TESTED 快照；收据与轮询器事件文件本身无法从公开仓库核实。

## 1. 逐文件脱敏检查

扫描方法：对 5 份文件做模式扫描（`ghp_`、`github_pat_`、`gho_`、`sk-`、`Bearer`、Authorization 值、私钥头、密码/密钥赋值、Cookie 值、邮箱、电话），并人工通读全文；同时统计 NUL 字节与文件类型。

| 文件 | 行数 | 检查结果 |
| --- | --- | --- |
| [muse-hub-delivery-report-2026-11-10.md](https://github.com/xy3293/muse-hub/blob/main/evidence/step6b/muse-hub-delivery-report-2026-11-10.md) | 79 | 通过。无密钥类残留。仅含 SHA-256 收据哈希、SHA-1 提交号、审批操作 ID（`connector-attempt-df1b8c…`，为操作记录编号，非凭据）、游标与评论 ID。含本地路径 `/home/hatch/...`（见 §5）。 |
| [step6b-test-results.md](https://github.com/xy3293/muse-hub/blob/main/evidence/step6b/step6b-test-results.md) | 111 | 通过。无密钥类残留。明确写明 `gh auth token` 退出 0 但“stdout/stderr discarded…No token was printed, logged or persisted”；额度数字为公开的 rate-limit 计数。含本地路径（见 §5）。 |
| [step6b-resume-regression-output.txt](https://github.com/xy3293/muse-hub/blob/main/evidence/step6b/step6b-resume-regression-output.txt) | 210 | 通过。无密钥类残留。仅含模拟 SHA（`aaaa…`/`cccc…`/`dddd…` 占位值）与本地回归输出。含本地路径（见 §5）。 |
| [step6b-exact.diff](https://github.com/xy3293/muse-hub/blob/main/evidence/step6b/step6b-exact.diff) | 340 | 通过。无密钥类残留。含 9 个 NUL 字节，位于 `.paths` manifest 的 NUL 分隔符处，文件本身已注明“NUL manifest 在 diff 中保留原始 NUL”，非隐藏内容。含本地路径（见 §5）。 |
| [step6b-test7-handoff.md](https://github.com/xy3293/muse-hub/blob/main/evidence/step6b/step6b-test7-handoff.md) | 42 | 通过。无密钥类残留。含本地路径（见 §5）。标题与正文写 chain NOT TESTED，见 §4 说明。 |

补充：5 份文件均为文本文件，无二进制附件；邮箱、电话号码扫描结果为 0 命中；`Cookie` / `Authorization` 仅出现在“不得持久化 token”等规范性文字中，无实际值。

## 2. 证据与 ACK、提交关联核查（远端已核实）

以下 SHA 均于 2026-11-15 通过 GitHub API 在 `xy3293/muse-hub-test` 逐一核对，提交信息与 `step6b-test-results.md`“Confirmed remote snapshot SHAs”表一致。

| 提交 | 远端核实结果 |
| --- | --- |
| 基线 `943a91b2b297ec71a899a50da8825c2dc25d0524` | 存在，[提交信息](https://github.com/xy3293/muse-hub-test/commit/943a91b2b297ec71a899a50da8825c2dc25d0524)为 `Step 6b baseline: isolated test board`，2026-11-10T08:14:41Z |
| T-900 `d62c24d7adf40c99d9fbdb1beca07c356e5874c1` | 存在，`Step 6b T-900: isolated test fixture` |
| T-901 `1b2cf75aeeb92f0b60349c24cb1a01a516641cc4` | 存在，`Step 6b T-901: isolated test fixture` |
| T-902 `01873dc5d12224ad80559203942e274a813a4d43` | 存在，`Step 6b T-902: isolated test fixture` |
| T-900-v2 `7b84059db2379ad1ba093b82c47dd4db43f0e9a5` | 存在，`Step 6b T-900-v2: isolated test fixture` |
| T-903 `94f03f6465070dfbfa71e9da989953eb525d666e` | 存在，`Step 6b T-903: isolated test fixture` |
| T15 `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` | 存在，`Step 6b T15: isolated test fixture` |
| T-904 `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` | 存在，[提交信息](https://github.com/xy3293/muse-hub-test/commit/bc3206e97018cebe7a4accf0ff1fdfe2b63943a9)为 `Step 6b T-904: isolated test fixture`，2026-11-10T08:20:11Z |
| ACK 提交 `12cb98b7079763700557be79ee98652a900eb515` | 存在，[提交信息](https://github.com/xy3293/muse-hub-test/commit/12cb98b7079763700557be79ee98652a900eb515)恰为 `MUSE-ACK task=T-904 node=node-1 event=result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9 verdict=PASS`；作者 login 为 xy3293；父提交为 T-904 提交；仅修改 `BOARD.md`；该提交下的 `BOARD.md` 中 T-904 为“完成”，其余行仍为“待验收”，T15 备注完整保留 |
| 提供方初始提交 `b7cc93baceed7fa3a708bf0d1908f9ac624a3901` | 存在，提交信息为 `Initial commit` |

其他远端事实：

- 测试仓库 Issue #1 评论 [6762499129](https://github.com/xy3293/muse-hub-test/issues/1#issuecomment-6762499129)：存在，正文为 `T-903 node-1 version=94f03f6465070dfbfa71e9da989953eb525d666e edit-marker=step6b-T04`，`created_at` 2026-11-10T08:18:12Z，`updated_at` 2026-11-10T08:18:47Z，作者 xy3293——与摘要（T03 建评论、T04 同一评论编辑后更新时间）一致。
- 生产仓库 [Issue #1](https://github.com/xy3293/muse-hub/issues/1) 评论：远端恰为 2 条，ID 为 `6747509854`、`6747528416`，作者均为 xy3293——与交付报告一致。
- 生产游标 `fd0ba0c8628af1b8f30bfd140634a8cb335e3920`：在本仓库历史中存在，提交信息为 T-001 验收通过——与交付报告“生产扫描游标”一致。
- 游标链：基线 `943a91b2…` → T01 `01873dc5…` → T02 `7b84059d…` → T03/T04 `94f03f64…` → T15 `9d4e3b98…` → test7 `bc3206e9…` → ACK `12cb98b7…`，与 `step6b-test-results.md` 的轮询表前后游标一致，无断链。
- 两份文件对 Test 7 关键值的记载一致：收据 SHA-256 `9f4d2d76…`、998 字节、mtime `2026-11-10 08:26:54.780583565 +0000`、`main_acked_at=2026-11-10T08:29:50Z`、`unacked_count 6 → 5`、审批 13 张（12 次恢复运行 + 1 次 Test 7 BOARD 推送）。

## 3. 原件未上传核查

- `evidence/step6b/` 在提交 `4252914` 中新增且仅包含上述 5 份文件；自 2026-11-10 起该目录无后续修改提交；当前目录文件清单与 T-002 任务书列出的 5 份证据一一对应，无多余文件。
- 证据正文引用的原始文件（`step6b-real-*.json/.stdout`、`step6b-resume-*.json/.log/.stdout`、`step6b-resume-write-requests.jsonl`、收据与事件文件、`test-repo.muse-github-snapshot-sync.json` 等 30 余个名字）经 `git ls-files` 全库检索，均不在公开仓库中。**事实**：脱敏副本范围与 A1 所述一致，无原件混入。
- **未验证**：总控本地 real-home 中的原件内容本复核无法读取，“原件本身是否含敏感信息”不在本次核查范围内；本结论仅针对“原件是否出现在公开仓库”。

## 4. NOT TESTED 与历史快照说明

- `step6b-test-results.md` 与交付报告均如实列出 4 项 NOT TESTED：T02 收据隔离子项、T04-delete、T15 终态保持子项、T18-real；两份文件口径一致，未发现标 PASS 但实际未测的项。
- `step6b-test7-handoff.md` 标题写 chain NOT TESTED、`step6b-exact.diff` 内嵌的旧版 `step6b-test-results.md` 写“真实仓库测试受限流阻断，未完成”：**事实**，两者均为执行前的历史快照（准备阶段），链路实际结果记录在 `step6b-test-results.md` 的 Test 7 一节；T-002 任务书已预先提示不要误判。本复核确认这不是矛盾，而是版本时序所致，不扣分。
- 中断方式如实说明：两份文件均写明中断是“受控检查点停止，不是 kill 信号”，未夸大为真实 kill 恢复。

## 5. 残留观察（不影响 PASS）

1. **本地路径残留**：5 份文件均含 `/home/hatch/...` 形式的本地路径（如 `real-home`、hook 脚本、测试目录）。其不属于任务书列出的 Token/PAT/密钥/Cookie/Authorization/私人信息类别，无凭据值，但暴露了执行环境的本地目录结构与用户名。如后续脱敏要求收紧，建议将此类路径替换为相对路径或占位符。
2. **交付报告 8 节齐全**：部署信息、当前实现盘点、修改清单、验证证据、Quota、审批和安全、未解决风险、报告位置与后续执行；Quota 一节诚实标注“尚未测得”，未做估算；未解决风险仅列两条（Muse 投递延迟不可控、author-login ACK 认证较弱），与正文事实相符。
3. **最终远端对账的 post-ACK 状态无独立 JSON 文件**：`step6b-resume-final-*.json` 本身注明仅为 ACK 前快照，post-ACK 状态在报告中说明系经 `gh api` 与轮询器核验。本次复核已用 GitHub API 独立复核 ACK 提交与 BOARD 内容，结果一致（见 §2），该缺口已由本次远端核查补足。
4. **无法从公开仓库核实的部分**（只能采信本地文件，标记为未验证）：收据文件本身的哈希/mtime/内容、轮询器事件文件的 DETECTED → ACKED 转换、`step6b-real-ack.*` 快照内容、13 张审批卡的逐张记录。上述内容在两份文件中的记载互相一致，无内部矛盾。

## 验收标准对照

| T-028 验收标准 | 结果 |
| --- | --- |
| 所有文件均已脱敏，无 Token、PAT、密钥、Cookie、Authorization、私人信息残留（逐文件列出） | 通过，见 §1 |
| 证据与 ACK、提交关联一致（收据、事件、ACK 提交号可追溯、无断链） | 通过，见 §2；收据与事件文件本身标记为未验证（§5.4） |
| 原件未上传公开仓库（与 A1 所述脱敏副本范围一致，无原件混入） | 通过，见 §3 |
| 复核报告在约定路径，远程可读 | 本文件位于 `results/node-1/T-028-step6b-evidence-review.md`，推送后由总控核验远端可读 |

## 来源

- 任务书：`tasks/T-028-step6b-evidence-review-node1.md`；T-002 任务书：`tasks/T-002-step6b-evidence-review.md`
- 证据目录：`evidence/step6b/`（提交 `4252914`，2026-11-10）
- 测试仓库：https://github.com/xy3293/muse-hub-test（提交与 Issue #1 评论，2026-11-10）
- 生产仓库：https://github.com/xy3293/muse-hub（Issue #1 评论、游标提交 `fd0ba0c8…`）

[node-1]
