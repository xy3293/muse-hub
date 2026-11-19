# T-076 BOARD 等待态：verify.sh 白名单校验 + Tower 快照 wait 字段 + 页面等待角标

## 任务信息

- **编号**：T-076
- **标题**：BOARD 等待态：verify.sh 白名单校验 + Tower 快照 wait 字段 + 页面等待角标
- **负责人**：Codex
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/71
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

Chen 2026-11-20 直令：BOARD 状态要能表达“我在等”。此前 T-075 连续 6 次被监督者误报“卡住”，根因是 BOARD 只有“进行中”，机器分不出“忙”和“等”。

新约定（已由总控写入 RULES.md C3、TASK_TEMPLATE、ONBOARDING，T-075 行已改为示范）：

- 状态列白名单（9 个值）：`待领` / `进行中` / `进行中·等定时` / `进行中·等外部` / `待验收` / `完成` / `拒收` / `失败` / `PARKED`，其余一律非法。
- 等待态必须带括号写清“等什么＋到什么时候”：`进行中·等定时(11-20 10:00)`、`进行中·等外部(等 X 回复)`；不写清的等待态视为非法。
- 等待态仍计入“进行中”（统计口径不变）；不改变 `完成` / `拒收` / `失败` / `PARKED` 的原义。

**当前已知缺口（本次要修）**：后端 `backend/muse_tower/github.py:132` 的解析白名单还是旧 6 值，`进行中·等定时(11-20 10:00)` 会被解析成 `board_status=None`、derived=`unlisted`，T-075 会在面板上从 In Progress 里掉出去。T-075 行已改，面板在后端修复落地前会暂时显示它为未识别——这是已知、可接受的短暂窗口，验收时须验证修复后它回到 In Progress 并带等待角标。

## 工作内容（Tower 仓库 `~/workspace/muse-control-tower-integration`，分支 `codex/T-076`）

### 1. `deploy/verify.sh` 增加 BOARD 状态一致性检查

- 扫描 `~/workspace/muse-hub-git/BOARD.md` 的数据行（以 `| T-` 开头的行，跳过表头与分隔行），取第 4 列为状态值。
- 状态值必须在 9 值白名单内；等待态须匹配 `进行中·等(定时|外部)\([^)]+\)`（括号非空），否则该项报 `FAIL`。
- 沿用脚本现有的 `pass` / `fail` 输出格式，检查项名用 `BOARD 状态白名单`。
- 约束：只读本地文件、不联网、要快——verify.sh 在每次快照导出时都会跑（60 秒超时）。
- 当前 BOARD（含 T-075 的 `进行中·等定时(11-20 10:00)` 行）跑下来必须是 PASS。

### 2. 后端：解析等待态并输出 `wait` 字段

- `backend/muse_tower/github.py`（约 132 行）：接受 9 值白名单。等待态解析为 `board_status='进行中'`（基值）＋新字段 `wait`：kind=`timer` 时 `until`=括号内容、`reason`='等定时触发'；kind=`external` 时 `reason`=括号内容、`until`=None。`board_status_raw` 已存原始串，保持不动。
- `backend/muse_tower/models.py`（约 138 行）：`board_status` Literal 增加 `'PARKED'`；新增 `wait` 字段（新模型，字段：`kind: Literal['timer','external']`、`until: str | None`、`reason: str | None`），并写清语义的 docstring——这段 docstring 就是快照 schema 文档（随 OpenAPI 进前端生成类型）。
- `backend/muse_tower/normalize.py`（约 117 行）、`service.py`（约 153、226 行）、`telemetry.py`（约 145 行）：等待态按 `进行中` 处理，derived 须为 `in_progress`，reconcile 与派发判定里 `进行中` 出现的地方都要覆盖到。`PARKED` 保持现有推导（unlisted），不新增 derived 桶、不改任何计数。
- 用文档化的方式重新生成前端类型（openapi-typescript@7.13.0 + typescript@5.9.3；`/tmp/t054-openapi-generator` 可能已被 VM 替换清掉，缺失则重建），验证生成的 `frontend/src/types/api.ts` 含有新 `wait` 字段与更新后的 `board_status` 联合类型。

### 3. 前端：等待角标（显示层最小改动）

- 任务表（`frontend/src/views/OverviewView.tsx` 任务行；`frontend/src/design-system/Badge.tsx` 已有 `进行中` 样式可复用）：等待任务在状态旁单独显示“等待中”角标＋原因＋到期时间（定时态显示 until 时间，外部态显示 reason 文本）。
- 等待态仍计入 In Progress（task_counts 口径不变，只验证不改）。
- 只做功能显示，不做美术重设计（前端美术归空间建造者；本次沿用 T-069 的一行动显先例，Antigravity 复核）。
- 补测试：沿用现有前端测试套件（如 `frontend/src/tests/tasks-filter.test.tsx` / `trustworthy-status.test.tsx`），覆盖“等待任务渲染等待角标＋原因＋到期时间”与“等待态计入 in_progress”。

## 测试

- 后端 pytest：`~/workspace/muse-control-tower-backend/.venv/bin/python -m pytest`（系统 python3 没有 pytest，只能用这个 venv）。
- 前端 bun 测试套件。
- `bash deploy/verify.sh` 全过，且输出里有新增的 `BOARD 状态白名单` PASS 项。
- 本地渲染核对：按 T-069 的办法（dist 配真实 snapshot.json 起服，量页面），确认 T-075 行能看到“等待中＋原因＋到期时间”。静态重建后务必核对 `tower-static/dist` 资产哈希/mtime（T-070 教训：只看提交标题会漏掉 stale dist）。

## 验收

- `deploy/verify.sh` 一次完整输出（含新增校验项 PASS）。
- 页面截图或文本里能看到 T-075 的“等待中＋原因＋到期时间”。
- 后端 pytest 与前端 bun 测试全过。
- 不改变 `完成` / `拒收` / `失败` / `PARKED` 的语义与计数；不改 `snapshot-export.sh` 的导出流程；最小代码，不加新依赖。

## 边界

- 只做上面三件（verify.sh 校验、后端 wait 字段、前端等待角标）。不碰 T-075 的验收（3 天数据，约 11-22 另行验收）；不动快照导出流程与 timer；不写任何密钥进仓库。
