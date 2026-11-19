> **已并入重设计第一批，不再单独实施：本任务并入 T-082（Issue #77）。BOARD 状态 PARKED。**

# T-078 全景总览首屏重做：异常/任务/节点上移，数据源卡片下沉

## 任务信息

- **编号**：T-078
- **标题**：全景总览首屏重做：异常/任务/节点上移，数据源卡片下沉
- **负责人**：Codex
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/73
- **合同版本**：`contract_revision`（即任务书版本 `版本：vN`；执行以认领时的版本为准）
- **运行标识**：`run_id`（复用 checkpoint-spec §3 已有字段；一次逻辑执行一个稳定标识）
- **进展时间戳**：`last_progress_at`（只在实质工作推进时更新，与存活心跳区分）
- **幂等键**：复用 checkpoint-spec §6 账本的 `effect_id`（每个外部副作用操作一个稳定键）
- **预估 worker 秒数**：未知，先按中任务做
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

Chen 2026-11-20 02:19 直令：把控制台同时发给 GPT 与 Gemini 评价并提改进意见。两边评价已回（全文存 `~/workspace/console-eval/chatgpt-eval.md`、`gemini-eval.md`），Chen 03:03 批准把两边重合的 5 条 P0 打包成下一批（T-077–T-081）。本任务是第 2 条。

两边对全景总览的判断一致：首屏约 80% 被 18 张底层数据源卡片占满（其中含 10 张单条 event/receipt 哈希、3 张完全重复且未标明归属节点的 `github:commits`），总览页居然看不到任何任务或节点状态。GPT 要求把总览升级为异常与行动入口；Gemini 要求推倒重做，只放三块内容。

## 工作内容（Tower 仓库 `~/workspace/muse-control-tower-integration`，分支 `codex/T-078`）

### 1. 总览首屏只放三块内容

- ① 真实快照/同步健康条 + 一致性单行摘要（读 T-077 修正后的快照年龄字段；一致性结论沿用现有 reconcile 输出）。
- ② 异常/进行中/等待中任务清单（T-075 直接露头，带 T-076 已落地的等待角标；按“卡住/超时 > 进行中 > 等待定时 > 最近更新”排序，与 T-081 的任务排序口径一致）。
- ③ 3 个节点的精简心跳卡（当前任务 + 最后可信活动及时间 + 阻塞状态，不展开长原文）。

### 2. 数据源卡片下沉到运行时监控

- 18 张数据源新鲜度卡片全部移出总览首屏，下沉到运行时监控页，按类型聚合去重（合并 3 张 `github:commits` 与 10 张零散 event/receipt 哈希）。
- 数据口径不变（只搬位置 + 聚合展示，不改后端数据源与 freshness 判定）。

### 3. 补测试

- 前端：首屏三块内容渲染测试（有进行中/等待任务时清单可见；数据源卡片不在总览首屏）。
- 后端：不改口径，无新增后端测试要求；现有 pytest 须全过。

## 测试

- 后端 pytest：`~/workspace/muse-control-tower-backend/.venv/bin/python -m pytest`（系统 python3 没有 pytest，只能用这个 venv）。
- 前端 bun 测试套件。
- `bash deploy/verify.sh` 全过（28/29 可接受，唯一 FAIL 须仍是已知采样器新鲜度项）。
- 本地渲染核对：按 T-069 的办法确认总览首屏三块内容与下沉后的运行时监控页。

## 验收

- 总览首屏可见：健康条 + 一致性单行摘要、任务清单（T-075 露头带等待角标）、3 节点简卡。
- 数据源卡片不在总览首屏；在运行时监控页按类型聚合展示，无重复 `github:commits`。
- 后端 pytest 与前端 bun 测试全过；页面截图为证。
- 不改后端数据口径与 freshness 判定；不改快照导出流程；最小代码，不加新依赖。

## 边界

- 依赖 T-077 的字段修正（健康条读修正后的年龄），由总控按顺序派发，不与 T-077 并行（重叠文件 `OverviewView.tsx`、`DataTime.tsx`）。
- 不做导航收口（7 页签变 5 个是两边分歧点，不在本批做）；不做美术重设计（前端美术归空间建造者；本次沿用 T-069/T-076 的功能显示改动先例，Antigravity 复核）。
- 不写任何密钥进仓库；不碰 T-075 的验收（3 天数据，约 11-22 另行验收）。
