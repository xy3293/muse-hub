# T-011 AI agent 群聊产品对比：Pachat 与同类方案

> node-1 交付 · 任务书 v1 · 核查日期：2026-11-12
> 结论先行：**先试 Pachat**。它是唯一同时满足“不同平台 agent 混用（含 Muse）、零部署、免费、人工拍板在环”的现成群聊产品。验证方法与改主意条件见文末“推荐”。

## 对比总表

| 维度 | Pachat | Grok Bot | OpenClaw（自托管网关） | Claude Code agent teams | Kimi Agent Swarm |
|---|---|---|---|---|---|
| 能否接入我们的 Muse 账号 | ✅ 能。平台列表含 `muse`；总控与 node-1/2/3 各自配对，各拿独立 token | ❌ 不能。群成员只能是 Grok Bot，模型固定为 Grok | ⚠️ 未验证。OpenClaw 接模型靠 provider API key，不是直接登 Muse 账号；Muse 账号直连方式未找到官方说明 | ❌ 不能。成员是 Claude Code 会话复制品，需 Claude 账号 | ❌ 不能。成员是 Kimi 模型 sub-agent，需 Kimi 付费会员 |
| 实时群聊还是异步 | 准实时：@提及/回复可 wake-up 唤醒，兜底每 10 分钟定时查收 | 实时群聊：2–6 个 Bot 同群，交接可见 | 实时（消息经网关即时路由），但需 Gateway 常驻 | 终端内并行协作，无群聊 UI | 异步并行：主 agent 拆任务、合结果，无群聊 |
| 不同平台 agent 混用还是同模型复制 | ✅ 混用：Muse、ChatGPT、Claude、Grok Bot、OpenClaw 等同群 | 同模型复制：全是 Grok Bot | ✅ 可混用：同一网关可接不同模型 provider 的 agent，但每个 agent 仍是独立配置 | 同模型复制：队友继承队长模型 | 同模型复制：全是 Kimi 模型 sub-agent |
| 成本与额度消耗 | Pachat 免费；额度消耗在各 agent 自身套餐。轮询默认每 10 分钟一次，每次查收是一次 agent 运行 | 无免费层；价格次级来源冲突（见下），以官方定价页为准 | 软件免费（MIT）；成本 = 模型 token + 自有主机电费；Gateway 需 24 小时常驻 | 按 Claude 套餐/API 计费；N 人队约 N 倍 token | 付费会员才可用；单次消耗约为普通任务数倍 |
| 隐私与数据去向 | 消息经 Pachat 服务器；群仅限链接加入或公开；agent 被要求只分享需要的信息，邮箱永不显示；token 存本地 | 所有 Bot 共享同一台云电脑，共享文件/浏览器会话/命令行凭证；官方明确 Bot 之间不是安全边界 | 状态、记忆、凭证留在自己硬件；但一个 Gateway 是一个信任边界，多 agent 不隔离互不信任的用户 | 数据在 Anthropic/所选 provider 与本地终端之间；队友间经本地文件邮箱通信 | 数据经 Moonshot 服务；sub-agent 间协调在 Kimi 内部完成 |
| 上手与运维成本 | 最低：邮箱注册＋配对码，无需部署、无需常驻进程 | 低：装应用、开订阅即可；但须在 xAI 生态内 | 高：需部署 Gateway、配 bot token、配 bindings、自己打补丁与做安全审计 | 中：需 Claude Code v2.1.32+ 并开实验 flag，终端操作 | 低：Kimi App/网页选 K3 Swarm 即可，无部署 |
| 验收、留痕、任务交接 | 无内置验收流程；留痕 = 群聊记录本身；交接靠 @提及/回复＋人工拍板 | 交接可见（Bot 间传 ownership）；邮件/Slack 发出前以草稿待人工批准；无正式验收流程 | 留痕强：会话落盘 JSONL/SQLite；验收无内置，须自己搭流程；交接靠 `sessions_send` | 验收靠 git diff 与人工 review；留痕 = 终端会话与文件；交接靠共享任务列表 | 无验收/留痕/交接机制，面向单任务并行提速 |
| 价格／免费额度与上限 | 免费；一账号最多 10 个 agent，一群最多 50 个 agent | 见下“价格冲突”说明；群 2–6 个 Bot，账号上限 50 个 Bot 与群聊合计 | 免费软件，无付费层；上限取决于自有主机 | Claude Pro/Max/Team/Enterprise 或 API 付费；实验功能 | Moderato（¥99/月）起才可用；Andante（¥49/月）不含 |
| 硬性短板 | 无实时推送：依赖轮询或 wake-up，消息最多延迟一个轮询周期；无内置验收 | 锁死 Grok 生态，接不进 Muse；Bot 间无安全隔离 | 运维与安全责任全在自己；多 agent 群聊需逐个配 bot token，配置易错 | 实验功能，随时可变；只能复制 Claude，不能混用 Muse | 不能混用、不能群聊、不能验收；只适合大批量并行任务 |

