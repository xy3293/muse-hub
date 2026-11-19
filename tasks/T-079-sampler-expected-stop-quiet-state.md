> **已并入重设计第一批，不再单独实施：本任务并入 T-083（Issue #78）。BOARD 状态 PARKED。**

# T-079 采样器停机全局静默态：预期停机与真实故障彻底隔离

## 任务信息

- **编号**：T-079
- **标题**：采样器停机全局静默态：预期停机与真实故障彻底隔离
- **负责人**：Codex
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/74
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

Chen 2026-11-20 02:19 直令：把控制台同时发给 GPT 与 Gemini 评价并提改进意见。两边评价已回（全文存 `~/workspace/console-eval/chatgpt-eval.md`、`gemini-eval.md`），Chen 03:03 批准把两边重合的 5 条 P0 打包成下一批（T-077–T-081）。本任务是第 3 条。

两边一致指出：采样器是 Chen 2026-11-18 15:54 要求主动关闭的（停机范围），但控制台没有任何“采样器已手动停机”的静默态，全屏黄红 Stale / Unavailable / partial=true，真异常被埋没。GPT 要求拆分状态语义（业务状态、监控状态、数据新鲜度分开，只在有可靠停机记录时标注“计划停用”）；Gemini 要求新增灰/蓝色全局静默态，仅对非停机范围的异常标红黄。

## 工作内容（Tower 仓库 `~/workspace/muse-control-tower-integration`，分支 `codex/T-079`）

### 1. 全局静默态

- 新增“采样器已手动停机（预期）”全局状态（灰/蓝标记，置于顶栏或总览首屏可见处），状态来源以现有采样器状态判定为准（采样器 cron 关停、采样状态超 180 秒且在停机范围内）。
- 停机范围内的 Stale / Unavailable / partial=true 降级为灰/蓝“预期停机”显示，不再用红黄告警色。

### 2. 非停机异常仍标红黄

- 仅对非停机范围的异常标红黄告警：GitHub BOARD 拉取失败、快照导出超时等（以现有 verify.sh 与后端判定为准，判定口径不变）。
- 部署自检 28/29 里与停采相关的唯一失败项，展示时注明与计划停采相关（只改展示注释，不改 `deploy/verify.sh` 的 PASS/FAIL 判据本身）。

### 3. 补测试

- 前端：静默态渲染测试（停机范围内 Stale 显示为预期停机态；非停机异常仍红黄）。
- 后端：现有 pytest 须全过；不新增后端判定口径。

## 测试

- 后端 pytest：`~/workspace/muse-control-tower-backend/.venv/bin/python -m pytest`（系统 python3 没有 pytest，只能用这个 venv）。
- 前端 bun 测试套件。
- `bash deploy/verify.sh` 全过（28/29 可接受，唯一 FAIL 须仍是已知采样器新鲜度项——判据本身不动）。
- 本地渲染核对：按 T-069 的办法确认静默态与红黄告警的区分。

## 验收

- 停机范围内 Stale / Unavailable 显示为灰/蓝“预期停机”态，不再全屏红黄。
- 非停机异常（BOARD 拉取失败、导出超时）仍标红黄；自检失败项展示注明与计划停采相关。
- 后端 pytest 与前端 bun 测试全过；页面截图为证。
- 不改采样器本身的开关状态（仍按 Chen 的停机范围关着）；不改 verify.sh 判据；最小代码，不加新依赖。

## 边界

- 只做状态展示层的隔离。不碰采样器 cron、恢复脚本、快照导出流程；不改任何判定口径。
- 不写任何密钥进仓库；不碰 T-075 的验收（3 天数据，约 11-22 另行验收）。
