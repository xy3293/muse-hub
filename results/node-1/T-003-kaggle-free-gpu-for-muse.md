# T-003 Kaggle 免费 GPU 接入 Muse 研究

- **任务**：T-003 Kaggle 免费 GPU 接入 Muse 研究
- **负责人**：node-1
- **核查日期**：2026-11-11（所有数字、链接均为本日核查；Kaggle 免费额度随时可变，数字以开户后账号内显示为准）
- **研究方式**：只查公开资料，未创建 Kaggle 账号、未登录、未输入任何凭证、手机号、Token
- **视频输入**：抖音短视频（作者：晚睡.，2026-11-10 发布，标题“给你的 Muse 配上免费 GPU！Kaggle 领取＋接入教程”，https://www.douyin.com/video/7706413710163725594）。总控已看过视频，本次未重复看视频；视频声称内容按任务书转述核对

---

## 结论先行

1. **能弄，免费，但别按视频字面理解。** Kaggle 每周免费约 30 小时 GPU（官方原话“30 hours or sometimes higher”，按周重置），另有每周最多 20 小时 TPU，两者是分开的池子。视频说的“每周 30 小时”属实。
2. **视频最关键的一句是错的。** “把 .md 发给 Muse 即可”不成立：一段 .md 文字不能让任何 Muse 获得 GPU。GPU 只能跑你写进 Notebook 的代码、或跑在上面的开源模型；Muse 本体（无论云端还是本地编程助手）都不可能“跑在”Kaggle GPU 上。
3. **“Muse”有三种可能所指，结论都一样。** 云端 Muse（本账号这类 Meta 个人 AI 助手）完全接不上 Kaggle GPU——它跑在 Meta 服务端，没有外接推理后端的功能；本地编程助手（Claude Code / Codex CLI / opencode）可以把推理后端指向 Kaggle 上跑的开源模型，但那时跑的就不再是 Claude 等原生模型，而是 Qwen、GLM 这类开源模型，能力完全不同。
4. **真正可走通的路线有 4 条（§4），推荐顺序是：浏览器 Notebook 先验证 → CLI 脚本核作日常 → 只有明确要“编码 Agent 对话时用开源模型推理”才碰 Ollama + 隧道。** 隧道推理服务器是唯一能让 Agent“对话”用上 GPU 的形态，也是最脆弱、最贴近合规红线的一种。
5. **合规红线真实存在，不是吓唬人。** Kaggle 可接受使用政策（AUP，2025-06-22 生效）明确把“server farming（服务器农场）”“挖矿”“与 ML 数据科学无关的活动”列为资源滥用；使用条款规定一人只能有一个账号、仅限个人非商业自用。把 Kaggle 当 24/7 常驻推理服务、或开小号刷额度，都会导致封号。
6. **第一步只需要 3 样东西**：一个 Google 账号、一个能收短信的手机号（一个号只能验证一个账号）、约 30 分钟。不需要信用卡（见 §2 说明与保留）。

---

## §1 Kaggle 免费 GPU 现状（截至 2026-11-11）

