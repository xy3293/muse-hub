# T-044 同类项目调研 · 角度 C：agent 可观测性 / 控制塔 / 任务看板（node-3）

- 任务：T-044（角度 C），Chen 直令，2026-11-16。
- 方法：GitHub Search API（`api.github.com/search/repositories`）＋仓库与 README 接口，全部为 2026-11-16 当日实测；未 clone、未部署、未装包。
- 口径：stars 为当日 API 返回的 `stargazers_count`；「最近提交日期」取 API 的 `pushed_at`（任意分支最近一次推送），非默认分支最后提交，两者通常接近但不等同。
- 对照对象：muse-hub 协作模式（公开 GitHub 仓库为唯一事实源：BOARD 派活、提交交付、Issue 留言、RULES 治理、Hook 巡逻）＋自建只读看板 Control Tower（6 页面、9 只读接口，数据实时拉 GitHub，节点状态由提交历史派生）。

## 方向 1：agent observability / LLM tracing

```
Langfuse | https://github.com/langfuse/langfuse | ★37481 | 最近推送 2026-11-16
是什么：开源 AI 工程平台，主打 agent observability、评测与 prompt 管理。
与我们重合：有 agent 执行轨迹（trace）的时间线视图和会话/运行列表，能回答「哪个 agent 做了什么」。
我们没有：LLM 调用级遥测（token、成本、延迟）、评测（evals）、prompt 版本管理、AI Gateway。
我们独有：它要求在 agent 代码里埋点上报；我们不埋点，状态从 Git 提交历史被动派生，且协作协议（派活/验收）本身就在被观测的数据里。
可复用程度：低。它解决的是「一次运行内部发生了什么」，不是「多个账号协作的全局状态」，数据源接不进 GitHub 仓库。
```

```
Phoenix（Arize） | https://github.com/Arize-ai/phoenix | ★12310 | 最近推送 2026-11-16
是什么：基于 OpenTelemetry 的 AI 可观测与评测工具，本地/自托管看 trace。
与我们重合：同样强调「不改业务代码也能看」——但它靠 OTel 自动埋点，我们靠读仓库。
我们没有：trace 瀑布图、嵌入漂移/数据质量分析、评测实验管理。
我们独有：跨账号、跨天的任务级状态（待领/进行中/完成）与治理规则层；Phoenix 只有单次运行级数据。
可复用程度：低。品类相同（observability），粒度完全不同（span 级 vs 任务级）。
```

```
Opik（Comet） | https://github.com/comet-ml/opik | ★23442 | 最近推送 2026-11-16
是什么：LLM 应用与 agentic workflow 的调试、评测、监控平台。
与我们重合：有 agent workflow 的轨迹追踪与监控面板。
我们没有：自动化评测、标注、生产监控告警、数据集管理。
我们独有：同 Langfuse——我们是零埋点、Git 原生、带治理（RULES/验收）的协作观测，它是埋点式的运行观测。
可复用程度：低。理由同上。
```

```
Helicone | https://github.com/Helicone/helicone | ★6282 | 最近推送 2026-11-12
是什么：开源 LLM 可观测平台，代理网关模式，一行代码接入监控。
与我们重合：成本/用量面板与我们的「额度可见性」需求（T-027 的 B3）部分对应。
我们没有：请求级日志、成本归因、缓存与限流网关。
我们独有：任务协作与节点状态维度；它只有 API 调用维度。
可复用程度：低。唯一可借鉴的是其成本面板呈现方式，与看板替换无关。
```

```
AgentOps | https://github.com/AgentOps-AI/agentops | ★5962 | 最近推送 2026-06-25
是什么：面向 AI agent 的监控 SDK：会话回放、LLM 成本跟踪、基准测试。
与我们重合：「会话回放」概念与我们按提交历史重建节点行为相似——都是事后重建时间线。
我们没有：agent 内部事件流（工具调用、决策点）的记录与回放。
我们独有：我们的时间线来自 Git 提交（不可篡改、自带审计），它来自 SDK 上报（agent 崩了就没数据）；我们还有派活/验收的双向协议，它只是单向观测。
可复用程度：低。且其仓库近 5 个月无推送，活跃度存疑。
```

```
OpenLLMetry（Traceloop） | https://github.com/traceloop/openllmetry | ★7539 | 最近推送 2026-11-09
是什么：基于 OpenTelemetry 的 GenAI 可观测埋点库（SDK 层，非看板）。
与我们重合：只是数据采集层理念（标准化 span），与 Control Tower 无直接重合。
我们没有：它就是「我们没有」的部分——标准化埋点；我们刻意不埋点。
我们独有：全部。它是管道，我们是消费端，而且消费的是 Git 数据不是 span。
可复用程度：低。除非未来决定给节点加埋点，否则用不上。
```

