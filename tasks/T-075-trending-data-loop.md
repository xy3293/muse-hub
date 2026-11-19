# T-075 P3 数据闭环：GitHub Trending 日榜/周榜抓取＋结构化存储

- Issue: #70
- 执行方：Codex（总控 VM 本地）
- 来源：Chen 直令 2026-11-19（待决策清单第 ② 项已定：P3 选候选① GitHub Trending 四周追踪＋交互报告站；第一包 = 数据闭环）
- 边界：不改 RULES；不碰 Tower 代码与部署；不建新库（数据先放 muse-hub 的 `data/trending/`，最终归属由报告站包再定）；不许要任何凭据（只用公开网页/公开 API）；不许用 agent 跑日常抓取（日常靠 timer）；若单日数据量可能超 200KB，先报方案再动，不许静默放大。

## 背景

P3 是 Tower 之后第一个真实项目：连续 4 周追踪 GitHub Trending，产出交互报告站。第一包只做数据闭环——把日榜/周榜稳定抓下来、存成结构化数据，为后续分析包、前端包供数。

## 任务

1. **抓取脚本**：写 `trending/fetch_trending.py`（Python，优先标准库；如需第三方库，列明并说明本机是否已有），抓 https://github.com/trending 公开页面：
   - 榜单：daily + weekly（`?since=daily` / `?since=weekly`）；
   - 语言维度：global（全部语言）+ Python / TypeScript / Rust / Go 四个语言页（`?language=python` 等）；
   - 每榜取前 25 条；字段：仓库全名、仓库语言、当日/当周新增 star 数、简介、抓取时间（UTC ISO）、榜单类型（daily/weekly）、语言维度（global 或语言名）；
   - 速率限制：公开页面无凭据访问，请求之间 sleep 2–5 秒；遇 429/5xx 按指数退避重试（至多 3 次），退避策略与实测到的限制写进报告。
2. **存储**：`data/trending/YYYY-MM-DD.jsonl`，一天一个文件，一行一条观测（同一仓库出现在多个榜单时各记一行，带榜单与语言维度字段）；单日 < 200KB；若实测会超，先停下报方案，不许擅自改格式或截断字段。
3. **查询演示**：写 `trending/query.py`（或等效命令），能回答“某仓库本周 star 增量是多少”——读本周 7 个文件，按仓库全名汇总；验收时用真实数据贴一次查询结果。
4. **自动化**：写 systemd timer + service（`trending/muse-trending-fetch.service`、`trending/muse-trending-fetch.timer`，每天 10:00 CST 抓一次）与包装脚本 `trending/run_daily.sh`（抓取 → 写文件 → git add/commit/push 到 muse-hub main；push 失败要报错退出，不许静默丢数据）。**只交单元文件，不许自行安装/启用 timer**（安装由总控部署时做）。
5. **首跑验证**：在工作区手动跑一次完整流程（抓取 → 写 `data/trending/2026-11-19.jsonl` → 查询演示），贴出：抓到的榜单数、条目数、文件字节数、一次真实查询的命令与输出。

## 验收

- 脚本 + timer 单元 + 包装脚本 + 查询命令齐全，路径如上；
- 首跑数据文件字段齐全、单日 < 200KB；
- 查询演示真实可用（命令 + 输出贴出）；
- 速率限制与退避策略写明；
- **验收窗口**：timer 部署后连续 3 天数据无丢失才算通过——Codex 交付后总控部署 timer，第 3 天数据齐了再由总控验收（Antigravity 复核交付物，不等 3 天）。

## 截止

- Codex 交付：2026-11-19 当天；验收：连续 3 天数据齐后（约 2026-11-22）。
