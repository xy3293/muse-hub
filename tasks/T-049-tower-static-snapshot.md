# T-049 Tower 前端静态快照模式（Control Tower 静态验收）

## 背景
- Chen 要在自己的 Windows 浏览器里打开 Control Tower 做验收，但 VM 的 Tailscale 不接受入站（100.111.36.21:3000/8000/22 全 refused，tailscale ping 超时）。
- `tailscale serve` 在本 VM 上不可用：VM 的 tailscale 是受限 wrapper，`serve` 子命令不存在（"unrecognized subcommand 'serve'"），且明确说明 serve/funnel 不支持、隧道不接受入站。ATTEMPT 1 已失败（2026-11-16 22:34，总控实测）。
- 降级方案（Chen 2026-11-16 直令）：把前端构建成纯静态 dist + 一个 snapshot.json（任务、事件、节点、刷新时间），推到 muse-hub 的 tower-static/，Chen 在 Windows 上 git pull 后用 127.0.0.1 静态服务打开验收。数据有滞后（巡逻时更新，60 秒级）。
- 这是 C11.2 的第二次尝试（ATTEMPT 2）。若本次失败，停手走 C11 咨询，不再试第三条路。

## 目标
给 Tower 前端加一个静态快照模式：构建时开启该模式后，前端不打 /api、不要求 access key，而是启动时 fetch ./snapshot.json，用里面的数据渲染全部只读视图（首页、节点、任务、事件、运行时）。

## 工作位置
- 仓库：muse-control-tower 私有库，integration 分支。
- 工作目录：~/workspace/muse-control-tower-integration/（integration worktree）。
- 只改前端（frontend/）。不改后端、不改 live 部署、不改 1.1.0/1.1.1 契约文件。

## 需求
1. 新增构建时开关，例如 `VITE_STATIC_MODE=true`（或等价的 `VITE_SNAPSHOT_URL`）。默认关闭；关闭时行为与现在完全一致（live 模式不受影响）。
2. 静态模式下，启动时 fetch `./snapshot.json`（相对路径，必须用相对路径，不能写死绝对路径或端口，以便 Chen 在任意 127.0.0.1:PORT 下打开）。
3. snapshot.json 为单个 JSON 对象，键与 API 端点一一对应，值就是对应端点原样返回的 JSON：
   ```json
   {
     "refreshed_at": "ISO-8601",
     "overview": { "GET /api/v1/overview 原样" },
     "nodes": { "GET /api/v1/nodes 原样" },
     "tasks": { "GET /api/v1/tasks?limit=100 原样（含 items/total/source_meta，total=48）" },
     "events": { "GET /api/v1/events?limit=100 原样" },
     "runtime": { "GET /api/v1/runtime 原样" },
     "notes": { "GET /api/v1/notes 原样（可为空）" },
     "todos": { "GET /api/v1/todos 原样（可为空）" }
   }
   ```
4. 静态模式下，全部只读方法（getOverview、listNodes、getNode、listTasks、getTask、listEvents、getRuntime、listNotes、listTodos、healthz）改为从已加载的 snapshot 内存数据返回，不再发任何 /api 请求。按 ID 取单条（getNode/getTask）时在 snapshot 数组里过滤；找不到返回与 API 一致的 NOT_FOUND 语义（不要崩）。
5. 静态模式下不要求、不弹窗索取 access key（AccessKeyModal 不出现）。snapshot 是公开数据（进仓库），无需鉴权。
6. 静态模式下写操作（createNote/patchNote/deleteNote、createTodo/patchTodo/deleteTodo、refreshReadModels）不发请求：按钮隐藏或禁用，或点后给出明确的“静态模式不可用”提示；不得因此导致页面崩溃或只读视图无法加载。
7. `VITE_STATIC_MODE=true npm run build` 必须成功（tsc + vite build），产物 dist/ 在纯静态服务器下可打开（例如 `python3 -m http.server` 或 `npx serve`），首页、任务、事件、节点均显示 snapshot 数据，且任务数与 snapshot 里的 total 一致。
8. 现有前端测试必须通过（`bun test`）。如测试框架允许，给静态模式加至少一个测试：加载一份示例 snapshot.json，确认 listTasks/getOverview 能从快照返回数据。

## 验证（你自己先验，写进报告）
- 用一份真实 snapshot（从 live API 导出，或手写一份与 API 结构一致的示例）+ `VITE_STATIC_MODE=true npm run build`，起纯静态服务器，打开页面，确认：无 access key 弹窗；首页、任务、事件、节点均有数据；任务数与 snapshot total 一致；控制台无 /api 请求失败刷屏。
- `bun test` 通过；`npm run build`（非静态模式）仍成功，live 行为不变。

## 约束（硬）
- 不新增服务器、不新增凭据、不改现有底座（live 后端/前端部署与 systemd 服务不动）、只用现有数据。
- 不把真实 access key 或任何凭据写进代码、构建产物、快照或报告。静态模式不得读取真实 key。
- 不改 contracts/ 下的契约文件，不新增契约版本（这是前端内部模式，不是 API 变更）。

## C11.2 事前自检（执行方必做）
动手前先在报告里写三行：
```
打算：一句话说清方案
最可能失败的两处：1) … 2) …
第一次失败后我会改什么：一句话
若第二次仍失败：停手，按 C11 咨询，不再试第三条路
```
两次失败后停手，给出 ATTEMPT 1 与 ATTEMPT 2 的差异表（改了什么、为什么这次可能不同），由总控决定是否咨询。不要自己试第三条路、不要硬磨。

## 交付
- integration 分支上的提交（SHA），改动集中在 frontend/。
- 报告含：事前自检三行、改了哪些文件、snapshot.json 格式确认、build 与静态服务器验证结果（贴命令输出）、测试结果（bun test 通过数）。
- 不推 main；不碰 muse-hub（总控负责把 dist/ + snapshot.json 推到 muse-hub tower-static/）。