同方向其他大项目（仅搜索核实，未深读）：PostHog（★40818，含 LLM observability 模块）、SigNoz（★32659，通用 OTel 平台）、MLflow（★28829，已扩展到 agent/LLM 工程）。Braintrust 为闭源 SaaS（仅 SDK 开源），未单列。

## 方向 2：agent control plane / fleet / supervisor

```
Mission Control（Builderz Labs） | https://github.com/builderz-labs/mission-control | ★6501 | 最近推送 2026-11-16
是什么：自托管的 AI agent 控制平面：派发任务、检视运行、审查失败、跟踪花费，本地 SQLite 存储（README 实读）。
与我们重合：这是全场与我们最像的品类——「总控派活＋看板总览＋失败审查」的产品形态几乎一一对应；同样支持多运行时（OpenClaw、Claude Code、Codex 等）。
我们没有：它自带任务队列与运行记录数据库、花费跟踪、管理员账号与 API key 体系；状态是它自己的，不是派生的。
我们独有：我们的事实源是公开 GitHub 仓库（任何人可审计、git 历史即账本），它的是私有 SQLite；我们的治理（RULES/RULINGS/审批卡）没有对应物；我们零部署（看板只读拉 GitHub），它要常驻运行一个服务（Docker 或 Node 22＋pnpm，README 实读；且自称 alpha，接口可能变）。
可复用程度：中。若要替换看板，它是形态最接近的候选；但替换的不是看板而是整个协作底座（见文末问题 2）。
```

```
OpenClaw Mission Control | https://github.com/abhi1693/openclaw-mission-control | ★4097 | 最近推送 2026-08-06
是什么：OpenClaw 生态的 agent 编排看板：管理 agent、分配任务、协调多 agent。
与我们重合：多 agent 任务分配＋状态总览。
我们没有：与 OpenClaw 运行时的深度集成（进程级管理）。
我们独有：Git 原生事实源与治理层。
可复用程度：低。仓库已归档（README 实读：已停止维护，开发迁至 Wardn AI），2026-08-06 的推送应即归档动作，不宜采用。
```

```
LoopX | https://github.com/loopx-project/loopx | ★6688 | 最近推送 2026-11-16
是什么：面向 24/7 常开 agent 的控制平面，把长期目标拆成可验证结果（仓库简介，未深读 README，机制细节未核实）。
与我们重合：「长期目标 → 可验证结果」的拆解与我们 goal/任务书＋验收标准的结构相似。
我们没有：常开 agent 的运行时托管（推断，未核实）。
我们独有：Git 事实源、公开审计、规则治理。
可复用程度：低（未深读，不下更细结论）。
```

## 方向 3：task board / kanban for agents

```
OverClick | https://github.com/ustoppble/overclick | ★119 | 最近推送 2026-11-11
是什么：开源任务看板，「人类决策与审查，agent 执行」：卡片即契约（做什么/为什么/如何确认），agent 经 MCP 认领、执行、带证据交付，人类盖章 Validated（README 实读）。
与我们重合：机制高度同构——它的「卡片契约」≈我们的任务书，「认领」≈已领，「带证据交付＋人类验收」≈推送交付＋总控验收，「驳回评论后 agent 下次认领时可见」≈Issue 打回。还把每张卡的实测遥测（时长、按模型的 token 数）直接标在卡上。
我们没有：MCP 原生认领接口（我们的认领靠巡逻 Hook 扫 BOARD）；卡上遥测（时长/token 是实测读数，我们只有提交时间戳）。
我们独有：事实源在 GitHub（它用自己的数据库＋MCP server，看板即事实源）；公开可审计；RULES 治理与审批卡。
可复用程度：中。机制最值得借鉴（尤其是卡上实测遥测），但采用它＝换掉 muse-hub 的协作底座。
```

```
Retinue（众卿） | https://github.com/jklthinking/retinue | ★115 | 最近推送 2026-10-22
是什么：自托管的人机混编任务看板：每份工作是一根「信物」（单持有者＋验收检查＋只追加的回执链），agent 经 MCP/HTTP 认领回写，人类验收或打回（README 实读）。
与我们重合：全场机制最接近的一个——「只追加回执链」≈我们的 MUSE-ACK 收据与提交历史；「单持有者」≈任务只派给一个号；还有按设备/模型的时间线、节点额度卡（各家订阅已用百分比、重置时间、数据新鲜度——正是我们 T-027 里 B3 测不出来的那块，它用采集器解决了）。
我们没有：任务关系图（委派/依赖/流转）、额度采集器、看板内置的对话时间线。
我们独有：GitHub 事实源与公开审计、Hook 巡逻唤醒、审批卡治理；它的看板是中心化服务，板即事实源。
可复用程度：中。回执链与额度卡的设计可直接借鉴到 Control Tower；整体采用同样面临换底座问题。
```