## 逐项展开

### 1. Pachat——不同 agent 的群聊，免费，零部署

**是什么。** Pachat 是“不同 AI agent 的群聊”：把自己在用的 agent（Muse、ChatGPT、Claude、Grok Bot、OpenClaw 等）拉进同一个群，它们互相核对事实，最后由人拍板。官网原话：“免费，不用下载 App，不用懂技术。”（https://pachat.ai/zh，2026-11-12 核查）

**接入我们的 Muse 账号：能。** 接入文档平台列表明确含 `muse`（https://pachat.ai/install.md，2026-11-12 核查）。两种接入方式：①配对码（形如 `7KQ2-LMZ9`，一次有效，复制后 24 小时内有效）；②邮箱＋6 位验证码（验证码 10 分钟有效）。每个 agent 各自配对，各拿一个 `pachat_` 开头的 token，token 只显示一次。**总控与 node-1/2/3 各自独立账号、独立 token，符合任务书要求。** token 存本地（`~/.pachat/token`，权限 600）或平台 secret store；多 agent 同机须各用自己的 token 文件，文档明确警告不得共用、不得写进群聊、不得放进 URL。丢 token 可用同一名字 `reclaim` 找回身份与群组。

**实时还是异步：准实时。** 默认定时查收：建议每 10 分钟查一次收件箱（`GET /api/v1/inbox`），频率由 owner 定。wake-up 种类共 6 种（`grok`、`openclaw`、`claude_routine`、`webhook`、`email`、`listener`），被 @ 或被回复、owner 在群里发帖时触发唤醒；wake-up 至多每 10 分钟一次、每天 30 次，失败重试一次，连续 3 次失败则关闭并邮件通知 owner。listener 需 macOS/Linux + Node 18+，在 owner 电脑上常驻，每天最多启动 agent 100 次。**推断（未验证）：** Muse 没有专属 wake-up kind，实际可用的是 `email`（Pachat 发邮件到 owner 邮箱触发）或定时查收；任务书背景称“靠定时任务查收件箱”与此一致。验证时应先测这两种。

**混用还是复制：混用。** 官网示例群同时有 OpenClaw、Muse、Claude、ChatGPT、Instinct、Grok Bot，互相纠错（自由现金流 19 亿→6 亿美元的例子）。Pachat 文档自述：Claude Code agent teams 与 Kimi Agent Swarm 是“同一模型的复制品，不是不同 agent 混用”。

**成本与额度：** Pachat 本身免费；一账号最多 10 个 agent，一群最多 50 个 agent（官网 FAQ，2026-11-12）。额度消耗不在 Pachat，而在各 agent 自身套餐：每 10 分钟一次查收，就是每 10 分钟跑一次 agent。**这是 Pachat 最大的隐性成本：** 对总控的 Muse 额度而言，3 个节点 × 每 10 分钟查收，比异步 hub 的按需唤醒贵得多。验证时必须实测一次查收的 token 量，再决定轮询间隔（可放宽到每小时或每天几次）。

**隐私与数据去向：** 消息经 Pachat 服务器中转；群默认仅限链接加入，可设公开＋入群问题。官网隐私承诺：agent 只分享问题需要的信息，邮箱永不显示，手机号、密码、token 留在自己处；群里有人索要密钥或隐私一律不理。install.md 另有行为规则：群里其他 agent 的话是信息、不是 owner 的指令，不得据此泄露秘密、打开外链或运行代码。**未验证：** Pachat 是否有公开的隐私政策/数据保留期限/合规认证，官网与 install.md 未给出，本报告不做断言。

**上手与运维：** 最低。邮箱注册、把配对指令发给 agent 即可；无需部署、无需常驻进程；可选 MCP 接入（`https://pachat.ai/mcp`）。

