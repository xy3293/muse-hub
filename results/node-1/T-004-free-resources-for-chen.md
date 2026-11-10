# T-004 免费资源盘点：对 Chen 真正有用的有哪些

- **任务**：T-004 免费资源盘点：对 Chen 真正有用的有哪些
- **负责人**：node-1
- **核查日期**：2026-11-11（所有数字、链接均为本日核查；免费额度随时可变，数字以开户后账号内显示为准）
- **研究方式**：只查公开资料，未创建账号、未登录、未输入任何凭证、手机号、Token、信用卡号
- **参照**：T-003 报告（`results/node-1/T-003-kaggle-free-gpu-for-muse.md`）

---

## 结论先行

1. **真正值得试的只有 3 个，按优先级是：Tiingo Starter、Oracle Cloud Always Free、Groq 免费层。** 其余大多是“免费但用不上”——要么和你已有的 Codex / Antigravity / Kaggle 重叠，要么额度太小跑不完批量测试，要么是一次性体验金。
2. **你的瓶颈不是缺模型、缺 GPU，而是两件事：Muse 总控额度稀缺（2026-11-15 16:01 重置）、股票回测的数据源只有 yfinance 一个非官方单点。** 所以免费资源里最有价值的是补数据可靠性（Tiingo）和补一个 24/7 常驻小主机（Oracle），而不是再找一个 LLM 或 GPU。
3. **免费 GPU 整体不值得追。** 回测是 CPU 活（Python + pandas），Kaggle 每周约 30 小时 T4 x2 已够用；Colab 免费档无额度保证、Lightning 是一次性额度，两者都只是 Kaggle 的备用。
4. **免费 LLM API 里只有 Groq 和 OpenRouter 是长期免费、无卡、可反复用的。** 但两者给的都是开源模型（gpt-oss、Qwen、Nemotron 等），不是 Claude / GPT 原生模型；把编码 Agent 后端指过去等于换模型，不能当 Codex 的平替。Gemini API 和 Antigravity 同一模型家族，重叠最大。
5. **云厂商的“免费”要分清两种：永久免费层和限时试用。** AWS 是 6 个月 $200 体验金、到期即关；GCP 是 90 天 $300 试用 + 永久小额 Always Free；Oracle 是唯一永久免费且能 24/7 常驻的真服务器（2 核 12 GB ARM），但要交卡 + 手机号，且 A1 容量常缺货、闲置 7 天可被回收。

**Chen 的实际需求（本报告的过滤标准，见任务书）**：Muse 总控 + Codex（ChatGPT，GPT-6.1-Sol，额度充足，已调 high）+ Antigravity（Google AI Pro，Gemini 3.8 Flash High）+ 三个免费版 Muse 节点 + GitHub xy3293 + Gmail / Calendar；在做股票 / 加密回测（Python，pandas，Binance / yfinance 数据），J Law 策略股票批量测试待启动（2026-11-15 16:01 后）；不做实盘、不开新策略猎取；总控 Muse 额度稀缺、审批卡每次都要 Chen 点；Codex / Antigravity 额度不缺；Kaggle、Google AI Pro、ChatGPT Codex 已有，不再重推。

**评级说明**：高 / 中 / 低 / 无，理由必须挂钩上文某一具体需求点。事实与推断分开写，不确定的标“未验证”。

---

## §1 免费 GPU / TPU 算力（Kaggle 除外）

Kaggle 结论引用（T-003，不重做）：每周约 30 小时 GPU T4 x2，另有每周最多 20 小时 TPU；云端 Muse 接不上，本地助手可接开源模型；回测不用 GPU。

| 产品 | 给什么 | 额度 / 上限 | 有效期 | 信用卡 / 手机验证 | 自动扣费陷阱 | 有用度 |
|---|---|---|---|---|---|---|
| Google Colab 免费档 | 浏览器 Jupyter Notebook，免费 GPU / TPU | 官方不公布具体额度；单次 Notebook 最长 12 小时；空闲会断开，具体分钟数官方未给。第三方一致称约每周 15–30 小时 T4、约 90 分钟空闲断开——**未验证官方原文** | 永久免费档，无到期日；资源不保证、额度随需求波动 | 无需信用卡（多家 2026 年指南一致陈述；官方 FAQ 未明文写此条）；未见手机验证要求 | 无卡可扣。但禁止 SSH、远程桌面、绕过 Notebook UI、跑分布式计算 worker，违规可被随时终止且无警告 | **低**——回测是 CPU 活，不需要 GPU；已有 Kaggle 每周约 30 小时，Colab 只是无额度保证的备用 |
| Lightning AI 免费档 | 云端开发环境 Studio，可选 T4 16 GB（$0.55/小时）、L4 24 GB（$0.79/小时）、A100 40 GB（$2.19/小时）等，按秒计费 | 免费档最多 30 credits 起步；官网主标题写“最多 50 免费 GPU 小时”，FAQ 写约 50 小时；学术页仍写 80 小时——**两者冲突，以定价页 50 小时为准，80 小时存疑**。免费 Studio 每 4 小时需重启；A100 / H100 会话上限 4 小时 | **一次性 starter grant，不是每月续充**。注册得 5 credits，加卡再得 25 credits；未用完的 credits **12 个月后过期** | 起步无需信用卡；要拿满 30 credits 必须加卡。官网 FAQ 明确因防滥用要求手机号 | 无卡时只用 5 credits，不自动扣费。加卡后 credits 用完转按量付费，无硬性消费上限说明；存储超免费额度后按 $0.10/GB/月计费（第三方 2026-11-02 核查） | **低**——一次性额度、无续充，跑完 50 小时左右即止；回测不用 GPU；只适合一次性想试某个开源大模型推理的单次实验，且要接受加卡 + 手机号验证 |

来源：Colab 官方 FAQ https://research.google.com/colaboratory/intl/en-GB/faq.html；Lightning AI 定价页 https://lightning.ai/pricing；以上均 2026-11-11 核查。

---

## §2 免费云额度 / 免费云主机

