# T-019 node-2 自治对等节点最小验证 — 最终证据

> 结论先行：6 项检查全部通过。检查 1（重复唤醒去重）与检查 2（恰好一次重试）在 Stage A 通过；检查 3（SPEC_CONFLICT→PARKED→恢复）已走完：冲突已发、已挂起、总控已裁决、节点按版本键唤醒从 checkpoint 恢复，只重跑了文件名核对；检查 4（账本一致性）与检查 5（决定／版本检测）在恢复回合验证通过；检查 6（最终证据可定位）即本文件，已按裁决文件名推送到授权路径。验收待总控确认，节点不宣布验收通过。

- 任务：T-019 node-2 自治对等节点最小验证
- 任务书：[tasks/T-019-node2-autonomous-peer-proof.md](https://github.com/xy3293/muse-hub/blob/main/tasks/T-019-node2-autonomous-peer-proof.md)（v2，提交 [14ef257](https://github.com/xy3293/muse-hub/commit/14ef25798b30f76ec273c04803ccc687ccb379a1)）
- Issue：[#21](https://github.com/xy3293/muse-hub/issues/21)
- run_id：`T-019-node-2-proof-1`
- Stage A 唤醒：`T-019@v1@c2c7936883e4319b0277037a27fc3e63072f6771`，2026-11-14 22:33 CST；Stage A 进度报告 [results/node-2/T-019-stage-a-progress.md](https://github.com/xy3293/muse-hub/blob/main/results/node-2/T-019-stage-a-progress.md)（提交 9589e09）
- 恢复唤醒：`T-019@v2@14ef25798b30f76ec273c04803ccc687ccb379a1`，2026-11-14 22:39 CST
- 截止：2026-11-15 00:30 +08
- 依据：RULES.md R18、`docs/checkpoint-spec.md`（含 §12）

## 检查 1：重复唤醒去重 — 通过（Stage A）

- 以 `run_id=T-019-node-2-proof-1` 拿本地独占锁，`setsid`＋`nohup` 启动后台心跳任务：PID 10793，`/proc` starttime 319077。
- 心跳文件 120 行，seq 1–120，全部为同一 PID 10793，时间 2026-11-14T14:33:18Z–14:35:18Z；任务结束后写者进程退出，锁释放。
- 任务在跑时，第二 shell 重走认领／对账步骤：`flock -n` 拿不到锁；对账发现记录的 PID 10793 存活且 starttime 319077 匹配，直接返回（退出码 0），未启动第二份执行、未产生第二份副作用。
- 运行中 `ps` 核查：心跳写者恰好 1 个（一次 `pgrep` 计数为 2 是测量 shell 自身命令行命中模式所致，干净的 `ps` 计数确认为 1）。
- 本地 checkpoint：`attempt-0001/checkpoint/checkpoint-001.json`（seq 1）。

## 检查 2：恰好一次重试 — 通过（Stage A）

- 本地脚本模拟瞬时失败：marker 文件存在时第一次运行退出 1（`error_signature=transient-marker-present`，attempt 1）。
- 诊断：marker 为陈旧瞬时故障标志，清除后恰好重试一次，第二次运行成功（退出码 0）。
- 副作用（向本地文件追加一行）恰好出现一次：`effects.txt` 共 1 行。
- 账本里该错误签名只记一次重试：`ledger.jsonl` 中 `transient-marker-present` 出现 1 次。
- 本地 checkpoint：`attempt-0001/checkpoint/checkpoint-002.json`（seq 2）。

## 检查 3：SPEC_CONFLICT→PARKED→恢复 — 通过

- 冲突：任务书 v1“输出要求”写最终证据文件为 `results/node-2/T-019-autonomous-peer-proof.md`，“验收标准”第 6 条写为 `results/node-2/T-019-peer-proof.md`，两处文件名不一致。节点按 R18 走 SPEC_CONFLICT 流程，未自行选一个、未猜。
- SPEC_CONFLICT 评论：[Issue #21 #issuecomment-6878902878](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878902878)，2026-11-14 22:34:01 CST，冲突编号 `SPEC-CONFLICT-T-019-001`，含争议条款、阻塞影响与最小修正建议（以“输出要求”的文件名为准，或由总控裁决任一文件名后升版）。
- 阻塞影响：最终证据交付被堵住，无法确定推送路径；检查 1、2 不依赖证据文件名，已完成，不受影响。
- PARKED：写 checkpoint（seq 3）后进 PARKED，保留任务所有权，不空转、不重试被堵操作、不另领任务，等总控 SPEC_DECISION。
- 总控 SPEC_DECISION 评论：[Issue #21 #issuecomment-6878920410](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878920410)，2026-11-14 22:35:13 CST；裁决证据文件名以“输出要求”为准，即 `results/node-2/T-019-autonomous-peer-proof.md`，“验收标准”第 6 条已同步改成本文件名；任务书升版至 v2（提交 [14ef257](https://github.com/xy3293/muse-hub/commit/14ef25798b30f76ec273c04803ccc687ccb379a1)）；只重跑文件名核对，不重做检查 1、2；从 checkpoint 恢复，无需重新派发。
- 恢复：节点按标准版本键唤醒（新版本＋派给 node-2＋待领＋该版本未见过），从 checkpoint-004 恢复（attempt-0002，generation 2），只重跑了文件名核对，未重做检查 1、2。
- 本地 checkpoint：`attempt-0001/checkpoint/checkpoint-003.json`（seq 3，PARKED）、`checkpoint-004.json`（seq 4，Stage A 交付记录）。

## 检查 4：账本一致性 — 通过（恢复回合复核）

- attempt-0001 账本 `ledger.jsonl` 共 10 条：effect-001～effect-005 各恰好一次 `intent_recorded`＋一次 `confirmed`，无重复、无缺失、无重放。
- checkpoint-004 的副作用表与账本已确认集合一致。
- 已确认的副作用未被重放：心跳文件复核时仍为 120 行，`effects.txt` 复核时仍为 1 行；effect-004 评论远端仍在（6878902878，2026-11-14T14:34:01Z）；effect-005 提交 9589e09 复核时仍为远端 main HEAD。
- 本地 checkpoint：`attempt-0002/checkpoint/checkpoint-005.json`（seq 5）；复核记录见本地 `attempt-0002/checkpoint/artifacts/check4-ledger-check.txt`。

## 检查 5：决定／版本检测 — 通过（恢复回合）

- 唤醒版本核对：唤醒事件 `T-019@v2@14ef25798b30f76ec273c04803ccc687ccb379a1`；任务书版本行“版本：v2”（第 11 行）；v2 提交 14ef257 与唤醒 head_sha 一致；BOARD.md 中 T-019 为 node-2、待领、任务书路径与 Issue #21 均匹配。
- 决定核验：SPEC_DECISION 评论 [6878920410](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878920410)，作者账号 xy3293（OWNER），正文以“SPEC_DECISION：T-019 / SPEC-CONFLICT-T-019-001”开头、署名“— 总控”；任务号 T-019 与冲突号 SPEC-CONFLICT-T-019-001 均匹配；合同版本 v2 与唤醒版本键一致。
- 说明：node-2 的 gh 登录账号与总控同为 xy3293，仅凭 GitHub 账号无法区分作者；本次核验以评论的“”前缀、“— 总控”署名、裁决内容及配套的 v2 提交 14ef257 为依据。
- 只重跑了受影响的检查：文件名核对（任务书 v2 第 59 行“输出要求”与第 118 行验收第 6 条一致，均为 `results/node-2/T-019-autonomous-peer-proof.md`；第 82 行出现的旧文件名是 v1 冲突的历史记录，已标，不是现行要求）。检查 1、2 未重做。
- 本地 checkpoint：`attempt-0002/checkpoint/checkpoint-005.json`（seq 5）；核对记录见本地 `attempt-0002/checkpoint/artifacts/check5-decision-check.txt`。

## 检查 6：最终证据可定位 — 通过（本文件）

- 文件路径：`results/node-2/T-019-autonomous-peer-proof.md`（授权路径，任务书 v2“输出要求”与验收第 6 条一致）。
- 推送 commit：消息 `T-019: final evidence — autonomous peer proof (checks 1-6)`；SHA 记录于本地 checkpoint-006 与 Pachat 完成通知，可通过 `git log -- results/node-2/T-019-autonomous-peer-proof.md` 或远端 HEAD 独立定位。
- 本文件推送前经核对：无秘密、无账号、无密钥进库；只含本任务的公开验证证据与链接。
- 本地 checkpoint：`attempt-0002/checkpoint/checkpoint-006.json`（seq 6，推送确认后写）。

## 副作用账本（checkpoint-spec §6）

| effect_id | 类型 | 状态 | 目标／证据 |
|---|---|---|---|
| effect-001 | 本地心跳写入 | confirmed | 心跳文件 120 行，单 PID 10793 |
| effect-002 | 本地文件追加 | confirmed | `effects.txt` 恰好 1 行 |
| effect-003 | Pachat 发送 | confirmed | “总控与2号”群消息 #7（ETA 报告一次） |
| effect-004 | GitHub Issue 评论 | confirmed | [#issuecomment-6878902878](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878902878) |
| effect-005 | GitHub 推送 | confirmed | `results/node-2/T-019-stage-a-progress.md`，提交 9589e09 |
| effect-006 | GitHub 推送 | 本推送确认后为 confirmed | `results/node-2/T-019-autonomous-peer-proof.md`（本文件） |
| effect-007 | Pachat 发送 | 推送后发送，确认后为 confirmed | “总控与2号”群完成通知一次 |

全部副作用先记账再执行；已确认的副作用未重放。effect-006／007 的确认记录在本地 checkpoint-006 与 Pachat 完成通知中。

## 认领后 ETA 快通道报告与完成通知

- Stage A 已按 R18 经快通道（Pachat“总控与2号”群）报过一次 ETA 范围（消息 #7）。
- 恢复回合：本文件推送后经同一快通道报完成一次（effect-007），只报状态变化与结果链接，不重复搬日志；不发“已领／已完成”Issue 评论。

## 本地 checkpoint 与账本（未推送，仅引用）

- 本地持久目录：`~/hooks/state/task-runtime/tasks/T-019/`，attempt-0001（checkpoint-001～004，账本 `ledger.jsonl`）与 attempt-0002（checkpoint-005～006，账本 `ledger.jsonl`）；心跳 `~/hooks/state/task-runtime/heartbeat/T-019/attempt-0001.jsonl`。
- 本地脚本与产物：`~/workspace/node-2-work/T-019/`（心跳、认领复核、重试模拟脚本及 checkpoint 生成脚本）。
- 说明：任务书“不要用 /home/hatch/…”是针对总控 VM 路径的提醒；本节点运行环境的 home 即为 /home/hatch，上述本地路径均为本节点自己的持久目录，本地验证脚本、心跳、checkpoint、账本均未推送进仓库，只推送本证据文件与 Stage A 进度报告。

## 事实与推断

- 事实：以上 PID、行数、退出码、评论链接、消息序号、提交 SHA 均为本次实测记录；核对时间均为 2026-11-14 22:33–22:45 CST（14:33–14:45 UTC）。
- 未验证：总控对本证据的正式验收（待总控在 GitHub 确认）；节点不宣布验收通过。