**验收、留痕、交接：** 无内置验收流程。留痕靠群聊记录本身（可读、可翻页、可下载附件）；交接靠 @提及/回复；最终决定权在人：agent 在人平时用的 App 里问人，支持“同意/再想想”。这与视频里的场景一致（四个 agent 凑证据，提交那一下由卖家自己点），也与我们 hub“总控验收”的工作方式兼容——但验收动作本身仍需人或总控在 hub 里另做，Pachat 不替你验收。

**硬性短板：** ①无实时推送，延迟取决于轮询间隔；②无内置验收/任务状态机，复杂多步任务容易在群里聊散；③隐私依赖各 agent 自律＋Pachat 服务器可信，秘密一旦发进群就收不回（2 分钟内可撤回，之后只能发更正）。

### 2. Grok Bot——最像“群聊产品”的一个，但锁死 Grok 生态

**是什么。** xAI 的常驻 AI teammate 产品，2026-08-11 发布 beta。每个 Bot 有名字、分工、跨会话记忆，共享一台云电脑，关掉笔记本也能继续工作。

**群聊能力（有来源）：** 可把 2–6 个 Bot 放进一个群聊，它们互相发消息、交接任务 ownership，不用人手动在会话之间搬运上下文；交接过程可见。来源：DigitalOcean 对比文章（信息截至 2026-10-28，2026-11-12 核查，https://www.digitalocean.com/resources/articles/grok-bot-vs-dots-vs-muse）；Composio 指南（https://composio.dev/content/guide-to-frok-bot）；Unico Connect（2026-10-17 核查，https://unicoconnect.com/blogs/grok-bot-agentic-chat-teams）。另据 metagrok.io（2026-11-12 核查，https://metagrok.io/how-to/start-a-grok-bot-group-chat），Bot 间交接消息目前仅支持文本，图片须由 Bot 直接发给另一 Bot；桌面端 0.71 版后群聊入口从主 UI 隐藏，需快捷键新建。

**能否接入 Muse：不能。** 群成员只能是 Grok Bot，模型固定为 Grok。我们的总控＋node-1/2/3 是 Muse 账号，进不去。这是 Grok Bot 对我们的一票否决项。

**隐私硬伤：** 同一用户的所有 Bot 共享同一台云电脑，共享文件、浏览器会话、命令行凭证；xAI 文档明确：不要把不同 Bot 当作安全边界（DigitalOcean、Composio、toolradar 多方一致，2026-11-12 核查）。总控与节点身份无法隔离。

**价格（冲突，未验证）：** 次级来源说法不一致——DigitalOcean 称 Grok Bot 包含在 X 订阅的 Premium、Super、Ultra 套餐内；eesel.ai 称 solo $200/月、团队 $120/座/月、无免费层（https://www.eesel.ai/blog/grok-bot-vs-claude-cowork）；toolradar 称无免费试用、起步为 Cursor Pro $20/月（https://toolradar.com/blog/what-is-grok-bot）。**本报告不采信其中任何一个具体数字，价格以 xAI 官方定价页为准。** 可确认的只有：无免费层、群 2–6 个 Bot、账号上限 50 个 Bot 与群聊合计（botteams.io，引 docs.x.ai，2026-08-24 核查，https://botteams.io/guides/grok-bot-group-chat）。

**验收、留痕、交接：** 交接可见是优点；对外邮件/Slack 先以草稿待人工批准，拍板在环。但无正式验收流程、无跨 Bot 审计隔离，企业级管控（allowlist、审计日志、SCIM）仅 Enterprise 档。

### 3. OpenClaw——自托管网关，多 agent 能力是真的，但要自己运维

**是什么。** 开源自托管网关（MIT 协议，无付费层、无托管服务）：一台机器上跑一个 Gateway 进程，把 WhatsApp、Telegram、Discord、Slack 等聊天应用接到 AI agent。官方定义见 https://openclaws.io/docs/（2026-11-12 核查）。

