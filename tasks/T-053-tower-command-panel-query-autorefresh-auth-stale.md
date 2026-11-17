# T-053：Tower 指令面板进阶 — query 表单 + 列表自动刷新 + 最小鉴权 + 静态过期提示

## 来源
Chen 直令 P2（2026-11-18 03:51）。T-051 建了指令面板（三表单：dispatch / board_status / notify_node），本任务是它的进阶：补齐 query 表单、列表自动刷新、最小鉴权、静态页过期提示。

## 现状（Codex 先读，再动手）
- `frontend/src/views/CommandsView.tsx`（205 行）：三表单（派任务 L150、改状态 L163、发消息 L177），指令列表只有手动「刷新指令列表」按钮，无 query 表单，无自动刷新。
- `frontend/src/api/commands.ts`（62 行）：`CommandRequest` 只有三 variant（无 query）；`request()` 只发 `Accept` + `Content-Type`，无鉴权头。
- `frontend/src/api/auto-refresh.ts`：已有 `REFRESH_INTERVAL_MS = 60_000` 与 `startAutoRefresh(refresh)`（单 flight 保护 + 返回清理函数），复用它，不要另写定时器。
- `frontend/src/components/DataTime.tsx`：已有 `stale` 判定（age > 180 秒或 error），过期时只显示一行小黄字「数据过期」，无醒目提示、无「等下一份快照」状态。
- **关键架构事实（验收前必须理解）**：Tower 后端没有任何 `/api/command` / `/api/commands` 路由；Vite 把 `/api` 代理到后端 :8000，所以**在线 Tower 里指令面板目前是 404**，指令面板只在 Chen 的 8899 静态部署（同源 `/api/command` → 8899）里真正可用。鉴权的校验方只能是 8899（Chen 的控制层），Tower 后端不在静态路径上，拦不住。本任务只做前端一半 + 契约文档，8899 侧的强制校验是 Chen 的后续决定，不得擅自改 8899、不得改 Chen 的指令协议字段。

## 任务（4 项，全部在 frontend/，不碰后端、不碰 1.1.0 契约）
1. **query 表单**：指令面板加第 4 张表单「问问题」。payload `{question}`，target `total`（与协议一致：query 只答复、不改文件）。沿用现有 `handleSubmit` 模式：question 非空校验；提交成功显示指令 ID + 「已入队，预计 1–3 分钟被处理」。`commands.ts` 的 `CommandRequest` 加 query variant。
2. **指令列表自动刷新**：复用 `startAutoRefresh`（60 秒）轮询 `listCommands()`，保留手动刷新按钮。失败时：保留上一次成功列表、不清空、不刷屏报错（沿用现有 `listError` 横幅）；下一轮继续重试。组件卸载时清理定时器。静态模式下列表来自快照，不轮询（不要对静态快照发请求）。
3. **最小鉴权（本地 token）**：
   - 面板加一个 token 输入（复用访问密钥弹窗的模式：**只放前端内存，永不进 localStorage / URL / 日志 / bundle / git**）。
   - `POST /api/command` 与 `GET /api/commands` 一律带 `X-CT-Command-Token: <token>` 头；未输入 token 时提交按钮不可用，并提示「请先输入指令 token」。
   - 写一份契约文档 `frontend/src/api/commands-auth.md`（短，不超过 40 行）：头名、token 存放（Chen 在 8899 侧自定）、8899 校验规则（比对不一致返回 401，前端收到 401 显示「指令 token 不正确」）、以及明确一句：**8899 侧强制校验不在本任务内，由 Chen 决定是否加上**。
   - token 值本身永不出现在 diff、测试、文档示例里（示例用 `TOKEN-PLACEHOLDER`）。
4. **静态页过期提示**：复用 `DataTime` 的 `stale` 判定（age > 180 秒或 error）。静态模式下 stale 时，在页面顶部显示一条醒目横幅（不只是小黄字），文案固定为：「数据过期 · 正在等下一份快照（快照每 10 分钟刷新一次）」。在线模式 stale 时横幅文案为「数据过期 · 正在重试」。横幅不得遮挡指令表单。

## 约束
- 只改 `frontend/`；不改后端、不改 1.1.0 契约、不新增后端路由。
- 不碰 Chen 的 8899 控制层与指令协议字段（`id / created_at / created_by / action / target / payload / note` 不动）。
- 静态模式不得假装能写（T-051 的 `COMMAND_UNAVAILABLE` 分支原样保留）。
- 测试：扩展 `src/tests/commands.test.ts`（query 提交、token 头、401 处理）+ 过期横幅测试；`bun test` 全过；`npm run build` 通过。

## 验收
- Codex 交付到 Tower integration 分支；Antigravity 独立复核 PASS；总控验收（收据 + BOARD + MUSE-ACK 一次提交）。
- 验收后总控重建静态 dist 并重推 muse-hub `tower-static/`（与 T-051 相同流程，不在本任务书内）。

## C11.2（三行，Codex 交付时附上）
- 打算：一句话说清方案
- 最可能失败的两处：1) … 2) …
- 第一次失败后我会改什么：一句话
- 若第二次仍失败：停手，按 C11 咨询，不再试第三条路
