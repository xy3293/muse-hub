# 任务书

## 任务信息

- **编号**：T-028
- **标题**：Step 6b 证据脱敏副本独立复核
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
- **Issue**：任务创建后填 Issue 链接
- **task_id**：T-028（与编号一致）
- **assigned_node**：node-1（与负责人一致）
- **execution_mode: AUTO_START**：Hook 唤醒即开工授权，完成第一项实质性工作后写 STARTED
- **deliverable_path**：`results/node-1/T-028-step6b-evidence-review.md`
- **acceptance_criteria**：填写下方验收标准中的可核验项目
- **requires_approval**：true（推送复核报告到 results/node-1/ 时需审批；等待时写 WAITING_APPROVAL）
- **resume_policy**：沿用原 Task ID 和检查点；确认原执行已退出再恢复，不重复执行；仅实质性进展更新 last_progress_at

## 背景

A/B 包 A2 步。总控已在本地 real-home 检查收据、事件文件及关联证据，扫描 Token、PAT、密钥、Cookie、Authorization、私人信息，制作脱敏副本（原件留本地加哈希），仅将脱敏副本推至公开仓库 evidence/step6b/。本任务由 node-1 从仓库获取脱敏副本并独立复核，确保原件未上传、证据与 ACK、提交关联一致。

## 目标

一句话：独立复核 evidence/step6b/ 下的脱敏证据，确认无敏感信息泄露、证据与 ACK、提交关联一致，提交复核报告。

## 输入

- 脱敏证据路径：公开仓库 `evidence/step6b/`（总控在 A1 完成后推送，A2 启动时已就位）。
- 关联 Issue：T-002（Step 6b 证据复核，Issue #2）。
- 任务书：本文件。

## 输出要求

- 文件路径：`results/node-1/T-028-step6b-evidence-review.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。

## 验收标准

- [ ] 复核报告确认 evidence/step6b/ 下所有文件均已脱敏，无 Token、PAT、密钥、Cookie、Authorization、私人信息残留（逐文件列出检查结果）。
- [ ] 证据与 ACK、提交关联一致（收据、事件、ACK 提交号可追溯、无断链）。
- [ ] 原件未上传公开仓库（核对 evidence/step6b/ 内容与总控 A1 所述脱敏副本范围一致，无原件混入）。
- [ ] 复核报告在约定路径，远程可读。

## 截止

- 期望完成时间：A/B 启动后 2 小时内（16:01 启动，18:01 前交付）。无硬性截止，但 A/B 包后续步骤依赖本复核结论。