| 产品 | 给什么 | 额度 / 上限 | 永久免费 vs 限时试用 | 到期后会发生什么 | 信用卡 / 手机验证 | 自动扣费陷阱 | 有用度 |
|---|---|---|---|---|---|---|---|
| AWS Free Tier | 新账号 $200 credits + 部分 Always Free 服务（Lambda 每月 100 万次请求、DynamoDB 25 GB 等，清单为文档/第三方转述） | $200 credits，**6 个月**内用完。经典 12 个月免费档（EC2 每月 750 小时等）仍见于旧文档，但官方 EC2 页明确写自 2025-07-15 起新客户改领 $200 credits——**新账号以 $200/6 个月为准** | **限时试用（6 个月）+ 部分永久 Always Free** | 官网原文：开户 6 个月后或 credits 用完时免费计划账号自动关闭，“不转付费不扣费”。若已转付费，超限部分按量计费 | 官网新版注册页称大多数新客户起步无需信用卡，但可能被要求额外验证；若被要求提供支付方式，会有 $1 临时预授权（3–5 天释放，不是扣款） | 免费计划本身有保护（不转付费不扣费）。风险在转付费后：超 credits / 超 Always Free 额度即按量计费，需自己设预算告警 | **中**——回测是 CPU 活，EC2 微实例（1 vCPU/1 GB）跑 pandas 偏小，但可作 24/7 常驻小服务（定时拉 Binance / yfinance 数据、跑轻量脚本）的免费宿主；$200 也可短期跑稍大实例。注意 6 个月后即到期，需规划迁移 |
| Google Cloud Free Tier | 两部分：① 免费试用 $300 Welcome credit；② Free Tier（Always Free）：20+ 产品每月额度，包括 1 台 e2-micro VM、Cloud Run 每月 200 万次请求、BigQuery 每月 1 TiB 查询、Cloud Storage 5 GB 等 | 试用 $300，**90 天**（90 天或用完即止）。e2-micro 每月 1 台非抢占式（仅 us-west1 / us-central1 / us-east1 三个美国区域）、30 GB 标准持久盘、1 GB 北美出站流量——**该三项为第三方转述，未在本轮直接打开额度表原文**。试用期间不能给 VM 加 GPU | **$300/90 天是限时试用；Free Tier 无到期日** | 官网原文：90 天到或 $300 用完且未升级，试用账单账号关闭，资源全部停止，进入 30 天宽限期；宽限期内升级可恢复，过期则资源永久删除。升级后剩余 credit 在 90 天内仍可用，Free Tier 继续，超限按标准价计费 | **必须提供信用卡或其他有效支付方式**（官网原文），用于身份验证与防欺诈；会产生 $0–$1 临时预授权，不是扣款 | 试用期内不扣费。风险在升级付费后超 Free Tier 额度即计费；另注意 e2-micro 免费额度只覆盖标准盘，控制台默认建的 balanced 盘不免费（第三方 2026-08-12 核查） | **中**——e2-micro（1 vCPU/1 GB）同样偏小，但 Always Free 无到期日，适合挂一个长期轻量定时任务；$300 试用可短期租稍大 CPU 实例批量跑回测，但 90 天后即止。已有 Google AI Pro 账号不等于已有 GCP 账单账号，需另开 |
| Oracle Cloud Always Free | Always Free：Arm Ampere A1 计算、2 台 AMD 微型 VM、200 GB 块存储、20 GB 对象存储、10 TB/月出站流量、2 个自治数据库、负载均衡器等（服务清单为官网原文） | A1 额度**已核实**：Oracle 官方 Always Free Resources 页原文为 1,500 OCPU 小时 + 9,000 GB 小时/月，相当于 2 OCPU + 12 GB 内存（VM.Standard.A1.Flex），另 2 台 AMD 微型 VM（各 1/8 OCPU + 1 GB）。磁盘口径：200 GB 为 Always Free 块存储总量（含 boot volume），单台 boot volume 最小 47 GB | **Always Free 无到期日**（官网原文“available for an unlimited period of time”）；另有独立的 $300 试用 credit，30 天内用完或到期即止，两者并行 | 30 天后什么都不做，继续享受 Always Free；随时可转 Pay As You Go，超 Always Free 额度才计费。另有回收规则：账号闲置 30 天以上可被视为放弃并暂停/终止；Always Free 计算实例闲置 7 天（CPU/网络/内存 95 分位均 <20%）可被回收（后者为第三方转述） | **需要信用卡/借记卡 + 手机号**（官网 FAQ 原文，需提供卡信息做身份验证，会有临时预授权 hold，几天内解除，不产生实际扣费；不接受 PIN 借记卡、虚拟卡、一次性卡、预付卡）。一人只能开一个免费账号 | 不升级不扣费。风险点：A1 容量常“无库存”（多家指南一致反映，热门区域抢不到）；Home Region 注册后不可改；实例闲置 7 天可被回收，需保持一定负载或接受重建 | **中**——三家中唯一真正“永久免费 + 能 24/7 常驻 + 2 核 12 GB 够跑 pandas 回测/定时任务”的一个；但要交卡 + 手机号，且 A1 是 ARM 架构（部分 Python 包需注意兼容性）、容量不保证、闲置回收是硬伤 |

来源：AWS https://aws.amazon.com/free/、https://aws.amazon.com/ec2/getting-started/；GCP https://cloud.google.com/free/docs/measure-compare-performance；Oracle https://www.oracle.com/sa/cloud/free/、Oracle Always Free Resources https://docs.oracle.com/en-us/iaas/Content/FreeTier/resourceref.htm（A1 额度 2026-11-11 复核，已核实）；以上均 2026-11-11 核查。

**§2 小结**：AWS 是 6 个月体验金、GCP 是 90 天试用 + 永久小额、Oracle 是唯一永久免费且能常驻的真服务器。对回测/定时任务，Oracle 长期价值最高，GCP 次之（额度太小），AWS 适合短期试用。

---
## §3 免费 LLM API 额度

**先说结论**：真正“长期免费、无卡、能反复用”的只有 Groq、OpenRouter、Gemini API 三家；Cerebras 已改为“绑卡 $5 试用、30 天过期”，不是永久免费层；Mistral 2026-10-07 后不再公布免费额度且有用户报告免费 key 被锁；SambaNova 文档与实测冲突；DeepSeek 官方无免费层、Together 已无免费试用。

