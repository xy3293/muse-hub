# T-012 Checkpoint 续跑验证 Stage B：新 worker 凭 checkpoint 续跑

## 任务信息

- **编号**：T-012
- **标题**：Checkpoint 续跑验证 Stage B：新 worker 凭 checkpoint 续跑
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/12
- **预估 worker 秒数**：300
- **单回合预算**：600
- **阶段**：Stage B（新 worker 读 Stage A checkpoint，验证 Stage 1 就绪并写新 checkpoint）
- **checkpoint**：Stage B 结束后按 `docs/checkpoint-spec.md` 写新 checkpoint（checkpoint_seq 2，attempt-0002，generation 2）
- **阶段产物路径**：`results/node-1/T-012-checkpoint-stage-b-resume.md`
- **续跑说明**：本任务是 Stage B；新 worker 仅凭 T-010 的 checkpoint 续跑，**不重新执行 Stage A 的 3 项远端事实核对**。Stage A 的 3 项事实以 checkpoint 为准。
- **外部副作用**：GitHub push（结果文件一次推送）
- **收尾开始时间**：450
- **发布与通知要求**：一次 shell 推送；成功不发 Issue 评论，交付靠推送

## 背景

T-010 Stage A 已完成并验收通过：3 项远端事实逐项实测全部一致，checkpoint 已按 `docs/checkpoint-spec.md` 写出（checkpoint_seq 1，attempt-0001，generation 1），并用全新进程重读验证通过。Stage A 的 checkpoint 明确指定 next_stage 为 stage-b：新 worker 仅凭本 checkpoint 续跑，不重新执行 Stage A 的核对，完成 v2 任务书规定的剩余工作并交付结果文件。

本任务是验证的第二半：一个全新的 worker 回合，**仅凭 T-010 的 checkpoint** 恢复上下文，完成一个明确的后续切片（验证 Stage 1 产出已就绪、可交 Codex 实现），并按规范写出新 checkpoint（seq 递增）。这验证的是人工续接和模板可用性，**不声称自动恢复已实现**。

同时，本任务在 Pachat × GitHub 试行（T0 2026-11-12）内派发：正式派发先走 GitHub，派发后总控在对应 Pachat 一对一群发一次 `[DISPATCH]` 通知。节点仍以本任务书为执行依据；群内通知不替代正式派发。

## 目标

一份 Stage B 结果：新 worker 仅凭 checkpoint 恢复，验证 Stage 1 产出（任务书模板 v2 字段、checkpoint 规范 v1）已就绪可交 Codex，并按规范写出新 checkpoint（seq 2）。供总控和 3 号复核：输入版本、续跑动作、输出和预算是否真实。

## 输入

- Stage A checkpoint（本地，节点本机）：`$HOME/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/checkpoint.json`
  - checkpoint_seq：1；attempt_id：attempt-0001；generation：1
  - checkpoint.json SHA-256：`86bf9a705f8fd9892d67731bf281e0328f2b4286a3d60aa50a6df7b15bf5933d`
  - 产物：`artifacts/stage-a-verification.md`，SHA-256：`a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577`
  - next_stage.stage_id：stage-b
- Stage A 结果文件（远端，含 checkpoint 脱敏副本）：`results/node-1/T-010-checkpoint-resume-validation.md`（交付提交 cad11968）
- Stage A 任务书：`tasks/T-010-checkpoint-resume-validation.md`（v1）
- 规范：`docs/checkpoint-spec.md`（v1）
- 任务书模板：`TASK_TEMPLATE.md`（Stage 1 已加 v2 字段）

## 输出要求

