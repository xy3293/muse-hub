# T-066：Tower 面板与仓库对账（T15）

## 来源
Chen 直令 2026-11-18 14:01，第三批 T15。现状：页面显示的任务数只来自后端自己的 task_snapshot，没有任何地方把它和仓库 BOARD.md 的真实行数比对过——面板一旦算错（漏行、状态映射错），页面会一本正经地显示错误数字，没人发现。**这是防止面板骗人。**

## 目标
页面加一个「一致性校验」区块：把页面显示的任务数与 `git show origin/main:BOARD.md` 的行数、状态分布直接比对，不一致就红字标出差异（写明差在哪几条，不只给数字）。

## 设计（总控已定，照做）
1. **后端**：在 `GET /api/v1/overview` 的响应里加可选字段 `reconciliation`（T-047 模式：只加可选字段，冻结的 1.1.0 契约文件不动，新字段进 1.1.1 版本化契约）：
   - `board_total`：BOARD.md 解析出的任务行数（`github.py board()` 的返回条数）。
   - `board_by_status`：按 BOARD 状态单元格原文计数的分布（待领/进行中/待验收/完成/失败/拒收六值；状态单元格不在六值内的行单独计入 `未识别`，并列出这些行的任务号）。
   - `tasks_total`：页面任务总数（`task_snapshot` 返回的条数，含 unlisted）。
   - `tasks_by_status`：按 `derived_status` 计数的分布。
   - `unlisted_count`：只在事件/收据里出现、不在 BOARD 里的任务数，并列出任务号（`task_snapshot` 已有此逻辑，不要重算第二套）。
   - `match`：布尔值。BOARD 行数与页面条数相等、且状态分布在计入 unlisted 后一致时为 true，否则 false。
   - `diffs`：字符串数组，每条写明具体差异，**必须点名任务号**，不许只给数字（例：「BOARD 64 行，页面 63 条，差 1 条：T-xxx 的 BOARD 状态单元格为 …，未计入 …」）。
   - `board_head`：本次比对的 BOARD 所在 commit 短 SHA；`checked_at`：比对时间。
2. **前端**：`OverviewView.tsx` 加「一致性校验」区块：`match=true` 显示绿色「一致」（附 BOARD 行数、页面条数、BOARD HEAD 短 SHA、比对时间）；`match=false` 显示红色差异清单（逐条 diffs，红字）。静态模式：snapshot.json 里 overview 自带 reconciliation（导出器原样导出 overview，无需改导出器）——显示时标注快照时间；若快照无此字段，显示「快照未含对账数据」，不许编造。
3. **必须查清的已知疑点**：Chen 说 64 个任务，2026-11-18 11:27 快照为 63 条。Codex 须用真实 BOARD 跑一次对账，在交付报告里写明差 1 条的**确切原因**（哪一行、哪个字段、哪条映射规则导致），查不清就写查不清，不许编造、不许用「可能」蒙混。
4. **新增后端文件先补 ACL 再重启**（T-063 教训，维护日志㊱）：若新增后端模块文件，重启后端前先 `setfacl -m u:muse-tower:r-- <新文件>`，否则后端起不来（root 0660 无 muse-tower 读权限会 crash-loop）。

## 约束
- 只加只读比对，不改任务/BOARD 的任何写逻辑；不改快照导出器；不改刷新逻辑。
- diffs 必须点名任务号；match 的判定逻辑写进测试，不许前端硬编码。
- 不新增采集、不新增定时任务、不新增凭据。

## 完成标准
- 后端 pytest 全过（新增：分布一致 → match true；BOARD 行状态未识别 → diff 点名该行；事件独有任务 → unlisted 单列不混入差异）；前端 bun test 全过（新增：绿块、红块逐条 diffs、快照无字段 fallback）；`npm run build` 通过。
- 隔离实例跑一次真实 BOARD 对账，返回的 reconciliation 对象贴进交付报告（含 64 vs 63 的确切原因）。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（pytest 输出 + bun test 输出 + build 输出 + 隔离实例 reconciliation 对象原文）
- 64 vs 63 的确切原因（一句）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
