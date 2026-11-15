# 任务书

## 任务信息

- **编号**：T-023
- **标题**：A/B 无人值守实测 tick：node-2 最小常规任务
- **负责人**：node-2
- **状态**：待领（由总控在 BOARD.md 登记）
- **Issue**：任务创建后填 Issue 链接
- **task_id**：T-023（与编号一致）
- **assigned_node**：node-2（与负责人一致）
- **execution_mode: AUTO_START**：Hook 唤醒即开工授权，完成第一项实质性工作后写 STARTED
- **deliverable_path**：`results/node-2/T-023-ab-tick.md`
- **acceptance_criteria**：填写下方验收标准中的可核验项目
- **requires_approval**：true（推送交付物到 results/node-2/ 时需审批；等待时写 WAITING_APPROVAL）
- **resume_policy**：沿用原 Task ID 和检查点；确认原执行已退出再恢复，不重复执行；仅实质性进展更新 last_progress_at

## 背景

A/B 无人值守实测第 1 段：把「派活 → 节点醒 → 干活 → 推送 → 总控扫到 → 批卡 → 验收」整条链跑一遍。本任务是最小常规任务，只做三行交付，不做其他事。

## 目标

一句话：交付三行文件，证明整条链路通。

## 输入

- R21 通信通道选择：汇报面是 Issue 评论 + git 推送，这是节点让总控“知道”的唯一途径，总控 Hook 每 60 秒扫 Issue `updated_at` 与提交；对话面是 chat 桥，只用于即时问答，不作为汇报通道，节点在 chat 里说的话不会唤醒任何人；chat 超时 ≠ 失败，超时只表示没等到回复，不代表没送到。
- 任务书：本文件。

## 输出要求

- 文件路径：`results/node-2/T-023-ab-tick.md`
- 内容正好三行：
1. 执行时的 UTC 时间（`date -u +%FT%TZ` 的实际输出）
2. `cat ~/.config/muse-hub/node-id` 的实际输出
3. 一句话：你（node-2）对 R21 的理解
- 只有这一个文件，一次推送，提交信息 `T-023 ab tick`
- 不许编数字，不许编来源；时间与节点标识写命令的实际输出。

## 验收标准

- [] 交付文件在约定路径，远程可读，正好三行。
- [] 第一行是 `date -u +%FT%TZ` 的真实输出格式，第二行是 `cat ~/.config/muse-hub/node-id` 的真实输出。
- [] 第三行是一句话，准确表达 R21（汇报走 Issue/git，chat 只对话、超时不等于失败）。

## 截止

- 无硬性截止。总控只观察：60 分钟内无动静记“未醒”，不重派，等下一个观察窗口。
