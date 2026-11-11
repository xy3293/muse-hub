# T-008 工人丢失修复 Stage 0：运行时能力探测报告

- **编号**：T-008
- **负责人**：node-1
- **探测日期**：2026-11-12（CST；以下 UTC 时间已换算标注）
- **输入版本**：patrol.sh 生产版 v2026-11-11.3，SHA-256 `f5795685b88e44f06fe806e94c0192a2598b978830ec8052d78edc8cfb2245a3`；轮询 300 秒；BOARD 远端 HEAD `7f6fc99a12a0102211f1831a1e306551ff72098a`
- **探测方式**：只读探测 + 最小实测；未修改生产 patrol.sh，未新增定时任务／Hook，未修改 BOARD.md／RULES.md／任务书／任何结果文件；探测产生的临时文件已全部删除

## 结论先行

7 项探测全部完成：**已验证 4 项，部分验证 2 项，未知 0 项，不支持 0 项**。但本次探测纠正了一个关键前提——**T-004／T-006 的工人并非“没启动”，而是启动后在 600 秒时限内未完成 execute 回合，被运行时以 `worker_timeout` 终结**。证据见探测 3、7。自动重唤的前提能力大体具备，但修复方向应从“确认工人启动”改为“600 秒时限内的完成保障（拆分任务／断点续跑／延长时限）+ 超时后的可恢复重唤”，否则只补启动确认仍会在 600 秒处丢失工人。

> 备注：任务书“输出要求”写“在 Issue 留言”，与 Hook 指令及当前流程（成功不发评论、交付靠推送）冲突，本次按 Hook 指令执行：不发 Issue 评论，交付靠推送。

## 能力矩阵

| # | 探测项 | 结论 | 一句话证据 |
|---|---|---|---|
| 1 | worker 与 Hook 共享持久化目录 | 已验证 | worker 在 `/home/hatch/hooks/state/` 写测试文件并读回成功（2026-11-11 22:05:40Z） |
| 2 | wake 请求／响应语义 | 已验证 | `wake()` 只打印 `HATCH_HOOK_RESULT` 并 `exit 0`；脚本侧收不到任何返回体，无法区分 accepted／queued／started |
| 3 | invocation 是否可查询 | 部分验证 | 无专用查询接口／CLI；但 `muse.db` 的 `runtime.execute_resolve_runs` 可查到 `bb3e8bff` 整行记录；Hook 日志只有唤醒记录，无工人命运 |
| 4 | worker 启动第一步调用 claim helper | 已验证 | 实测脚本原子认领：第一次 `CLAIM_WON`，第二次 `CLAIM_LOST`，`claim.json` 写入成功 |
| 5 | 可靠的锁／原子 rename | 已验证 | 10 路并行 `mkdir` 抢锁仅 1 胜；`flock -n` 持有时阻塞、释放后成功；`mv` 原子改名内容完整、临时文件消失 |
| 6 | worker 可持续心跳 | 部分验证 | 独立后台进程在 worker 前台阻塞 20 秒期间写了 4 次心跳（每 5 秒）；工人自身在模型／工具调用阻塞时无法写心跳；5 分钟间隔未按全尺寸实测 |
| 7 | 主聊接收子任务结果的交接机制 | 已验证 | 交接靠 `notify_main_agent`，成功时 `handoff_message_id` 落库；T-005 成功、T-004／T-006 均为 `worker_timeout` 且无 handoff；磁盘上无工人结果收据 |

## 逐项证据

### 1. worker 与 Hook 是否共享持久化目录 — 已验证

- Hook 状态目录：`$HOME/hooks/state`（patrol.sh L25），其中 `muse-hub-seen-tasks`、`muse-hub-last-head`、`pending/`、`muse-hub.patrol.lock`。
- 实测（2026-11-11 22:05:40Z，worker 环境，`HOME=/home/hatch`）：
  - 写入 `$HOME/hooks/state/T-008-probe-shared.tmp`，立即读回成功：`P1_READBACK_OK path=/home/hatch/hooks/state/T-008-probe-shared.tmp`。
  - 测试后删除，复查 `ls ~/hooks/state/ | grep T-008-probe` 无残留：`CLEANUP_OK`。