```
Agent Teams AI | https://github.com/777genius/agent-teams-ai | ★2495 | 最近推送 2026-11-16
是什么：「你是老板，agent 是团队」——agent 自主处理任务、互相发消息、向你汇报的团队协作产品（仓库简介，未深读）。
与我们重合：多 agent 团队＋任务流转＋向单一所有者汇报的组织形态。
我们没有：产品化的桌面/交互体验（推断，未核实）。
我们独有：Git 事实源、规则治理、公开仓库。
可复用程度：低（未深读）。
```

```
agent-kanban | https://github.com/saltbo/agent-kanban | ★506 | 最近推送 2026-11-13
是什么：「agent-first 的任务看板，把人类移出回路」（仓库简介，未深读）。
与我们重合：看板即 agent 协作面这一点。
我们没有：未知（未深读）。
我们独有：我们刻意把人类（Chen 的审批卡与裁决）留在回路里，与它的设计哲学正相反。
可复用程度：低。
```

## 方向 4：agent health check / heartbeat / stale 检测

结论先行：**没有找到现成做法。** 以 `agent heartbeat monitoring`、`agent fleet management`、`stale agent detection` 等词搜索（2026-11-16），返回的基本是传统基础设施监控（Docker/K8s/uptime，如 maintenant ★549、uptimy/agent ★83，均当日核实）与零散的 agent 框架插件，没有一个项目做「从 Git 提交历史派生 agent 存活/陈旧状态」。

开源界的标准做法是**主动心跳**：被监控方定期向监控方打点，超时未打点判死（dead man's switch，代表如 healthchecks.io——本次未核实其仓库数据，仅作模式引用）。我们的 Control Tower 用的是**被动派生**：不要求节点打点，直接拿公开仓库的提交时间戳算新鲜度。两者判读逻辑（阈值＋超时判 stale）相同，但数据来源范式相反；被动派生在开源里未见成型项目，这一项是我们相对独有的做法。可复用程度：无现成可复用；若要增强，可借鉴心跳派的阈值与告警分级惯例。

## 重点问题

### 1. Control Tower 在开源里对应什么品类？

**没有完全对应的品类。** 逐项对照：

- 不是 "agent observability"：那一品类（Langfuse、Phoenix、Opik 等）的原子数据是埋点上报的 LLM 调用 span，回答的是「一次运行内部发生了什么、多少钱」；Control Tower 的原子数据是任务与提交，回答的是「谁在做什么、卡在哪、验没验」。
- 最接近 "agent control plane / mission control"（Mission Control、LoopX 等），但只接近其**监视面**：控制平面本体还包含派发与运行时托管，且状态存在自己的数据库里、由 agent 主动上报。
- 也接近 "agent task board"（OverClick、Retinue），但那些看板**就是**事实源（写进它才算数）；Control Tower 是只读旁观者，事实源在它之外的 GitHub。

准确的说法是：Control Tower 属于「**Git 原生的、只读的 agent 协作观测层**」——把 GitOps 的「以 Git 为唯一事实源、状态靠派生」思想用在多 agent 协作治理上。这个组合（公开仓库＋提交派生状态＋规则治理＋只读看板）在本次调研的四个方向里都没有对应产品，是我们自成一类。

### 2. 有没有现成项目可以直接替换自建看板？

**没有可以直接替换的。** 形态最接近的三个（Mission Control、OverClick、Retinue）有一个共同前提：**它们自己的数据库才是事实源**，agent 必须经它们的 API/MCP 认领与回写。没有任何一个能以 GitHub 仓库（BOARD、提交、Issue）为数据源接入。所谓「替换」实际要付的代价是：

- **换底座，不只是换看板**：派活、认领、交付、验收、回执整套协议要从 GitHub 迁到对方系统里，我们现有的 RULES 治理、巡逻 Hook、审批卡、MUSE-ACK 全部要重做或作废。
- **丢公开审计**：现在任何人打开仓库就能核对全部历史；迁到自托管数据库后，账本变成私有服务内部状态。
- **部署与运维**：三者都可 Docker 一键起（不难），但从此多一个需要常驻、备份、升级的服务；Mission Control 还自称 alpha。
- **换来的收益**：现成的任务图、卡上实测遥测（时长/token）、额度卡、失败审查视图——都是体验与呈现层收益，不解决我们任何未解决的正确性问题。

**建议：不替换。** Control Tower 继续自建（它只读、无状态、零运维的特性正是现有候选都不具备的）；把候选的好机制借进来即可，优先级：Retinue 的只追加回执链呈现与节点额度卡、OverClick 的卡上实测遥测、Mission Control 的失败审查视图。

## 数据可信度说明

- 全部 stars 与 pushed_at 为 2026-11-16 经 GitHub API 实测；标「未深读」者仅核实了仓库简介与元数据，机制描述基于简介，未读 README；标「README 实读」者（Mission Control、OpenClaw Mission Control、OverClick、Retinue）机制描述来自当日读取的 README。
- healthchecks.io 仅作模式引用，其仓库数据未核实。
- 本报告只做调研：未 clone、未部署、未安装任何包。
