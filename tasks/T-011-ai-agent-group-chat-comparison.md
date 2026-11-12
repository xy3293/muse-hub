# T-011 AI agent 群聊产品对比：Pachat 与同类方案

## 任务信息

- **编号**：T-011
- **标题**：AI agent 群聊产品对比：Pachat 与同类方案
- **负责人**：node-1
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/11
- **预估 worker 秒数**：450
- **单回合预算**：600
- **阶段**：Stage 1（搜集候选产品事实）→ Stage 2（按维度对比并写推荐）
- **checkpoint**：每阶段结束后按 `docs/checkpoint-spec.md` 写 checkpoint
- **阶段产物路径**：`results/node-1/T-011-ai-agent-group-chat-comparison.md`
- **续跑说明**：新 worker 仅凭 checkpoint 和产物继续，不依赖旧 worker 的隐式记忆
- **外部副作用**：GitHub push（结果文件一次推送）
- **收尾开始时间**：450
- **发布与通知要求**：一次 shell 推送；成功不发 Issue 评论，交付靠推送

## 背景

Chen 在抖音看到一个视频：卖家第一次被拒付 89 美元（买家称未收到货），证据由四个 agent 一起凑齐，提交那一下由卖家自己点。视频标签含 pachat、muse。Chen 问视频里的 AI 互相交流我们能不能用。总控已核 Pachat 接入文档（`https://pachat.ai/install.md`，2026-11-12）：原则上能接，Muse 在其平台列表里，接入方式为配对码或邮箱＋6 位验证码，token 存本地，靠定时任务查收件箱。Chen 决定先对比同类方案再定用哪个。

## 目标

一份对比报告：Pachat 与同类 AI agent 群聊／多 agent 协作方案逐项对比，给出明确推荐（先试哪个、怎么验证、什么情况下改主意），供 Chen 决策。

## 输入

- Pachat 接入文档：`https://pachat.ai/install.md`（配对码／邮箱接入、token、定时查收、wake-up 种类）
- Pachat 官网：`https://pachat.ai/zh`
- 已知背景（须用来源再核实，不得只凭本段写结论）：Grok Bot 是 xAI 的多 agent 产品，一个群放 2 到 6 个 Bot，各有名字和分工，共享目标，交接过程可见（2026-11-09 总控与 Chen 讨论过）；Claude Code agent teams 与 Kimi Agent Swarm 是同一模型的复制品，不是不同 agent 混用（Pachat 文档自述）。
- 对照基线（不用重新调研，按本段描述即可）：我们现有 muse-hub 是异步版 AI 协作——总控＋node-1／2／3 三个 Muse 账号走 GitHub 传任务书和结果，有验收和留痕，无实时群聊。

## 输出要求

- 文件路径：`results/node-1/T-011-ai-agent-group-chat-comparison.md`
- 格式：中文，结论先行；先给对比表，再逐项展开，最后写推荐。
- 至少覆盖 4 个可比方案：Pachat、Grok Bot、OpenClaw（核实它自身的多 agent／群聊能力，不只写它能加入 Pachat）、Claude Code agent teams 或 Kimi Agent Swarm（注明其为同模型复制）；有余力再补 1–2 个真实产品。纯开发框架（如 AutoGen、CrewAI、LangGraph）只有在提供可直接用的聊天产品时才列入，否则在报告里一句话说明排除原因。
- 对比维度（每项逐方案给结论）：能否接入我们的 Muse 账号（总控＋node-1／2／3 各自独立账号、独立身份／token）；实时群聊还是异步；不同平台 agent 混用还是同模型复制；成本与额度消耗（轮询频率、是否需常驻进程）；隐私与数据去向（消息经谁的服务器、群可见性、秘密怎么处理）；上手与运维成本（是否需部署、是否需常驻）；是否支持验收、留痕、任务交接（适配我们 hub 的工作方式）；价格／免费额度与上限；每个方案的硬性短板。
- 每个关键结论贴来源链接并注明日期；区分事实与推断，不确定的写“未验证”。不许编数字，不许编价格，不许编来源。
- 推荐必须明确：先试哪个、第一步具体做什么验证（如一次入群测试）、什么证据会改变推荐。
- 不得把 token、密钥、电话、地址等秘密写进结果文件、checkpoint 或 Issue。
- 本任务同样受 600 秒执行上限约束：分批做、边做边写、尽早推送；每完成一个阶段写一次 checkpoint。

## 验收标准

- 至少 4 个可比方案，每项有来源链接与日期。
- Pachat 事实与 install.md 一致（配对码／邮箱、token、定时查收、wake-up 种类含 listener／email）。
- Grok Bot 事实有来源，不得只凭记忆写。
- 推荐明确且立足我们的约束（Muse 账号、总控额度、公开库不放秘密）。
- 无编造数字、价格与来源。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止；期望 1 天内交付。遇阻塞直接在 Issue 说明，不要静默等待。