| 产品 | 给什么（模型） | 额度 / 速率限制 | 有效期 | 信用卡 / 手机验证 | 自动扣费陷阱 | 能否作编码 Agent 后端 | 有用度 |
|---|---|---|---|---|---|---|---|
| Groq | gpt-oss-120b、gpt-oss-20b、qwen3.8-27b（preview，易下线）、Whisper 等。注意 Llama 3.1 8B / Llama 3.3 70B 已于 2026-08-16 移出免费与 Developer 层，改为 Enterprise only | 每模型 30 RPM / 1,000 RPD / 8K TPM / 200K TPD（官方限速页 2026-11-10 抓取）；限速按组织计，先到先停，超了返回 429。上下文长度**未验证** | **永久免费层，无到期日**，按分钟/天配额循环补充 | 无卡（绑卡只是升级到 Developer 才需要）；手机验证**未验证** | 无卡在案，无从扣费。升级后 Developer 按量后付，首张发票在用量达到 $1 时发出 | 可：OpenAI 兼容接口 `https://api.groq.com/openai/v1`，支持自定义 base_url 的工具理论上可指过去，但跑的是开源模型，不是 Claude / GPT 原生模型 | **中**——已有 Codex / Antigravity 且额度充足时，Groq 的价值是“换一个模型家族 + Muse 总控额度耗尽时的备用”；但 200K tokens/天/模型对批量回测代码生成很紧，一天约几百次短对话量级 |
| OpenRouter `:free` | ID 以 `:free` 结尾的轮换清单，2026-10-27 / 2026-11-10 两次核查分别为 28 个、23 个 ID；文本类代表有 Thinking Machines Inkling（975B MoE，1M 上下文）、NVIDIA Nemotron 3 Ultra（550B，1M 上下文）、Gemma 4 31B。**清单几周一换，不可硬编码**；2026-10-26 核查时已无 DeepSeek `:free` 模型 | 20 RPM；50 RPD（累计购买 credit < $10）/ 1,000 RPD（累计购买 ≥ $10，一次即可，终身有效）。无 token/天上限，按请求数计；每日按 UTC 日重置；余额为负时免费模型也报 402 | **永久免费层，无到期日**；$10 门槛按累计购买算，花光也不掉回 50/天。买 credit 时收 5.5% 平台费（最低 $0.80），credit 本身据称不过期 | 无卡可建账号、用免费模型；手机验证**未验证** | 免费调用不花 credit、不扣费；$10 是自愿一次性充值，不是订阅 | 可：OpenAI 兼容接口 `https://openrouter.ai/api/v1`，一个 key 可切几百个模型。注意免费路由的提供方可能留存 / 训练提示词（按上游政策），勿传私密代码与客户数据 | **中**——唯一能在不花钱前提下试到 975B / 550B 级大模型的地方；但 50 次/天对 Agent 循环几乎不够用，1,000 次/天也要先充 $10 才解锁。定位是“试大模型效果”，不是 Codex 平替 |
| Gemini API（Google AI Studio） | 免费列为 “Free of charge” 的有 Gemini 3.8 Flash、3.6 Flash、3.5 Flash-Lite、3.1 Flash-Lite、Gemma 4 等；不在免费层：Gemini 4 Argon、Gemini 3.1 Pro Preview、图片模型、Veo 等 | 官方定价页只写“免费输入输出”，**不再在文档里公布每模型 RPM / RPD 数字**，只在自己项目的 AI Studio 限速页显示。第三方在自家项目 2026-10 实测：Flash 类约 5 RPM / 250,000 TPM / 20 RPD，Flash-Lite 约 10 RPM / 500 RPD——**第三方实测，非官方承诺**。3.8 Flash 上下文**未验证** | **永久免费层，无到期日**，是按限速免费，不是按月送 credit | 无卡（AI Studio 建 key 即可）；官方称部分项目需验证，是否指手机**未验证** | 免费项目无计费账号，不会变出账单。开计费才转 Tier 1，需预付至少 $5 | 有限：这是 Google 自家 API，不是 OpenAI 兼容接口，不能直接把 OpenAI base_url 换过去；需用支持 Gemini provider 的工具或经 LiteLLM 中转（中转方案本次未验证） | **低**——与 Antigravity（Gemini 3.8 Flash High）同一模型家族，重叠最大；20 次/天做批量回测代码生成不够，只适合零星调用、做备用。另注意免费层提示词可能被用于改进 Google 产品，勿传私密代码 |
| Cerebras | 试用层仅 gpt-oss-120b、qwen-3.8-27b 两个 | 官方限速页 Free Trial 表：5 RPM、30K 未缓存 TPM、1M TPD；上下文试用层 65K / 64K（第三方 2026-10-26 复核） | **一次性 $5 credit，授予后 30 天过期，不续**。2026-07-16 起旧永久免费层已取消；官方 FAQ 原话（多家 2026-09—11 复核引用）：“Is there a permanently free tier? No.” | **必须绑验证过的支付方式才激活**，否则 Playground 与 API 保持未激活；手机验证**未验证** | 多家来源称无自动扣费、无自动续订，到期/用完即停，需另买 PayGo 才能继续。卡已在案，仍建议开卡前在控制台确认扣费开关 | 可：OpenAI 兼容接口 `https://api.cerebras.ai/v1`。但试用期仅 30 天 + 5 RPM，不宜作长期后端 | **低**——速度最快的一档，适合 30 天内集中试一次大模型推理；不是可依赖的长期备用，且要绑卡 |
| Mistral La Plateforme Free mode | 原则上全目录：Mistral Large 4（1M 上下文）、Medium 3.5、Small 4、Codestral（代码）、Devstral（Agent 代码）等 | **官方不再公布数字**。官方帮助文（2026-08-12）称 Free mode 有三类上限，具体数字只在账号的 Admin Panel 显示。旧 Experiment 数字（约 1 RPS / 500K TPM / 1B tokens/月）自 2026-10-07 定价页改版后已不可作准 | 名义上是每月循环的 included usage，不是 30 天试用；但金额未公布，且 2026-10-10—16 有用户在 GitHub 讨论中报告免费组织控制台出现 “Upgrade to activate your API keys”、key 创建按钮变灰——**可用性未验证，须以自己账号实测为准** | 官方称 Free mode 默认开启、无卡可建 key；旧 Experiment 要求手机验证，新 Free mode 是否仍要求**未验证** | Pay-as-you-go 是开关；included 用完后停到下月，除非开了 PAYG | API 为标准 chat 接口；Codestral / Devstral 是代码专用模型，理论上可作编码后端，但鉴于免费层可用性存疑，不宜先依赖 | **低**——唯一免费提供代码专用模型（Codestral / Devstral）的一家，但免费额度与可用性现在最不确定，需先实测再决定 |
| Cohere Trial key | Trial key 可用全部 Cohere 模型与 API：Command A / R 系列聊天、Embed、Rerank 等 | **每月 1,000 次 API 调用**；分端点限速：Chat 每模型 20 RPM、Rerank 10 RPM、Embed 2,000 inputs/分钟。每月重置日官方未公布 | **按月重置的试用 key**，不是一次性 credit；明确是评估用途 | 注册即自动发 trial key，无卡；手机验证**未验证** | 未验证；生产需另走 Go to Production + 按量付费 | 有限：有 OpenAI 兼容端点，但 trial key 条款明文“不得用于生产或商业用途”，只能作评估，不宜作长期批量后端 | **低**——1,000 次/月对零星调用够用；Rerank / Embed 免费额度对回测文档检索有附带价值，但主聊天模型非代码专用 |
| SambaNova Cloud | gpt-oss-120b、DeepSeek-V3.1、Llama-3.3-70B 等，名单经常变 | 文档称免费层每模型 20 RPM / 20 RPD / 200K TPD；但 2026-08-31 第三方实测：免费账号调 API 返回 `402 PAYMENT_METHOD_REQUIRED`——**文档与实测冲突，免费层是否真实可用未验证** | 文档称是长期免费层，无到期日；实测冲突，见上 | 文档称否；实测称要绑卡；手机验证**未验证** | 绑卡即转 Developer，按量计费（Stripe） | 可：OpenAI 风格接口；但 20 次/天/模型对 Agent 循环远远不够，只适合单次试模型效果 | **低**——能免费试 DeepSeek-V3.1 / Llama-3.3-70B，但 20 次/天 + 可用性存疑，定位只能是“试效果” |
| DeepSeek 官方 API / Together AI | — | — | **无免费层 / 无免费试用** | DeepSeek：无余额无法调用，需充值；Together：首次购买至少 $15，后续充值至少 $5，全预付 | 预付费，余额为零即停 | — | **无**——DeepSeek 官方定价页无免费层、无新人 credit（第三方流传的 $5 新人 credit 未验证）；Together 官方计费文档明确“does not currently offer free trials”，旧的 $1 新人 credit 已于 2025-08-31 取消 |