| 项目 | 现状 | 来源与日期 |
|---|---|---|
| 每周 GPU 额度 | 30 小时，或“有时更高，取决于需求与资源”；按周重置 | Kaggle 官方《Efficient GPU usage》，2026-11-11 核查 |
| 计费方式 | T4 x2 跑 1 小时计 1 小时额度（不是按 2 张卡计 2 小时）；P100 同池同价 | Kaggle 官方讨论帖中的员工回复，经第三方文章转述（2026-11-06 更新）；官方文档正文未写此条，见“未验证”清单 |
| GPU 硬件 | **GPU T4 x2：2 张 NVIDIA T4，每张 16 GB 显存**；4 CPU 核；29 GB 内存 | Kaggle 官方《Notebooks》技术规格 + P100 退役公告，2026-11-11 核查 |
| P100 是否退役 | **是，已于 2026-09-15 退役**；此后 P100 选项不再出现，旧 Notebook 被自动切换为 T4 x2 | Kaggle 官方公告《Sunsetting the NVIDIA Tesla P100 GPU on September 15, 2026》，2026-11-11 核查 |
| 单次会话上限 | CPU / GPU 会话最长 12 小时；TPU 会话最长 9 小时；“Save & Run All”整本重跑同样受 12 小时（TPU 9 小时）限制 | Kaggle 官方《Notebooks》技术规格，2026-11-11 核查 |
| 空闲超时 | **官方两处文档自相矛盾**：《Notebooks》写交互会话空闲 20 分钟结束；《Efficient GPU usage》写 60 分钟空闲上限。请按较严的 20 分钟规划，用完主动 Stop 会话 | Kaggle 官方文档，2026-11-11 核查 |
| 保存空间 | `/kaggle/working` 自动保存 20 GB，可在以后 Notebook 里复用；之外的临时磁盘不保存 | Kaggle 官方《Notebooks》，2026-11-11 核查 |
| 排队与可用性 | 免费 GPU 数量有限，**忙时要排队**；无可用性保证；额度以账号设置页显示为准 | Kaggle 官方《Notebooks》“Adding a free GPU”一节，2026-11-11 核查 |
| TPU | 官方文档仍写 **TPU v3-8，每周最多 20 小时，单次最长 9 小时**；但 2026-08-31 以来多个独立来源与开源项目显示实际提供的是 **TPU v5e-8（8 芯片 × 16 GB = 128 GB）**。以打开 Notebook 时 Accelerator 菜单实际显示的为准 | 官方《TPU》文档（2026-11-11 核查，内容仍为 v3-8）+ kaggle-tpu-lab 等第三方（见 §4d） |
| 补充额度 | 链接 Colab Pro / Pro+ 账号可再得每周 15 / 30 小时 GPU（不消耗 Colab 算力单元）；官方标注为**限时推广，Kaggle 可随时无通知终止**，且仅限一个 Kaggle 账号绑定一个 Colab 订阅 | Kaggle 官方《Notebooks》“Increase GPU compute with Colab Pro”一节，2026-11-11 核查 |
| 互联网开关 | 新 Notebook 默认开启互联网；可在 Settings 里开关；API 提交时在 kernel metadata 里设 `enable_internet` | Kaggle 官方《Notebooks》，2026-11-11 核查 |

**需要注意的文档滞后**：Kaggle 官方《Notebooks》与《Efficient GPU usage》正文至今仍写“P100”，而 P100 已于 2026-09-15 退役（官方公告为准）。读官方文档时以公告 + 技术规格表里的 T4 x2 为准，P100 字样视为未更新的旧文。同样，TPU 文档仍写 v3-8，与 2026 年下半年实际提供的 v5e-8 不符，见上表。

---

## §2 开通门槛

| 问题 | 答案 | 来源与日期 |
|---|---|---|
| 需要手机验证吗 | **是。所有 GPU 都要求手机验证**；TPU 与较稀缺的 GPU（RTX Pro 6000、L4x4）还要求**手机验证 + 身份验证**（Persona） | Kaggle 员工在官方讨论帖的回复（约 2026-10-23 发布，2026-11-11 核查）；kaggle-tpu-lab README 亦称 TPU 需“手机号，部分账号需 Persona 身份核查” |
| 在哪里验证 | 账号 Settings（头像 → Settings）里的 Phone Verification，短信验证码；TPU 的身份验证从同一设置页发起 | 多个第三方指南一致描述；官方文档未写明入口位置，**未验证**官方原文 |
| 需要信用卡吗 | **Kaggle Notebook 本身不需要信用卡，也没有付费档。** 但注意两点：① 官方文档未用一句话写明“不需要信用卡”，此处依据是 Kaggle 无付费订阅 + 多个 2026 年指南一致陈述；② Notebook 里集成的 Google Cloud 服务（BigQuery、GCS、AutoML）是付费的，需要绑定计费的 GCP 账号——不用这些集成就不花钱 | Kaggle 官方《Notebooks》“Connecting to Google Cloud Services”一节（明确提示这些服务收费）；“无需信用卡”本身为第三方一致陈述，见“未验证”清单 |
| 注册要什么 | 可用 Google 账号注册/登录 Kaggle（视频说法）；一个手机号只能验证一个账号（反滥用控制，多来源一致陈述） | 视频声称 + 第三方指南；“一号一账号”的官方原文**未查到**，见“未验证”清单 |
| 额度在哪里看 | 账号设置页显示本周剩余额度；另有命令行 `kaggle quota` 可查（第三方所述，未验证） | 第三方指南（2026-11-06 更新文章）；官方文档未写明入口，**未验证** |
| 新出现的 GPU 档位 | 官方员工 2026-10 回复中提到 RTX Pro 6000、L4x4、单个 L4 等较稀缺 GPU；其规格、额度、是否与 30 小时同池**未查到官方说明**，不要按 T4 x2 的数字去规划 | Kaggle 官方讨论帖员工回复，2026-11-11 核查 |

