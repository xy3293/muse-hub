# 任务书

## 任务信息

- **编号**：T-032
- **标题**：升级巡逻脚本到 2026-11-15.1（node-2）
- **负责人**：node-2
- **状态**：待领（由总控在 BOARD.md 登记）
- **Issue**：[#33](https://github.com/xy3293/muse-hub/issues/33)
- **task_id**：T-032（与编号一致）
- **assigned_node**：node-2（与负责人一致）
- **execution_mode: AUTO_START**：Hook 唤醒即开工授权，完成第一项实质性工作后写 STARTED
- **deliverable_path**：`results/node-2/T-032-patrol-update.md`
- **acceptance_criteria**：填写下方验收标准中的可核验项目
- **requires_approval**：true（推送报告到 results/node-2/ 时需审批；等待时写 WAITING_APPROVAL）
- **resume_policy**：沿用原 Task ID 和检查点；确认原执行已退出再恢复，不重复执行；仅实质性进展更新 last_progress_at

## 背景

巡逻只唤醒一次的 bug 已修（提交 560c8e9，版本 2026-11-15.1，含 stuck-task-rewake：超 15 分钟未认领的任务重新唤醒）。node-3 试点（T-029）已验收通过，现推广到 node-2。T-026 卡住就是因为你这边还是旧版巡逻。

## 目标

一句话：把本机巡逻脚本升级到 2026-11-15.1，dry-run 验证版本与 60 秒轮询不变，报告结果。

## 输入

- 远端修复版：`hooks/patrol.sh`（提交 560c8e9，版本 2026-11-15.1）
- 本任务书。

## 输出要求

- 文件路径：`results/node-2/T-032-patrol-update.md`
- 格式：中文，结论先行；每个关键结论贴来源或命令输出；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源。

## 步骤（按 T-029 规程）

1. 同步本地克隆（git pull），从远端取新版 `hooks/patrol.sh`
2. 旧版备份成 `.last-good`（保留 `~/hooks/scripts/patrol-muse-hub.sh.last-good`）
3. 装到 `~/hooks/scripts/patrol-muse-hub.sh`，`chmod +x`
4. dry-run 验证：版本为 2026-11-15.1，60 秒轮询不变，无状态文件写入

## 验收标准

- [ ] 巡逻脚本版本为 2026-11-15.1（给出验证命令与输出）
- [ ] dry-run 通过（无状态文件写入）
- [ ] 60 秒轮询间隔不变
- [ ] 报告在约定路径，远程可读

## 截止

- 期望完成时间：23:00 前交付。无硬性截止。
- 安全边界：只改本机巡逻脚本，不动仓库其他文件；不借用总控凭据。
