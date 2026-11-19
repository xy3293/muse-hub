# T-077 顶栏快照年龄：改绑实际最新导出时间 + 相对时间（北京时间）

## 任务信息

- **编号**：T-077
- **标题**：顶栏快照年龄：改绑实际最新导出时间 + 相对时间（北京时间）
- **负责人**：Codex
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/72
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

Chen 2026-11-20 02:19 直令：把控制台同时发给 GPT 与 Gemini 评价并提改进意见。两边评价已回（全文存 `~/workspace/console-eval/chatgpt-eval.md`、`gemini-eval.md`），Chen 03:03 批准把两边重合的 5 条 P0 打包成下一批（T-077–T-081）。本任务是第 1 条，也是后 4 条的地基（总览健康条要读修正后的年龄）。

两边对顶栏“4589 分钟”的定位一致：

- GPT：公开快照根级 `refreshed_at` 是 11-20 02:25:14，但 `runtime.data_last_refreshed_at` 是 11-16 22:01:18；顶部“4589 分钟”与旧 runtime 时间按 UTC 算的年龄基本吻合，且显示的 2026-11-16 14:01:18 未正确转换为北京时间。结论：字段选取与显示语义错误，不是快照生成真停了 4589 分钟；须追踪顶栏字段从 API 到组件的完整映射，确认是否误用了 `runtime.data_last_refreshed_at`。
- Gemini：用算术验证 01-overview 的 2026-11-19T18:30:48Z 减去 2026-11-16 14:01:18 恰好等于 4589 分钟，而 04-runtime 底部日志明写着 02:25 快照导出成功。结论：读写错位的数据口径问题，顶栏绑定的导出状态字段没有接入实际生效的导出记录；叠加全站时区混用。

## 工作内容（Tower 仓库 `~/workspace/muse-control-tower-integration`，分支 `codex/T-077`）

### 1. 定位误用字段

- 追踪顶栏快照年龄从后端 API（`/api/v1/runtime`、`snapshot.json`）到前端组件（`frontend/src/components/DataTime.tsx`、api client）的完整映射，写清当前到底读了哪个字段、为什么是旧值。结论写进交付说明（总控验收时要对得上 GPT 指出的两个字段）。
- 以实际最新导出时间为准：根级 `refreshed_at`（快照生成时间）或导出成功日志（`export-status.json` 的 `last_success_at`）；二者选其一并写清理由，不要两个混用。

### 2. 改绑 + 相对时间 + 北京时间

- 顶栏“快照年龄”改绑第 1 步确认的正确字段；显示改为相对时间（`X 分钟前` / `X 天 X 小时前`），不再直接显示 4589 分钟这种需心算的绝对分钟数。
- 时间统一转换为北京时间（UTC+8）显示；无时区裸时间一律注明时区或转换为带时区的北京时间。
- 只改顶栏这一处的时间字段与显示；全站其余页面的时间格式统一另有 T-080，不在本任务重复做。

### 3. 补测试

- 后端：字段组装测试（顶栏读到的年龄与 `snapshot.json` 根级 `refreshed_at` 一致，快照刷新后年龄回到分钟级）。
- 前端：相对时间渲染测试（分钟/小时/天三档）与北京时间转换测试。
- 沿用现有测试套件，不新增测试框架。

## 测试

- 后端 pytest：`~/workspace/muse-control-tower-backend/.venv/bin/python -m pytest`（系统 python3 没有 pytest，只能用这个 venv）。
- 前端 bun 测试套件。
- `bash deploy/verify.sh` 全过（28/29 可接受，唯一 FAIL 须仍是已知采样器新鲜度项）。
- 本地渲染核对：按 T-069 的办法确认顶栏年龄与远端最新快照一致。

## 验收

- 顶栏快照年龄与远端最新 `snapshot.json` 根级 `refreshed_at` 一致（相对时间显示，分钟级），快照刷新后年龄归零附近。
- 页面截图或文本里能看到修正后的顶栏（相对时间 + 北京时间）。
- 后端 pytest 与前端 bun 测试全过。
- 不改快照导出流程与 timer；不改底层数据字段（只改顶栏读哪个字段与怎么显示）；最小代码，不加新依赖。

## 边界

- 只做顶栏快照年龄这一处。T-078（总览重做）依赖本任务的字段修正，由总控按顺序派发，不并行。
- 不写任何密钥进仓库；不碰 T-075 的验收（3 天数据，约 11-22 另行验收）。