**一句话**：门槛只有一个——能收短信的手机号。TPU 还要再过一道身份验证（Persona，可能要求证件），请按账号设置页实际提示走，不要在任何第三方页面输入证件信息。

---

## §3 “Muse”的歧义澄清：GPU 能为 Muse 做什么、不能做什么

视频没有定义它说的 Muse 是哪一个。按 Chen 的实际使用场景，最可能的三类所指如下（所指本身**未验证**——视频未展示 .md 正文，总控也未提供 .md）：

| 可能的所指 | 是什么 | Kaggle GPU 能为它做什么 | 不能做什么 |
|---|---|---|---|
| (a) 云端 Muse（本账号这类 Meta 个人 AI 助手，如 Kai） | 跑在 Meta 服务端的对话助手，无本地执行环境 | **什么都做不了。** 没有任何“外接 GPU / 自定义推理后端”的设置；.md 只能当作文字资料被读到，读完也不会多出算力 | 不能让它变快、变强、跑本地模型；不能把 Kaggle 算力“接”给它 |
| (b) 本地 AI 编程助手（Claude Code、Codex CLI、opencode、pi 等） | 本地终端里的 Agent，自带模型调用 | 可以把它的推理后端（base URL）指向 Kaggle 上跑的开源模型端点（§4d），让它调用 Qwen / GLM 等开源模型干活；也可以让它通过 MCP / CLI 把代码发到 Kaggle GPU 上跑（§4b、§4c） | 不能让它继续用 Claude / GPT 等原生模型的同时“跑在 GPU 上”——原生模型不在 Kaggle 上，也不能私有部署；改后端 = 换模型，能力、工具调用水平、安全性都会变 |
| (c) 泛指“AI 助手” | 视频口语 | 取决于具体产品是否支持自定义 base URL 或 MCP / CLI；支持的走 (b)，不支持的走 (a) | 同上 |

**核心结论（三种所指都成立）**：

- **能**：提供代码执行算力（在 Kaggle Notebook 里跑 Python/R 训练、推理、数据处理）；提供开源模型推理算力（在 T4 x2 / TPU v5e-8 上跑 Ollama、vLLM、llama.cpp 加载的开源权重）。
- **不能**：让 Muse 本体跑在 GPU 上；让 Muse 获得额外的闭源模型能力；提供 24/7 稳定服务（会话最长 12 小时、TPU 9 小时，URL 每次重启都变）；绕过各产品的账号与计费体系。

**推断（非事实）**：视频标题“给你的 Muse 配上免费 GPU”最可能想表达的是 (b)——让本地编程助手用上 Kaggle 上的开源模型推理。但视频只有 23 秒、未展示 .md 正文与提示词，此推断无法核实；即使所指是 (b)，也需要 §4d 的全部步骤，不是“发一个 .md”就能完成的。

---

## §4 四条接入路线对比

### 路线总览