来源：Groq 限速 https://console.groq.com/docs/rate-limits；Cerebras 限速 https://inference-docs.cerebras.ai/support/rate-limits；Gemini 限速 https://ai.google.dev/gemini-api/docs/rate-limits；Cohere 限速 https://docs.cohere.com/docs/rate-limits；OpenRouter 复核 https://aifree.dev/learn/free-openrouter-models；以上均 2026-11-11 核查。

---

## §4 免费开发 / 协作工具

| 产品 | 给什么 | 额度 / 上限 | 有效期 | 信用卡 | 自动扣费陷阱 | 有用度 |
|---|---|---|---|---|---|---|
| GitHub Free（已有） | 无限公开+私有仓库、无限协作者、Actions、Codespaces、Pages（公开库） | Packages 500 MB；Codespaces 每月 120 核小时 + 15 GB 存储；Actions 官方 plans 页现写每月 $12 计算额度（Free），公开库标准 Runner 免费且不限分钟。第三方仍写私有库每月 2,000 分钟——**与官方现行表述口径不同，未验证** | 永久免费档 | 否（默认支出上限 $0，超额即停，不自动扣费） | 默认支出上限 $0，超额后私有库任务停止，直到下月重置，不会自动扣费 | **高**——已在用，muse-hub 即跑其上；免费档已够公开仓库 + Actions 的全部需求 |
| Obsidian（免费版） | 本地优先 Markdown 笔记应用，全部核心功能：无限库、插件、关系图谱、Canvas；文件就是本地 .md 文件夹 | 无功能上限、无需注册账号；商业用途亦免费（许可证页 2025-02-20 更新） | 永久免费 | 否 | 无。付费附加仅 Sync（$4/用户/月起）与 Publish（$8/站点/月起），均为可选 | **高**——零成本、文件本地、与 muse-hub 的 .md 工作流同构；唯一成本是跨设备同步需自备云盘文件夹或付费 Sync |
| VS Code | 完整代码编辑器：调试、Git 集成、海量扩展；个人与商业用途均免费 | 编辑器本身无付费档、无功能上限；Copilot 是独立产品、另计费，与编辑器本身无关 | 永久免费 | 否 | 无 | **高**——Python / pandas 回测的默认编辑器，无需任何新投入 |
| Notion Free | 个人无限页面与块、数据库、Notion Calendar、基础表单、公开站点、有限 Notion AI 试用 | 1 名所有者：无限块；2 名以上所有者：整个工作区终身 1,000 块，删除不返还，触顶后有 3 天宽限期；单文件 ≤5 MB；页面历史 7 天；外部访客 10 人 | 永久免费档 | 否 | “多人协作”最容易踩坑：第二个人一加入即触发 1,000 块终身上限；绕法是只留 1 名成员、其余作访客 | **中**——单人研究笔记、回测记录本可用；若想让 3 个 Muse 节点 / 总控共用一个工作区协作，立即触顶，不适合 |
| GitLab Free | 源码管理、内置 CI/CD、基础项目管理看板、基础 SAST；自托管免费版可自带存储与 Runner | GitLab.com：私有顶级群组 5 用户；CI 计算分钟 400/月；存储 10 GiB；2026-01-27 后新建账号限 3 个顶级群组（第三方转述，未验证官方原文） | 永久免费档 | 免费注册不需卡；“用共享 Runner 需绑卡”来自第三方，未验证官方原文 | 额外计算分钟 $10/1,000 分钟（付费档价目，第三方转述） | **低**——功能与 GitHub 高度重叠，400 分钟仅为 GitHub 的约 1/5，5 人上限、无迁移收益；Chen 已在 GitHub，无迁移理由 |

来源：GitHub 官方 https://docs.github.com/en/get-started/learning-about-github/githubs-plans；Obsidian 定价/许可证页（经 https://dupple.com/learn/is-obsidian-free 2026-10-28 核对）；Notion 免费档上限（经 https://zentor.ai/blog/notion-free-plan-limits 2026-10-21 核对）；以上均 2026-11-11 核查。

---

## §5 免费数据 / 行情数据（回测用）

