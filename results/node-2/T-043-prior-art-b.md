# T-043 同类项目调研——角度 B：人机审批闸门＋浏览器桥接

- 任务：T-043（角度 B），负责人 node-2
- 派发：Chen 2026-11-16 18:34 直令
- 调研时间：2026-11-16 18:34–19:00 CST
- 方法：GitHub Search API（6 组查询：`human in the loop agent`、`agent approval gate`、`chat2api`、`playwright mcp`、`approval card automation`、`webhook retry delivery`）＋ 8 个仓库直接核对 ＋ 7 份 README 原文核对；stars 与最近提交日期均为 2026-11-16 实测 API 返回值，最近提交日期取 `pushed_at`（UTC 日期）
- 边界：只调研；未 clone 大仓库、未装包、未跑浏览器自动化测试

方向 3（`approval card`／`permission prompt automation`／`click approval`）空结果：GitHub 搜索只命中信用卡审批 ML 项目，与“点审批卡”无关——“读卡并程序化点批”在开源里没有成类的仓库，它是产品 UI 层面的做法，不是开源项目形态。另：webhook 重试方向除 Svix 外只剩几十 star 的小项目（sparrow 52、Relay 33 等），未单独成块。

## humanlayer/humanlayer | https://github.com/humanlayer/humanlayer | stars 12891 | 最近提交 2026-11-16

是什么：跑编码 agent（Claude Code、Codex、OpenCode、Pi）的团队控制台——任务、会话、计划、评审在桌面端／网页端／宿主 daemon 间同步，配插件把 agent 会话镜像进来供人督导。
与我们重合：人督导 agent 会话、评审（review）环节是审批闸门的一种；面向编码 agent。
我们没有：它有现成的多端同步控制台与会话镜像插件，评审发生在它自己的界面里。
我们独有：我们的审批发生在第三方聊天界面里、没有 API，只能靠 CDP 读 DOM 卡并点批；它没有这种“在别人 UI 上操作”的桥，也没有跨账号的 GitHub 仓库总线。
可复用程度：中——评审／督导的产品形态可作参照，但它现在是一整套平台（daemon＋应用），不是能嵌进来的库。

## langchain-ai/langgraph | https://github.com/langchain-ai/langgraph | stars 45022 | 最近提交 2026-11-16

是什么：构建有韧性 agent 的图框架，核心机制之一是人机回路：`interrupt()` 让图执行在指定点暂停、持久化状态，人给输入后再 resume。
与我们重合：审批闸门＝“执行暂停等人拍板”的机制，与我们“操作先弹卡、批了才执行”是同一类闸门语义。
我们没有：它有成体系的暂停／恢复／持久化状态机，以及围绕中断的工具链。
我们独有：我们的闸门不在自己的执行图里，而在厂商聊天界面的审批卡上；暂停靠 CDP 读卡，恢复靠点批，执行图不在我们手里。另有 fingerprint 审计（哪张卡、谁批的、可复核），它没有。
可复用程度：中——“暂停＋持久化＋恢复”的模式可直接借鉴到我们的审批状态机设计，但框架本身不能直接套到 CDP 桥上。

## openai/openai-agents-python | https://github.com/openai/openai-agents-python | stars 30708 | 最近提交 2026-11-16

是什么：OpenAI 的多 agent 工作流 SDK（轻量），核心概念含 guardrails（输入输出安全检查）与 human-in-the-loop（工具调用审批）。
与我们重合：工具调用先过审批才执行，与我们审批卡的语义一致；guardrails 是审批之外的另一层检查。
我们没有：它有 SDK 内原生的审批钩子与 guardrails 体系，开箱即用。
我们独有：我们的审批对象不是自己 SDK 里的工具调用，而是厂商聊天界面里弹出的卡；guardrails 式的事前检查在我们这里不存在，审计靠 fingerprint。
可复用程度：低——它是“在自己框架里造 agent 才有闸门”的方案；我们的 agent 跑在别人界面里，只能借鉴“审批分层”（工具审批＋guardrails）的思路。

## Tencent/LoopForge | https://github.com/Tencent/LoopForge | stars 2100 | 最近提交 2026-11-16

是什么：自托管的编码 agent 交付工作流：编排 CodeBuddy、Codex、Claude Code 在沙箱工作区里干活，跑可重复的 SOP，最终“approve what ships”——人工审批才放行。
与我们重合：是最接近我们的产品形态——编码 agent＋人工审批闸门＋交付流程。
我们没有：它有 SOP（可重复流程）与沙箱工作区编排，审批是交付流程里的一环。
我们独有：它编排的是有 API／CLI 的 agent，我们桥接的是没有 API 的聊天界面；它没有 CDP 读卡点批，也没有跨账号仓库总线与 fingerprint 审计。
可复用程度：中——“SOP＋审批放行”的流程设计最值得抄，但它是自托管平台，不是桥。

## lanqian528/chat2api | https://github.com/lanqian528/chat2api | stars 3840 | 最近提交 2025-05-17

是什么：把网页版 ChatGPT 转成 OpenAI API 格式的代理服务，走逆向 API（用 AccessToken／RefreshToken 调网页端后端接口），输出与真实 API 一致，多账号轮询、失败重试。
与我们重合：“把网页聊天变成 API”是同一目标；重试＋轮询的容错思路相通。
我们没有：它有现成的逆向接口封装与多账号轮询。
我们独有：它调的是网页端后端接口（逆向 API），我们是 CDP 驱动浏览器界面读 DOM、点真实的卡——它不处理界面里的审批卡，也没有审批语义。
可复用程度：中——“网页服务→标准 API 垫片”的形态可借鉴；但逆向接口依赖 AccessToken 且与账号强绑定，不适用于我们的审批卡场景。

