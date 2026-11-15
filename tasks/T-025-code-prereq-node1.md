# 任务书

## 任务信息

- **编号**：T-025
- **标题**：代码派活前提核查（node-1）
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
- **Issue**：[#28](https://github.com/xy3293/muse-hub/issues/28)
- **task_id**：T-025（与编号一致）
- **assigned_node**：node-1（与负责人一致）
- **execution_mode: AUTO_START**：Hook 唤醒即开工授权，完成第一项实质性工作后写 STARTED
- **deliverable_path**：`results/node-1/T-025-code-prereq.md`
- **acceptance_criteria**：填写下方验收标准中的可核验项目
- **requires_approval**：true（推送报告到 results/node-1/ 时需审批；等待时写 WAITING_APPROVAL）
- **resume_policy**：沿用原 Task ID 和检查点；确认原执行已退出再恢复，不重复执行；仅实质性进展更新 last_progress_at

## 背景

A/B 包 B1+B2+B3 步（合并为单任务）。代码派活前，需确认三个节点能否跑代码、额度是否充足。本任务由 node-1 自查：技能链接、执行能力、Muse 额度三项。

## 目标

一句话：核查 node-1 的 direct_codex_antigravity 技能链接、执行能力（最小 Python/Shell/测试样例）、Muse 套餐额度，报告结果，供总控分配后续代码任务。

## 输入

- 技能：`direct_codex_antigravity`（检查本地链接是否有效；链接不等于执行器，需实测）。
- 任务书：本文件。

## 输出要求

- 文件路径：`results/node-1/T-025-code-prereq.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。

## 验收标准

- [ ] B1：direct_codex_antigravity 技能链接有效（给出链接路径与验证方法）；明确说明链接不等于执行器（不能只写“有链接”就当能跑代码）。
- [ ] B2：用最小 Python、Shell 及测试样例探测执行能力，记录可运行命令、环境限制、依赖安装需求和错误（实测，不可只凭推断）。
- [ ] B3：查 Muse 套餐用量界面，报告剩余额度、重置时间及查询时间；无数字则注明不可见。若剩余 ≤30% 或出现限流，立即注明“停重活”。
- [ ] 报告在约定路径，远程可读。

## 截止

- 期望完成时间：21:00 前交付（原定 18:01 因 A/B 顺序顺延）。无硬性截止。
- 安全边界：不安装任何软件、不借用总控凭据；未确认的不安装。只做探测与报告，不改系统。