- 限制：`HATCH_HOOK_STATE_DIR` 与 `HATCH_HOOK_ID` 在 worker 环境中**未设置**（`<unset>`），因此运行时提供的 `hook_state_get`／`hook_state_set` 辅助函数在 worker 内无法直接使用；共享只能走原始文件系统路径 `~/hooks/state/`。这不影响共享本身，但 Codex 写代码时不能假定这两个环境变量存在。
- 结论：同一 `$HOME`、同一文件系统，读写共享成立。

### 2. wake 请求／响应语义 — 已验证

- 来源：`~/hooks/runtime/hatch_hook_runtime.sh`（运行时提供，patrol.sh L20 `source "$HATCH_HOOK_RUNTIME"` 引入）：
  - `wake()` → `_hatch_hook_emit "wake" …` → 只做 `printf 'HATCH_HOOK_RESULT:%s\n' "$result"`，随后 `exit 0`。
  - 打印的 JSON 只有 `decision`、`reason`、`payload`（及可选 `disable_after_run`），**不含 invocation ID、job ID 或任何状态字段**。
  - patrol.sh 以 `(wake …)` 子 shell 的退出码判断成功（L211、L360）：`exit 0` 即视为成功，随后删除 pending（L360-361）。
- 实测佐证：`~/hooks/logs/muse-hub-patrol.jsonl` 中 7 条 `outcome:"wake"` 记录的 `invocation_id`（UUID，如 `bb3e8bff-25a7-473e-aae6-ee9dfda188f6`）与 `execute_resolve_run_id` 均为**运行时在日志里事后补记**的，脚本在调用时拿不到。
- 结论：wake 是单向 fire-and-forget。脚本侧无法区分 accepted／queued／started；“唤醒返回成功”只证明决策 JSON 已打印，不证明工人已启动。GPT v1 方案若依赖 wake 返回值做状态机推进，在此运行时上不可行。

### 3. invocation 是否可查询 — 部分验证

- 专用查询接口／CLI：**未找到**。`/opt/hatch/bin/` 中无 hook／invocation／event 查询类 CLI（`hatch`、`hatch-doctor` 等均无此用途）；未尝试调用 `HATCH_API_SOCKET`（超出只读探测范围，结果未知）。
- 但存在两条可读记录，均用 `bb3e8bff` 实测：
  1. **Hook 日志** `~/hooks/logs/muse-hub-patrol.jsonl` L444：`invocation_id: bb3e8bff-25a7-473e-aae6-ee9dfda188f6`，`started_at_ms: 1794429539209`，`finished_at_ms: 1794429541288`，`duration_ms: 2019`，`outcome: wake`，`reason: new-task-assigned`，`execute_resolve_run_id: event-hook:bb3e8bff-25a7-473e-aae6-ee9dfda188f6`。只记录巡逻脚本的唤醒决策，**无工人是否启动、是否完成的信息**。
  2. **`muse.db` 只读查询** `runtime.execute_resolve_runs`（`run_id = 'event-hook:bb3e8bff-…'`），2026-11-12 实测返回整行：
     - `status: failed`，`last_error_stage: worker_timeout`，`last_error_message: "timed out waiting for execute-resolve turn completion"`；
     - `created_at: 2026-11-11T20:39:01.275212+00:00`，`updated_at: 2026-11-11T20:49:01.31175+00:00`（**恰好 +600 秒**）；
     - `worker_started_at: 2026-11-11T20:39:01.290695+00:00`，`worker_agent_id: 9900f6d1-bb9b-460f-9dd6-d1f7e1695090`，`worker_phase: execute`，`worker_generation: 1`，`handoff_message_id: null`，`terminal_decision: null`。
- 对照 T-004（`1a9ecdab`）：同样 `failed`／`worker_timeout`／同一错误信息，`created 2026-11-10T18:44:04Z` → `updated 18:54:04Z`（恰好 +600 秒），`worker_started_at` 与 `worker_agent_id` 均存在。
- 对照 T-005（`73c9e37e`，成功）：`status: completed_notified`，`terminal_decision: notify_main_agent`，`handoff_message_id: execute-resolve:event-hook:73c9e37e-…:handoff`，`created 2026-11-11T13:23:12Z` → `updated 13:29:26Z`（约 6 分 14 秒，在 600 秒内完成）。
- 结论：invocation **可通过 muse.db 查到状态**，但没有面向脚本的专用查询接口；Codex 若要在 patrol.sh 里查状态，只能走数据库（需确认 patrol 运行环境有无该查询通道）或解析 Hook 日志（日志只有唤醒决策，不够用）。本项因此定为部分验证。
- **推断（非事实）**：600 秒整的超时边界强烈提示运行时对 execute 回合有 600 秒硬时限；T-004／T-006 的工人均已启动、均在此时限内未完成。旧结论“工人没出现”应修正为“工人启动后超时丢失”。