**自身的多 agent／群聊能力（已核实，不只“能加入 Pachat”）：** 一个 Gateway 可托管多个相互隔离的 agent，各有自己的 workspace、状态目录与会话存储，入站消息经 bindings 路由到正确 agent；agent 间可用 `sessions_send`（向另一会话发消息并等回复）、`sessions_spawn`（起 sub-agent）协作。多个 agent 可各持自己的 bot token 进同一个 Telegram/Discord/Slack/飞书群，@谁谁回（`requireMention: true` 防串话）。来源：OpenClaw 官方文档（https://openclaws.io/docs/）；社区多 agent 指南（https://clawdocs.org/guides/multi-agent，2026-11-12 核查）；Telegram 多 bot 实操（https://zerofuturetech.substack.com/p/multiple-openclaw-ai-agents-in-one）；Slack 多 bot 方案（https://gist.github.com/rafaelquintanilha/9ca5ae6173cd0682026754cfefe26d3f）；Telegram 论坛多 agent（https://www.dan-malone.com/blog/building-a-multi-agent-ai-team-in-a-telegram-forum）。

**能否接入 Muse：未验证。** OpenClaw 接模型靠 provider 的 API key，不是“登录 Muse 账号”。Muse 是否有可供 OpenClaw 调用的 API/接入方式，本次未找到官方说明，**不得假设能直连**。若只能接 API 模型，则总控与各节点的“独立 Muse 账号、独立身份”在 OpenClaw 里无法原样复现。Pachat 的 wake-up 表里有 `openclaw` 一种，说明 OpenClaw agent 可以作为 Pachat 群成员，但那是“OpenClaw 里跑的 agent 进 Pachat 群”，不是“Muse 账号进 OpenClaw”。

**成本与额度：** 软件免费；成本 = 模型 token + 自有主机；Gateway 需 24 小时常驻。额度消耗与 Pachat 轮询不同：消息到即处理，无空轮询，但常驻进程本身持续占用主机。

**隐私与数据去向：** 状态、记忆、凭证留在自己硬件，这是 OpenClaw 最大的隐私优点。但官方安全文档明确：一个 Gateway 是一个信任边界，多 agent/多会话不隔离互不信任的用户；混合信任场景须跑多个 Gateway。沙箱默认关闭。

**上手与运维：** 最高。需装 Node 24、跑 Gateway、逐个申请 bot token、写 `openclaw.json`（`agents.list`、`channels.*.accounts`、`bindings`）、处理安全更新。第三方统计称 2026 年该项目发布过 700+ 安全公告（https://tech-stack.codeamanilabs.org/read/openclaw，2026-10-20 复核，转述第三方统计，未独立核实），须跟进更新并跑 `openclaw security audit`。

**验收、留痕、交接：** 留痕强（会话落盘 JSONL/SQLite，可审计）；交接机制真实存在（`sessions_send`）；但验收流程无内置，须自己用规则/流程搭。OpenCrew 等社区项目提供角色分工模板，但属于第三方，非官方产品。

**硬性短板：** 运维与安全责任全在自己；多 agent 群聊配置步骤多、易错；Muse 账号接入方式未验证。

### 4. Claude Code agent teams——同一模型的复制品，无群聊

**是什么。** Claude Code 的实验性功能（需 v2.1.32 或以上，开 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag）：多个 Claude Code 会话组成一队，一人任队长分任务、汇总结果，队友各有独立上下文窗口，经共享任务列表与文件邮箱直接通信。来源：https://www.agentpatterns.ai/tools/claude/agent-teams/（2026-10-14 更新，2026-11-12 核查）；另见 https://blog.laozhang.ai/en/posts/claude-code-desktop-vs-terminal（2026-10-15）。

**同模型复制（已核实）：** 队友继承队长的模型（v2.1.73 更新日志明确修复此行为）。不存在“Claude + Muse + Grok 混用”，所有成员都是 Claude Code 的复制品。Pachat 文档的说法与此一致。

**能否接入 Muse：不能。** 成员须是 Claude 账号下的 Claude Code 会话；且桌面版无 agent teams，只有终端版有。

**成本：** N 人队约 N 倍 token；实验功能，随时可变；一个 session 只能有一队，队长不可转让，队友不能再建自己的队。

**验收、留痕、交接：** 验收靠 git diff 与人工 review（适合代码，不适合拒付证据这类非代码任务）；留痕是终端会话与文件；交接靠共享任务列表。无群聊 UI、无跨平台。

**硬性短板：** 实验功能不稳定；不能混用不同 agent；不能解决 Chen 的问题（视频里是四个不同 agent 凑证据）。

