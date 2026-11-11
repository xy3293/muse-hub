# T-003 Kaggle 免费 GPU 接入 Muse 研究

## 任务信息

- **编号**：T-003
- **标题**：Kaggle 免费 GPU 接入 Muse 研究
- **负责人**：node-1（1 号研究员）
- **状态**：待领（由总控在 BOARD.md 登记）
- **版本**：v1 <!-- 版本：v1 -->
- **Issue**：https://github.com/xy3293/muse-hub/issues/3

## 背景

Chen 在抖音看到一个 23 秒短视频（作者：晚睡.，2026-11-10 发布，标题“给你的Muse配上免费GPU！Kaggle领取＋接入教程”），视频只给了概念：Kaggle 每周免费 30 小时 GPU，准备 Google 账号、登录 Kaggle、设置里做手机验证、把作者整理好的 .md 文档发给 Muse 即可。视频没有给命令、代码、链接、Notebook 创建步骤，也没有展示 .md 正文和提示词，无法按视频复现。总控已看过视频，不再重复看视频；本次任务是核对 Kaggle 官方规则，给出真正可走通的接法。

## 目标

一份自包含研究报告，回答：Kaggle 免费 GPU 能不能给 Muse 用、怎么接、对 Chen 有什么用、第一步做什么。Chen 看完能直接决定要不要做。

## 输入

- 抖音视频：https://www.douyin.com/video/7706413710163725594（短链 https://v.douyin.com/GaXjW6pZWLg/）
- 视频声称：每周免费 30 小时 GPU；步骤为 Google 账号 → 登录 Kaggle → 设置里手机验证 → 把 .md 发给 Muse。
- Kaggle 官方文档（以官方为准，第三方只作交叉验证）：
  - https://www.kaggle.com/docs/notebooks
  - https://www.kaggle.com/docs/efficient-gpu-usage
  - https://www.kaggle.com/docs/mcp
- 不要创建 Kaggle 账号，不要登录，不要输入任何凭证、手机号、Token。只做公开资料研究。

## 输出要求

- 文件路径：`results/node-1/T-003-kaggle-free-gpu-for-muse.md`
- 中文，结论先行；每个关键结论贴来源链接；所有数据注明日期；区分事实与推断，不确定的写“未验证”。
- 不许编数字，不许编来源；查不到的写“未查到”，不要猜。
- 不许在报告或 Issue 里写任何真实账号、手机号、Token、密钥。

## 验收标准

- [ ] 覆盖以下 6 点，缺一项验收不通过：
  1. Kaggle 免费 GPU 现状（截至 2026-11-11）：每周额度、单次会话上限、硬件型号（核对 P100 是否已于 2026-09-15 退役、现为 T4 x2）、RAM / 保存空间、排队与可用性。
  2. 开通门槛：是否需要手机验证、是否需要信用卡、TPU 是否另有身份验证。
  3. “Muse” 的歧义澄清：视频说的 Muse 可能指哪种 Muse（本账号云端 Muse、本地 Claude Code / Codex 等）；GPU 能为 Muse 做什么、不能做什么（不能让 Muse 本体跑在 GPU 上，只能提供代码执行 / 模型推理算力）。
  4. 至少 3 条可走通的接入路线对比：(a) 浏览器 Notebook 手动跑；(b) Kaggle API / CLI 脚本核（script kernel）推送执行；(c) Jupyter Server / kagglerun / kgz / 官方 MCP（https://www.kaggle.com/mcp）给 AI Agent 用；(d) Kaggle 里跑 Ollama + 隧道（ngrok / Cloudflare Tunnel）作推理服务器。每条写清需要 Chen 提供什么、步骤、局限。
  5. 合规与风险：Kaggle 可接受使用政策里对 server farming / 挖矿 / 非 ML 用途的限制、多账号风险、Token 保管方式（只走 Secure Vault / 本地，绝不进仓库）。
  6. 给 Chen 的结论：能不能弄、值不值得弄、推荐哪条路线、第一步具体做什么、需要 Chen 准备什么（账号、手机验证、Token）。
- [ ] 所有数字注明日期与来源，可复核。
- [ ] 事实与推断分开写，不确定的已标注“未验证”。

## 截止

- 无硬性截止，越快越好。
