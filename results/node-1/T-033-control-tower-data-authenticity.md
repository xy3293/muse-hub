# T-033 Control Tower Stage 3 数据真实性核查（node-1）

- 任务：Control Tower Stage 3 数据真实性核查（node-1），按 v1.1 Stage 3 node-1 一节
- 核查时间：2026-11-16 01:30–01:55 CST（主聊直接执行；巡逻两次唤醒的工人均未交付，见 §9）
- 基线：后端 integration `d211bd5`；muse-hub 对照 HEAD `0d921a0`（任务书指定）与当前 HEAD；合同 1.1.0 冻结于 `db649ab`
- 方法：读后端映射逻辑（`github.py`、`normalize.py`、`service.py`、`runtime.py`、`common.py`、`cache.py`、`storage.py`、`config.py`）；用真实 `board()` / `read_book()` 代码（import stub，仅绕过未装的 httpx/pydantic）解析真实 BOARD.md；gh api 核实 Issues 与提交；全库 grep Mock/SYNTHETIC；后端测试未本地运行（httpx/pydantic/fastapi/pytest 均未装，按不装软件边界未装，任务书“可运行”未强制）
- 结论总览：7 项中 3 项 PASS（2、6、7）、2 项 PARTIAL（4、5）、2 项 FAIL（1、3）。核心缺陷 2 个，见 §8。

## 1. BOARD 数据是否正确 — FAIL（计数 PASS，任务书链接 FAIL）

- 方法：真实 `board()` 解析 BOARD.md@`0d921a0` 与 HEAD；独立 grep 计数对照；检查任务书列格式。
- 结果：
  - 计数与状态分布 PASS：`0d921a0` 解析 32 任务、全完成，partial=0，与 grep 计数（32 行）一致，与“32 任务”说法一致。HEAD 解析 34 任务（32 完成＋T-033 待领＋T-034 进行中）。
  - 任务书路径 FAIL：32/32（`0d921a0`）与 34/34（HEAD）任务的 `task_book_path` 均为 None。原因：`github.py:131-133` 只从 markdown 链接 `[text](path)` 提取任务书路径；BOARD 自始用纯路径（`tasks/T-xxx.md`，第 5 列含 `[` 计数为 0，最早 BOARD 同格式）。对照：冒烟脚本与单测用的合成 BOARD 是链接格式 `[task](tasks/T-001.md)`（`smoke_stage3.py:108`、`test_github_cache_config.py:30`）。
  - 后果：`read_book()` 永不执行；`task_version` / `version_sha` / `contract_revision` / `run_id` / `source_paths` 全为 None（实测 0 字段）；`verify_delivery()` 直接返回，`remote_verified` 全 False；freshness 仍标 fresh（缺书路径不置 partial），快照看似完整。
- 缺陷 D1：`github.py:131-133`，任务书列只认链接。复现：`/tmp/t033_board_check.py`（真实 `board()`，BOARD@`0d921a0` → 32 任务，book path 全 None）。

## 2. Issue 是否正确关联 — PASS

- 方法：真实 `board()` 提取 Issue 号；gh api 拉全量 Issues（state=all）逐项核对标题与状态；查重复号。
- 结果：`0d921a0` 的 32 任务 Issue 号无重复、无缺失；#1–#36 全部存在，仅 #17 closed，其余 open；标题与任务一一对应（抽查 #35=T-033、#32=T-031、#28=T-025、#26=T-028、#23=T-021、#6=T-006、#1=T-001）；T-016 指向 #18（v2，open），未指向已关闭的 #17；无两任务共用同一 Issue。Issue 提取正则对 `[#N](url)` 格式有效。

## 3. 任务版本是否正确区分 — FAIL

- 方法：grep 任务书 `^version_sha:` / `^source_paths:` 字段行；读 `normalize.py` 的版本过滤逻辑；查多版本实例（T-021 五修订、T-004 双收据）。
- 结果：代码机制正确（`read_book` 提 `version_sha`；`normalize` 只取 `version_sha` 一致的当前收据/事件，历史收据保留一对多；冲突记 `source_conflicts`）。但数据侧为零：34 本任务书 0 本含可解析的 `version_sha` / `source_paths` / `task_version` 字段行；T-006/T-022 的 version_sha 出现只是正文/模式描述，不是字段。叠加第 1 项（任务书读不到），版本区分无任何输入。`service.enrich()` 可从运行时事件推导 `version_sha`，但事件文件在后端宿主机，node-1 不可达。结论：同一任务多版本在 GitHub 侧无法区分；T-021 的五次修订、T-004 的两次交付在后端数据里不可区分。

## 4. 收据与交付是否匹配 — PARTIAL

- 方法：读 `normalize.py` 收据关联逻辑；git cat-file 核实 T-022 点名的 T-004 两份收据 SHA；找收据文件位置。
- 结果：机制正确（收据 event_id 须链接到事件、verdict 须一致、路径须为子集、`remote_missing`＋收据→冲突；`verify_delivery` 校验提交 SHA 与每个 source_paths 文件）。T-004 的两份收据 SHA 均为真实提交（`5d71eee`、`fa4cee5`，后者为修正，git cat-file 存在）。但端到端实证受限：收据文件 `receipts/*.json` 在总控 VM（T-006 §9），node-1 不可达，无法逐份核对 event_id/version_sha；且因第 1/3 项，远端核验无 version_sha 输入，`remote_verified` 全 False。结论：机制 PASS，实证 PARTIAL。

## 5. Hook 状态是否准确 — PARTIAL

