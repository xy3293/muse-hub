# T-010 Checkpoint 续跑验证 Stage A：写 checkpoint（小型）

## 任务信息

- **编号**：T-010
- **标题**：Checkpoint 续跑验证 Stage A：写 checkpoint（小型）
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/10
- **预估 worker 秒数**：300
- **单回合预算**：600
- **阶段**：Stage A（核对 3 项远端事实并写 checkpoint）
- **checkpoint**：Stage A 结束后按 `docs/checkpoint-spec.md` 写 checkpoint
- **阶段产物路径**：`results/node-1/T-010-checkpoint-resume-validation.md`
- **续跑说明**：本任务只做 Stage A；Stage B 由总控随后以 v2 派发，新 worker 仅凭本任务的 checkpoint 续跑
- **外部副作用**：GitHub push（结果文件一次推送）
- **收尾开始时间**：450
- **发布与通知要求**：一次 shell 推送；成功不发 Issue 评论，交付靠推送

## 背景

Stage 1 任务书模板与 checkpoint 规范已定（`TASK_TEMPLATE.md`、`docs/checkpoint-spec.md`，与本任务同批推送）。v2 要求先用小型真实任务验证 checkpoint 可由新 worker 读取，再让 Codex 按规范实现。本任务是验证的第一半：只做 Stage A，写出合规 checkpoint；Stage B 随后以 v2 派发。

## 目标

一份 Stage A 结果：3 项远端事实核对无误，一份按规范写的有效 checkpoint，及一份 checkpoint 重读验证记录。供 Stage B 的新 worker 仅凭 checkpoint 续跑。

## 输入

- 仓库远端 main 版：`BOARD.md`、`docs/checkpoint-spec.md`（本任务同批推送，先读规范再动手）
- 待核对的 3 项远端事实（期望值由总控给出，逐项实测核对）：
  1. `BOARD.md` 远端 T-009 行状态，期望：完成
  2. `hooks/patrol.sh` 远端 SHA-256，期望：`f5795685b88e44f06fe806e94c0192a2598b978830ec8052d78edc8cfb2245a3`
  3. `results/node-1/T-009-v2-stage0-db-patrol-probe.md` 远端 blob SHA，期望：`40bfd7b607b8795b08f921788d26e19677bc53b9`

## 输出要求

- 文件路径：`results/node-1/T-010-checkpoint-resume-validation.md`
- 格式：中文，结论先行；3 项核对逐项贴实测命令与输出；区分事实与推断，不确定的写“未验证”。
- 按 `docs/checkpoint-spec.md` 第 2–4 节写 checkpoint：位置 `task-runtime/tasks/T-010/attempt-0001/checkpoint/`（`$HOME/hooks/state/` 下），含已完成阶段、产物路径及 SHA-256、`next_stage`（Stage B 的目标／输入／验收）、副作用账本；`checkpoint_seq` 从 1 起；产物先写临时文件、校验、原子 rename。
- 写完 checkpoint 后，用全新 shell／进程重读一次，核对 checkpoint 可解析、引用产物存在且 SHA-256 匹配，把重读验证结果写进结果文件。
- 结果文件须含 checkpoint 完整内容（脱敏副本）、checkpoint 路径、`checkpoint_seq`、产物 SHA-256、重读验证结果。
- 不许编数字，不许编来源。不得把 token、密钥、电话、地址等秘密写进结果文件、checkpoint 或 Issue。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写、尽早推送；只做 Stage A，**不得擅自做 Stage B**。
- 交付走正常路径：写结果文件、一次 shell 推送；成功不发 Issue 评论，交付靠推送；遇阻塞才在 Issue 说明。

## 验收标准

- 3 项远端事实逐项有实测命令与输出，与期望值一致（不一致时如实写明，不得改写期望值）。
- checkpoint 符合 `docs/checkpoint-spec.md`：schema 可解析、任务版本匹配、产物存在且 SHA-256 匹配、`next_stage` 可让新 worker 独立继续。
- 重读验证已做并记录在结果文件里。
- 结果文件含 checkpoint 脱敏副本，无秘密、无编造数字、无编造来源。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止；期望 1 天内交付。遇阻塞直接在 Issue 说明，不要静默等待。
