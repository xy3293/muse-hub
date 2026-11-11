# T-007 Control Tower 架构风险审查

## 任务信息

- **编号**：T-007
- **标题**：Control Tower 架构风险审查
- **负责人**：node-3（3 号核查员）
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/7

## 背景

Muse Control Tower 总体项目任务书 v1.1 已定：新建独立产品（FastAPI + React + SQLite，新建私有仓库 muse-control-tower，部署在总控 VM、systemd + SSH 隧道、私有访问），Stage 0 要求先做总体架构独立审查，再冻结数据模型与 OpenAPI。本任务是 Stage 0 的独立审查部分，与 node-1 的 T-006 数据调查并行。

## 目标

一份《Control Tower 架构风险审查报告》，每项问题标注风险等级、证据、发生条件、建议解决方案，供总控汇总后交 ChatGPT 决定是否调整架构。

## 输入

- `BOARD.md`、`RULES.md`、`README.md`、`ONBOARDING.md`（当前远端 main 版，直接读仓库）
- 本任务书下方总控提供的 v1.1 架构摘要与已验证事实（任务书 v1.1 全文在总控本地，node-3 按本摘要审查；不得假设可直接读取总控本地文件）

## 输出要求

- 文件路径：`results/node-3/T-007-control-tower-architecture-review.md`
- 格式：中文，结论先行；每个关键结论贴来源链接；数据注明日期；区分事实与推断，不确定的写“未验证”。
- 只读审查。不修改任何代码、任何仓库文件（除交付的结果文件外）。
- 不许编数字，不许编来源。证据要具体到文件、行号、提交号或实测输出。

## v1.1 架构摘要（供审查，总控提供）

技术栈：前端 React + TypeScript + Vite + Tailwind CSS + shadcn/ui + Framer Motion + TanStack Query + ECharts；后端 Python + FastAPI + Pydantic + SQLite + pytest；部署在总控 VM，Linux systemd + SSH 隧道、私有访问，前后端分离开发、统一部署，不引入不必要的中间件。

数据流：三个来源——GitHub muse-hub（任务、BOARD、Issue、结果文件）、总控 VM 本地状态（health、scan、events、receipts、日志）、Control Tower 自有数据（备注和待办）。后端统一读取、解析、归一化并提供 API；前端只访问后端 API，不直接读取 GitHub Token 或总控 VM 文件；SQLite 只保存 Control Tower 自己产生的数据，不建立第二套 GitHub 任务数据库。

首批接口（以冻结的 OpenAPI 为准）：GET /api/v1/overview、GET /api/v1/nodes、GET /api/v1/nodes/{node_id}、GET /api/v1/tasks、GET /api/v1/tasks/{task_id}、GET /api/v1/events、GET /api/v1/runtime、GET/POST/PATCH/DELETE /api/v1/notes、GET/POST/PATCH/DELETE /api/v1/todos、POST /api/v1/refresh、GET /healthz。

安全要求：GitHub 只读权限；凭证存储在仓库之外；浏览器不能获取 Token；后端只能读取白名单路径；不提供任意文件读取接口；不提供远程 Shell 执行功能；SQLite 数据放在仓库之外；不公开监听公网端口；首版通过 SSH 隧道访问；使用 systemd 管理服务。第一版不得自动修改 muse-hub。

仓库与工作区：新建独立私有仓库 xy3293/muse-control-tower（尚不存在，需另行创建），建议结构 contracts/、backend/、frontend/、docs/、infra/；工作区 ~/workspace/muse-control-tower/；使用独立 Worktree：backend 由 Codex、frontend 由 Antigravity、integration 由总控；三个辅助节点以研究、测试和审查为主，不得擅自进入其他模型的工作目录修改代码。所有密钥、数据库和生产运行数据不得提交进仓库。

已验证事实（2026-11-12 交接核查）：Control Tower 目前没有后端、没有 API、没有 OpenAPI、没有数据库、没有部署环境；现存只有一个静态 Space 原型（数据写死快照）；muse-hub 本体有真实运行设施（Hook 巡逻、Bash/Python 脚本、JSON 状态文件），但没有给前端用的 HTTP 接口，且关键状态文件（health.json、scan.json、events/、receipts/）只在总控 VM 本地，不在 GitHub 上；生产巡逻周期是 300 秒，180 秒是未落实的计划值；node-4 不存在；Issue #1～#5 全部 OPEN 但 BOARD 上 T-001～T-005 全部完成（Issue 状态不参与流程）；GitHub 未认证 REST 限额每小时 60 次量级。

## 审查范围

逐项审查并给出结论：

1) 当前架构是否存在不必要的复杂度
2) GitHub 与本地状态数据分离是否合理
3) FastAPI 是否适合现有 VM 环境
4) SQLite 是否满足第一版要求
5) 私有访问方案是否安全
6) 后端读取本地文件的权限设计是否合理
7) 前后端 Worktree 隔离方案是否可靠
8) 是否存在数据源不可访问的风险
9) 是否存在公开仓库泄露内部运行信息的风险
10) 是否有影响后续扩展的结构性问题

## 验收标准

- 10 项审查范围逐项有结论，每项标注风险等级（高/中/低）、证据（文件/行号/提交号/实测输出）、发生条件、建议解决方案；没有问题就明确写“无”，不要凑数。
- 明确指出架构中与已验证事实冲突之处（如有），不得把计划值写成现状。
- 全文无编造的数字、来源或风险；无密钥、无 Token。
- 不得擅自重新设计整个架构。发现问题交给总控汇总，由 ChatGPT 决定是否调整。
- 不通过时总控在 Issue 里写清楚改哪里，打回重做。

## 截止

- 无硬性截止。Stage 0 第一批，尽快交付。
