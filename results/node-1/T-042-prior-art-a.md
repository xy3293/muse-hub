# T-042 同类项目调研 A：多 agent 协作框架 + “仓库/Markdown 当协作总线”

- 任务：T-042 角度 A（Chen 直令，2026-11-16，主聊派发；BOARD 无 T-042 行，无任务书，以本直令为准）
- 方法：GitHub Search API（`gh api`，已登录账号 xy3293），搜索词见各节；每个项目的 stars 与最近提交日期均取自 `api.github.com` 当场返回（`stargazers_count` / `pushed_at`，UTC 日期）；komnet、planr、ework、software-factory、orca 另读了 README 原文核机制。其余项目的机制描述以其 API 返回的 description 与公开周知的用途为准，未展开读源码的细节标“未核实”。
- 我们的参照系：1 个总控 + 3 个执行节点，以一个公开 GitHub 仓库当协作总线——BOARD.md 派活、任务书定契约、Issue 留言、git push 交付、RULES.md 当群规、cron/Hook 巡逻唤醒、只读 Control Tower 看板。核心是版本控制当状态机、提交当交付凭证、规则文本当治理。

## 方向 1：多 agent 协作框架（挑最相关的 9 个）

AutoGen | https://github.com/microsoft/autogen | 61,869 | 2026-11-12
是什么：微软的 agentic AI 编程框架，多个 agent 在进程内对话协作（GroupChat 等模式）。
与我们重合：多 agent 对话本身就是协调原语——对应我们的总控↔节点留言、Issue 评论。
我们没有：进程内消息传递、代码执行沙箱、GroupChat/Selector 等现成 agent 模式。
我们独有：仓库当持久总线、提交当交付凭证、RULES.md 文本治理、巡逻唤醒。
可复用程度：低——它是代码框架不是总线，只有对话模式可作参考。

CrewAI | https://github.com/crewAIInc/crewAI | 60,982 | 2026-11-16
是什么：角色扮演式自主 agent 编排框架（crew、task、tool，进程内跑）。
与我们重合：角色分工（总控/节点）与任务指派——对应我们的 BOARD 派活。
我们没有：进程内 task 对象、工具调用框架、记忆层。
我们独有：公开仓库当总线、Issue 当邮箱、提交当凭证。
可复用程度：低——角色/task 建模思路可参考，机制不在一层。

MetaGPT | https://github.com/FoundationAgents/MetaGPT | 71,289 | 2026-01-21
是什么：多 agent“软件公司”（产品经理/架构师/工程师按 SOP 传文档写代码）。
与我们重合：agent 之间传结构化产物（PRD/设计文档）——最接近我们任务书契约的大框架类比。
我们没有：SOP 文档流水线、进程内消息池。
我们独有：真实 git 提交就是产物交接、RULES 治理、巡逻唤醒。
可复用程度：中——SOP/产物传递思路可映射到任务书格式，但它是进程内的。

ChatDev | https://github.com/OpenBMB/ChatDev | 34,755 | 2026-11-06
是什么：LLM 驱动的多 agent 协作开发，chat chain 串起多个角色写软件。
与我们重合：聊天驱动的多 agent 开发。
我们没有：chat-chain 流水线、内存内对话。
我们独有：持久仓库总线、交付凭证、治理文本。
可复用程度：低——对话链在内存里，不解决跨账号持久协调。

OpenHands | https://github.com/OpenHands/OpenHands | 93,572 | 2026-11-16
是什么：AI 驱动开发 agent，在真实代码库里用终端/浏览器干活（原 OpenDevin）。
与我们重合：agent 在真实 git 仓库里工作、提交代码。
我们没有：单 agent 运行时（工具调用、沙箱）。
我们独有：多账号经仓库协调、群规治理、巡逻唤醒。
可复用程度：中——它的仓库工作纪律（分支/worktree 用法）可直接给节点参考。

SWE-agent | https://github.com/SWE-agent/SWE-agent | 20,819 | 2026-11-09
是什么：拿一个 GitHub Issue，自动修掉它（跑测试验证）。
与我们重合：Issue 驱动的工作 intake——正是我们“Issue 当邮箱”的一半。
我们没有：Issue→补丁自动循环、测试验证 harness。
我们独有：BOARD 多节点派发、总控人工治理、跨账号提交当凭证。
可复用程度：中——它的 Issue→干活→PR 循环就是节点手工走的流程，验证 harness 思路可复用。

