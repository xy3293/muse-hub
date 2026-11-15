# 任务书

## 任务信息

- **编号**：T-030
- **标题**：修 node-3 克隆凭据 helper（store 旧凭据失效，改走 gh）
- **负责人**：node-3
- **状态**：待领（由总控在 BOARD.md 登记）
- **Issue**：[#31](https://github.com/xy3293/muse-hub/issues/31)
- **task_id**：T-030（与编号一致）
- **assigned_node**：node-3（与负责人一致）
- **execution_mode: AUTO_START**：Hook 唤醒即开工授权，完成第一项实质性工作后写 STARTED
- **deliverable_path**：`results/node-3/T-030-credential-fix.md`
- **acceptance_criteria**：填写下方验收标准中的可核验项目
- **requires_approval**：true（推送报告到 results/node-3/ 时需审批；等待时写 WAITING_APPROVAL）
- **resume_policy**：沿用原 Task ID 和检查点；确认原执行已退出再恢复，不重复执行；仅实质性进展更新 last_progress_at

## 背景

T-029 报告推送时，首次推送因本地 credential.helper=store 存的旧凭据失效被拒；改用单次 `gh auth git-credential` 后成功。`~/.git-credentials` 里的旧凭据仍是 stale 状态，下次从该克隆推送会重现此失败。Chen 直令修复。

## 目标

一句话：把本机 muse-hub 克隆的 credential helper 从 store 改为 gh，让后续推送走已登录的 gh，不再用失效的旧凭据，并验证通过。

## 输入

- 本任务书。
- 已知事实：本机 gh 已登录（T-029 推送时 `gh auth git-credential` 一次性调用成功）；`~/.git-credentials` 里有失效的旧凭据。

## 输出要求

- 文件路径：`results/node-3/T-030-credential-fix.md`
- 格式：中文，结论先行；每个关键结论贴命令输出；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。**不许在报告里贴任何凭据值、token、设备码。**

## 步骤

1. 在本机 muse-hub 克隆里执行：`git config credential.helper '!gh auth git-credential'`（只改本克隆，不改全局）
2. 验证：`git config --get credential.helper` 应输出 `!gh auth git-credential`
3. 验证：`git ls-remote origin main` 能通（证明后续推送不再走旧凭据）
4. 写报告并推送（本次推送本身就是一次验证）

## 安全边界

- **只改 credential.helper，不删 `~/.git-credentials` 文件、不改、不读其中任何凭据内容。** 不要打开、不要 cat、不要贴出该文件。
- 不跑 `gh auth login`（gh 已登录，不需要重新登录）。
- 不借用总控凭据。

## 验收标准

- [ ] 克隆的 credential.helper 已改为 `!gh auth git-credential`（给出 `git config --get credential.helper` 的输出）
- [ ] `git ls-remote origin main` 能通（或一次测试推送成功）
- [ ] 未删、未读 `~/.git-credentials` 内容
- [ ] 报告在约定路径，远程可读；报告无凭据值

## 截止

- 期望完成时间：22:00 前交付。无硬性截止。