## xiaoY233/Chat2API | https://github.com/xiaoY233/Chat2API | stars 1746 | 最近提交 2026-05-28

是什么：Electron 桌面应用，把 DeepSeek、GLM、Kimi、MiniMax、Qwen、Z.ai 等多家官方网页 UI 统一成 OpenAI 兼容 API，零成本走网页端。
与我们重合：同样是“借官方网页 UI，用出 API”的桥。
我们没有：它有多家厂商网页端的统一封装与桌面端形态。
我们独有：它是模型调用桥，不处理审批卡；我们桥的是审批动作本身（读卡＋点批＋审计），且跑在服务端而非桌面应用里。
可复用程度：低——多厂商垫片思路可参考，但 Electron 桌面形态与我们的服务端桥不匹配。

## miuuyy/codex-chatgpt-web | https://github.com/miuuyy/codex-chatgpt-web | stars 15747 | 最近提交 2026-11-12

是什么：把账号里的 ChatGPT 网页版模型（含 Pro）接进 Codex 的原生模型选择器，消息走已登录的网页会话，附桌面端安装包与架构文档。
与我们重合：桥接形态最接近我们——已登录网页会话→程序化调用，复用账号现成权益而不走官方 API。
我们没有：它有现成的会话保持与网页模型接入架构（含桌面端分发）。
我们独有：它桥的是模型调用，我们桥的是审批卡点击＋审计；它不处理“界面里弹卡等人批”的流程，也没有多账号协作总线。
可复用程度：中——会话保持与“网页会话程序化”的架构最值得读，但它是模型接入不是审批，形态是桌面应用。

## browser-use/browser-use | https://github.com/browser-use/browser-use | stars 121167 | 最近提交 2026-11-16

是什么：AI 浏览器 agent 的 Python 库（附云服务）：LLM 看 DOM、驱动浏览器完成任务，含反检测浏览器。
与我们重合：底层同样是“LLM／程序读 DOM、操作浏览器”，我们的 detector（DOM 判空容器 vs 真有卡）就是这种思路的窄化版。
我们没有：它有通用的 DOM 观察、动作规划与反检测能力。
我们独有：我们只做一个界面的一个动作（读卡＋点批），且审批语义与审计在桥之外；它是通用 agent 框架，不含审批闸门。
可复用程度：中——DOM 观察与鲁棒性做法可用来加固我们的 detector，但通用框架比我们的窄桥重得多。

## microsoft/playwright-mcp | https://github.com/microsoft/playwright-mcp | stars 39718 | 最近提交 2026-11-15

是什么：Playwright 的 MCP 服务器，把浏览器操作（导航、点击、填表、读内容）暴露成 MCP 工具，供 agent 调用。
与我们重合：都是“把浏览器操作变成程序可调的接口”。
我们没有：它有标准化的浏览器工具集与 MCP 协议接入。
我们独有：我们直接走 CDP 读卡点批，不经过 MCP；我们的审批卡检测（空容器 vs 真卡）是针对单一界面的专用逻辑，它没有。
可复用程度：中——“浏览器操作工具化”的接口形态值得借鉴，但 MCP 层对我们是多余的，直接 CDP 更轻。

## browserbase/stagehand | https://github.com/browserbase/stagehand | stars 26068 | 最近提交 2026-11-14

是什么：与任意网站交互、抽取数据的 SDK（配 Claude Code、Codex 等使用），面向开放网页。
与我们重合：同样是程序化操作网页。
我们没有：它有通用的页面交互与数据抽取能力。
我们独有：它面向开放网页的通用交互，不针对固定聊天界面、不含审批闸门与审计。
可复用程度：低——通用网页交互 SDK，与“固定界面＋审批卡”这个窄问题不匹配。

## svix/svix-webhooks | https://github.com/svix/svix-webhooks | stars 3481 | 最近提交 2026-11-13

是什么：开源＋企业级的 webhook 服务：一次 API 调用，平台负责可达性、重试、安全等；含持久化投递、指数退避、死信处理、幂等与投递追踪。
与我们重合：投递保障机制正是我们 hook 唤醒 20 分钟级延迟缺的那块——重试、死信、幂等、投递追踪。
我们没有：它有成体系的投递保障（持久队列＋退避＋死信＋幂等键）。
我们独有：我们的 hook 唤醒是“叫醒一个 agent 去干活”，不是 webhook 投递；投递保障思路可移植，但场景不同。
可复用程度：高——重试／死信／幂等的模式可直接移植到 hook 唤醒投递上，是这批里最能直接抄的；但它是个服务形态，不是能原样嵌进来的库。

## 重点回答：开源里有没有成体系的“审批闸门”方案？我们是不是在重复造轮子？

有，但只在“自己的执行体里”成体系：LangGraph 的 interrupt、OpenAI Agents SDK 的工具审批＋guardrails、HumanLayer 的评审控制台、LoopForge 的审批放行，都是“agent 跑在自己代码里、闸门是执行中的暂停点”。
我们的 director_override＋fingerprint 审计不是重复造轮子：那些方案都假设 agent 与闸门在同一侧，而我们的 agent 跑在厂商聊天界面里（无 API），闸门是界面上的一张卡，必须从外面用 CDP 读卡、点批，并用 fingerprint 证明“哪张卡、谁批的”——这一层开源里没有现成方案（方向 3 搜索为空即是证据）。

[node-2]
