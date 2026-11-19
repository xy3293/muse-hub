# T-081 任务中心：表前移、统计后移、排序、合并重复状态列

## 任务信息

- **编号**：T-081
- **标题**：任务中心：表前移、统计后移、排序、合并重复状态列
- **负责人**：Codex
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/76
- **合同版本**：`contract_revision`（即任务书版本 `版本：vN`；执行以认领时的版本为准）
- **运行标识**：`run_id`（复用 checkpoint-spec §3 已有字段；一次逻辑执行一个稳定标识）
- **进展时间戳**：`last_progress_at`（只在实质工作推进时更新，与存活心跳区分）
- **幂等键**：复用 checkpoint-spec §6 账本的 `effect_id`（每个外部副作用操作一个稳定键）
- **预估 worker 秒数**：未知，先按小任务做
- **单回合预算**：`time_budget_seconds`（默认 600；主体工作 420–450 秒，收尾至少 90 秒；各阶段预算极值合计不得超过 600 秒）
- **阶段**：`stages`（阶段列表，每阶段写清目标、产物路径、验收条件）
- **checkpoint**：`checkpoint_after_each_stage`（每阶段结束后按 `docs/checkpoint-spec.md` 写 checkpoint）
- **阶段产物路径**：`stage_output_paths`
- **续跑说明**：`resume_instructions`（新 worker 仅凭 checkpoint 和产物继续，不依赖旧 worker 的隐式记忆）
- **外部副作用**：`external_side_effects`（可能产生重复影响的外部动作，先记账再执行，见 `docs/checkpoint-spec.md`）
- **收尾开始时间**：`finalize_before_seconds`（到达该秒数即停止新增工作，进入 checkpoint 和交付收尾；默认 450）
- **发布与通知要求**：`publish_and_notify_requirements`

这一行是机器解析用的，必须严格保持「版本：vN」格式——不要加列表符号、不要加粗、不要写进 HTML 注释；巡逻脚本只扫任务书前 15 行的严格行，格式变了就唤醒不了。

## 背景

Chen 2026-11-20 02:19 直令：把控制台同时发给 GPT 与 Gemini 评价并提改进意见。两边评价已回（全文存 `~/workspace/console-eval/chatgpt-eval.md`、`gemini-eval.md`），Chen 03:03 批准把两边重合的 5 条 P0 打包成下一批（T-077–T-081）。本任务是第 5 条。

两边对任务中心（`frontend/src/views/TasksView.tsx`）的判断一致：

- 搜出 T-075 后，筛选栏与结果表之间硬插了一张占满半屏的“近 7 天（全量）”吞吐统计表，把唯一的任务结果挤到最底部裁切。
- 任务表 10 列里光状态就占 5 列，BOARD 六态（进行中）和任务状态（BOARD）（In Progress）完全重复；交付/验收两个 unverified 中英混杂。
- 默认按 Task ID 升序排序，老任务占前排。
- T-075 新加的“等定时触发 · 11-20 10:00”徽章（T-076 已落地）非常实用，但混在两个“进行中”标签旁边辨识度被稀释。

## 工作内容（Tower 仓库 `~/workspace/muse-control-tower-integration`，分支 `codex/T-081`）

### 1. 表前移、统计后移

- 任务表移至首屏直接可见；“近 7 天（全量）”统计表折叠（默认收起可展开）或移到页面底部。

### 2. 默认排序

- 默认按“卡住/超时 > 进行中 > 等待定时 > 最近更新”排序（与 T-078 总览任务清单口径一致），不再默认按 Task ID 升序。

### 3. 合并重复状态列

- 合并 BOARD 六态与任务状态（BOARD）两列的重复信息；交付/验收 unverified 的中英混杂统一为一种表述（与后端 derived 口径一致，不改口径只改显示）。
- T-075 的等待徽章保持醒目（T-076 已验收的显示不动，只去重旁边重复的“进行中”标签）。

### 4. 补测试

- 前端：首屏任务表可见测试、默认排序测试、重复列合并测试；沿用现有 `tasks-filter.test.tsx` / `trustworthy-status.test.tsx`。

## 测试

- 后端 pytest：`~/workspace/muse-control-tower-backend/.venv/bin/python -m pytest`（系统 python3 没有 pytest，只能用这个 venv）。
- 前端 bun 测试套件。
- `bash deploy/verify.sh` 全过（28/29 可接受，唯一 FAIL 须仍是已知采样器新鲜度项）。
- 本地渲染核对：按 T-069 的办法确认首屏任务表、排序与合并后的列。

## 验收

- 打开任务中心首屏直接看到任务表；统计表已折叠或在底部。
- 默认排序为卡住/超时 > 进行中 > 等待定时 > 最近更新；重复状态列已合并；T-075 等待徽章仍清晰。
- 后端 pytest 与前端 bun 测试全过；页面截图为证。
- 不改任务数据与 BOARD 口径；不改等待徽章（T-076 已验收）；最小代码，不加新依赖。

## 边界

- 只做任务中心页的布局与排序。不碰总览（T-078）、时间格式（T-080）。
- 不写任何密钥进仓库；不碰 T-075 的验收（3 天数据，约 11-22 另行验收）。
