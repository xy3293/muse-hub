# T-046：CDP 桥层的鲁棒性（借 browser-use / playwright-mcp 的做法）

- Issue：#44
- 执行：Codex；复核：Antigravity；验收：总控
- 工作区：桥源码 `~/workspace/node3-browser-poc/muse-chat-mcp-test/source/`（`muse-driver.mjs` 是 detector 所在文件；`muse-server.mjs` 是服务入口）

## 先说清：借的是什么模式，为什么不换库

借的是 **browser-use / playwright-mcp 的 DOM 判定做法**，不是这两个库本身：
1. 多信号判定：不只判容器存在，同时判"有审批按钮 + 按钮可见 + 在输入框可视区域内"三个条件；
2. 状态轮询 + 变化检测：DOM 变化用 MutationObserver 或定时快照 diff，不用一次性判断；
3. 失败要能自愈：检测到"发送被暂停但无卡"这种矛盾态时，自动 reload 页面并重试一次，记录发生了自愈；
4. 误判留痕：每次判定记录命中了哪几个信号，便于事后分析。

为什么不换库（不引入 playwright-mcp / browser-use）：
- playwright-mcp 是 MCP 服务器形态，引入等于多一层 MCP；我们的桥直接走 CDP 更轻，MCP 是多余层。
- browser-use 是通用 agent 框架（LLM 看 DOM、规划动作），比我们的窄桥重得多；我们只做一个界面的一个动作（读卡＋点批）。
- 所以：借它们的"做法"（多信号、轮询 diff、自愈、留痕），代码留在 `muse-driver.mjs` 里，不引入新依赖、不换桥的形态。

## 现状问题

我们手写 detector 判"空容器 vs 真有卡"，已经踩过两次：
- 假阳性卡 243 秒（容器在但无真卡，误判为有卡）；
- 分享卡不在 `[data-hatch-composer-approval-stack]` 容器里（容器判空，但卡真实存在，导致发送被拦到超时）。
- 现有代码（`muse-driver.mjs:45` 的 `approvalStack` 选择器、`muse-driver.mjs:271` 与 `:833` 的 `count() > 0` 判断）是单信号：只判容器存在。

## 要做的事

1. 多信号判定（改 `muse-driver.mjs` 的 needsApproval 判定）：
   - 信号 A：审批栈容器存在（现有选择器保留）；
   - 信号 B：容器内有审批按钮（例如"允许一次 / 总是允许"类按钮，以实际 DOM 为准，Codex 先读页面结构再定选择器）；
   - 信号 C：按钮可见（bounding box 非零、非 `display:none` / `visibility:hidden`）且在输入框可视区域内；
   - 判定规则：A + B + C 全命中才判"有真卡"；只命中 A（容器在、无按钮）判"空容器"；A 不命中但发送被暂停判"疑似分享卡"（见第 3 条的自愈与第 4 条的留痕）。
   - 保留对分享卡的检测：分享卡不在 approval-stack 容器里——要单独处理（例如检测分享卡特有的 DOM 特征，或把"发送被暂停但无 approval-stack 卡"本身当作一个信号）。
2. 状态轮询 + 变化检测：
   - 不要一次性判断；用定时快照 diff（或 MutationObserver）观察 DOM 变化，等状态稳定后再下结论（例如连续两次快照一致才采信）；
   - 给判定加一个短超时（例如 2–3 秒内等稳定，超时则按当时快照判并记一笔"未稳定"）。
3. 失败自愈：
   - 检测到矛盾态（"发送被暂停但无卡"）时，自动 reload 页面并重试一次；
   - 记录发生了自愈（时间、原因、重试结果），写进日志（不要静默 reload）。
4. 误判留痕：
   - 每次判定记录命中了哪几个信号（A/B/C 各自 true/false、快照摘要），写进日志（`send_log.json` 同级或 detector 专用日志文件，二选一并在 REPORT 里写清）；
   - 便于事后分析误判。
5. 保持接口不变：`GET /v1/muse/approvals` 返回的卡结构、`needsApproval` 字段语义不动；只改内部判定。

## 验收（Codex 自己先跑，Antigravity 复核，总控终验）

构造三种场景，三种都要判对，并贴判定依据（命中了哪几个信号）：
1. 真有审批卡（approval-stack 容器 + 按钮 + 可见）→ 判"有卡"；
2. 空容器（容器在、无按钮）→ 判"无卡"；
3. 分享卡（不在 approval-stack 容器里，但真实存在）→ 判"有卡"（或至少判"疑似有卡"并触发自愈/留痕，不许判"无卡"后静默）。

证据：三种场景的判定日志（信号 A/B/C 各自结果 + 结论）贴进 `evidence/T-046-bridge-robustness/REPORT.md`（muse-hub），并把改动后的 `muse-driver.mjs` 相关行号列出来。
- 若本地无法复现三种真实 DOM 场景，允许用 fixture / 模拟页面构造，但必须在 REPORT 里写清"哪种是真实 DOM、哪种是模拟"，不许把模拟写成实测。

## 边界

- 不换仓库总线；不引入常驻新服务；不改 RULES.md。
- **部署注意**：改的是桥源码的本地副本；三台 live 桥跑在 Chen 的 PC 上，Codex 不要尝试往 Chen 的 PC 上部署。部署由总控另行与 Chen 协调；任务书里写清"本地改完、待部署"。
- 不碰 Chen 的 PC、不改 ACL、不动 Tailscale。
- 只改 detector 判定逻辑，不重构整个 bridge server。

## 本地执行状态（Codex，2026-11-16）

- 本地改完、待部署；未连接或修改 Chen 的 PC。部署由总控另行与 Chen 协调。
- 四项 detector 改动已实现；本地 Chromium 模拟三种 DOM 场景均判对，另覆盖可见性、变化检测、自愈及完整发送路径。
- 证据与复跑方法：[REPORT.md](../evidence/T-046-bridge-robustness/REPORT.md)。等待 Antigravity 复核、总控终验；真实页面 DOM 与在线回声仍待部署环境核验。