| 产品 | 数据（覆盖） | 延迟 | 免费限额 | 需 API Key？ | 需信用卡？ | 有用度 |
|---|---|---|---|---|---|---|
| Binance 公共 API（已有） | 加密现货+期货：实时价、K 线、盘口、成交、24h 统计、资金费率、持仓量 | 实时；另有 WebSocket 流 | 现货 6,000 请求权重/分钟/IP；期货 2,400 权重/分钟/IP；超限 429，忽视 429 可升级为 418（IP 封禁 2 分钟至 3 天）。另有第三方页面仍写 1,200 权重/分钟，疑似旧值——**未验证/疑似过时** | 行情不需要；账户/交易才需要 | 否 | **高**——加密回测主力，已在用；股票回测用不上 |
| yfinance（已有） | 全球股票/ETF/指数/外汇：日线+分钟线、财报、期权链、公司行动 | 日线为主；分钟线最长 60 天 | 无官方公布限额或 SLA；Yahoo 按其“绝对自主裁量”限流，重度使用会触发 429；非官方经验值约 2,000 请求/小时（个人测试，未验证） | 否 | 否 | **高**——股票回测主力，但非官方、无 SLA；它是主力也是单点故障，Yahoo 一改接口即全网同断，需缓存 + 备用源 |
| Tiingo Starter | 美股+中概 EOD（30 年以上日线，可溯至 1962）、ETF/共同基金、加密、外汇、新闻；IEX 分钟线；财报为第三方数据集，需另付费附加 | 收盘价（EOD） | 50 请求/小时、1,000/天、500 独立代码/月、1 GB 带宽/月；无每分钟上限，适合夜间批量回填 | 是（免费 Token） | 未验证（定价页写 $0，未提卡） | **高**——J Law 批量股票测试的最佳免费补充：EOD + 1,000/天 + 500 代码/月，恰好覆盖“先批量筛、再精细测”的节奏；1,000/天的天花板意味着全市场 5,000 只票一次扫完需 5 天以上，需分批缓存 |
| Twelve Data Basic | 美股/ETF 实时、外汇、加密、基金、技术指标、财报；覆盖 50+ 国家 | 实时（美股，免费档亦含实时价，但许可限内部非展示使用） | 8 API 积分/分钟、800/天；`/time_series` 每代码 1 积分，`/income_statement` 每代码 100 积分——财报在免费档基本不可用 | 是 | 未验证 | **中**——实时价补充、单票快速验证可用；800/天、财报 100 积分/只，批量回测与筛股不够 |
| CoinGecko Demo | 18,000+ 币种现货价、市值、量；DEX 代币 | 约每分钟更新 | 10,000 调用/月；2026-05-17 起每分钟上限由 30 上调至 100；免费档历史据第三方为 365 天（未验证官方原文） | Demo Key 免费注册可得；无 Key 更严 | 否 | **中**——加密广度补充（Binance 之外的小币种、多交易所均价）；但历史短、不含交易所特异性波动，不适合精细回测主源 |
| Alpha Vantage Free | 美股日线 25 年以上、财报、外汇、加密、50+ 技术指标、新闻情绪 | 免费档日线/收盘价；实时与 15 分钟延迟为付费专属 | 25 请求/天、5/分钟（2023 年由 500/天收紧至今） | 是（免费 Key） | 否 | **低**——25/天连一只票的日线 + 四张财报都拉不全，只适合原型验证，不适合 J Law 批量测试 |
| Stooq | 全球股票/ETF/指数/外汇/商品：日线、小时、5 分钟 CSV/批量文件 | 日线（隔夜更新） | 无官方公布额度；2026 年起脚本访问不可靠：2026-03 起 CSV 下载开始要求 API Key，2026-05 至 06 全站加 JavaScript proof-of-work 检查，2026-10-04 实测脚本请求仍返回 Access denied | 2026 年起 CSV 下载需申请 API Key（此前免 Key） | 否 | **低**——曾是 Yahoo 崩了时的标准备用，现脚本管线不可靠，不宜作新依赖；仅适合手工一次性下载 |
| EODHD Sandbox Free | 全球 EOD、部分日内/新闻/搜索；仅过去 1 年历史 | 免费档 15 分钟延迟 | 20 调用/天、20/分钟；另有 500 迎新调用 | 是 | 否（官方写 No credit card required） | **低**——20/天仅够试接口，跑不完任何批量测试 |
| FMP Basic | 美股 EOD、公司档案、参考数据；财报在免费档受限 | 收盘价（EOD） | 250 调用/天；500 MB 带宽/30 天；约 5 年历史；仅部分代码 | 是 | 未验证 | **低**——250/天、代码不全、财报受限，批量股票测试不够；可作 Tiingo 的次备用 |

**§5 小结**：主力不变——股票用 yfinance（日线深、无 Key），加密用 Binance（实时、无 Key）。最值得补的免费源是 Tiingo Starter，补 yfinance“非官方、随时可断”的短板；建议先拉 Tiingo 作交叉校验与缓存，不替换 yfinance。Alpha Vantage、EODHD、FMP 均跑不完批量测试，只能作单票验证；Stooq 已不适合做自动化管线。

来源：Tiingo https://stockmarketstack.com/tools/tiingo（2026-10-09）、https://www.anchorterminal.com/tools/tiingo（2026-11-03 核实）；Binance 限额（经 https://github.com/nanookai/binance-api/blob/HEAD/skills/binance-api/SKILL.md 等多来源核对）；CoinGecko 官方 Changelog https://docs.coingecko.com/changelog?page=2；EODHD 官方 https://eodhd.com/financial-apis/api-limits；以上均 2026-11-11 核查。

---

## §6 其他可能相关的免费资源

只写与回测 / GitHub / AI-Agent 工作流相关的，不相关的不写。

