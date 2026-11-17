# T-054：运行时监控显示 timer 状态（Chen T2）

## 来源
Chen 直令 2026-11-18 04:06，T1–T8 之 T2。意义：把「timer 悄悄死掉」变成一眼可见——昨晚 snapshot timer 就是悄悄死的（PARTIAL 反复报，直到 T-052 才找到 HOME=/root 根因）。

## 目标
页面上直接显示以下四项的 `active/inactive` 与最近触发时间：
1. `muse-tower-snapshot-export.timer`（快照导出，10 分钟一轮）
2. 心跳兜底（watchdog fallback，每 20 分钟一轮的 cron —— 注意：**它是 cron，不是 systemd timer**，没有 unit）
3. `muse-tower-backend` service（:8000）
4. `muse-tower-frontend` service（:3000）

## 现状（Codex 先读，再动手）
- 后端 `GET /api/v1/runtime` 返回 `Runtime` 模型（`backend/muse_tower/models.py` L212：node_patrol、director_patrol、health、scan、data_last_refreshed_at 等），**没有 systemd 单元状态**。
- 1.1.0 契约已冻结。新增字段必须走 T-047 的模式：**可选字段 + 新版本化契约文件**（1.1.1），不得破坏 1.1.0 客户端（`additionalProperties: false` 的严格客户端会拒收未知字段，见 T-047 教训）。
- 后端以 muse-tower 用户运行（非 root）。`systemctl is-active` / `systemctl show` 只读操作非 root 可用；不要用 sudo。
- 前端已有 `RuntimeView`（`frontend/src/views/RuntimeView.tsx`），在该视图内加监控区块，不要另起页面。

## 任务
1. **后端**：给 `Runtime` 加可选字段（或新端点，二选一，Codex 定，以不破坏 1.1.0 为准），内容为四项的状态：每项 `name`、`active: bool`、`last_trigger_at: string | null`（最近一次触发/激活时间，ISO）、`next_trigger_at: string | null`（仅 timer 有）、`detail: string | null`（一行备注，如 inactive 原因）。
   - 前三项（两服务 + snapshot timer）用 `systemctl is-active` + `systemctl show -p ActiveState,LastTriggerUSec,NextElapseUSecMonotonic` 读取。命令失败或超时（5 秒）时该项 `active: false`、`detail` 写明原因，**不得让整个 /api/v1/runtime 失败**。
   - 心跳兜底是 cron：先查它有没有可读的状态来源（cron 本身无状态文件；`~/hooks/scripts/watchdog-fallback.sh` 目前不写 last-run）。若无现成来源，**不要编造数据**：该项 `active` 取「cron 任务是否存在」需另找办法，实在没有则显示 `last_trigger_at: null`、`detail: "无状态文件，未知"`。如需 fallback 脚本写 last-run 文件，写进报告作为后续建议，**不要在本任务里改 hook 脚本**。
2. **前端**：在 `RuntimeView` 内加「运行时监控」区块，四项各一行：名称、状态徽章（active 绿 / inactive 红）、最近触发时间、下次触发时间（有则显示）。inactive 时整行标红并显示 detail。复用现有设计系统组件。
3. **附带小项（T-053 遗留调整）**：把指令列表自动刷新间隔从 60 秒改为 **30 秒**（Chen 新直令 T4）。只改 `CommandsView` 里指令列表的轮询间隔，不要动 `auto-refresh.ts` 的全站 `REFRESH_INTERVAL_MS`（那是全站数据刷新用的）。对应测试一并改。

## 约束
- 不改 1.1.0 契约文件；新增字段走版本化契约（1.1.1），可选字段。
- 不改 hook 脚本、不改 cron、不改 systemd 单元。
- 不编造状态：无数据源的项显示「未知」，不要写假时间。
- 测试：后端 pytest + 前端相关测试全过；`npm run build` 通过。

## 验收
- Codex 交付到 Tower integration 分支；Antigravity 独立复核 PASS；总控验收（收据 + BOARD + MUSE-ACK 一次提交）。
- 验收证据：在线 Tower 的 Runtime 页截图或 API 返回（四项状态真实值），以及 30 秒刷新间隔的测试。

## C11.2（三行，Codex 交付时附上）
- 打算：一句话说清方案
- 最可能失败的两处：1) … 2) …
- 第一次失败后我会改什么：一句话
- 若第二次仍失败：停手，按 C11 咨询，不再试第三条路
