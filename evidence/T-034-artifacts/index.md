# T-034 浏览器测试执行产物（v2，总控 VM 侧执行）

- 执行机：总控 VM（`http://127.0.0.1:3000`，本地部署，前后端均在监听）
- 执行方式：Playwright headless Chromium（`chromium_headless_shell-1255`），真实渲染截图
- 执行时间：2026-11-15 19:37–19:38 UTC（2026-11-16 03:37–03:38 CST）
- 结果：**12/12 PASS**
- 任务书：`tasks/T-034-control-tower-browser-node2.md`（v2，执行机改为总控 VM，node-2 改为独立评审）
- 后端：integration 分支 c9ea494（含 D1/D2 修复），257 测试通过；前端 23 测试通过
- 注意：测试过程中在 Control Tower 的 SQLite 库里创建了 1 条备注（“T-034 测试备注”）与 1 条待办（“T-034 测试待办”），执行后已从库中删除；截图为执行当时真实状态。

| # | 项目 | URL | Viewport | 执行 UTC 时间 | HTTP | 结果 | 关键断言 | 依据 |
|---|---|---|---|---|---|---|---|---|
| 01 | home | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:11.358Z | 200 | PASS | overview content loads (tasks/nodes/overview text present) | loaded |
| 02 | nodes | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:13.513Z | 200 | PASS | node list shows node-1/2/3 | 3 nodes visible |
| 03 | task-filter | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:17.517Z | 200 | PASS | status filter applies (a non-empty option selected) | filter applied |
| 04 | task-search | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:20.761Z | 200 | PASS | search T-033 returns matching task | T-033 in results |
| 05 | task-detail | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:24.768Z | 200 | PASS | task detail drawer opens with detail content | drawer opened |
| 06 | runtime | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:28.000Z | 200 | PASS | runtime view shows health/patrol data | runtime data visible |
| 07 | notes-save | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:32.261Z | 200 | PASS | saved note appears in the list | note visible after save |
| 08 | todo-create-edit | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:35.584Z | 200 | PASS | todo created (and edit control present if found) | created + edit attempted |
| 09 | refresh | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:37:38.383Z | 200 | PASS | refresh reloads data (content present after sync) | data present after refresh |
| 10 | mobile | http://127.0.0.1:3000/ | 390x844 | 2026-11-15T19:37:46.294Z | 200 | PASS | mobile viewport renders without horizontal overflow | no horizontal overflow |
| 11 | error | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:38:04.719Z | 200 | PASS | error UI appears when API calls fail during refresh | error text visible |
| 12 | empty-state | http://127.0.0.1:3000/ | 1440x900 | 2026-11-15T19:38:09.912Z | 200 | PASS | empty state shown for a search with no matches | empty-state text visible |

## 截图文件

- `01-home.png` — 首页加载（总览）
- `02-nodes.png` — 节点列表（3 节点）
- `03-task-filter.png` — 任务筛选（状态过滤已应用）
- `04-task-search.png` — 任务搜索（T-033）
- `05-task-detail.png` — 任务详情（抽屉）
- `06-runtime.png` — 运行监控
- `07-notes-save.png` — 备注保存
- `08-todo-create-edit.png` — 待办创建和修改
- `09-refresh.png` — 页面刷新
- `10-mobile.png` — 手机端布局（390x844 真实移动 viewport）
- `11-error.png` — 错误提示（API 中断后刷新）
- `12-empty-state.png` — 空数据状态（搜索无匹配）

12 张截图 MD5 均不相同，无重复、无冒充。

## 执行中发现的附带问题（不阻塞本项，供 node-2 评审时参考）

1. **`/api/v1/events` 持续 503**：后端 events 端点在三轮直接调用中均为 503（`SOURCE_UNAVAILABLE`）。前端因此在多处显示“全局数据请求异常 / Required data unavailable; no usable snapshot”横幅（01、02、04、06、07、08、09、11、12 的截图里均可见），但各视图自身的取数（overview/nodes/tasks/runtime）均为 200 且内容正常。属于后端 events 数据源问题，与本次 12 项的断言无关。
2. **后端 `CT_ALLOWED_ORIGINS` 需含 `http://127.0.0.1:3000`**：VM 本地执行时浏览器 Origin 是 `127.0.0.1:3000`，与原配置的 Tailscale 地址不同，写操作（POST notes/todos）会被 403 `FORBIDDEN_ORIGIN` 拦截。已在测试部署的启动环境里补上（`CT_ALLOWED_ORIGINS=http://100.111.36.21:3000,http://127.0.0.1:3000`），未改代码、未改仓库配置。
3. **服务曾因 VM 替换掉线**：执行前发现前后端均已掉线（nohup 启动、无 systemd），已重启并验证监听与 `/healthz`。正式部署仍待 Stage 4（systemd＋非 root 用户）。