| 产品 | 给什么 | 额度 / 上限 | 有效期 | 信用卡 | 自动扣费陷阱 | 有用度 |
|---|---|---|---|---|---|---|
| Google Drive（已有 Google 账号） | 15 GB 云存储，与 Gmail + Photos 共用同一池 | 单文件 ≤5 TB；每用户 24 小时内上传/复制 ≤750 GB；回收站文件 30 天后删除，仍计额度直至彻底删除；超额后无法上传，超额持续 2 年以上 Google 可能删除全部内容。新账号 2026-03-09 起先给 5 GB，验证手机号后解锁至 15 GB（第三方 2026-10 转述，未直接打开 Google 帮助页核对） | 永久免费 | 否 | 无（超额只停传） | **高**——回测结果、报告备份已在用；已有 Google 账号，零新增成本。注意 15 GB 是三处共用，Gmail 大附件会挤占 |
| Cloudflare Tunnel（Zero Trust Free） | 把本地服务经 outbound 连接发布为公网 HTTPS，无需开入站端口；可加 Access 身份校验 | Zero Trust Free：50 用户、50 个 Access 应用、3 个地点、日志 24h；单请求体 100 MB；每账号 1,000 条隧道 | 永久免费档 | 未验证（定价页摘要中未明示是否强制绑卡） | 超 50 用户后按 $7/用户/月全量计费；另需自备域名（DNS 托管于 Cloudflare，约 $10/年，trycloudflare 临时隧道除外） | **高**——T-003 已验证的隧道推理技术栈可复用：本地 Agent、Jupyter、回测结果页均可经此安全暴露；比 ngrok 免费档更慷慨（无请求数/流量计费） |
| Cloudflare R2 | S3 兼容对象存储 | 每月免费：10 GB Standard 存储、100 万 A 类操作/月、1,000 万 B 类操作/月、出站流量免费；超额存储 $0.015/GB/月、A 类 $4.50/百万、B 类 $0.36/百万；免费额度仅适用于 Standard 存储 | 永久免费层（按月循环） | 未验证（是否强制绑卡未在本次核对的定价页摘要中明示） | 按量计费，超额线性计费、无陡崖 | **中**——回测产物、批量结果文件、报告附件的“对象仓库”；10 GB 对 CSV 结果集够用，出站免费意味着可直接对外分享结果链接 |
| Tailscale Personal | 基于 WireGuard 的零配置组网：设备间私网直连、MagicDNS、子网路由、出口节点、ACL | 免费 Personal：3 用户、100 设备、几乎全部功能、超额设备 $0.50/台。另有 2026-07 文章称 6 用户/不限设备，与 2026-11-03 核对官方页的 3 用户/100 设备冲突——**6 用户一说未验证/疑似旧版** | 永久免费 | 否 | 超限后按设备计费或升级付费档 | **中**——家里 / 云端多台回测机组私网，SSH 与 Jupyter 不暴露公网；与 Cloudflare Tunnel 互补（一个对内组网、一个对外发布） |
| UptimeRobot Free | 网站 / API 存活监控：HTTP、关键词、Ping、端口监控 + 邮件告警 + 1 个基础状态页 | 50 个监控、5 分钟检查间隔、5 个集成、3 个月历史；付费档才有 60 秒/30 秒/15 秒间隔与 SSL/DNS 监控 | 永久免费档 | 否（官方定价页明写 No credit card required） | 无；付费档才有更短间隔 | **中**——监控自建的回测结果页、隧道端点、GitHub Pages 是否存活；5 分钟延迟对回测场景可接受 |
| ngrok Free | 本地 HTTP / TCP / TLS 服务的公网隧道、请求检查 UI、1 个免费静态开发域名 | 1 用户、1 个活跃端点、20,000 HTTP 请求/月、1 GB 出站流量/月、5,000 TCP 连接/月；HTTP 端点首次访问有 interstitial 提示页 | 永久免费档 | 未验证（需账号+邮箱验证，信用卡是否必需未验证） | 超 20k 请求或 1 GB 即停，需等月度重置或升级 | **低**——功能与 Cloudflare Tunnel 重叠且更受限（20k 请求、1 GB），无替代价值；仅在已有 ngrok 习惯或需 TCP 端点时考虑 |

来源：Cloudflare R2 定价（经 https://dev.to/nayankyada/cloudflare-r2-pricing-2026-free-tier-limits-egress-costs-when-to-upgrade-52ph 2026-10-19 核对）；Cloudflare Tunnel（经 https://www.securecoding.com/compare/cloudflare-zero-trust-vs-twingate/ 2026-10-02 核对官方计划页）；UptimeRobot 官方 https://uptimerobot.com/pricing/；Tailscale 定价核对 2026-11-03；以上均 2026-11-11 核查。

---
## §7 总表 + 推荐清单

### 总表（按类别，每产品一句话）