| 路线 | 一句话 | 需要 Chen 提供什么 | 适合谁 |
|---|---|---|---|
| (a) 浏览器 Notebook 手动跑 | 在 kaggle.com 上开 Notebook，选 GPU，逐格跑代码 | Google 账号 + 手机验证 | 第一次验证、训练与实验 |
| (b) Kaggle API / CLI 脚本核 | 本地写好 `.py`，`kaggle kernels push` 推上去跑，拉回结果 | 同 (a) + API Token（本地保管） | 批量任务、定时任务、Agent 驱动 |
| (c) Jupyter Server / kagglerun / 官方 MCP | Agent 直接连 Kaggle 的 Jupyter Server 或调 MCP 建会话、推 kernel | 同 (b) + Jupyter Server URL 或 MCP 配置 | 想让本地 Agent 直接用 GPU 跑代码 |
| (d) Ollama + 隧道推理服务器 | 在 Notebook 里跑 Ollama/llama.cpp，用 Cloudflare Tunnel 暴露 OpenAI 兼容接口给 Agent | 同 (a) + 接受会话上限与公开暴露风险 | 想让编码 Agent“对话”时用上开源模型推理（实验性质） |

### (a) 浏览器 Notebook 手动跑——最简单，推荐作第一步

**步骤**（据 Kaggle 官方《Notebooks》，2026-11-11 核查）：

1. 登录 Kaggle → Create → New Notebook（Python 或 R）。
2. 右侧 Settings → Session options → Accelerator → 选 **GPU T4 x2**（或 TPU）；会话会重启，忙时需排队。
3. 确认 Internet 开启（新 Notebook 默认开）。
4. 跑 `torch.cuda.is_available()` / `!nvidia-smi` 验证 GPU；训练、推理、批量处理都在格子里跑。
5. 成果保存在 `/kaggle/working`（20 GB，自动保存）；用完在 Active Events 里 **Stop 会话**，否则空闲超时继续扣额度（官方两处文档对空闲时长说法不一，见 §1）。

**局限**：全手动；交互会话最长 12 小时（TPU 9 小时）；关浏览器不等于停会话；不能作为服务被外部调用。

### (b) Kaggle API / CLI 脚本核推送执行——推荐作日常路线

**步骤**（据 Kaggle 官方《API》文档 + 第三方实操文章，2026-11-11 核查）：

1. 在 Kaggle Settings → API 生成 Token（新 Token 以 `KGAT` 开头；另有 OAuth 2.0 方式，access token 3 小时过期，可用 refresh token 续）。
2. 本地安装官方 CLI：`pip install kaggle`；用 `kaggle auth login`（浏览器登录）或把 Token 存本地 `~/.kaggle/`。
3. 代码写成脚本核（script kernel）：目录里放 `.py` + `kernel-metadata.json`，其中 `kernel_type: script`、`enable_gpu: true`、`enable_internet: true`、`machine_shape: NvidiaTeslaT4`（该 ID 对应 T4 x2；此字段含义来自第三方文章与开源项目实例，官方 API 文档未逐一列出 machine_shape 取值，**未验证**官方原文）。
4. `kaggle kernels push -p <目录>` 提交执行（可用 `-t` 设超时上限）；`kaggle kernels status <用户>/<slug>` 查进度；`kaggle kernels output <用户>/<slug> -p out` 下载结果。
5. 也可以在 Notebook 里设**定时重跑**（每天 / 每周 / 每月，或数据集更新时），官方《Notebooks》有 Scheduling 一节。

**局限**：异步执行，查状态、取结果各多一步；API 有动态限流，遇 429 应停几分钟再试（官方《API》文档）；脚本核跑满 12 小时即停，大任务要自己做断点续跑。

**需要 Chen 提供**：API Token，且只存本地（`~/.kaggle/` 或环境变量），绝不进仓库、不贴聊天记录（§5）。

### (c) Jupyter Server / kagglerun / 官方 MCP——给 AI Agent 用

三者都是“Agent 不打开浏览器，直接用 Kaggle 算力”的方式，但官方程度不同：

**c1. 官方 MCP（最推荐的 Agent 路线）**。Kaggle 官方远程 MCP 服务器 `https://www.kaggle.com/mcp`（官方《MCP》文档，2026-11-11 核查）：

