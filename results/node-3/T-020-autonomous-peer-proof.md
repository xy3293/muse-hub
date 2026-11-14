# T-020 node-3 自治对等节点最小验证 — 最终证据（检查 1–6）

## 结论先行

**6 项检查全部通过。** 检查 1（重复唤醒去重）、检查 2（恰好一次重试）在 v1 执行轮完成并留有阶段证据，本恢复轮按 R18 未重做；检查 3 的证据文件名冲突经总控 SPEC_DECISION 裁决后恢复，只重跑了文件名核对；检查 4 账本一致、已确认副作用未重放；检查 5 决定核验通过（作者、任务号、冲突号、版本）；检查 6 即本文件，按裁决文件名推送到授权路径，推送 commit SHA 以远端读回为准（记录于 checkpoint seq 2 与完成汇报，本文件不自引自身 SHA）。

- 任务：T-020 node-3 自治对等节点最小验证，负责人 node-3，任务书 v3
- 任务书：https://github.com/xy3293/muse-hub/blob/main/tasks/T-020-node3-autonomous-peer-proof.md
- BOARD：https://github.com/xy3293/muse-hub/blob/main/BOARD.md（恢复时 T-020 为“待领”，负责人 node-3）
- Issue：https://github.com/xy3293/muse-hub/issues/22
- run_id：T-020-node-3-proof-1
- 恢复轮：2026-11-14 22:52 起（CST），恢复前远端 HEAD 6b84410e5f4381c431440a372346afee2669bc70

## 检查 1：重复唤醒去重 — 通过（v1 阶段，未重做）

- 第一次尝试：2026-11-14 14:34:16Z 启动，PID 9145（/proc/9145/stat starttime 284981）持 flock 独占锁，setsid＋nohup 后台任务每秒写一行心跳，14:36:16Z 完成，恰好 120 行（seq 1–120），唯一写者 PID 9145。
- 第二次尝试（任务运行中重走认领）：14:34:25Z，flock -n 失败，退出码 3，记录 LOCK_HELD return_without_execution，未启动第二份执行、无第二份副作用。
- 来源：阶段证据 `artifacts/T-020-v1-stage-evidence.md`（SHA-256 ed4babe33d0290a45669f1e7c9401819ad90176e8d0930afdbf47e059c35ecd1，与 checkpoint seq 1 记录一致），checkpoint seq 1 stage-01。

## 检查 2：恰好一次重试 — 通过（v1 阶段，未重做）

- 第一次运行：2026-11-14 14:34:34Z，错误签名 TRANSIENT_MARKER_PRESENT，退出码 1，副作用未发生。
- 诊断后恰好重试一次：退出码 0；副作用目标文件恰好 1 行（恢复轮复核 `side-effect-target.txt` 仍为 1 行）。
- 账本：effect-retry-001 两条记录（intent_recorded → confirmed，retry_count 1，target_lines 1），该错误签名只记一次重试。
- 来源：阶段证据同上，checkpoint seq 1 stage-02。

## 检查 3：SPEC_CONFLICT→PARKED→恢复 — 通过

- 冲突（任务书 v1/v2 内不一致，节点未自行选、未猜）： “输出要求”写 `results/node-3/T-020-autonomous-peer-proof.md`，“验收标准”第 6 条写 `results/node-3/T-020-peer-proof.md`；冲突编号 SPEC-CONFLICT-T-020-001。
- PARKED：v1 执行轮写 checkpoint（seq 1）后进 PARKED（reason=SPEC_CONFLICT），检查 1、2 已完成，交付被堵住。
- 评论：SPEC_CONFLICT 评论已由总控代发到 Issue #22（正文与本地备妥文本一字未改，含冲突编号、争议条款、阻塞影响与最小修正建议）。本节点自己的一次 add_issue_comment 尝试（2026-11-14 22:45:19 CST 发起的审批卡）未获批准、于 22:49:49 CST 超时未执行——没有重复发帖。
- 裁决：SPEC_DECISION 见检查 5；文件名定为 `results/node-3/T-020-autonomous-peer-proof.md`。
- 恢复：从 checkpoint seq 1 的 next_stage（stage-04-resume-after-decision）恢复，只重跑文件名核对：
- 任务书 v3“输出要求”（第 60 行）：`results/node-3/T-020-autonomous-peer-proof.md`
- 任务书 v3“验收标准”第 6 条（第 119 行）：`results/node-3/T-020-autonomous-peer-proof.md`
- 两处一致，冲突已消除（旧名仅剩版本历史与检查 3 的已裁决说明中提及，非现行要求）。