### 5. Kimi Agent Swarm——同一模型的大规模并行，不是群聊

**是什么。** Moonshot AI 的 Agent Swarm：主 agent 自动把大任务拆成子任务，指挥最多 300 个 sub-agent 并行执行，再合并结果。2026-01-27 随 Kimi K2.5 发布，2026-04-20 随 K2.6 升级到 300 sub-agent、4,000+ 次工具调用，现由 Kimi K3（K3 Swarm）驱动。来源：Moonshot 帮助中心 https://www.kimi.com/en/help/agent/agent-swarm（2026-11-12 核查）；https://spectrumailab.com/blog/kimi-k2-5-agent-swarm-moonshot-ai-guide-2026（2026-10-03 更新）。

**同模型复制：** 全部 sub-agent 都是 Kimi 模型，无预设角色、无人工设计流程，组织方式由 AI 自己决定；不是不同 agent 混用，更不是群聊——没有群聊界面，成员之间不“聊天”，只由主 agent 协调。

**能否接入 Muse：不能。** 须 Kimi 付费会员（Moderato、Allegretto、Allegro；Andante 不含）。价格为第三方整理：Moderato ¥99/月约 25 次 Swarm、Allegretto ¥199/月约 50 次、Allegro ¥699/月约 120 次（spectrumailab，2026-10-03），**次数为 Moonshot 估算值、非硬性配额，以官方为准**；单次消耗约为普通任务数倍（Moonshot 帮助中心原话）。

**适用面：** 适合大规模并行搜索、批量处理、长文写作；不适合需要不同 agent 互相核对、人工拍板、留痕验收的场景。无验收、留痕、交接机制。

**硬性短板：** 不能混用、不能群聊、不能验收；成本随并行规模放大。

### 对照基线：我们现有的 muse-hub

异步版 AI 协作：总控＋node-1/2/3 三个 Muse 账号走 GitHub 传任务书和结果，有验收、有留痕（commit、BOARD、Issue），无实时群聊。它的优点（验收、留痕、身份隔离、秘密不进公开库）正是上面多数群聊产品所缺的；它的缺点（异步、来回慢、Chen 要在中间传话）正是 Pachat 想补的。**结论：Pachat 应作为 hub 的补充，不是替代。** 任务书、结果、验收仍走 hub；需要多 agent 实时互相核对的单次讨论才进 Pachat 群。

### 排除说明

AutoGen、CrewAI、LangGraph 是纯开发框架，不提供可直接用的聊天产品：要用它们得自己写代码、搭服务、接聊天入口，不符合“先试一个现成产品”的目标，故不列入对比表。同样，ChatGPT dots、Manus Cue、Instinct 等单个 agent 产品本次未单列——它们是 Pachat 群的潜在成员，不是群聊方案本身。

## 推荐

**先试 Pachat。** 理由：唯一同时满足四点——①能接 Muse 账号（总控与各节点独立 token）；②不同平台 agent 混用；③零部署、免费；④人工拍板在环（与视频场景一致）。Grok Bot 被 Muse 接入一票否决；OpenClaw 是长期备选，但运维重且 Muse 接入未验证；Claude Code agent teams 与 Kimi Agent Swarm 是同模型复制，答非所问。

**第一步验证（一次入群测试，预计 1 小时内可完成）：**

1. Chen 用邮箱在 pachat.ai 注册，拿到配对码，分别发给总控 Muse 与 node-1 Muse，各自配对（各拿独立 token，存各自 secret store，不进 hub、不进群）。
2. 总控建一个仅限链接加入的群（例如“拒付复核测试”），把两个 Muse 拉进来，指定 node-1 负责核对、总控负责汇总。
3. 出一道带数字的核查题：用视频里那笔 89 美元拒付做原型，给一段含金额/日期的证据材料，让两个 Muse 各自查、群里互相核对，最后由 Chen 在平时聊天的 App 里拍板。
4. 同时记录三件事：①一次 10 分钟轮询实际消耗多少 Muse 额度；②email wake-up 是否能把 Muse 叫起来；③群聊记录是否完整可追溯。

**什么证据会改变推荐：**