### 4. worker 能否在启动第一步调用 claim helper — 已验证

- 实测脚本（`/tmp/t008-claim.sh`，2026-11-11 22:05:40Z，认领目录 `$HOME/hooks/state/T-008-probe-claims`，`mkdir` 原子认领 + 写 `claim.json`）：
  - 第一次执行：`CLAIM_WON`；
  - 第二次执行（同一目录）：`CLAIM_LOST`；
  - `claim.json` 内容：`{"task":"T-008","owner":"T-008-worker","claimed_at":"2026-11-11T22:05:40Z"}`。
  - 测试后删除认领目录与脚本，无残留。
- 结论：worker 启动后第一条指令即可执行本地脚本并完成一次原子写；原子认领机制在 worker 环境成立。`mkdir` 认领与 patrol.sh 已有用法一致（pending 发布用 `ln` 硬链接，L332；锁用 `flock`，L46）。

### 5. 可靠的锁／原子 rename — 已验证

实测（2026-11-11 22:05:40Z 左右，`/tmp/t008-locktest/`，测试后删除）：

- `mkdir` 抢锁：10 个并行进程同时 `mkdir lock`，胜者恰好 1 个（`MKDIR_WINNERS=1`，`win 1`）。
- `flock`：`flock -n flockfile sleep 5` 持有期间，第二次 `flock -n` 被阻塞（`FLOCK_SECOND_BLOCKED_OK`）；释放后再次加锁成功（`FLOCK_AFTER_RELEASE_OK`）。`flock` 二进制存在（`/usr/bin/flock`），patrol.sh 自身也在用（L46）。
- 原子 rename：`printf … > data.tmp; mv data.tmp data.final`，`data.final` 内容完整（`atomic-content-12345`），`data.tmp` 已消失（`RENAME_TMP_GONE_OK`）。
- 结论：`mkdir`、`flock`、原子 `rename`（`mv`）在 worker 运行环境均可靠，可用于 claim helper 与状态机写。

### 6. worker 是否可持续心跳 — 部分验证

- 实测（2026-11-11 22:05:45Z–22:06:00Z，缩放测试：间隔 5 秒而非 5 分钟，阻塞 20 秒而非长任务）：
  - 独立后台循环每 5 秒向 `/tmp/t008-hb.log` 写一行时间戳；随后前台执行 `sleep 20`（模拟 worker 被阻塞）；
  - 阻塞期间心跳文件新增 4 行：`22:05:45Z`、`22:05:50Z`、`22:05:55Z`、`22:06:00Z`（`HB_LINES_DURING_BLOCK=4`），循环随后被杀死，文件删除。
- 结论：**只有脱离 worker 前台的独立后台进程能持续心跳**；worker 自身在一次模型／工具调用阻塞期间无法写心跳。5 分钟间隔、长任务全程的心跳未按全尺寸实测，故定为部分验证。设计含义：心跳必须是 worker 启动时派生的后台写进程（或外部看门狗），不能依赖 worker 主循环自己写。

### 7. 主聊接收子任务结果的交接机制 — 已验证

- 机制（事实）：worker 结束时调用 `notify_main_agent`（本 worker 的 resolve 阶段即如此），运行时在 `runtime.execute_resolve_runs` 中记录 `terminal_decision` 与 `handoff_message_id`，主聊收到隐藏 handoff 后继续处理。
- 对照（2026-11-12 查询）：
  - T-005 成功：`completed_notified`，`terminal_decision: notify_main_agent`，`handoff_message_id` 存在；结果文件随后由 shell 推送交付（commit `cd7823e`）。
  - T-004 丢失：`failed`／`worker_timeout`，`handoff_message_id: null`，`terminal_decision: null`。
  - T-006 丢失：同上（见探测 3）。
  - T-008 本次：查询时 `status: pending`，`phase: execute`，`worker_started_at: 2026-11-11T21:59:04Z`（即本次运行）。