- 文件路径：`results/node-1/T-012-checkpoint-stage-b-resume.md`
- 格式：中文，结论先行；逐项贴实测命令与输出；区分事实与推断，不确定的写“未验证”。
- 按以下步骤执行（**不重新执行 Stage A 的 3 项远端事实核对**——那 3 项以 checkpoint 为准）：
  1. 读取本地 Stage A `checkpoint.json`，核对：可解析、checkpoint_seq 为 1、attempt_id 为 attempt-0001、generation 为 1、产物 `artifacts/stage-a-verification.md` 存在且 SHA-256 与 `a5021c4c…` 一致、next_stage.stage_id 为 stage-b。把核对命令与输出写进结果文件。
  2. 读取远端 T-010 结果文件中的 checkpoint 脱敏副本，核对与本地 checkpoint 一致（同 seq、同产物 SHA、同 next_stage）。不一致时如实写明，不得改写任一方。
  3. 验证 Stage 1 产出已就绪、可交 Codex（只核对存在性与版本，不重做 Stage A 的事实核对）：
     - `TASK_TEMPLATE.md` 在远端存在，且含 v2 的 9 个字段：`estimated_worker_seconds`、`time_budget_seconds`、`stages`、`checkpoint_after_each_stage`、`stage_output_paths`、`resume_instructions`、`external_side_effects`、`finalize_before_seconds`、`publish_and_notify_requirements`。逐项贴 grep/读取证据。
     - `docs/checkpoint-spec.md` 在远端存在，schema 版本为 1。
     - 记录当前远端 HEAD（只记录实际值，不预设期望值；若 HEAD 已前移，核对 T-010 交付提交仍在有效历史中）。
  4. 按 `docs/checkpoint-spec.md` 第 2–4 节写新 checkpoint：位置 `task-runtime/tasks/T-010/attempt-0002/checkpoint/`（`$HOME/hooks/state/` 下），checkpoint_seq 2、attempt-0002、generation 2，completed_stages 含 stage-b（本任务的验证工作与产物），next_stage 指向 Codex 实现（Stage 2）的输入与验收，副作用账本含本次推送（先记 intent_recorded，推送后核验远端再记 confirmed）；产物先写临时文件、校验、原子 rename。
  5. 写完新 checkpoint 后，用全新 shell／进程重读一次，核对 checkpoint 可解析、引用产物存在且 SHA-256 匹配，把重读验证结果写进结果文件。
- 结果文件须含新 checkpoint 完整内容（脱敏副本）、新 checkpoint 路径、checkpoint_seq、产物 SHA-256、重读验证结果、远端 HEAD 实际值。
- 不许编数字，不许编来源。不得把 token、密钥、电话、地址等秘密写进结果文件、checkpoint 或 Issue。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写、尽早推送；只做 Stage B 定义的切片，**不得擅自扩大范围或做 Codex 的实现工作**。
- 交付走正常路径：写结果文件、一次 shell 推送；成功不发 Issue 评论，交付靠推送；遇阻塞才在 Issue 说明。

## 验收标准

- 本地 Stage A checkpoint 已读并核对：可解析、seq 1、attempt-0001、generation 1、产物存在且 SHA-256 匹配、next_stage 为 stage-b，逐项有实测命令与输出。
- 远端 T-010 结果文件中的 checkpoint 脱敏副本与本地 checkpoint 一致（不一致时如实写明）。
- **Stage A 的 3 项远端事实核对未被重新执行**（结果文件不得出现对该 3 项的重复核对命令与输出；Stage B 只核对 checkpoint 本身与 Stage 1 产出）。
- TASK_TEMPLATE.md 的 9 个 v2 字段逐项有 grep/读取证据；docs/checkpoint-spec.md 存在且 schema 版本为 1；远端 HEAD 实际值已记录。
- 新 checkpoint 符合 `docs/checkpoint-spec.md`：schema 可解析、checkpoint_seq 2、attempt-0002、generation 2、产物存在且 SHA-256 匹配、next_stage 可让后续 worker 独立继续。
- 重读验证已做并记录在结果文件里。
- 结果文件含新 checkpoint 脱敏副本，无秘密、无编造数字、无编造来源。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。验收后总控另行安排 3 号复核输入版本、续跑动作、输出和预算（不把 A 当 B）。

## 截止

- 无硬性截止；期望 1 天内交付。遇阻塞直接在 Issue 说明，不要静默等待。