- 方法：读 `runtime.py` health/scan/patrol 逻辑；对 node-1 真实巡逻脚本跑 backend 的 patrol 正则；核对总控 Hook 注册值（T-006）。
- 结果：health/scan 逻辑正确（`now()` 真实 UTC；healthy 阈值 900 秒；scan cursor 原样透传；`hook_wake_guaranteed_realtime=False` 硬编码诚实；节点状态恒 unknown、不伪造在线，`service.py` node_projection）。但 node_patrol 读取与实际脚本失配：`runtime.py` patrol() 要求文件内有大写字面赋值（`POLL_INTERVAL_SECS=60` 等），实测其正则对 node-1 真实巡逻脚本（`~/hooks/scripts/patrol-muse-hub.sh`，2026-11-15.1）零命中 → SourceFailure；60 秒间隔在 Hook 注册里，不在脚本文件里。director YAML 侧（`poll_interval_secs`）与总控 Hook 注册 300 秒（T-006）格式一致，但宿主机文件不可达，实值未验证。结论：逻辑 PARTIAL；node_patrol 若指向巡逻脚本则读不到值（缺陷 D2）；实值未验证。

## 6. 数据更新时间是否正确 — PASS（代码；实值未验证）

- 方法：读 `common.py` / `cache.py` / `storage.py` / `service.py` 的时间来源；grep 生产代码硬编码时间。
- 结果：`now()` 为真实 UTC 时钟；github meta fetched/observed 与 snapshot generated_at 均为采集时 `now()`；cache TTL=0 时重读标 stale 且不改写源时间戳；`store.refreshed()` 在 refresh 完成时写入真实 `now()`；生产代码无硬编码时间（仅 GitHub API 版本头 `2022-11-28`）；`normalize` 对非 fresh 来源保守置冲突。未发现假时间。实值（上次 refresh 时刻）取决于宿主机运行状态，node-1 未验证。

## 7. 是否出现模拟数据冒充真实数据 — PASS

- 方法：全库 grep Mock/SYNTHETIC/fake/placeholder/lorem（后端＋前端＋合同）；查前端 mock 引用与失败回退。
- 结果：生产后端 `muse_tower/` 零命中；前端 mock mode 在 `api/index.ts` 永久关闭（`isMockMode()=false`，`setMockMode` 空操作）；ApiClient 只调真实 `/api/v1/*`，失败抛 CustomApiError，无 mock 回退；mock-service/mock-data 仅被测试文件引用，MockBadge 无任何使用；Mock/SYNTHETIC 只出现在测试与冒烟脚本（MockTransport、SYNTHETIC 令牌/数据，明确标注）及文档中。结论：无一处 Mock 数据以真实数据名义展示。注：`mock-service.ts`、`mock-data.ts`、MockBadge 作为死代码仍在前端树内，未被生产引用。

## 8. 缺陷清单

- D1（高）：`github.py:131-133`，BOARD 任务书列只认 markdown 链接，真实 BOARD 自始用纯路径 → 32/32 任务书路径丢失，`read_book` / `verify_delivery` / 版本区分 / 远端核验全部无输入，且快照仍标 fresh。修复方向：任务书列同时接受纯路径（经 `repo_path` 校验），或 BOARD 改链接格式；缺书路径应置 partial。复现：`/tmp/t033_board_check.py`。
- D2（中）：`runtime.py` patrol()，node_patrol 要求脚本文件内大写字面赋值；真实巡逻脚本无此赋值（间隔在 Hook 注册里）→ 正则零命中、SourceFailure。修复方向：改为读 Hook 注册的 `poll_interval_secs`，或放宽为大小写不敏感并接受注册值。复现：对 `~/hooks/scripts/patrol-muse-hub.sh` 跑该正则，零命中。
- 未验证（非缺陷，是边界）：后端算子实际配置 `CT_GITHUB_REF`、`CT_RUNTIME_CONFIG` 的文件路径、宿主机上的 health/scan/events/receipts 文件实值、线上 refresh 时刻；后端测试未本地运行（依赖未装，未装软件）。

## 9. 巡逻未认领诊断（Chen 问）

- 不是巡逻没看到：巡逻 01:07:19 首次唤醒（event `T-033@v1@6072ff3`，派发提交 `6072ff3`），seen 当时已写 `T-033@v1`；01:19:19 巡逻 silent `no-new-task-for-me`（seen 已有，故判无新任务）；01:22:19 stuck-task-rewake（age 900 秒）第二次唤醒（invocation `cfbb2a68-326c-4247-a3e3-b996dba21977`）。
- 是工人执行侧卡住：两次唤醒均未交付——无 T-033 运行时目录、无工人进程、无结果文件、无推送；首次唤醒的工人 600 秒内零产出，第二次唤醒至 01:27 亦无工人。属 T-008 同款 seen-before-wake＋工人丢失模式；新版 stuck-task-rewake 已按设计触发，但重唤的工人同样丢失。建议：查 01:07 与 01:22 两次唤醒的 worker 启动记录；本次由主聊直接执行，不再等巡逻。

## 10. 方法与边界

- 后端测试未本地运行：httpx/pydantic/fastapi/pytest 均未装；按不装软件边界未装。替代：真实 `board()` / `read_book()` 代码经 import stub 运行（逻辑与文件逐字节一致），远端数据用 gh api / git 核实。
- 未改代码、未推代码（只读核查）；只写 `results/node-1/` 下本报告。
- 无密钥、无凭据：报告不含任何 token；核查用的 gh 令牌只在进程内读，未打印、未写入文件。