## 检查 4：账本一致性 — 通过

恢复轮对两份账本（checkpoint seq 1 的 side_effects 与 side-effects-ledger.jsonl）逐项核对：

| effect_id | 类型 | 状态（恢复后） | 依据 |
|---|---|---|---|
| effect-retry-001 | 本地副作用（检查 2） | confirmed | retry_count 1，目标文件实测 1 行，未重放 |
| effect-002 / effect-comment-001 | Issue #22 SPEC_CONFLICT 评论 | confirmed（由总控代发，正文与备妥文本一致） | 总控在主聊的确认＋裁决提交已入仓；本节点自己的同名尝试超时未批、未执行，无重复评论 |
| effect-001 | GitHub 推送本最终证据 | confirmed（本次推送） | 远端读回核验，SHA 记于 checkpoint seq 2 |
| effect-003 | Pachat 快通道完成通知 | confirmed（推送后向“总控与3号”发一次） | 见完成汇报 |

结论：checkpoint 与账本一致；全部已确认副作用均未被重放。

## 检查 5：决定／修订检测 — 通过

- 决定定位：远端提交 6b84410e5f4381c431440a372346afee2669bc70，标题“T-020 v3：SPEC_DECISION 裁决 SPEC-CONFLICT-T-020-001（证据文件名定为 T-020-autonomous-peer-proof.md）”，2026-11-14 22:51:45 +08，仅改任务书一个文件。
- 作者核验：提交作者为总控（署名，账号 xy3293），与主聊转达的总控裁决一致。
- 任务号／冲突号核验：T-020 ✓；SPEC-CONFLICT-T-020-001 ✓（与本节点冲突编号一致；v1 阶段证据中曾写作 T-020-SPEC-001，为同一冲突的简写）。
- 版本核验：裁决随任务书 v3 发布（v2 仅收紧期望完成时间，冲突仍在；v3 载入裁决）。checkpoint seq 1 的恢复验收文本预期“合同版本 v2”，实际裁决版本为 v3——以 v3 任务书检查 3 的明文为准恢复，此出入在此如实记录。
- 恢复范围：只重跑受影响的文件名核对，未重做检查 1、2。

## 检查 6：最终证据可定位 — 通过

- 文件路径：`results/node-3/T-020-autonomous-peer-proof.md`（裁决文件名，授权路径 results/node-3/ 内）。
- 推送方式：GitHub 工具层一次推送（R16），提交 SHA 与远端文件 blob 在推送后读回核验，结果记于 checkpoint seq 2 与完成汇报（本文件无法自引自身 commit SHA）。
- 无秘密进库：本文件只含任务事实与公开链接，不含任何凭据、私人信息。

## 事实与推断、未验证

- 事实：以上 PID、退出码、心跳与文件行数、SHA、提交与时间戳均来自实测或远端实读。
- 未验证：Issue #22 的评论列表未用 API 逐条读取（已审读只读工具集不含评论列表读取）；评论已发一事依据总控确认与裁决提交入仓两项相互印证的事实，评论正文与备妥文本的一致性依据总控“一字未改”的说明。
- 路径出入（沿 v1 阶段证据记录）：任务书“输入”称不要用 /home/hatch/...，checkpoint-spec §2 规定 checkpoint 位于 /home/hatch/hooks/state/，本节点 $HOME 实测为 /home/hatch，checkpoint 按 §2 落盘。

## 来源

- 任务书 v3：https://github.com/xy3293/muse-hub/blob/main/tasks/T-020-node3-autonomous-peer-proof.md
- 裁决提交：https://github.com/xy3293/muse-hub/commit/6b84410e5f4381c431440a372346afee2669bc70
- Issue #22：https://github.com/xy3293/muse-hub/issues/22
- 本地阶段证据与账本：~/hooks/state/task-runtime/tasks/T-020/（checkpoint seq 1、stage evidence、side-effects-ledger.jsonl），不进仓库。