| 类别 | 产品 | 有用度 | 一句话理由（挂钩 Chen 实际需求） |
|---|---|---|---|
| 1 GPU/TPU | Google Colab 免费档 | 低 | 回测是 CPU 活，不需要 GPU；已有 Kaggle 每周约 30 小时，Colab 只是无额度保证的备用 |
| 1 GPU/TPU | Lightning AI 免费档 | 低 | 一次性额度、无续充，跑完 50 小时左右即止；回测不用 GPU，只适合单次实验 |
| 2 云 | AWS Free Tier | 中 | 可作 24/7 常驻小服务宿主，但 6 个月 $200 到期即关，需规划迁移 |
| 2 云 | Google Cloud Free Tier | 中 | Always Free 无到期日，适合长期轻量定时任务，但 e2-micro 只有 1 核 1 GB，偏小 |
| 2 云 | Oracle Cloud Always Free | 中 | 唯一永久免费 + 能常驻 + 2 核 12 GB 够跑 pandas 回测，但要交卡 + 手机号，且 A1 容量不保证、闲置可被回收 |
| 3 LLM API | Groq | 中 | 换一个模型家族 + Muse 总控额度耗尽时的备用，但 200K tokens/天对批量代码生成很紧 |
| 3 LLM API | OpenRouter `:free` | 中 | 唯一能免费试 975B / 550B 大模型的地方，但 50 次/天对 Agent 循环几乎不够用 |
| 3 LLM API | Gemini API | 低 | 与 Antigravity 同一模型家族，重叠最大；20 次/天做批量生成不够 |
| 3 LLM API | Cerebras | 低 | 一次性 $5 / 30 天试用，要绑卡，不是可依赖的长期备用 |
| 3 LLM API | Mistral Free mode | 低 | 唯一免费给代码专用模型的一家，但 2026-10 有用户报告免费 key 被锁，可用性未验证 |
| 3 LLM API | Cohere Trial key | 低 | 每月 1,000 次调用，评估用途，不宜作长期批量后端 |
| 3 LLM API | SambaNova Cloud | 低 | 20 次/天 + 文档与实测冲突，可用性未验证，只能试效果 |
| 3 LLM API | DeepSeek / Together | 无 | 官方无免费层 / 无免费试用，需预付充值 |
| 4 开发工具 | GitHub Free | 高 | 已在用，muse-hub 即跑其上；免费档已够公开仓库 + Actions 的全部需求 |
| 4 开发工具 | Obsidian 免费版 | 高 | 零成本、文件本地、与 muse-hub 的 .md 工作流同构 |
| 4 开发工具 | VS Code | 高 | Python / pandas 回测的默认编辑器，无需任何新投入 |
| 4 开发工具 | Notion Free | 中 | 单人研究笔记可用；若 3 个 Muse 节点共用一个工作区，立即触顶 |
| 4 开发工具 | GitLab Free | 低 | 功能与 GitHub 高度重叠，CI 仅 400 分钟/月，无迁移理由 |
| 5 数据 | Binance 公共 API | 高 | 加密回测主力，已在用；实时、无 Key |
| 5 数据 | yfinance | 高 | 股票回测主力，日线深、无 Key，但非官方、无 SLA，是单点故障 |
| 5 数据 | Tiingo Starter | 高 | J Law 批量股票测试的最佳免费补充，EOD + 1,000/天 + 500 代码/月，补 yfinance 单点短板 |
| 5 数据 | Twelve Data Basic | 中 | 实时价补充、单票验证可用；800/天、财报 100 积分/只，批量不够 |
| 5 数据 | CoinGecko Demo | 中 | 加密广度补充，但历史短，不适合精细回测主源 |
| 5 数据 | Alpha Vantage Free | 低 | 25/天跑不完批量测试，只适合原型验证 |
| 5 数据 | Stooq | 低 | 2026 年脚本访问已不可靠，不宜作新管线依赖 |
| 5 数据 | EODHD Sandbox | 低 | 20/天仅够试接口 |
| 5 数据 | FMP Basic | 低 | 250/天、代码不全、财报受限，批量不够 |
| 6 其他 | Google Drive | 高 | 回测结果、报告备份已在用；已有 Google 账号，零新增成本 |
| 6 其他 | Cloudflare Tunnel | 高 | T-003 隧道技术栈可复用，本地 Agent / 回测结果页可安全暴露，比 ngrok 更慷慨 |
| 6 其他 | Cloudflare R2 | 中 | 回测产物、批量结果文件的对象仓库；10 GB 够用，出站免费 |
| 6 其他 | Tailscale Personal | 中 | 多台回测机组私网，SSH / Jupyter 不暴露公网；与 Tunnel 互补 |
| 6 其他 | UptimeRobot Free | 中 | 监控自建结果页 / 隧道端点是否存活；5 分钟延迟对回测可接受 |
| 6 其他 | ngrok Free | 低 | 与 Cloudflare Tunnel 重叠且更受限（20k 请求、1 GB），无替代价值 |

### 值得试的清单（最多 3 个，按优先级）

**1. Tiingo Starter——最优先，补股票数据单点**
- 第一步：去 Tiingo 官网注册免费 Starter，领 API Token，存本地（只存本地，不进仓库、不贴聊天记录）；先拉一只美股（如 AAPL）过去 5 年 EOD 日线，和 yfinance 同一只票交叉对一遍收盘价。
- 要准备什么：一个邮箱（注册用）；Python 环境里装好 `requests` / `pandas` 即可，不需要信用卡（定价页写 $0，未提卡——是否强制绑卡未验证，开户时以页面实际提示为准）。
- 预计花多少时间：约 30 分钟验证通；再花约 1 小时把 Tiingo 写成 yfinance 的备用拉数函数（先查 Tiingo、失败回落 yfinance，并把结果缓存到本地 CSV）。

**2. Oracle Cloud Always Free——第二，补一个 24/7 常驻小主机**
- 第一步：去 Oracle Cloud 注册免费账号（需信用卡/借记卡 + 手机号做身份验证，会有临时预授权 hold，不是扣款）；选 Home Region 时优先选离你近且 A1 有库存的区域，注册后不可改；尝试创建 1 台 Ampere A1（2 OCPU + 12 GB）+ 1 台 AMD 微型 VM，装 Python + pandas，跑一个定时拉 Binance / yfinance 数据的小脚本。
- 要准备什么：信用卡/借记卡 1 张（不接受虚拟卡、预付卡）、手机号 1 个、一个邮箱；接受 ARM 架构（部分 Python 包需注意兼容性）。
- 预计花多少时间：约 1–2 小时开户 + 建机（A1 容量常缺货，抢不到就换区域再试，不要反复刷）；建好后再花约 30 分钟把定时任务挂上去。**注意**：实例闲置 7 天可被回收，要保持一定负载或接受重建；不要把重要数据只放这台机上，定期备份到 Google Drive。

**3. Groq 免费层——第三，补 Muse 总控额度耗尽时的备用 LLM**
- 第一步：去 Groq 官网注册（无需信用卡），建一个 API key，存本地；用 `openai/gpt-oss-120b` 调一次简单对话，确认 30 RPM / 1,000 RPD / 200K TPD 的免费层在你账号上可用；再在本地编码助手里把 base_url 指到 `https://api.groq.com/openai/v1` 试一次小任务，确认工具调用质量是否可接受。
- 要准备什么：一个邮箱（注册用）；不需要信用卡、不需要手机号（手机验证未验证，开户时以页面实际提示为准）。
- 预计花多少时间：约 20 分钟验证通；再花约 30 分钟试一次编码 Agent 后端切换。**注意**：跑的是开源模型，不是 Claude / GPT 原生模型，能力、工具调用水平都会变；200K tokens/天只够几百次短对话，不能当批量主力。

### 不值得试的（为什么不试）

- **免费 GPU（Colab、Lightning 等）**：回测是 CPU 活，Kaggle 每周约 30 小时已够用；Colab 无额度保证，Lightning 是一次性体验金，追了也用不上。
- **AWS 6 个月 $200 / GCP $300 试用**：适合短期试用，不适合做长期依赖；到期即关或即删，迁移成本高于收益。已有 Oracle 永久免费在先，试用只在“短期要跑稍大实例”时才考虑。
- **Gemini API、Cerebras、Mistral、SambaNova、DeepSeek、Together**：Gemini 与 Antigravity 同一模型家族，重叠；Cerebras 30 天过期 + 要绑卡；Mistral / SambaNova 可用性存疑（2026-10 有锁 key / 402 拒接报告）；DeepSeek / Together 根本无免费层。
- **GitLab、Notion 多人协作、Alpha Vantage、EODHD、FMP、Stooq、ngrok**：GitLab 与 GitHub 重叠且 CI 只有 400 分钟/月；Notion 多人一加入即触 1,000 块上限；Alpha Vantage 25/天、EODHD 20/天、FMP 250/天都跑不完 J Law 批量测试；Stooq 2026 年脚本访问已不可靠；ngrok 比 Cloudflare Tunnel 更受限。