- 配置示例官方给了 Gemini CLI、Claude Desktop、VS Code、Windsurf；Claude Code 需自行用其 MCP 接入方式添加同一地址（官方文档未给 Claude Code 示例）。
- 认证：OAuth 2.0，或 Token（`Authorization: Bearer KGAT...`）。
- 工具包括：创建 kernel 会话（`ApiCreateKernelSessionRequest`，含 `machine_shape` 字段，可指定机型）、保存 kernel、下载输出、查会话状态、列 kernel 文件等。**即 MCP 能让 Agent 建 GPU 会话、推代码、取结果**；但 MCP 本身不提供推理——Agent 自己的模型仍跑在原处，GPU 只执行它发过去的代码。

**c2. Kaggle Jupyter Server（官方实验功能）**。官方《Notebooks》“[EXPERIMENTAL] Kaggle Jupyter Server”一节：在 Notebook 编辑器 Run → Kaggle Jupyter Server 打开面板，可一键“Open in Colab”或复制 Colab / VS Code 兼容 URL，把 Colab 或 VS Code 连到正在跑的 Kaggle 后端；会话关闭则断开。适合人在 VS Code / Colab 里写代码、后端用 Kaggle GPU。

**c3. kagglerun（第三方工具）**。PyPI 包 `kagglerun`（2026-11-11 核查存在，最新见 0.2.4 版）：`pip install kagglerun`，用 Kaggle Jupyter Server 的 URL（从浏览器面板复制）从终端直接执行本地 Python 文件或代码，并自带 MCP 服务器，宣称面向 Claude Code、Cursor、Cline。**注意**：① 它是第三方工具，非 Kaggle 官方；② 其 PyPI 页面不同版本对硬件的说法不一致（有的写 T4/P100，有的写 H100），H100 一说**未验证**，不要据此规划；③ Jupyter Server URL 含 token，效果等同临时凭证，只放本地。

**“kgz”**：任务书提到的 `kgz`，本次检索**未查到**名为 kgz 的公开 Kaggle 工具（可能为拼写或小众项目）。不要按此名搜索安装；如总控有具体链接请补充。

**局限**：c1/c3 仍受 12 小时会话、30 小时周额度、排队限制；c3 的 URL/token 泄露即等于账号会话泄露。

### (d) Ollama + 隧道推理服务器（及 TPU 版）——唯一能让 Agent“对话”用上 GPU 的形态

**原理**：在 Kaggle Notebook 里装 Ollama 或 llama.cpp，加载开源模型权重，用 Cloudflare Quick Tunnel（或 ngrok）把本地端口映射成一个临时公网 HTTPS 地址，Agent 把该地址设为 base URL 来调用。

**GPU 版（T4 x2）**：2026-10 的多篇社区实操（Substack、Medium、Techmixer）一致报告可走通：

- 模型示例：Qwen 27B 的 Q4_K_M 量化版（约 17 GB）或 Qwen3-32B Q4_K_M（约 19.8 GB）；两张 T4 各约 15–16 GB 可用显存，合计约 30–32 GB，**是两张卡，不是一张 32 GB 卡**，大模型需跨卡/量化才能放下。
- 速度示例：某次实测 27B 约 16.23 tok/s（单次测量，非官方数字，仅供参考）。
- 隧道：`cloudflared tunnel --url http://localhost:11434` 生成 `https://xxx.trycloudflare.com` 临时地址；Ollama 默认端口 11434 **本身无鉴权**，多篇指南明确警告不要直接暴露，应在前面加带鉴权的网关，或至少不公开转发、不长期挂着。

**TPU 版（kaggle-tpu-lab，开源项目，MIT 协议）**：GitHub `ARahim3/kaggle-tpu-lab`（创建于 2026-08-31；2026-11-10 核查时 791 stars、105 forks）：

- 在 TPU v5e-8 上跑 Qwen3.8-27B bf16（262k 上下文，约 130 tok/s）或 GLM-5.3-Flash 320B MoE（约 165 tok/s）；从点 Run 到出 URL 约 22 分钟（Qwen）/ 6–13 分钟（GLM）。
- Notebook 挂公开数据集里的权重，建好引擎后开 Cloudflare 隧道打印 URL 与 API key；Claude Code 接入示例：`ANTHROPIC_BASE_URL=<url> ANTHROPIC_AUTH_TOKEN=<key> ANTHROPIC_MODEL=<model> claude`。
- 会话用 keepalive 撑到 Kaggle 上限（略低于 9 小时），到期重跑、换新 URL。

