# 开源同类扫描汇总（T-042 / T-043 / T-044 ＋总控角度 D）

- 来源：T-042（node-1，角度 A：多 agent 协作框架＋仓库当总线）、T-043（node-2，角度 B：审批闸门＋浏览器桥）、T-044（node-3，角度 C：可观测性 / 控制塔 / 任务看板）、总控角度 D（GitHub 仓库当 agent 消息总线）。
- 方法：三份节点报告均用 GitHub API 当场取 stars / pushed_at；总控抽核 3 个项目（见文末核实记录），全部一致。总控角度 D 的项目亦经 API 核实。
- 口径：不确定的标"未核实"；汇总里不出现未核实的数字；"看起来像"不写成"就是"。

## 1. 对比表（维度 × 我们 vs 开源最佳候选）

| 维度 | 我们 | 开源最佳候选 | 差距 |
|---|---|---|---|
| 协作总线 | 公开 GitHub 仓库当整条总线（BOARD / Issue / RULES / 提交），零服务器 | komnet（8★，git 当传输）/ ework（23★，Issue 驱动，需自托管服务器） | 候选只占一个切片：komnet 只传消息，ework 要服务器；没有"零服务器整条总线" |
| 交付凭证 | git 提交＋MUSE-ACK＋收据，不可篡改、可审计 | Retinue（115★，只追加回执链）/ leadkit（3★，评审门禁绑提交 SHA） | 候选是"回执链"呈现，我们是"提交本身就是凭证"；机制相近，数据源不同（Git vs 自家 DB） |
| 治理 / 规则 | RULES.md / RULINGS.md 文本治理＋总控裁决＋审批卡 | 无对应物（MetaGPT / LoopForge 的 SOP 是流程模板，不是治理层） | 开源里没有"规则文本当治理＋人工裁决"的对应物 |
| 审批闸门 | CDP 读厂商聊天界面审批卡＋点批＋fingerprint 审计 | LangGraph interrupt（45,022★，进程内暂停）/ HumanLayer 评审控制台（12,891★） | 候选都在"自己的执行体里"设闸；我们是在"别人 UI 上"设闸（无 API），开源里无对应方案 |
| 可观测性 | Control Tower：只读、Git 派生、任务级、零埋点 | Mission Control（6,501★，最接近的产品形态，但自家 SQLite 事实源）/ Langfuse（37,481★，span 级，需埋点） | 候选要么埋点（span 级），要么自家 DB；没有"Git 原生只读观测层" |
| 部署形态 | 零服务器（仓库＋cron / Hook 巡逻＋只读看板） | 无对应物（planr 无 DB / daemon，74★，但只是规划层） | 所有完整方案都要常驻服务；零服务器整套协作在开源里未见 |

## 2. 我们真正独特的地方（≤3 条）

1. **公开仓库当整条总线＋提交当凭证＋规则文本当治理，三者拼在一起且零服务器。** 没有任何一个开源项目把这三者拼在一起。最接近的 ework（Issue→worktree→PR）要自托管服务器；komnet（git 当传输）只做消息；planr（Markdown 任务）只做规划。组合不存在。
2. **CDP 读厂商聊天界面审批卡＋点批＋fingerprint 审计。** LangGraph、HumanLayer、OpenAI Agents SDK 的闸门都在"自己的执行体里"；我们的 agent 跑在厂商聊天界面（无 API），闸门是界面上的一张卡，必须从外面读卡、点批，并用 fingerprint 证明"哪张卡、谁批的"。开源里没有现成方案（T-043 方向 3 搜索为空）。
3. **从 Git 提交历史被动派生 agent 存活 / 陈旧状态，不打心跳。** 开源标准做法是主动心跳（dead man's switch，如 healthchecks.io）；没有项目做"从提交时间戳算新鲜度"的被动派生。T-044 方向 4 搜索确认无现成做法。

## 3. 我们明显在重复造轮子的地方（≤3 条）

说明：下面三条都不是"整个换掉"，而是"把开源已有的模式 / 机制借进来"——我们的底座（仓库总线）换不掉，但这些局部可以抄。

1. **Hook 唤醒的投递保障（重试 / 退避 / 死信 / 幂等）。** 我们自己写的巡逻＋唤醒，可靠性差（20 分钟级延迟、丢唤醒）。可换成：Svix（3,481★）的投递保障模式——重试、指数退避、死信、幂等键。迁移代价：低（模式移植，约 1 个 Codex 任务；Svix 服务本身不直接嵌，要自己实现模式）。
2. **浏览器 CDP 操作层的鲁棒性。** 我们手写 CDP detector（判空容器 vs 真有卡）。可换成：playwright-mcp（39,718★，标准浏览器工具集）/ browser-use（121,167★，DOM 观察＋反检测）的鲁棒性做法。迁移代价：中（重写桥层，约 2 个 Codex 任务；但直接 CDP 更轻，MCP 是多余层，需权衡是借模式还是换库）。
3. **任务卡片的实测遥测与回执呈现。** 我们 Tower 卡上只有提交时间戳，没有实测时长 / token / 额度；OverClick（119★）把每张卡的实测遥测直接标在卡上，Retinue（115★）有节点额度卡与只追加回执链。可换成：把 OverClick 的卡上遥测与 Retinue 的回执链呈现借进 Tower（不是换掉 Tower，只是加字段）。迁移代价：低-中（Tower 加遥测字段＋额度采集器，约 1–2 个 Codex 任务）。