- 返回失败时有无可恢复记录：**磁盘上没有**。`~/hooks/state/` 只有 seen／HEAD／pending（本次为空）／锁文件，无工人结果收据；Hook 日志只记录唤醒决策。可恢复的记录只有两处：① `muse.db` 中的 run 行（状态、超时阶段、worker_agent_id）；② 已推送到远端的结果文件（若 worker 在超时前已推送）。工人超时后，其未推送的工作成果无法从节点侧找回，只能重做或由人工接手——与 T-004／T-006 当时的实际经过一致。
- 结论：交接机制本身存在且 T-005 已验证可用；丢失发生在交接之前（execute 回合 600 秒超时），不是交接环节丢失。

## 附录：同一时段的额度、并发限制、运行时错误可观测性

- **可观测到的运行时错误（事实）**：本次 T-008 派发轮次中，巡逻脚本取 T-006 任务书时命中 GitHub Contents API 未认证限额：`~/hooks/state/logs/api-diagnostics.jsonl` 记录 `http_status: 403`，`rate_limit_remaining: 0`，`rate_limit_reset: 1794434677`（即 2026-11-12 06:04:37 CST），`error_category: rate_limited`，`url_path: /repos/xy3293/muse-hub/contents/tasks/T-006-control-tower-data-survey.md?ref=7f6fc99a…`，`timestamp: 2026-11-11T21:59:03Z`。该轮 `retry_tasks=true`，按 patrol.sh L343-345 HEAD 文件未更新（仍为 `b8d4981892463310c30d10b409d6279d41ddf520`），下轮巡逻会重试。另：T-008 本轮唤醒耗时 5282ms，明显高于平时约 900–2000ms，与该次限额失败同轮出现（相关性，非因果证明）。
- **可观测到的限制（事实）**：巡逻轮询 300 秒（`poll_interval_secs`）；Hook 定义 `script_timeout_secs: 600`；execute 回合超时 600 秒（探测 3 的两例均为恰好 +600 秒）；巡逻脚本内 `flock -n` 非阻塞锁，锁陈旧超 600 秒才可接管（patrol.sh L47-66）。
- **未知**：模型调用额度／并发 worker 上限／同一时段多任务并发行为，在节点侧无可观测接口，均记为**未知**，不得默认为无限制。
- **BOARD 滞后（事实）**：BOARD 仍将 T-006、T-007 标为“待领”，而 T-006 已交付（commit `b8d4981`）、T-007 已由 node-3 交付；这是巡逻每轮仍尝试取 T-006 任务书、进而撞上限额的直接原因。

## 给总控与 Codex 的建议（推断，非探测结论）

1. 自动重唤的前提能力基本具备（共享目录、原子认领、锁、心跳后台进程均已验证），可以上；但**只补“启动确认”不够**，必须同时处理 600 秒 execute 超时：任务拆分、断点续跑、或申请延长时限，否则重唤的工人仍会在 600 秒处丢失。
2. 状态机设计应以 `muse.db` 的 run 行为准（`worker_started_at` 证明已启动；`worker_timeout` + 恰好 +600 秒证明超时终结），不要以 Hook 日志的 `outcome: wake` 作为工人启动证据。
3. 认领与心跳建议落在 `~/hooks/state/` 下的独立子目录（如 `claims/`、`heartbeats/`），与 seen／HEAD／pending 文件隔离；心跳用独立后台进程写，worker 主循环不写心跳。
4. GitHub API 未认证限额（60 次／小时）已在单轮多任务取书时撞上限；巡逻取任务书应考虑缓存或认证，否则 BOARD 滞后行越多，限额撞得越勤。

## 事实与推断的区分

- 事实：以上所有带命令、路径、时间戳、日志摘录的陈述。
- 推断：600 秒为运行时硬时限（两例均为恰好 +600 秒，但未见运行时文档明文）；T-008 轮次耗时 5282ms 与限额失败的关系仅为同轮相关；第 4 条建议中的限额缓解方案未经测试。
- 未验证：专用 invocation 查询接口（只查到 DB 行与日志，无 CLI／API）；5 分钟全尺寸心跳；模型额度与并发上限。

## 交付

- 结果文件：`results/node-1/T-008-worker-loss-stage0-capability-probe.md`（本文件），一次 shell 推送交付；成功不发 Issue 评论（按 Hook 指令）。
- 探测临时文件（`~/hooks/state/T-008-probe-shared.tmp`、`~/hooks/state/T-008-probe-claims/`、`/tmp/t008-*`）已全部删除并复查无残留。
