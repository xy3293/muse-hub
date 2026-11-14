# T-019 node-2 自治对等节点最小验证 — Stage A 进度报告

> 结论先行：Stage A 已完成。检查 1（重复唤醒去重）与检查 2（恰好一次重试）通过，有 PID／锁／心跳与账本证据；检查 3 的 SPEC_CONFLICT 已发到 Issue #21，节点已进 PARKED。总控已于本回合内发布 SPEC_DECISION（见下），裁决文件名；本回合到此收尾，恢复待下一次版本键唤醒（任务书 v2）从 checkpoint 继续，完成检查 4、5、6。
>
> 本文件为 Stage A 进度报告，文件名刻意区别于两个争议文件名，不预判裁决结果。最终证据文件待恢复后按裁决文件名另行推送。

- 任务：T-019 node-2 自治对等节点最小验证，任务书 v1
- 任务书：[tasks/T-019-node2-autonomous-peer-proof.md](https://github.com/xy3293/muse-hub/blob/main/tasks/T-019-node2-autonomous-peer-proof.md)
- Issue：[#21](https://github.com/xy3293/muse-hub/issues/21)
- 认领唤醒：`T-019@v1@c2c7936883e4319b0277037a27fc3e63072f6771`，HEAD `c2c7936883e4319b0277037a27fc3e63072f6771`
- run_id：`T-019-node-2-proof-1`
- 认领时间：2026-11-14 22:33 CST（14:33 UTC）
- 截止：2026-11-15 00:30 +08（v2 收紧，原 02:00）

## 检查 1：重复唤醒去重 — 通过

- 以 `run_id=T-019-node-2-proof-1` 拿本地独占锁，`setsid`＋`nohup` 启动后台心跳任务：PID 10793，`/proc` starttime 319077。
- 心跳文件 120 行，seq 1–120，全部为同一 PID 10793，时间 2026-11-14T14:33:18Z–14:35:18Z；任务结束后写者进程退出，锁释放。
- 任务在跑时，第二 shell 重走认领／对账步骤：`flock -n` 拿不到锁；对账发现记录的 PID 10793 存活且 starttime 319077 匹配，直接返回（退出码 0），未启动第二份执行、未产生第二份副作用。
- 运行中 `ps` 核查：心跳写者恰好 1 个。注：一次 `pgrep` 计数为 2 是测量 shell 自身命令行命中模式所致，干净的 `ps` 计数确认为 1。
- 本地 checkpoint：`attempt-0001/checkpoint/checkpoint-001.json`（seq 1）。

## 检查 2：恰好一次重试 — 通过

- 本地脚本模拟瞬时失败：marker 文件存在时第一次运行退出 1（`error_signature=transient-marker-present`，attempt 1）。
- 诊断：marker 为陈旧瞬时故障标志，清除后恰好重试一次，第二次运行成功（退出码 0）。
- 副作用（向本地文件追加一行）恰好出现一次：`effects.txt` 共 1 行。
- 账本里该错误签名只记一次重试：`ledger.jsonl` 中 `transient-marker-present` 出现 1 次。
- 本地 checkpoint：`attempt-0001/checkpoint/checkpoint-002.json`（seq 2）。

## 检查 3：SPEC_CONFLICT → PARKED — 已发帖，已挂起

- 冲突：任务书“输出要求”写最终证据文件为 `results/node-2/T-019-autonomous-peer-proof.md`，“验收标准”第 6 条写为 `results/node-2/T-019-peer-proof.md`，两处文件名不一致。节点按 R18 走 SPEC_CONFLICT 流程，未自行选一个、未猜。
- SPEC_CONFLICT 评论：[Issue #21 #issuecomment-6878902878](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878902878)，冲突编号 `SPEC-CONFLICT-T-019-001`，含争议条款、阻塞影响与最小修正建议（以“输出要求”的文件名为准，或由总控裁决任一文件名后升版）。
- 阻塞影响：最终证据交付被堵住，无法确定推送路径；检查 1、2 不依赖证据文件名，已完成，不受影响。
- 节点状态：已写 checkpoint（seq 3）后进 PARKED，保留任务所有权，不空转、不重试被堵操作、不另领任务，等总控 SPEC_DECISION。
- 本地 checkpoint：`attempt-0001/checkpoint/checkpoint-003.json`（seq 3）；PARKED 元数据记在本地 `task-state.json`（checkpoint-spec §12：PARKED 不进 checkpoint.json）。

## 认领后 ETA 快通道报告 — 已发一次

- Pachat “总控与2号”群发送一次 ETA 报告（消息 #7）：Stage A 本回合内完成；全部完成待总控裁决后恢复，截止 2026-11-15 02:00 +08；置信度 Stage A 高、整体中（取决于裁决时间）。

## 副作用账本（checkpoint-spec §6）

| effect_id | 类型 | 状态 | 目标／证据 |
|---|---|---|---|
| effect-001 | 本地心跳写入 | confirmed | 心跳文件 120 行，单 PID 10793 |
| effect-002 | 本地文件追加 | confirmed | `effects.txt` 恰好 1 行 |
| effect-003 | Pachat 发送 | confirmed | “总控与2号”群消息 #7 |
| effect-004 | GitHub Issue 评论 | confirmed | [#issuecomment-6878902878](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878902878) |
| effect-005 | GitHub 推送（本文件） | intent_recorded → 本推送确认后为 confirmed | `results/node-2/T-019-stage-a-progress.md` |

全部副作用先记账再执行；已确认的副作用未重放。

## 本地 checkpoint 与账本（未推送，仅引用）

- 本地持久目录：`~/hooks/state/task-runtime/tasks/T-019/`（checkpoint-spec §2 路径），`attempt-0001/checkpoint/checkpoint-001/002/003.json`，账本 `attempt-0001/ledger.jsonl`，心跳 `~/hooks/state/task-runtime/heartbeat/T-019/attempt-0001.jsonl`。
- 本地脚本与产物：`~/workspace/node-2-work/T-019/`（心跳、认领复核、重试模拟脚本及 checkpoint 生成脚本）。
- 说明：任务书“不要用 /home/hatch/…”是针对总控 VM 路径的提醒；本节点运行环境的 home 即为 /home/hatch，上述本地路径均为本节点自己的持久目录，本地验证脚本、心跳、checkpoint、账本均未推送进仓库，只推送本证据文件。
- 恢复说明（checkpoint-003 的 `next_stage` stage-04）：总控发布 SPEC_DECISION、任务书升版至 v2、BOARD 置回待领后，节点按标准版本键唤醒，从 checkpoint-003 恢复：核验决定作者（总控）与任务号／冲突号匹配、合同版本为 v2；只重跑受影响的检查（文件名核对）；按裁决文件名推送最终证据；不重做已完成阶段。

## 总控 SPEC_DECISION — 已发布（本回合内）

- 总控 SPEC_DECISION 评论：[Issue #21 #issuecomment-6878920410](https://github.com/xy3293/muse-hub/issues/21#issuecomment-6878920410)，2026-11-14 22:35:13 CST，作者总控；裁决证据文件名以“输出要求”为准，即 `results/node-2/T-019-autonomous-peer-proof.md`，“验收标准”第 6 条已同步改成本文件名。
- 任务书升版至 v2：提交 [14ef257](https://github.com/xy3293/muse-hub/commit/14ef25798b30f76ec273c04803ccc687ccb379a1)（2026-11-14 22:35:12 CST），版本行改为“版本：v2”，新增版本历史；期望完成时间 02:00→00:30 +08（Chen 要求收紧预期）。
- BOARD.md：T-019 仍为“待领”（该提交未改 BOARD.md，状态本身即为待领，满足“置回待领”的状态要求）。
- 本回合到此收尾：恢复按 R18／checkpoint-spec §12 走标准版本键唤醒（新版本＋派给 node-2＋待领＋该版本未见过），新 worker 从 checkpoint-003 恢复（generation 递增、新 attempt），只重跑文件名核对，不重做检查 1、2。本回合不提前在 v1 唤醒内做恢复，以保留检查 5 要求的“唤醒时的版本核对记录”证据。

## 待恢复后完成

## 事实与推断

- 事实：以上 PID、行数、退出码、评论链接、消息序号均为本次实测记录。
- 未验证：恢复后的检查 4、5、6（待版本键唤醒后验证）。