## 4. 角度 D：GitHub 仓库当 agent 消息总线，有没有开源先例？（总控补查）

**有先例，而且不止一个。但全是小项目（大多 <1000 星），且每个只占一个切片。**

| 项目 | stars（API 实测） | 最近推送（API 实测） | 它做了什么 | 与我们的关系 |
|---|---|---|---|---|
| A2A-over-Git（dobryakov/a2a-example） | 0 | 2026-05-20 | Google A2A 标准跑在共享 git 仓库上，文件系统当队列（inbox / outbox），git 当传输；原子 rename 抢单 | 形式化程度最高的"git 当总线"：有标准消息格式，但只是传输层，不做任务治理 |
| leadkit（MattGrundy/leadkit） | 3 | 2026-10-27 | Markdown 任务队列放磁盘，评审门禁绑提交 SHA | 任务队列＋提交 SHA 门禁，与我们 BOARD＋MUSE-ACK 思路同构，但只是 CLI＋配置 |
| Citadel（SethGammon/Citadel） | 931 | 2026-11-12 | Markdown 当控制面，仓库内文件存记忆 / 任务路由 / 交接，git worktree 并行 | "Markdown 当控制面"最成型的实现；但它是单机编排 harness，不是多账号协作总线 |
| Cowork（slashman413/cowork） | 5 | 2026-11-15 | JSON / Markdown 任务存磁盘，MCP＋看板，多 agent 共享 inbox | 任务存磁盘（JSON / Markdown），但要常驻 hub 服务，不是零服务器 |
| awesome-agent-orchestrators（andyrewlee） | 2,438 | 2026-11-15 | 编排器清单（含 GNAP：Issue=队列、分支=工作区、PR=交付物、提交消息=信号） | GNAP 是"git 原生 agent 协议"的纲领，但只是清单 / skill，未见完整实现 |
| ASIF（论文，nxtg.ai，2026-07） | —（论文，非仓库） | — | 两个 agent 用一个共享仓库管 21 个项目 21 周，无消息 broker，5 分钟 cron 同步 git | 与我们最像的生产级验证：仓库当协调层、cron 同步、无 broker；但它是论文记述的内部系统，未见开源仓库 |
| 19 Squads（agents-squads.com，博客） | —（实践记述，非仓库） | — | 19 个 agent 小队生产运行：GitHub Issue 当工作队列、Markdown 当记忆、PR 当交接 | 生产实践记述，与我们工作流高度同构；但它是内部做法记述，不是开源项目 |

**未核实：** Karpathy 的 AgentHub（据 Facebook 截图称"bare git repo + message board"，589 星）——GitHub API 查 `karpathy/agenthub` 返回 Not Found，星数与存在性均未核实，不列入上表。

**结论：** "仓库当消息总线"这个方向在开源里确实存在，但全是小项目或论文 / 实践记述，没有成熟大项目；且没有一个把"仓库当总线＋Markdown 当状态机＋提交当凭证＋规则文本当治理＋巡逻唤醒"拼成整套。最接近我们的是 ASIF 论文（生产级、仓库协调、无 broker）和 ework（Issue 驱动舰队），但前者未开源、后者要服务器。

## 5. 一句话结论

**少见但有价值**——不是"已有成熟方案"：零件（多 agent 框架、Markdown 任务、Issue 驱动、审批中断、可观测看板）都存在且多为成熟大项目，但"公开仓库当整条总线＋提交当凭证＋规则文本当治理＋巡逻唤醒＋只读看板"这个组合在开源里没有对应物，最接近的也只是小项目或单一切片。

## 核实记录

- 总控抽核 3 个项目（GitHub API，2026-11-16 当场）：Komdosh/komnet stars 8 / pushed 2026-11-16（T-042 写 8 / 2026-11-16 ✅）；humanlayer/humanlayer stars 12,891 / pushed 2026-11-16（T-043 写 12,891 / 2026-11-16 ✅）；builderz-labs/mission-control stars 6,501 / pushed 2026-11-16（T-044 写 6,501 / 2026-11-16 ✅）。三处全部一致，无不符。
- 总控角度 D 的项目亦经 API 核实：dobryakov/a2a-example（0★）、MattGrundy/leadkit（3★）、SethGammon/Citadel（931★）、slashman413/cowork（5★）、andyrewlee/awesome-agent-orchestrators（2,438★），stars 与 pushed_at 均为 2026-11-16 当场 API 返回值。karpathy/agenthub 查无此库（Not Found），星数未核实，不采用。
- 节点报告里其余项目的数字以其各自 API 实测为准，总控未逐一复核（只抽核 3 个）；汇总里不出现未核实的数字。