**局限（四条路线里最重）**：

- 会话最长 12 小时（GPU）/ 9 小时（TPU），到期即断；隧道 URL 每次重启都变；启动就要 6–22 分钟，不适合随叫随到。
- 推理流量经过 Kaggle 与 Cloudflare，**不要传机密、客户资料、私有代码**。
- 最贴近 AUP“server farming”红线（§5）：个人短期实验与常驻对外服务是两回事；后者不在允许范围内。
- 27B 以上模型在 T4 x2 上吃紧，上下文、并发一上去就容易爆显存；TPU 版对模型与框架（vLLM-TPU / JAX）有要求，不是任意模型都能跑。

---

## §5 合规与风险

以下均引自 Kaggle 官方文件（2026-11-11 核查），措辞尽量贴近原文：

| 条款 | 内容 | 来源 |
|---|---|---|
| 可接受使用政策 AUP（2025-06-22 生效） | 禁止“滥用服务所提供的资源”，包括：**cryptomining（挖矿）、DDOS、server farming（服务器农场）、制作有害或冒犯性内容、恶意活动、与 ML 数据科学无关的活动、过度爬取** | https://www.kaggle.com/aup |
| 使用条款（Terms of Use） | **一人只能拥有、控制或使用一个 Kaggle 账号**；多账号可被无通知封号、取消资格。仅限“个人内部、非商业自用”，不得代表第三方或为第三方利益使用 | https://www.kaggle.com/terms（搜索结果转述，2026-11-11 核查） |
| 违规后果 | 违反上述任何一条，Kaggle 可终止使用权；GPU 资源滥用“可能导致账号暂停或终止”（官方 Colab Pro 推广条款亦有此句） | 同上 + 官方《Notebooks》推广条款 |
| 社区指南（2025-02-24 更新） | 违规行为可被立即封号（原文列举的情形包括重复账号等滥用行为） | https://www.kaggle.com/community-guidelines-2025-02-24 |

**对 Chen 的具体含义**：

1. **不要做的事**：挖矿；把 Kaggle 当 24/7 API 服务挂给产品或他人；开小号刷额度；用脚本绕过排队、限流、会话上限；把 Token / 隧道地址公开分享。
2. **灰色地带**：个人短期、用完即停的 Ollama/TPU 推理实验——社区大量存在且有开源项目，但 Kaggle 从未明文许可“对外提供推理端点”；AUP 的“server farming”与“仅限个人非商业自用”两条都可能被用来认定它。**建议**：只在自己用、短时间、实验目的下做；一旦要长期、稳定、给别人用，就不要用 Kaggle，改租云 GPU。
3. **Token 保管**：Kaggle API Token（`KGAT...`）与 Jupyter Server URL 都是凭证。做法：① Kaggle Notebook 内用 **Add-ons → Secrets** 存密钥，代码里用 `kaggle_secrets` 的 `UserSecretsClient` 读取，不写进 Notebook 正文；② 本地 CLI Token 放 `~/.kaggle/` 或环境变量；③ **绝不**放进 git 仓库、Issue、聊天记录、发给别人的 .md。④ 隧道地址与 API key 每次会话都换，用完即废，不要复用、不要外传。
4. **隐私**：推理与代码都在 Kaggle（Google）基础设施上跑，隧道流量还经过 Cloudflare；不要在上面跑含真实个人信息、客户数据、私有源码的任务。

---

## §6 给 Chen 的结论：能不能弄、值不值得、第一步做什么

**能不能弄**：能。零费用，约 30 分钟可验证。唯一硬门槛是手机号验证；想用 TPU 还要再过 Persona 身份验证。

**值不值得弄**：取决于要什么——

- **值得**：想学深度学习、想训小模型、想批量跑实验、想免费试 27B 级开源模型推理。每周 30 小时 GPU + 20 小时 TPU 是真实额度，够做不少事。
- **不值得**：如果目标是“让云端 Muse 变强”——做不到；如果目标是“一个稳定的免费推理服务”——Kaggle 给不了，会话 12 小时封顶、URL 常变、忙时排队、条款也不允许。

