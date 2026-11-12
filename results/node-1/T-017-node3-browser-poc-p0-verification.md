# T-017 直控 node-3 浏览器自动化 PoC：P0 只读可行性核验

- **编号**：T-017
- **负责人**：node-1
- **核验日期**：2026-11-13
- **任务书**：`tasks/T-017-node3-browser-poc-p0-verification.md`（v1）
- **Issue**：https://github.com/xy3293/muse-hub/issues/19
- **核验方式**：只读。读公开仓库原文、代码入口、官方资料与 hub 文档；未安装任何桥接器，未运行浏览器，未登录任何账号，未向 node-3 发测试消息，未改任何配置、Hook、BOARD、RULES。报告、checkpoint 均无秘密（R5）。

## 结论先行

**P0 结论：有条件通过。**

三候选中只有 **Muse-Chat-MCP 是 Muse 专用的桥接器**，且四种状态（完成／超时／需审批／登录失效）在其代码里是真实返回的字段，不是宣传口径；登录复用用户自己在真实 Chrome 里登过一次的 profile，不复制任何密码、Cookie、Token；HTTP 垫片默认只绑 `127.0.0.1`。以只读核验的标准看，可信路径存在。

**建议：可以进 P1，但只做小范围试验，且先补两项前置——（1）Chen 另行批准安装与登录（本次只批准了 P0，2026-11-13 01:32）；（2）确认以总控 VM 操作 node-3 的实时登录会话是否符合 Muse／Meta 服务条款（本次未找到允许或禁止的官方依据，写“未验证”，不得推定合规）。** P1 的精确前置见第 7 问。

**唯一首选：Muse-Chat-MCP**（理由见第 6 问）。agent-browser 与 PinchTab 暂不选。

---

## 1. 维护与可信度

数据来源：GitHub API 仓库元数据与 releases 接口，2026-11-13 读取；版本取自各仓库 `package.json`／release tag。