LangGraph | https://github.com/langchain-ai/langgraph | 45,022 | 2026-11-16
是什么：以图（状态机）编排 agent，带检查点、重试。
与我们重合：状态机编排——我们的 BOARD 也是状态机，只不过写在 Markdown 里。
我们没有：进程内状态图、检查点、重试。
我们独有：版本控制本身就是状态机，状态变更即提交。
可复用程度：低——不在一层（代码内 vs 仓库）。

agent-framework | https://github.com/microsoft/agent-framework | 14,705 | 2026-11-15
是什么：微软较新的 agent 构建/编排/部署框架（Python/.NET）。
与我们重合：编排原语（workflow、多 agent）。
我们没有：部署能力、工作流引擎。
我们独有：仓库当总线。
可复用程度：低——同上，代码层框架。

Orca | https://github.com/stablyai/orca | 126,223 | 2026-11-16
是什么：桌面端 AI 编排器，并行跑 Claude Code/Codex 等 coding agent，每个 agent 一个 git worktree，协调 agent 拆任务分给 worker（README 原文核过）。
与我们重合：coding agent 编队 + 协调者/工人分工 + git worktree 隔离——大项目里最接近我们节点模型的一个。
我们没有：桌面应用、实时编排、远程服务器。
我们独有：公开仓库当整条总线（BOARD/Issue/RULES）、提交当凭证、巡逻唤醒、跨账号。
可复用程度：中——worktree-per-agent 与协调者拆任务的模式可直接参考。

## 方向 2：仓库/Markdown 当协作总线

komnet | https://github.com/Komdosh/komnet | 8 | 2026-11-16
是什么：给 AI coding agent 的消息总线，传输就是你自己的 Git 仓库——“房间是文件夹，消息是文件，git 历史就是日志，没有服务器”（README 原文）。
与我们重合：核心机制本身——git 仓库当传输、提交历史当 agent 间消息。
我们没有：MCP 接口、本地 daemon 同步、收件箱暂存。
我们独有：任务派发（BOARD.md）、任务书契约、RULES.md 治理、Issue/PR 当邮箱、提交当交付凭证、巡逻唤醒、Control Tower。
可复用程度：高——“房间是文件夹，消息是文件”可直接复用为节点间消息格式；但它只解决传消息，不解决任务治理。

planr | https://github.com/instructa/planr | 74 | 2026-10-20
是什么：给 agent 造产品的轻规划层，Markdown 任务放 Git 里，规划仓通常与代码仓分离、无数据库/daemon/MCP（README 原文）。
与我们重合：Markdown 任务放 Git + 规划仓与代码仓分离——几乎就是我们的 BOARD.md + 任务书。
我们没有：Claude Code/Codex 的 CLI 与 skill 插件、依赖跟踪。
我们独有：派发 + 唤醒 + 治理 + 交付凭证 + 多账号。
可复用程度：高——Markdown 任务格式与“规划仓独立”可直接复用；是 BOARD 概念最接近的在先项目。

Tasks.md | https://github.com/BaldissaraMatheus/Tasks.md | 2,219 | 2026-03-08
是什么：自托管、基于 Markdown 文件的任务看板（给人用的）。
与我们重合：Markdown 文件就是任务。
我们没有：Web 界面、给人看的看板。
我们独有：agent 侧的一切（agent 读写、派发、凭证）。
可复用程度：低——人用的工具，不是 agent 总线；只证明“Markdown 当任务”本身不新鲜。

nextask | https://github.com/TolgaOk/nextask | 6 | 2026-09-13
是什么：分布式任务队列，带实时日志流与 git 快照（可复现）。
与我们重合：用 git 做快照/可复现。
我们没有：实时日志流、分布式队列基础设施。
我们独有：Markdown 治理、Issue 邮箱。
可复用程度：低——它是队列基础设施，不是仓库总线。

## 方向 3：Issue/PR 当邮箱、Issue 驱动开发

ework | https://github.com/ranxianglei/ework | 23 | 2026-11-15
是什么：自托管 issue 驱动 AI 开发舰队——提 issue，agent 接单、在隔离 worktree 干活、在评论区汇报、提 PR、关单（README 原文，中英双语）。
与我们重合：Issue 驱动派发 + worktree 隔离 + 评论区汇报 + PR 交付——全场最接近我们工作流的一个。
我们没有：自托管服务器、webhook、Web 界面、唤醒策略/模型选择等控制面。
我们独有：公开仓库就是全部总线（零服务器）、BOARD.md 派发表、任务书契约、RULES.md 治理、提交当凭证、cron/Hook 巡逻唤醒、只读 Control Tower。
可复用程度：高——Issue→worktree→PR→关单的循环就是我们的流程；它的唤醒策略/模型选择控制面值得抄成 BOARD 字段。

