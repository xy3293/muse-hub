# T-006 Control Tower 数据结构调查

## 任务信息

- **编号**：T-006
- **标题**：Control Tower 数据结构调查
- **负责人**：node-1（1 号研究员）
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/6

## 背景

Muse Control Tower 总体项目任务书 v1.1 已定：新建独立产品，后端 FastAPI + SQLite，前端 React，第一阶段只读 GitHub muse-hub。Stage 0 要求先把现有数据结构摸清楚，再冻结数据模型与 OpenAPI。本任务是 Stage 0 的数据调查部分。

## 目标

一份数据调查报告：数据字典、字段映射表、真实 JSON 样本、任务状态案例、数据异常案例、不确定字段清单，供 Codex 设计后端解析层使用。

## 输入

- `BOARD.md`、`RULES.md`、`tasks/`、`results/`、Issues #1～#5（当前远端 main 版，直接读仓库）
- 本任务书下方总控提供的脱敏结构与样本（本地运行数据只在总控 VM 上，node-1 不得假设可直接读取原始文件）

## 输出要求

- 文件路径：`results/node-1/T-006-control-tower-data-survey.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 只读调查。不修改 BOARD.md / RULES.md / 任何任务书 / 任何结果文件。
- 不许编数字，不许编来源。样本值只能用本任务书提供的脱敏样本或仓库内已公开的数据。

## 调查范围

逐项核实并记录：

1) `BOARD.md` 的结构：六列（编号 | 任务 | 负责人 | 状态 | 任务书 | Issue），列顺序固定，巡逻脚本按列解析；状态枚举：待领 / 进行中 / 待验收 / 完成 / 失败 / 拒收；BOARD 是人工维护表、不是实时事实，以远端提交和收据为准
2) `RULES.md` 中的状态定义（重点是 R6a/R6b/R7 的任务状态与事件状态）
3) `tasks/` 目录的任务书格式（任务信息、版本行 `版本：vN` 独占一行且位于前 15 行内、输出要求、验收标准）
4) `results/node-N/` 的交付组织方式（node-1 有 T-001/T-003/T-004/T-005，node-2 仅 README 无正式交付，node-3 有 T-002；另有 `_sandbox/` 例外不验收）
5) GitHub Issue 与任务之间的关联方式（一任务一 Issue，#N 对应 T-00N；Issue 正文含任务书路径与交付路径）
6) `health.json` 的字段和更新时间（样本见下）
7) `scan.json` 的字段和更新时间（样本见下）
8) `events/` 的事件类型与状态取值（样本见下；实测 8 个事件：6 个 ACKED、2 个 NEEDS_ATTENTION）
9) `receipts/` 的验收收据结构（样本见下；共 5 份，对应 T-002～T-005）
10) `logs/health-exceptions.jsonl` 的异常记录结构
11) 当前任务状态可能发生冲突的案例（至少覆盖：BOARD 完成 vs Issue OPEN；巡逻周期 300 vs 180；NEEDS_ATTENTION 事件的含义；`health.json` 的 `last_error` 残留历史错误值）

## 总控提供的脱敏结构与样本（2026-11-12 核查实测，无密钥、无 Token）

BOARD 实测内容（5 行，全部“完成”，远端 HEAD e24bfc6）：T-001 代币化美股研究 node-1 #1；T-002 Step 6b 证据独立复核 node-3 #2；T-003 Kaggle 免费 GPU 接入 Muse 研究 node-1 #3；T-004 免费资源盘点 node-1 #4；T-005 规则一致性核查 node-1 #5。

Issues 实测：#1～#5 全部为 OPEN，无一关闭；评论数 #1 为 2 条、#2 为 2 条、#3/#4/#5 为 0 条。任务“完成”只体现在 BOARD 与 ACK 提交上，不回关 Issue，这是现行流程，不是漏操作。

health.json 字段（schema_version: 1）：last_success_at、last_attempt_at、consecutive_api_failures、consecutive_script_failures、note、rate{remaining, reset, checked_at}、last_error、s3{ledger_available, error}。实测例：last_success_at 2026-11-11T19:40:08Z，consecutive 失败计数均为 0，rate.remaining 53，last_error 残留 "comments-fetch-failed"（该字段语义是“最后一次错误”而非“当前错误”，成功运行时仍残留）。

scan.json 字段（schema_version: 1）：scan_cursor（例：e24bfc6…）、scan_cursor_updated_at、comments{Issue 号: [{id, updated_at, processed}]}、migrated_from、migrated_at、s3_ledger{ledger_id, prefix_bytes, prefix_sha256, seq}。

事件文件 events/*.json 字段（schema_version: 1）：event_id、kind、task_id、node_id、source_commit_sha、source_paths、state、review{verdict, receipt_path, reviewed_at}、delivery{status, attempt_count}、approval{status, operation_id}、main_ack{acked, ack_commit_sha, ack_method}、retry{attempt_count, wakes, last_wake_at}、signals[{comment_id, issue, updated_at}]、timestamps{detected_at, receipt_saved_at, main_acked_at}、last_error。state 实测取值：ACKED、NEEDS_ATTENTION；代码中另有终态 REJECTED、SUPERSEDED、CLOSED_INTERNAL。

收据文件 receipts/*.json 字段：schema_version、event_id、task_id、node_id、version_sha、status: REVIEWED、verdict: PASS|REJECT、summary、reviewed_at、source_paths、checks[]，其中 checks[] 每项为 {name, status: PASS|FAIL, evidence}。

关键口径（核查时不得写反）：生产巡逻周期是 300 秒（总控 Hook 注册 poll_interval_secs 300，RULES R6b 同）；180 秒是 v1.1 已批方案值，阶段二改注册未授权未执行，是计划值不是现状。node-4 不存在（BOARD、RULES、results、事件文件里均无记录），不得为其生成任务或状态。署名标记为【总控】【1号】【2号】【3号】全角形式，是机器分类依据之一。

## 验收标准

- 11 项调查范围逐项有结论，每项贴来源（文件路径 + 行号或 Issue 链接）。
- 数据字典与字段映射表完整，样本为真实结构（值可脱敏，但字段名、类型、层级必须与样本一致）。
- 任务状态案例至少 3 个，数据异常案例至少 2 个，不确定字段单独列清单并写“未验证”。
- 全文无编造的数字、来源或字段；无密钥、无 Token、无原始本地运行记录全文。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止。Stage 0 第一批，尽快交付。