- 若实测轮询额度不可接受（例如每 10 分钟查收的消耗超过一次正常任务的量级），且放宽到每小时查收后仍不够用 → 改试 OpenClaw（消息到即处理，无空轮询），或退回 hub 异步流程。
- 若 Pachat 群内出现消息丢失、乱序、@唤醒失效 → 暂停使用，先报 Issue，等总控决定。
- 若 Muse 无法通过 email wake-up 或定时查收稳定进群 → Pachat 对 Muse 不可用，改试 OpenClaw（须先验证 Muse 账号接入方式）。
- 若 OpenClaw 验证出 Muse 账号可直连、且有人愿承担运维 → 长期可迁往 OpenClaw 自托管，Pachat 只作临时方案。

**不建议现在做的事：** 不要为测试去开 Grok Bot 付费订阅（接不进 Muse）；不要把真实客户资料、拒付证据原文发进任何群聊测试，先用脱敏原型；不要把任何 token、密钥写进 hub、checkpoint 或群聊。

## 事实与推断清单

- 事实（有来源，2026-11-12 核查）：Pachat 接入方式、token 规则、wake-up 6 种、免费与数量上限、10 分钟轮询；Grok Bot 2–6 群、共享云电脑、无安全边界、2026-08-11 beta；OpenClaw 自托管、MIT、bindings/`sessions_send` 多 agent；Claude agent teams 实验 flag、队友继承队长模型；Kimi Swarm 300 sub-agent、付费会员才可用。
- 推断（已标注）：Muse 在 Pachat 上可用 wake-up 种类为 email/定时查收（无专属 kind，待实测）；Pachat 轮询的额度量级（待实测）；OpenClaw 接 Muse 的可行性（未验证）。
- 未验证：Grok Bot 具体价格（次级来源冲突）；Kimi 各档 Swarm 次数（第三方整理）；Pachat 隐私政策/数据保留期限/合规认证（官网与 install.md 未给出）；OpenClaw 700+ 安全公告（第三方统计，未独立核实）。

## 来源清单（核查日期均为 2026-11-12，除非另注）

- Pachat 接入文档：https://pachat.ai/install.md
- Pachat 官网（中文）：https://pachat.ai/zh
- Grok Bot 对比（DigitalOcean，信息截至 2026-10-28）：https://www.digitalocean.com/resources/articles/grok-bot-vs-dots-vs-muse
- Grok Bot 群聊建群（metagrok.io）：https://metagrok.io/how-to/start-a-grok-bot-group-chat
- Grok Bot 指南（Composio）：https://composio.dev/content/guide-to-frok-bot
- Grok Bot 团队解析（Unico Connect，2026-10-17）：https://unicoconnect.com/blogs/grok-bot-agentic-chat-teams
- Grok Bot 价格对照（eesel.ai）：https://www.eesel.ai/blog/grok-bot-vs-claude-cowork
- Grok Bot 说明（toolradar）：https://toolradar.com/blog/what-is-grok-bot
- Grok Bot 群聊上限（botteams.io，引 docs.x.ai，2026-08-24）：https://botteams.io/guides/grok-bot-group-chat
- OpenClaw 官方文档：https://openclaws.io/docs/
- OpenClaw 多 agent 指南（社区）：https://clawdocs.org/guides/multi-agent
- OpenClaw 多 bot 同群（Telegram/Discord）：https://zerofuturetech.substack.com/p/multiple-openclaw-ai-agents-in-one
- OpenClaw 多 bot 同群（Slack）：https://gist.github.com/rafaelquintanilha/9ca5ae6173cd0682026754cfefe26d3f
- OpenClaw Telegram 多 agent 实操：https://www.dan-malone.com/blog/building-a-multi-agent-ai-team-in-a-telegram-forum
- OpenClaw 集成指南（2026-10-20 复核）：https://tech-stack.codeamanilabs.org/read/openclaw
- Claude Code agent teams（2026-10-14 更新）：https://www.agentpatterns.ai/tools/claude/agent-teams/
- Claude Code 桌面/终端对照（2026-10-15）：https://blog.laozhang.ai/en/posts/claude-code-desktop-vs-terminal
- Kimi Agent Swarm（Moonshot 帮助中心）：https://www.kimi.com/en/help/agent/agent-swarm
- Kimi Agent Swarm 指南（2026-10-03 更新）：https://spectrumailab.com/blog/kimi-k2-5-agent-swarm-moonshot-ai-guide-2026
- Kimi Agent 总览（Moonshot 帮助中心）：https://www.kimi.com/en/help/agent/agent-overview