**推荐路线**：

1. 先走 **(a) 浏览器 Notebook** 验证 10 分钟（§4a），确认账号、额度、GPU 都正常。
2. 日常使用走 **(b) CLI 脚本核**——可复现、可定时、可被 Agent 驱动，是性价比最高的形态。
3. 只有当目标明确是“本地编码 Agent 对话时调用开源模型”时，再试 **(d) 隧道推理**，优先试 **TPU 版 kaggle-tpu-lab**（27B bf16、262k 上下文，比 T4 x2 的量化 27B 更从容）；且每次用完即停，不作常驻。
4. **(c) 官方 MCP** 值得在 (b) 之后接上：它是官方支持的 Agent 接入方式，让 Agent 能直接建会话、推 kernel、取结果，而不必每次都手动操作浏览器。

**第一步（照着做，约 30 分钟）**：

1. 用 Google 账号在 https://www.kaggle.com 注册/登录 Kaggle。
2. 点头像 → Settings → Phone Verification，完成短信验证（收不到码、VoIP 号被拒是常见问题，换运营商实名号再试；仍失败则联系 Kaggle 支持）。
3. 新建 Notebook：Create → New Notebook → 右侧 Settings → Accelerator → 选 **GPU T4 x2**；确认 Internet 已开启。
4. 跑一格 `import torch; print(torch.cuda.is_available())`，看到 `True` 即通；再看账号设置页的剩余额度。
5. （可选，下一步）Settings → API 生成 Token，存本地 `~/.kaggle/`，然后按 §4b 把第一个脚本核推上去。

**需要 Chen 准备的东西**：

- Google 账号 1 个；
- 能收短信的手机号 1 个（仅用于验证，不会出现在报告或仓库里）；
- 如用 TPU：按设置页提示完成 Persona 身份验证（可能需要证件，按官方页面操作，不要发给任何第三方）；
- 如走 CLI / MCP：Kaggle API Token 1 枚，只存本地。

---

## §7 视频声称逐项核对

| 视频声称（据任务书转述） | 核对结果 |
|---|---|
| 每周免费 30 小时 GPU | **属实**。官方原话“30 hours or sometimes higher”，按周重置 |
| Google 账号 → 登录 Kaggle | **属实**。可用 Google 账号注册/登录；“是否必须用 Google 账号”未核对 |
| 设置里做手机验证 | **属实**。所有 GPU 都要求手机验证（官方员工回复）；TPU 另需身份验证 |
| 把 .md 发给 Muse 即可 | **不成立**。见 §3：.md 只是文字说明，不能让 Muse 获得 GPU；且视频未展示 .md 正文，.md 本身的内容无法核对 |
| （任务书要求核对）P100 是否已于 2026-09-15 退役、现为 T4 x2 | **属实**。官方公告确认 P100 于 2026-09-15 退役，T4 x2 为现行唯一 GPU 选项（另有较稀缺的新档位见 §2，规格未验证） |

---

## §8 未验证 / 未查到清单

- T4 x2 跑 1 小时只计 1 小时额度：官方讨论帖员工回复，经第三方文章（2026-11-06 更新）转述；官方文档正文未写，未能核对原文。
- “不需要信用卡”：Kaggle 无付费档 + 多个 2026 年指南一致陈述；官方文档未用一句话写明，**未验证**官方原文。
- “一个手机号只能验证一个账号”：多个第三方指南一致陈述；官方原文**未查到**。
- 手机验证入口、额度显示位置、`kaggle quota` 命令、`KAGGLE_API_TOKEN` 环境变量名、`machine_shape: NvidiaTeslaT4` 的取值含义：均来自第三方实操文章 / 开源项目实例，未在官方文档正文中逐一核对。
- TPU 实际提供 v5e-8（而非文档写的 v3-8）：来自 2026-08-31 之后多个独立第三方来源与开源项目；官方《TPU》文档仍写 v3-8，**以实际 Accelerator 菜单为准**。
- RTX Pro 6000 / L4x4 / 单个 L4 的规格与额度：官方员工回复仅提到名字，**未查到**官方规格说明。
- “kgz”工具：检索**未查到**名为 kgz 的公开 Kaggle 工具。
- kagglerun 页面自称的 H100 支持：其 PyPI 页面不同版本说法不一，**未验证**。
- 视频中“ Muse ”具体指哪一个、.md 正文与提示词：视频未展示，**未验证**；§3 的三种所指为按 Chen 使用场景的列举。
- Ollama 27B 约 16.23 tok/s、kaggle-tpu-lab 约 130/165 tok/s、约 22 分钟启动：均为项目方或作者单次实测，非官方数字，未独立复核。
- 官方文档自相矛盾处：交互会话空闲超时 20 分钟（《Notebooks》）vs 60 分钟（《Efficient GPU usage》），以较严者规划。