| 仓库 | 最后推送 | 最新 release | 许可证 | Stars／Forks | Open issues | 语言 | 状态判断 |
|---|---|---|---|---|---|---|---|
| [Muse-Chat-MCP](https://github.com/duclm1x1/Muse-Chat-MCP) | 2026-09-30T19:25:19Z | 无 release；`package.json` 版 `0.1.0` | MIT | 80／35 | 1 | JavaScript | **最年轻、风险最明显**：2026-09-30 创建，同日最后一次推送，距今约 6 周无更新；单作者（duclm1x1）；无正式 release，只有 `0.1.0` |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | 2026-11-12T17:13:59Z | v0.42.0（2026-11-10） | Apache-2.0 | 50,248／3,498 | 586 | Rust 为主＋TypeScript | **相对最可维护**：Vercel Labs 出品，2026-01-11 创建，持续高频发布（v0.41.1→v0.41.2→v0.42.0 均在 2026-11 月内），社区最大 |
| [PinchTab](https://github.com/pinchtab/pinchtab) | 2026-11-10T22:44:49Z | v0.15.2（2026-08-26） | MIT | 10,577／789 | 17 | Go 为主 | 维护活跃但 release 滞后：main 最后推送 2026-11-10，最新 release 却是 2026-08-26 的 v0.15.2，约 2.5 个月未发版；社区规模居中 |

**结论**：相对最可维护的是 agent-browser；明显风险在 Muse-Chat-MCP——仓库只有 6 周历史、单作者、无 release、6 周无提交，存在作者停更后无人接手的风险。但它的风险是“维护风险”，不是“功能不存在”：第 3 问证实其核心状态字段是真实代码。

---

## 2. 登录与会话机制

### Muse-Chat-MCP

- 驱动“你自己的、已登录的真实 Chrome”（Playwright），复用一个专用 Chrome profile（`.muse-profile/`，git-ignored）。原文（[README](https://github.com/duclm1x1/Muse-Chat-MCP)）：
> “A Chrome window opens to `https://muse.ai`. Sign in with your Meta account. The session is stored in a dedicated profile (`.muse-profile/`, git-ignored) and reused afterwards. When `muse_status` reports `"loggedIn": true`, you're ready.”
- 明确声明不带任何凭据：“It ships with **no** credentials, no Chrome profile, and no captured traffic — you sign in to your own Meta account on first run.”
- 也可以挂到已在运行的 Chrome：`--remote-debugging-port=9222`（CDP 附加；关闭时只断开，不杀浏览器）。
- 登录状态判定是调 `POST /api/auth/check`（`muse-driver.mjs` L174-176），不是读本地 Cookie 文件。
- **不要求复制密码、Cookie、Token。不开放入站端口**：MCP 走 stdio；OpenAI 垫片是本地 HTTP，默认 `127.0.0.1:8787`（`muse-openai-shim.mjs` L30-31：`HOST` 默认 `'127.0.0.1'`，可由 `MUSE_SHIM_HOST` 环境变量改——改 host 是调用方行为，默认即 loopback）。

### agent-browser

- 通用浏览器自动化 CLI（Rust），自带守护进程＋CDP 控浏览器。默认浏览器是下载来的 Chrome for Testing（`agent-browser install` 首次下载）；也可以 `--cdp`／`--auto-connect` 挂到已在运行的 Chrome。
- 会话隔离：每个 `--session` 有自己的浏览器实例、Cookie、存储与认证状态（[Sessions 文档](https://agent-browser.dev/sessions)）；登录做法是在 headed 浏览器里人工登录一次，靠 session 持久化（`--state`）复用。
- **不要求复制密码、Cookie、Token**（工具本身不提供此类导入口径；登录靠人工在浏览器里完成）。无入站端口：CLI＋本地守护进程模式，无 HTTP 服务端口（`stream` 功能绑 localhost 端口，仅用于运行时流传输，属可选功能）。

### PinchTab

- Go 单二进制（约 30MB）的 HTTP 服务，驱动本地已装 Chrome／Chromium；支持 headless 或 headed profile，profile 可配置认证、Cookie（[README](https://github.com/pinchtab/pinchtab)）。登录做法同样是人工在 headed profile 里登录一次后复用。
- **要求管理一个新的秘密**：每个 API 请求都要带 server token（`Authorization: Bearer $PINCHTAB_TOKEN`），token 在 `config init` 时生成、存在配置文件里。README 同时写明默认 `server.bind = 127.0.0.1`（默认端口 9867），并警告超出 loopback 绑定要自行负责 token、网络边界与 TLS。
- 不要求复制 node-3 的密码或 Cookie，但引入了一个需妥善保管的 server token；这是三者中唯一新增秘密管理负担的候选。

**小结**：三者登录都走“人工在真实浏览器登一次、复用 profile／会话”的正常流程，都不要求复制密码、Cookie、Token；Muse-Chat-MCP 与 PinchTab 默认只绑 loopback，agent-browser 本地守护进程模式无对外端口。

---

## 3. 收发与状态区分

### Muse-Chat-MCP：四种状态均为代码真实返回的字段

`muse-driver.mjs`（main 分支，2026-11-13 读取）`_run` 的返回类型声明（L337）：

```js
@returns {Promise<{reply:string, messages:string[], threadUrl:string, elapsedMs:number, error?:string, timedOut?:boolean, needsApproval?:boolean}>}
```

实际返回逻辑（L418-445）：

- **完成**：返回 `reply`、`messages`、`threadUrl`、`elapsedMs`。
- **超时**：`if (Date.now() >= deadline) timedOut = true`，返回含 `timedOut: true`（默认等待 240 秒，`timeout_sec` 上限 1800 秒）。
- **需审批**：`const needsApproval = (await p.locator(SELECTORS.approvalStack).count()) > 0`，其中 `approvalStack: '[data-hatch-composer-approval-stack]'`（L44），返回含 `needsApproval: true`。**`needsApproval` 是代码里真实返回的字段，不是文档宣传。**
- **登录失效**：`muse_status` 返回 `loggedIn: false`（由 `POST /api/auth/check` 的 `ok` 判定，L174-176、L195-223）；`muse_login` 在超时未登录时返回 `loggedIn: false` 并附提示 “Complete the Meta sign-in in the opened Chrome window…”。
- **失败**：助手错误提示被捕获进 `error` 字段（L418-419，`[data-testid="assistant-response-error-notice"]`）。

`NODE3_OK` 的判定可直接映射这四个字段，无需猜测 DOM 文本。

### agent-browser：无 Muse 专属四态，需自定义脚本层实现

- 通用 CLI：`open`／`snapshot`／`click`／`fill` 等命令返回快照文本或 JSON；命令失败时报错而非谎报成功（README：“A click fails, instead of reporting success, when the target is hidden, disabled, outside the viewport, or covered…”）。
- `confirm`／`deny` 命令属于它自己的 `--confirm-actions` 动作确认策略（README 命令表归入 “Sessions and auth”），不是 Muse 审批卡的检测；文档站说明默认自动接受的是 JS `alert`／`beforeunload` 对话框，`confirm`／`prompt` 对话框仍需显式处理——与 Muse 的 Sentinel 审批卡无关。
- **未验证**：本核验未找到 agent-browser 内置的“完成／超时／需审批／登录失效”四态返回；要区分这四态，需在脚本层轮询 snapshot／DOM 自行实现（例如检测审批卡元素、检测登录页跳转、命令超时自行判定）。

### PinchTab：无 Muse 专属四态，需自定义逻辑

- 通用 HTTP API 返回 JSON；README 与配置文档中未找到 Muse 专属状态字段或审批相关口径。
- **未验证**：内置四态返回不存在（按现有文档判断）；区分四态同样需在调用方逻辑里对页面状态做轮询与判定。

**小结**：只有 Muse-Chat-MCP 能开箱返回四种状态；另两者要达到同样区分度，都要额外写一层 Muse 专用的 DOM／状态判定脚本。

---

## 4. 审批与平台边界

- **Muse-Chat-MCP 未发现自动通过审批的代码或文档**。全文 grep `approval` 在 `muse-driver.mjs` 仅命中三处：选择器定义（L44）、`needsApproval` 判定（L430）与返回（L444），以及 `--dump-dom` 的 `hasApproval` 标志（L658）；**没有任何点击审批按钮、代点“允许”的代码**。它只“报告需要审批”，不“通过审批”。`muse-server.mjs` 同样无审批相关操作。
- **agent-browser**：默认“不限制导航、动作与输出”（[Security 文档](https://agent-browser.dev/security)）；`--confirm-actions` 是可选的、针对它自己动作的确认门。它是一个通用点击工具——会不会点 Muse 审批卡，取决于调用方脚本让它点什么，工具本身不对审批卡做特殊处理。**未发现自动通过 Sentinel 审批卡的代码或文档；同样未发现“禁止点击审批卡”的保护。**
- **PinchTab**：README 与配置文档中未找到审批相关口径；同为通用桥接器，结论与 agent-browser 相同——**未发现自动通过审批的证据，也未发现防误点的保护**。
- **官方依据**：
- [ai.meta.com/muse](https://ai.meta.com/muse/) FAQ（2026-11-12 爬取）：“Muse is designed to ask your permission before taking certain actions, like sending messages, making purchases, or sharing information…”——确认 Muse 会在特定操作前征求许可。
- [about.fb.com 介绍文章](https://about.fb.com/news/2026/09/introducing-muse-personal-ai-agent/)（发布 2026-09-08）：“A separate Sentinel agent runs on that same machine… Nothing Muse does reaches the internet unless the Sentinel approves it, and it asks the person for permission when needed.”
- **两处官方资料均未提及第三方浏览器自动化是否允许或禁止；Meta 服务条款全文未在本任务逐条核对。浏览器自动化是否违反 Muse 平台权限或自动化限制：未验证，不得自行推定合规或违规。**
- Muse-Chat-MCP 自带免责声明（README [Disclaimer](https://github.com/duclm1x1/Muse-Chat-MCP#disclaimer)）：“This is an **unofficial, unaffiliated** tool… respect Muse's / Meta's Terms of Service and your local laws.”——作者自己也把合规责任交给使用者。
- **额外风险（推断，非官方依据）**：本 PoC 的实质是总控 VM 操作 node-3 账号的实时登录会话（跨账号会话操作），且审批卡出现时仍需真人点“允许”——若无人值守，流程会在审批处停住，这正是 `needsApproval` 要区分出来的状态。P1 前须由 Chen 明确这是否可接受。

---

## 5. 总控 VM 可行性（只从文档推断，不实测）

| 候选 | 需要的环境 | P1 若要装，缺什么／能否隔离 |
|---|---|---|
| Muse-Chat-MCP | Node.js ≥ 18（实测 v24）；已安装的 Google Chrome 或 Edge；`npm install` 只拉 `playwright-core`（库，不下载浏览器）；持久化目录 `.muse-profile/`（会话） | 缺：总控 VM 上需有 Node ≥ 18 与 Chrome；首次登录需一个能打开的 Chrome 窗口（或已登录 Chrome 的 CDP 附加）。可隔离在试验目录：仓库本身就是一组 `.mjs` 脚本＋`node_modules`，不改总控主环境；profile 目录可放在试验目录内。**未验证**：无显示器的 VM 上首次登录是否可行（README 只写了“打开 Chrome 窗口登录”） |
| agent-browser | `npm install -g agent-browser`（或 Homebrew）；`agent-browser install` 下载 Chrome for Testing；Linux 上 `--with-deps` 装系统库；每 session 一个守护进程＋浏览器 | 缺：npm 包＋下载的 Chrome for Testing＋系统库。可隔离：二进制与浏览器都可放在试验目录／用户目录；但 `--with-deps` 的系统库安装会动系统包，需确认总控 VM 权限 |
| PinchTab | 单 Go 二进制（约 30MB）＋本地已装 Chrome／Chromium；配置文件 `~/.pinchtab/config.json`（含 server.token）＋状态目录 | 缺：二进制＋Chrome。隔离性最好：单文件＋配置文件，试验目录即可；但 server.token 的保管与轮换要另外定规矩 |

**小结**：三者都能隔离在试验目录、不必改总控主环境；Muse-Chat-MCP 依赖最少（Node＋现成 Chrome），PinchTab 次之（单二进制＋Chrome），agent-browser 要多下载一套 Chrome for Testing 与系统库。

---

## 6. 候选排序

**首选：Muse-Chat-MCP。**

理由：它是三者中唯一为 Muse（muse.ai／Hatch）写的桥接器——登录状态、会话、回复读取、四态返回都是针对 muse.ai 页面结构实现的（`needsApproval` 直接对应页面上的 `[data-hatch-composer-approval-stack]`），`NODE3_OK` 的判定规则可以直接落在返回字段上，不用再写一层 DOM 猜测；登录不复制任何秘密；默认只绑 loopback；依赖只有一个 `playwright-core`，试验成本最低。

**暂不选 agent-browser**：维护性与社区规模最好，但它是通用浏览器自动化——对 Muse 没有任何专属理解，四态区分、审批卡检测、回复读取都要从零写脚本；还要另下一套 Chrome for Testing。它是“最稳的通用工具”，不是“最短的 Muse 路径”。若首选在 P1 实测中被证伪（例如 muse.ai 页面结构变化导致选择器失效），agent-browser 是第一备用。

**暂不选 PinchTab**：同样通用、无 Muse 专属状态，且比 agent-browser 多两项负担——新增一个需保管的 server token，以及一个常驻 HTTP 服务＋dashboard 的攻击面；社区与发布节奏也不如 agent-browser。不要同时安装三套：三套并存只会让登录会话、端口与 token 的管理复杂度 triple，而 P0 已证明一條路就够。

---

## 7. P0 结论与 P1 前置

### P0 结论：有条件通过

- 通过的部分：存在一条可信的只读验证过的路径（Muse-Chat-MCP），四态可区分、登录不复制秘密、默认 loopback、无自动通过审批的代码。
- “有条件”：该结论只覆盖 P0 只读核验本身；P1 的安装、登录与实测均未批准、未验证；合规性（是否违反平台限制）未验证。

### P1 精确前置（缺一不可）

1. **批准**：Chen 另行批准 P1（安装、登录、实测）。本次批准（2026-11-13 01:32）仅限 P0 只读核验，未批准安装、登录、P1 或任何生产切换。
2. **登录（是，需要用户在总控 VM 上登录 node-3 账号）**：Muse-Chat-MCP 不提供账号密码登录。P1 必须有人在总控 VM 上打开 Chrome、用 **node-3 的 Meta 账号**在 `https://muse.ai` 完成一次真实浏览器登录（或把已登录 node-3 账号的 Chrome 以 `--remote-debugging-port=9222` 挂给它），会话存进专用 profile 后才能复用。谁去登、登哪个账号，需 Chen 明确。
3. **环境**：总控 VM 装 Node.js ≥ 18 与 Google Chrome；仓库放在隔离试验目录，不动总控主环境与现有 Hook／巡逻；先确认无显示器 VM 上首次登录的做法（未验证项）。
4. **判定规则**：把 `NODE3_OK` 写成对返回字段的映射——`reply` 非空且无 `error`／`timedOut`／`needsApproval` 为完成；`timedOut: true` 为超时；`needsApproval: true` 为需审批（停住等真人点）；`loggedIn: false` 为登录失效。审批出现时不得代点。
5. **合规确认**：核对 Meta 服务条款中关于自动化／第三方客户端的条款，确认总控 VM 操作 node-3 实时会话的做法可接受；在未确认前，P1 只做最小范围试验（总控＋node-3，不触 node-1／node-2／node-4），GitHub、BOARD、Hook、Control Tower 全部保留作备用。
6. **秘密管理**：P1 不产生新秘密（Muse-Chat-MCP 无 token）；若后续改用 PinchTab，需另立 server.token 保管与轮换规矩。

### 阻断点（若其中任何一项成立，P0 即不通过／P1 不得启动）

- 本次核验未发现 P0 级别的阻断点。
- P1 级别的潜在阻断点：Chen 不批准 P1；无人能在总控 VM 上完成 node-3 账号登录；服务条款核对结果为禁止此类自动化；无显示器 VM 上无法完成首次登录。

### 是否建议进 P1：建议进，但只进小范围试验

理由：P0 已验证首选路径的四个关键点（专用性、四态真实返回、不复制秘密、默认 loopback），且试验成本低、可隔离、可回退（GitHub 备用链路不动）。但合规性未验证、仓库本身维护风险高（单作者、6 周无更新），所以 P1 应限定为“总控 VM 上的一次性登录＋最小发送／读取试验”，先验证登录与四态在真实环境成立，再谈任何常态化；同时把 agent-browser 列为第一备用。

---

## 事实与推断区分

- **事实**：上表全部仓库元数据、版本、许可证、依赖、代码行引用、官方 FAQ 原文，均有来源链接，核验日期 2026-11-13。
- **推断**：agent-browser／PinchTab“需自定义脚本层实现四态区分”（基于其文档无相关字段的判断，未逐行审计其全部源码）；“无显示器 VM 首次登录可行性未验证”；“跨账号会话操作需 Chen 明确是否可接受”。
- **未验证**：浏览器自动化是否违反 Muse 平台权限或自动化限制；agent-browser 与 PinchTab 全部源码中是否存在审批相关逻辑（只读了 README 与文档站，未逐行审计）；PinchTab main 分支与 v0.15.2 release 之间的具体差异。

## 参考

- 计划背景：Chen 2026-11-13 01:30 计划 v1《Muse 总控直控 node-3：低额度浏览器自动化实施计划》；Chen 2026-11-13 01:32 批准仅派 P0 只读核验。
- 前置报告：`results/node-1/T-011-ai-agent-group-chat-comparison.md`（群聊产品对比；本 PoC 是另一条直控通道，不替代 Pachat／GitHub 链路）；T-008／T-009 关于 600 秒超时与唤醒 fire-and-forget 的结论（本任务在预算内完成，单次推送交付）。
- Hub 规则：`RULES.md` R5（公开库脱敏红线）、R7（交付）、R16（shell 推送）；`docs/checkpoint-spec.md`（checkpoint seq 1 已写，见 `~/hooks/state/task-runtime/tasks/T-017/attempt-0001/checkpoint/`）。
- 研究笔记：`~/hooks/state/task-runtime/tasks/T-017/attempt-0001/checkpoint/artifacts/phase-01-notes.md`（SHA-256 见 checkpoint.json）。

---

T-017 P0 只读核验完成：首选 Muse-Chat-MCP，P0 有条件通过，建议进 P1 小范围试验（需 Chen 另批＋总控 VM 上 node-3 账号登录＋条款确认）。