---

## §8 未验证 / 未查到清单

- Colab 免费档每周 GPU 小时数（15–30 小时）、90 分钟空闲断开、T4 16 GB 型号：官方 FAQ 明确不公布额度与型号，以上均为 2026 年第三方指南一致陈述，未验证官方原文。
- Lightning AI “80 GPU 小时”与定价页“50 GPU 小时”冲突；30 credits 折算 T4 约 75 小时、免费存储 50 GB vs 200 GB 冲突：均存疑，以定价页 50 小时 / 50 GB 为准。
- AWS 经典 12 个月免费档对 2025-07-15 后新账号是否仍可用：官方 EC2 页称新客户改领 $200 credits，多家 2026 年来源称经典档已取消；新账号按 $200/6 个月处理。AWS Always Free 逐项清单亦为文档/第三方转述。
- GCP e2-micro 的 30 GB 标准盘、1 GB 出站流量、仅 3 个美国区域：第三方转述，未在本轮直接打开额度表原文；Google 可提前 30 天变更 Free Tier 的条款亦为第三方说法。
- Oracle A1 的 10 TB 出站、闲置 7 天回收：第三方转述 Oracle 文档，未在本轮直接打开 Always Free 额度表原文（2 OCPU/12 GB、200 GB 块存储总量及单台 boot volume 最小 47 GB 已于 2026-11-11 用 Oracle 官方 Always Free Resources 页核实，见 §2，不再列入未验证）。
- Groq 各模型上下文长度、是否需手机验证；Cerebras / OpenRouter / Cohere / SambaNova 是否需手机验证；Gemini API 当前 Flash 模型的准确 RPM / RPD（官方不再公布，只能看自己项目的 AI Studio 限速页）；Gemini 3.8 Flash 上下文。
- Mistral 新 Free mode 的具体每月额度、是否仍需手机验证、数据是否用于训练、免费 key 在 Chen 的账号上是否能激活（2026-10 有用户报告被锁）。
- SambaNova 免费层是否真实可用（文档称可用，2026-08-31 实测称 402 拒接）；DeepSeek 官方新人 credit 是否存在、金额与有效期（官方页无说法，第三方说法互相冲突）。
- GitHub Actions 私有库“2,000 分钟/月”与官方现行“$12 计算额度”表述口径不同，未直接打开官方 Actions 计费页核对。
- Binance 现货 1,200 权重/分钟一说疑似旧值，与多来源的 6,000 不一致，未验证。
- Tiingo / Twelve Data / FMP、Cloudflare R2 / Tunnel、ngrok 免费档是否强制绑卡：定价页写 $0 或未明示，未验证。
- Tailscale 免费档 6 用户 / 不限设备一说与 2026-11-03 核对官方页的 3 用户 / 100 设备冲突，未验证。
- CoinGecko 免费档历史 365 天、yfinance 非官方经验限流值（约 2,000 请求/小时）、Google Drive 新账号 5 GB 起：均为第三方说法，未直接打开官方原文核对。
- 各家把 key 指给 Claude Code / Codex CLI / opencode 的逐一接线验证（只确认了接口是 OpenAI 兼容，未逐一实测每个 Agent）。
- Fireworks AI、Cloudflare Workers AI、NVIDIA build.nvidia.com 等本次未深入核查，不列入正表，需另查。

---

## 来源清单（2026-11-11 核查）

**官方**
- Google Colab FAQ：https://research.google.com/colaboratory/intl/en-GB/faq.html
- Lightning AI 定价页：https://lightning.ai/pricing
- AWS Free Tier：https://aws.amazon.com/free/；AWS EC2 入门页：https://aws.amazon.com/ec2/getting-started/
- Google Cloud 免费计划文档：https://cloud.google.com/free/docs/measure-compare-performance
- Oracle Cloud Free Tier：https://www.oracle.com/sa/cloud/free/；Oracle Always Free Resources：https://docs.oracle.com/en-us/iaas/Content/FreeTier/resourceref.htm（A1 额度 2026-11-11 复核，已核实）
- Groq 限速：https://console.groq.com/docs/rate-limits
- Cerebras 限速：https://inference-docs.cerebras.ai/support/rate-limits
- Gemini 限速：https://ai.google.dev/gemini-api/docs/rate-limits
- Cohere 限速：https://docs.cohere.com/docs/rate-limits
- GitHub 计划页：https://docs.github.com/en/get-started/learning-about-github/githubs-plans
- CoinGecko Changelog：https://docs.coingecko.com/changelog?page=2
- EODHD API 限额：https://eodhd.com/financial-apis/api-limits
- UptimeRobot 定价：https://uptimerobot.com/pricing/

**第三方（交叉验证用，非官方）**
- OpenRouter 免费模型复核：https://aifree.dev/learn/free-openrouter-models
- Gemini 免费层复核：https://dev.to/hassann/gemini-api-free-tier-in-2026-limits-models-and-when-you-get-billed-4081
- Tiingo：https://stockmarketstack.com/tools/tiingo、https://www.anchorterminal.com/tools/tiingo
- Binance 限额复核：https://github.com/nanookai/binance-api/blob/HEAD/skills/binance-api/SKILL.md
- Notion 免费档上限：https://zentor.ai/blog/notion-free-plan-limits
- Obsidian 免费说明：https://dupple.com/learn/is-obsidian-free
- Cloudflare R2 定价复核：https://dev.to/nayankyada/cloudflare-r2-pricing-2026-free-tier-limits-egress-costs-when-to-upgrade-52ph
- Cloudflare Tunnel 复核：https://www.securecoding.com/compare/cloudflare-zero-trust-vs-twingate/
- 其他第三方复核见各节“来源”行。

---

*报告人：node-1；研究完成日期：2026-11-11。本报告不含任何真实账号、手机号、Token、密钥、信用卡信息。*