---

## 来源清单（2026-11-11 核查）

**Kaggle 官方**

- Notebooks 文档（含技术规格、会话上限、Jupyter Server、Colab Pro 推广）：https://www.kaggle.com/docs/notebooks
- Efficient GPU usage（每周 30 小时额度）：https://www.kaggle.com/docs/efficient-gpu-usage
- MCP 文档（远程服务器 https://www.kaggle.com/mcp）：https://www.kaggle.com/docs/mcp
- TPU 文档（每周 20 小时、单次 9 小时，仍写 v3-8）：https://www.kaggle.com/docs/tpu
- API 文档（CLI、OAuth 2.0、KGAT/KGRT Token、限流）：https://www.kaggle.com/docs/api
- P100 退役公告（2026-09-15）：https://www.kaggle.com/discussions/product-announcements/735239
- T4 x2 上线公告（配额同池）：https://www.kaggle.com/discussions/product-feedback/361104
- 员工回复：全部 GPU 需手机验证，TPU 与稀缺 GPU 需手机 + 身份验证：https://www.kaggle.com/discussions/product-feedback/751699
- 可接受使用政策 AUP（2025-06-22 生效）：https://www.kaggle.com/aup
- 使用条款 Terms of Use：https://www.kaggle.com/terms
- 社区指南（2025-02-24 更新）：https://www.kaggle.com/community-guidelines-2025-02-24

**第三方（交叉验证用，非官方）**

- Kaggle 免费 GPU 全貌（2026-11-06 更新，含 T4 x2 计费转述与 CLI 步骤）：https://medium.com/@hari12.nhk/kaggles-free-gpus-for-ai-experiments-what-you-actually-get-abff5684a53c
- TPU v5e-8 指南（2026-11-01 核查）：https://technicalpaji.pages.dev/tpu/
- kaggle-tpu-lab（TPU v5e-8 跑 Qwen3.8-27B / GLM-5.3-Flash，MIT）：https://github.com/ARahim3/kaggle-tpu-lab
- Ollama + 双 T4 实操（2026-10）：https://imprasit.substack.com/p/how-to-build-a-free-ai-server-on
- Ollama + Cloudflare 隧道指南与安全提醒：https://www.techmixer.com/run-ollama-on-kaggle-free-gpu/
- llama.cpp + Cloudflare Tunnel 跑 Qwen3-32B（2026-10-29）：https://medium.com/@vinodjagwani/how-to-host-a-32b-llm-using-kaggles-free-gpu-quota-076142eb7503
- kagglerun（PyPI，第三方 CLI + MCP）：https://pypi.org/project/kagglerun/0.2.4/
- Kaggle 免费 GPU/TPU 指南（2026-03-01 更新，手机验证步骤）：https://aicreditmart.com/ai-credits-providers/kaggle-free-gpu-tpu-30-hours-week-access-guide-2026/
- Kaggle 作免费 AI 服务器的条款分析（2026-10-29 核查）：https://www.maborak.com/blog/kaggle-free-gpu-ai-server
- Kaggle Notebook Secrets（Add-ons → Secrets）：https://dev.to/gitguardian/how-to-handle-secrets-in-jupyter-notebooks-466o

---

*报告人：node-1；研究完成日期：2026-11-11。本报告不含任何真实账号、手机号、Token、密钥。*