software-factory | https://github.com/sun-praise/software-factory | 3 | 2026-06-05
是什么：轻量 FastAPI 的 Issue/PR 驱动自主开发系统，webhook 决定何时开工，agent worker 执行，SQLite 存状态（README 原文）。
与我们重合：Issue/PR 驱动的 intake→worker→写回循环。
我们没有：服务器、webhook 触发、数据库。
我们独有：零服务器（巡逻轮询代替 webhook）、RULES 治理。
可复用程度：中——它的循环可映射到我们流程；webhook 是巡逻轮询的 push 版。

Sweep | https://github.com/sweepai/sweep | 7,710 | 2025-09-18
是什么：Issue→PR 的先驱（现已转向 JetBrains 插件，README 已改；最近提交 2025-09-18， stale）。
与我们重合：Issue 进、PR 出。
我们没有：自动补丁生成。
我们独有：多账号治理、仓库总线。
可复用程度：低——已转向且 stale，单 agent 自动化，不是总线。

## 方向 4：提交历史当 agent 间消息 / Issue-PR 当 mailbox（重点）

本方向无成熟大项目，命中的全是小项目，上面已列的 komnet 与 ework 就是本方向的两个极点：

- komnet（8 stars）：把“提交历史当消息”做到了极致——房间是文件夹、消息是文件、git 历史就是日志；但它只做消息传输，不做任务派发、契约、治理、凭证。
- ework（23 stars）：把“Issue 当 mailbox”做到了极致——issue 提单、评论区汇报、PR 关单；但它靠自托管服务器 + webhook 驱动，不是无服务器的仓库总线。

另有两个文件级消息项目：

tap | https://github.com/HUA-Labs/tap | 39 | 2026-06-20
是什么：跨厂商 agent 间协议，Claude/Codex/Gemini 经基于文件的 P2P 消息互通。
与我们重合：基于文件的 agent 间消息（我们的 Pachat/GitHub 评论起这个作用）。
我们没有：跨厂商协议。
我们独有：共享仓库总线（不是 P2P）、治理文本。
可复用程度：中——文件消息格式可借鉴节点间消息，但 P2P ≠ 共享总线。

CCteam-creator | https://github.com/jessepwj/CCteam-creator | 309 | 2026-04-13
是什么：Claude Code 的多 agent 小组编排 skill，并行 agent 小组、基于文件的 handoff。
与我们重合：agent 间基于文件的 handoff。
我们没有：Claude Code skill 封装。
我们独有：仓库总线 + 治理 + 凭证。
可复用程度：中——文件 handoff 模式可复用于节点交接。

补充：`git as message bus`、`repo-driven workflow` 两个搜索词几乎无相关命中（前者除 komnet 外无；后者 0 相关），`git-based task queue` 仅 1 个 6 星项目——“仓库当总线”这个方向本身在开源里就很空。

## 判断（5 行）

我们这套东西在开源里是确实少见，不是已有成熟方案。
大框架（AutoGen/CrewAI/OpenHands 等）都在进程内编排，不用仓库当总线；仓库/文件/Issue 当总线的项目全是小项目（大多 <100 星），且每个只占一个切片——komnet 只传消息、planr 只做规划、ework 只做 Issue→PR 舰队。
没有任何一个项目把“公开仓库当整条总线 + Markdown 当状态机 + 提交当交付凭证 + 规则文本当治理 + 巡逻唤醒”拼在一起；最接近的 ework 还是自托管服务器平台，不是零服务器的仓库总线。
所以：零件都存在，组合不存在——这正是我们的独特处，也是风险处：治理、唤醒、凭证这三块没有上游可抄，只能自己长出来。
可复用最高的三处：komnet 的消息格式、planr 的 Markdown 任务格式、ework 的 Issue→worktree→PR 循环与唤醒控制面。

## 核实记录

- 全部 18 个项目的 stars 与 pushed_at 均取自 `api.github.com`（2026-11-16 当场查询，`gh api` 已登录账号）；“最近提交日期”即 `pushed_at` 的 UTC 日期。
- README 原文核过：komnet、planr、ework、software-factory、orca（机制描述有原文支撑）；其余以 API description 与公开周知用途为准。
- 未 clone 任何仓库，未装任何包。
