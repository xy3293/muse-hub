# T-051：Tower 指令消费进巡逻 + 前端指令面板 + C11.2 补充

Chen 直令（2026-11-16 23:36）。两步，都别等。

## 背景

- Chen 自建控制层（`http://127.0.0.1:8899`）：`POST /api/command` 写指令并推到仓库，`GET /api/commands` 查状态，`GET /api/pull` 取快照。
- 指令协议（`commands/`，字段不动）：
- 待处理：`commands/pending/CMD-*.json` = `{ "id": "CMD-xxx", "created_at": "ISO", "created_by": "chen", "action": "dispatch | board_status | notify_node | query", "target": "node-1|node-2|node-3|total", "payload": {...}, "note": "人写的备注"}`
- 结果：`commands/done/<same id>.result.json` = `{ "id": "CMD-xxx", "status": "done|rejected|failed", "by": "总控", "at": "ISO", "detail": "一两句人话", "artifacts": ["SHA 或路径"]}`
- 语义：`dispatch` payload `{title, assignee, body_markdown}` → 按正常流程建任务书 + BOARD 行 + Issue；`board_status` payload `{task_id, status}` → 只改该 BOARD 行，结果须写改前/改后值；`notify_node` payload `{node, message}` → 桥直发消息给该节点（node-3=8787，node-1=8788，node-2=8789），不改仓库；`query` payload `{question}` → 只回答，不改任何文件（除移动文件 + 写结果本身）。
- 消费规则：每轮巡逻开头扫 `commands/pending/`，按 `created_at` 升序；处理完 `git mv` 到 `commands/done/` + 写 `<id>.result.json`；幂等（`done/` 已有同 id 结果就跳过）；失败也必须留痕（`status=rejected|failed` + detail 写清原因，不许静默丢）；优先级：`query` → `board_status` → `notify_node` → `dispatch`；日报加一行：`指令：收到 N / 完成 N / 拒绝 N`。
- 已验证：两条 query 指令已手动处理（CMD-mwjetvwm-1fecac，f3a2176；CMD-mwjfymin-911cf5，5478133，延迟 105 秒，中文正常）。手动处理是 bootstrap，自动消费是本任务的目标。

## 第一步：消费逻辑进巡逻（总控做，已完成）

- 在 `~/hooks/scripts/director-watch-poll.sh` 的 mutation phase 开头（`add_wake` 定义之后）加一段：每轮扫 `commands/pending/*.json`（读 `origin/main`，按 `created_at` 升序），新指令（未在 `$STATE_DIR/commands-watch.json` 的 seen 列表里）建一个 `kind: "tower_command"` 的唤醒事件；处理由总控收到唤醒后执行。
- 每轮写一行到 `$STATE_DIR/logs/commands.log`：`commands: scanned N, done M`（N=pending 数，M=done/ 结果总数），同时 `note` 一行。失败不杀死本轮。
- 已验证（2026-11-17 00:25）：巡逻日志出现 `2026-11-16T16:25:04Z commands: scanned 0, done 2`，`bash -n` 通过，巡逻健康（`health.json last_success_at` 正常推进）。备份：`director-watch-poll.sh.last-good-20261117-T051-commands`。
- 命名规范（Chen 2026-11-17 直令）：指令一律 `CMD-xxx`，任务一律 `T-0xx`，两者不许混。以后指令处理提交信息写 `指令 CMD-xxx 处理完成`（不再写 `T-050 query 处理` 这类借用任务号的标题）。

## 第二步：前端指令面板（Codex 做，本任务书是 spec）

在 Tower 前端（integration 分支，`~/workspace/muse-control-tower-integration/`）的**静态版**里加一个「指令」页。只加页面，不重构现有视图；不改 RULES 语义；不动 `commands/` 协议字段。

- 页面：新增「指令」页（路由/导航入口与现有六个视图并列）。
- 三个表单，都提交到**同源** `POST /api/command`（相对路径 `/api/command`，不写死地址、不写死端口）：
- a) **派任务**：标题 / 执行方（Codex 或节点，下拉）/ 正文（markdown 文本域）→ 生成 `action=dispatch`，payload `{title, assignee, body_markdown}`。
- b) **改状态**：任务号（下拉，从快照里的任务列表来，即 `GET /api/v1/tasks` 或静态 `snapshot.json` 的 tasks）/ 新状态（完成·进行中·待领·拒收，下拉）→ `action=board_status`，payload `{task_id, status}`。状态值用 BOARD 的中文值（完成/进行中/待领/拒收）。
- c) **发消息**：目标节点（node-1/2/3，下拉）/ 消息内容（文本域）→ `action=notify_node`，payload `{node, message}`。
- 提交后显示：指令 ID ＋「已入队，预计 1–3 分钟被处理」。
- 页面同时列出 `GET /api/commands` 返回的 pending / done 列表（id、action、target、创建时间、结果状态）。`GET /api/commands` 也是同源相对路径。
- **静态模式下不能假装能写**：如果 `fetch('/api/command')` 失败（比如直接开 dist 文件而没有本地控制层），要明确显示「未连接本地控制层，指令不可用」，不许静默失败。同样，`GET /api/commands` 失败时列表区也要明确显示未连接，不许显示空白或假数据。
- 静态模式（`VITE_STATIC_MODE=true`，T-049 已建）：指令页在静态构建里也要存在；提交与列表走相对路径 `fetch`，静态下无控制层时走「未连接本地控制层」分支。不要把访问密钥或任何凭据写进前端 bundle。
- 验收（Codex 自测，写进报告）：
- `npm run build`（正常模式与静态模式各一次）通过；
- 静态构建 + 本地静态服务器：三个表单都在；提交时无控制层 → 显示「未连接本地控制层，指令不可用」（贴截图或 curl 证据）；
- 有控制层时（若本地能起一个桩 `/api/command` 与 `/api/commands` 返回固定 JSON）：提交后显示指令 ID 与「预计 1–3 分钟」；列表显示 pending/done。

## 第三步：C11.2 补充（总控做，已完成）

RULES.md C11.2 末尾加（Chen 原话，一字不改）：

> **自检不是请示**：贴完必须立刻动手；除非触发 C11 咨询条件，否则不得以"自检已贴、等待确认"为由停工。

已加进 `RULES.md`（与本任务书同批推送）。

## 交付

- Codex：Tower integration 分支提交（前端指令面板），报告含自测证据（build、静态模式未连接分支、桩测试）。
- 总控：Antigravity 独立复核；复核通过后重建静态 dist + 导出新 snapshot + 重推 `tower-static/`（Chen 的 8899 层要能看到新页面）；验收（巡逻日志扫描行原文、8899 打开指令页并提交一条、SHA）报 Chen。

## 验收（Chen 核）

1) 巡逻日志里出现扫描行（贴原文）；
2) Chen 用 `http://127.0.0.1:8899` 打开能看到「指令」页并成功提交一条；
3) 报 SHA。
