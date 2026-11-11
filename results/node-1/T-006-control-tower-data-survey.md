# T-006 Control Tower 数据结构调查

- **任务**：T-006 Control Tower 数据结构调查
- **负责人**：node-1
- **核查日期**：2026-11-12（所有核查均为本日；仓库以远端 main 为准）
- **核查基线**：远端 main `331e4c968eebc3014e3a616c709517bbf4dc6660`（2026-11-12 `git pull` 已是最新，`git ls-remote` 一致）；任务书快照基线为 `e24bfc6`，见 §11 案例 6
- **研究方式**：只读调查。直接读仓库（BOARD.md、RULES.md、tasks/、results/、Issues #1～#7）；`health.json`、`scan.json`、`events/`、`receipts/`、`logs/health-exceptions.jsonl` 只在总控 VM 本地，不在 GitHub 上，node-1 未直接读取原始文件，本报告这 5 项以任务书提供的脱敏结构与样本为准，并在文中注明
- **不许编**：样本值只用任务书提供的脱敏样本或仓库内已公开的数据；无样本值的字段写 null 并注明，未验证的写“未验证”

---

## 结论先行

1. **BOARD.md 是唯一的人工状态表，但不是实时事实。** 6 列固定、巡逻脚本按列解析（`hooks/patrol.sh` L251–257）；状态枚举 6 个（待领 / 进行中 / 待验收 / 完成 / 失败 / 拒收）；BOARD 本身写明“不是实时事实，以远端提交和收据为准，表的状态可能滞后数小时”（BOARD.md L4）。实测：T-007 已由 node-3 交付（提交 `331e4c9`，文件已在库内），BOARD 仍显示“待领”——这就是滞后，不是错误。
2. **任务“完成”只体现在 BOARD 与交付提交上，Issue 永远 OPEN。** 实测 2026-11-12：Issue #1～#7 全部 OPEN，已关闭 0 个；BOARD 上 T-001～T-005 已是“完成”。这是现行流程（R2、R7），不是漏操作；Tower 任何界面不得把 Issue OPEN 解读为任务未完成。
3. **生产巡逻周期是 300 秒，180 秒是未落实的计划值。** 300 秒见 RULES.md R6b L46、README.md L13/L15、ONBOARDING 注册参数、本节点 Hook 注册值（`poll_interval_secs: 300`）；“180”在 RULES、README、ONBOARDING、巡逻脚本中均未出现，只在两份任务书的口径说明里出现。Tower 不得把 180 秒写成现状。
4. **事件状态只有两个是实测值：ACKED、NEEDS_ATTENTION。** 任务书实测 8 个事件：6 个 ACKED、2 个 NEEDS_ATTENTION；NEEDS_ATTENTION 不是终态（R6b L49），是未确认事件重唤 12 次后待总控 48 小时内归类的状态，48 小时 / 7 天两级机制尚未在代码中实现。代码中的另三个终态 REJECTED、SUPERSEDED、CLOSED_INTERNAL 只见于任务书陈述，node-1 未独立验证。
5. **`health.json` 的 `last_error` 是“最后一次错误”，不是“当前错误”。** 实测残留值 `"comments-fetch-failed"`，而同期 `consecutive_api_failures` 与 `consecutive_script_failures` 均为 0、`last_success_at` 为 2026-11-11T19:40:08Z。解析层不得把 `last_error` 非空当成“当前失败”。
6. **本地运行数据不在仓库里。** `health.json`、`scan.json`、`events/`、`receipts/`、`logs/health-exceptions.jsonl` 在仓库 `git ls-tree -r HEAD` 中均无记录；本报告这 5 项的字段名、层级以任务书脱敏样本为准，原始文件 node-1 未读到。`logs/health-exceptions.jsonl` 连字段清单都没有，列入未验证。
7. **node-4 不存在。** BOARD、RULES、README、ONBOARDING、results/ 全文无 `node-4` 记录（唯一出现处是 T-007 报告 L176 的核实结论本身）；不得为其生成任务或状态。署名标记为全角形式，是机器分类依据之一（R1）。

---

## §1 BOARD.md 的结构

**结论**：6 列固定表，列顺序固定，巡逻脚本按列解析；状态枚举 6 个；人工维护、可能滞后。

| 项目 | 内容 | 来源 |
|---|---|---|
| 列 | 编号 \| 任务 \| 负责人 \| 状态 \| 任务书 \| Issue，共 6 列 | BOARD.md L7 |
| 列顺序 | 固定；“改列必须同步改 `hooks/patrol.sh`” | BOARD.md L5 |
| 巡逻解析 | `awk -F'\|'`：`$2` 编号、`$4` 负责人、`$5` 状态、`$6` 任务书路径（再从中提取 `tasks/*.md`） | `hooks/patrol.sh` L251–257 |
| 修改权限 | 只有总控能改；其他号只读 | BOARD.md L3；RULES.md R2 L10–12 |
| 实时性 | 人工维护表，不是实时事实；任务状态以远端提交和收据为准，表的状态可能滞后数小时 | BOARD.md L4 |
| 状态枚举 | 待领 / 进行中 / 待验收 / 完成 / 失败 / 拒收 | BOARD.md L22–27 |
| 负责人取值 | 只写 node-1 / node-2 / node-3 三种，不要写人名或账号名 | BOARD.md L31 |

当前行（2026-11-12，HEAD `331e4c9`）：T-001～T-005 完成；T-006 node-1 待领（BOARD.md L14）；T-007 node-3 待领（BOARD.md L15）。任务书快照（HEAD `e24bfc6`）只有 5 行、全部完成；现已新增 T-006、T-007 两行，见 §11 案例 6。

状态定义原文（BOARD.md L22–27）：待领 = 任务书已写好，等负责人 Hook 发现并领取；进行中 = 任务已派发，节点 Hook 已唤醒并开始执行，不以评论为准；待验收 = 结果已交到 `results/<负责人>/`，等总控验收；完成 = 总控验收通过，已合入主项目；失败 = 执行失败或验收不通过，原因写在 Issue 里，等总控重派；拒收 = 总控验收不通过（REJECT），等待升版重派——总控在任务书生成新版本并写明变更或重派原因，核对负责人，再将 BOARD 状态改为“待领”；仅当“新版本＋派给该节点＋待领”同时成立且该版本未见过时，支持版本键的节点才会重新唤醒。

## §2 RULES.md 中的状态定义（R6a / R6b / R7）

**结论**：节点 Hook 只看 BOARD 的“派给自己、待领、未见过”；总控 Hook 不看 BOARD 做触发，靠提交扫描；交付触发是 R6b 提交扫描，不是 BOARD 状态变化。

| 规则 | 内容 | 来源 |
|---|---|---|
| R6a 节点 Hook | 只扫 BOARD.md；`git ls-remote` 看 HEAD，未变即静默；只对“派给自己、状态待领、未见过”的任务唤醒；巡逻读 BOARD 用实时接口，不用带缓存的镜像 | RULES.md L37–40 |
| R6b 总控 Hook | 每 300 秒一次（当前为 300 秒；改动时总控同步改本行）；扫两样：`scan_cursor..HEAD` 之间的全部提交（逐提交取文件列表，`results/node-X/T-xxx` 建 result_revision 事件）；全库 Issue 评论（按 updated_at 增量）；带任务编号 + 节点号的评论挂到对应事件，挂不上的建 issue_signal 事件 | RULES.md L44–47 |
| R6b 重唤 | 未确认事件最多重唤 12 次（当前为 12 次），之后转入待人工处理状态（代码当前记为 NEEDS_ATTENTION），总控须在 48 小时内归类；48 小时未归类进日报超时清单，超过 7 天升级给 Chen。**NEEDS_ATTENTION 不是终结状态。48 小时归类与 7 天升级两级机制尚未在代码中实现，列为后续批次。** | RULES.md L49 |
| R6b 不读 BOARD | 总控 Hook 不读 BOARD 做触发，BOARD 只是验收后更新的状态表 | RULES.md L49（末行） |
| R7 领 / 干 / 交 | Hook 发现新任务 → 本地 `git pull` 拉任务书 → 开始干活，**不发“已领”评论**；结果写进自己专属目录 → 本地准备好全部文件 → 一次推送交齐；**不发“已完成”评论**；总控的 Hook 靠推送上来的提交发现交付，不靠评论 | RULES.md L54–57 |
| R7 交付触发 | 交付触发是 R6b 的提交扫描，不是 BOARD 状态变化 | RULES.md L58 |
| R7 验收 | 总控验收（数字抽查、来源复核），通过才算完成；不通过时总控在 Issue 里写清楚改哪里，打回重做。打回次数按同一任务书版本计，上限 2 次，第 3 次升级给 Chen；累计返工数按任务计，到 4 次升级给 Chen，不随版本重置 | RULES.md L59 |
| R7 版本与重派 | 实质变更或总控明确决定重派时版本 +1；内容不变的重派也须升版并写清重派原因；仅错别字与链接修正且不重派时不 +1；每次 +1 必须在任务书文件头留三条记录（谁授权、UTC 时间、改了什么）。正常重派仅适用于已升级到支持 `task_id@vN` 的节点：任务书产生新版本、BOARD 派给该节点、状态设为“待领”，三个条件同时满足且该版本未见过才唤醒；未升级节点先升级。不要把手工删除 seen 当作重派步骤或快捷兜底 | RULES.md L61–63 |
| R7 验收提交 | 验收提交不得修改 results/：只允许改 BOARD.md 状态、写 MUSE-ACK、改 RULES / README / ONBOARDING 等说明文件。results/ 下的内容属节点交付物，总控不得在验收提交里顺手改（本次 496b973 即此情况） | RULES.md L63（末段） |
| R1 署名 | 四个号：总控、1 号、2 号、3 号；GitHub 上所有提交都显示为同一用户 `xy3293`，提交信息开头必须署名（全角）；半角变体 `[node-1]` 作废，只认全角；缺署名标记的提交按 REJECT 打回，理由写“未署名”；ACK 提交第一行仍须带署名标记；MUSE-ACK 必须独占一行，poll 按行匹配，不独占一行会丢 ACK | RULES.md L3–8 |
| R8 例外评论 | 仅事实性缺口（数字、来源、口径、任务书矛盾）与失败时发 Issue 评论；提问必须带任务编号 + 节点号，否则 poll 无法挂事件；只有 Issue 评论发不出去时，才改走自己与 Chen 的私聊 | RULES.md L65–71 |

事件状态取值：实测为 ACKED、NEEDS_ATTENTION（任务书实测 8 个事件：6 个 ACKED、2 个 NEEDS_ATTENTION）；代码中的另三个终态 REJECTED、SUPERSEDED、CLOSED_INTERNAL 只见于任务书陈述，node-1 未独立验证（总控 Hook 代码不在仓库内）。

## §3 tasks/ 目录的任务书格式

**结论**：按 TASK_TEMPLATE.md，7 份任务书格式一致；版本行全部合规（独占一行、`版本：vN`、位于第 9 行，前 15 行内）。

| 项目 | 内容 | 来源 |
|---|---|---|
| 模板 | `TASK_TEMPLATE.md`：任务信息（编号、标题、负责人三选一、状态待领、版本行、Issue 链接）→ 背景（≤5 行）→ 目标 → 输入 → 输出要求 → 验收标准 → 截止 | TASK_TEMPLATE.md 全文 |
| 版本行格式 | 必须是单独一行的「版本：vN」，不要加列表符号、不要加粗、不要写进 HTML 注释；巡逻脚本只扫任务书前 15 行的严格行，格式变了就唤醒不了 | TASK_TEMPLATE.md；RULES.md R7 L61 |
| 实测 | T-001～T-007 的 `版本：v1` 全部在第 9 行，独占一行、无列表符号、无加粗 | 2026-11-12 对 7 份任务书 `head -15 \| grep 版本` 的实测 |
| 任务书路径 | `tasks/<编号>-<简短英文名>.md`，如 `tasks/T-006-control-tower-data-survey.md` | TASK_TEMPLATE.md；BOARD.md L7、L14 |
| 输出路径 | `results/<负责人>/T-xxx-<简短英文名>.md` | TASK_TEMPLATE.md；各任务书“输出要求”节 |
| 负责人取值 | node-1 / node-2 / node-3（三选一） | TASK_TEMPLATE.md；BOARD.md L31 |

## §4 results/node-N/ 的交付组织方式

**结论**：一节点一目录，目录间隔离；node-1 有 4 份正式交付，node-2 只有 README（无正式交付），node-3 有 2 份；`_sandbox/` 与 TEST-identity.md 只在本地，未进仓库。

| 目录 | 内容（远端 main HEAD `331e4c9`，`git ls-tree -r HEAD`） | 来源 |
|---|---|---|
| `results/node-1/` | README.md；T-001、T-003、T-004、T-005 共 4 份正式交付 | 仓库文件清单；BOARD.md L9、L11–L13 |
| `results/node-2/` | 仅 README.md，无正式交付 | 仓库文件清单；BOARD.md（无 node-2 任务行） |
| `results/node-3/` | README.md；T-002、T-007 共 2 份正式交付 | 仓库文件清单；BOARD.md L10、L15 |
| `results/node-1/_sandbox/` | **不在仓库内**，只在 node-1 本地未跟踪：T-TEST-a.md、T-TEST-b.md；TEST-identity.md 亦只在本地未跟踪 | 2026-11-12 本地 `git status` 实测；R15 |

各目录 README 均写明专属与隔离：如 `results/node-1/README.md`“1 号研究员（node-1）专属结果目录。**只有 1 号能写这里**，其他号不要写入。文件名带任务编号，例如 `T-001-tokenized-us-stocks.md`。”node-2、node-3 的 README 同款表述。隔离规则见 RULES.md R3 L14–20：各号只写自己专属目录；文件名必须带任务编号；绝不允许多号同时改同一文件；公共文件只有总控能动；`git push` 前先 `git pull`；自测与临时验证产物走 R15 沙盒，不要写进 results/ 根目录。

## §5 GitHub Issue 与任务之间的关联方式

**结论**：一任务一 Issue，编号对应（#N ↔ T-00N）；Issue 正文含任务书路径、交付路径、范围、限制与负责人；Issue 状态不参与流程。

| 项目 | 内容 | 来源 |
|---|---|---|
| 编号对应 | #N 对应 T-00N：#1↔T-001、#2↔T-002、#3↔T-003、#4↔T-004、#5↔T-005、#6↔T-006、#7↔T-007 | BOARD.md L9–15；Issue 标题实测 |
| Issue 正文 | 含任务书路径（如 `tasks/T-006-control-tower-data-survey.md`）、交付路径（如 `results/node-1/T-006-control-tower-data-survey.md`）、调查/审查范围、限制、负责人 | Issue #6 正文实测（`list_issues` OPEN）；Issue #7 正文同款结构 |
| 状态 | 2026-11-12 实测：#1～#7 全部 OPEN，已关闭 0 个 | `list_issues` state=OPEN 7 条、state=CLOSED 0 条 |
| 评论数 | #1：2 条；#2：2 条；#6：2 条；#3、#4、#5、#7：API 未返回 comments 字段，按 0 计（与任务书“#3/#4/#5 为 0 条”一致） | `list_issues` OPEN 实测 2026-11-12 |
| #6 的 2 条评论 | 内容未验证：评论列表接口不在免审批只读工具集内，按新流程不走 `call-tool` 去读；#6 创建于 2026-11-11T20:33:23Z，更新于 2026-11-11T21:05:23Z，更新时间晚于创建时间，内容以总控侧为准 | `list_issues` OPEN 实测；任务书“输入”节 |

补充：#1 的 2 条评论是旧流程下的“已领 / 已完成”评论（T-001 交付时发出，见本节点交付记录）；新流程（R7）下成功任务不再发评论，#3、#4、#5 的 0 条评论与此一致。Issue #6 正文还明文写了三条口径：本地运行数据只在总控 VM 上、node-4 第一版不存在、生产巡逻周期 300 秒而 180 秒是未落实的计划值、Issue OPEN 不代表任务未完成——与本报告其他各节的核查一致。

---
## §6 health.json 的字段和更新时间

**结论**：文件不在仓库内（`git ls-tree -r HEAD` 无记录），只在总控 VM 本地；字段名与层级以任务书脱敏样本为准；`schema_version: 1`。

### 数据字典

| 字段 | 类型（按样本值推断） | 含义 | 示例值（任务书样本） | 来源 |
|---|---|---|---|---|
| `schema_version` | 整数 | 模式版本 | 1 | 任务书 |
| `last_success_at` | 字符串（ISO-8601 UTC） | 最近一次成功运行时间 | `2026-11-11T19:40:08Z` | 任务书 |
| `last_attempt_at` | 字符串（ISO-8601 UTC） | 最近一次尝试运行时间 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `consecutive_api_failures` | 整数 | 连续 API 失败次数 | 0 | 任务书 |
| `consecutive_script_failures` | 整数 | 连续脚本失败次数 | 0 | 任务书 |
| `note` | 字符串 | 备注 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `rate.remaining` | 整数 | API 剩余额度 | 53 | 任务书 |
| `rate.reset` | 字符串 / 整数 | 额度重置时间 | 任务书未给示例值（格式未验证） | 任务书（字段名）；值与格式未验证 |
| `rate.checked_at` | 字符串（ISO-8601 UTC） | 额度检查时间 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `last_error` | 字符串 | **最后一次错误**（不是当前错误）；成功运行时仍残留历史值 | `"comments-fetch-failed"`（残留） | 任务书 |
| `s3.ledger_available` | 布尔 | S3 台账是否可用 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `s3.error` | 字符串 / null | S3 台账错误信息 | 任务书未给示例值 | 任务书（字段名）；值未验证 |

### 真实 JSON 样本（结构真实，值只用任务书给出的；无示例值的写 null）

```json
{
"schema_version": 1,
"last_success_at": "2026-11-11T19:40:08Z",
"last_attempt_at": null,
"consecutive_api_failures": 0,
"consecutive_script_failures": 0,
"note": null,
"rate": {
"remaining": 53,
"reset": null,
"checked_at": null
},
"last_error": "comments-fetch-failed",
"s3": {
"ledger_available": null,
"error": null
}
}
```

注意：`last_error` 的残留语义是本文件的关键口径——它记录“最后一次错误”，不是“当前错误”；成功运行时仍残留，见 §11 案例 4。解析层不得把 `last_error` 非空当成“当前失败”。

## §7 scan.json 的字段和更新时间

**结论**：文件不在仓库内，只在总控 VM 本地；字段名与层级以任务书脱敏样本为准；`schema_version: 1`。

### 数据字典

| 字段 | 类型（按样本值推断） | 含义 | 示例值 | 来源 |
|---|---|---|---|---|
| `schema_version` | 整数 | 模式版本 | 1 | 任务书 |
| `scan_cursor` | 字符串（完整 commit SHA） | 扫描游标：已扫到的提交位置 | `e24bfc6190ac19474554ec59f5dd56b5967f03ac`（任务书写为 `e24bfc6…`；完整值见仓库 `git log`，为公开提交） | 任务书 + 仓库 `git log` 核实 |
| `scan_cursor_updated_at` | 字符串（ISO-8601 UTC） | 游标更新时间 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `comments` | 对象：Issue 号 → 评论数组 | 按 Issue 号索引的已处理评论 | 键为 Issue 号字符串，见下 | 任务书 |
| `comments[<号>][].id` | 整数 | 评论 ID | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `comments[<号>][].updated_at` | 字符串（ISO-8601 UTC） | 评论更新时间 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `comments[<号>][].processed` | 布尔 | 是否已处理 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `migrated_from` | 字符串 | 迁移来源（旧游标/旧格式标识） | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `migrated_at` | 字符串（ISO-8601 UTC） | 迁移时间 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `s3_ledger.ledger_id` | 字符串 | S3 台账 ID | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `s3_ledger.prefix_bytes` | 整数 | 台账前缀字节数 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `s3_ledger.prefix_sha256` | 字符串 | 台账前缀 SHA-256 | 任务书未给示例值 | 任务书（字段名）；值未验证 |
| `s3_ledger.seq` | 整数 | 台账序号 | 任务书未给示例值 | 任务书（字段名）；值未验证 |

### 真实 JSON 样本（结构真实，值只用任务书给出的；无示例值的写 null）

```json
{
"schema_version": 1,
"scan_cursor": "e24bfc6190ac19474554ec59f5dd56b5967f03ac",
"scan_cursor_updated_at": null,
"comments": {
"1": [
{
"id": null,
"updated_at": null,
"processed": null
}
]
},
"migrated_from": null,
"migrated_at": null,
"s3_ledger": {
"ledger_id": null,
"prefix_bytes": null,
"prefix_sha256": null,
"seq": null
}
}
```

说明：`comments` 的键是 Issue 号（任务书写作“Issue 号”），上例用 `"1"` 只作结构示意，不代表 #1 的实际评论处理记录——实际记录 node-1 未读到。`scan_cursor` 的完整值是仓库公开提交 `e24bfc6`（第二批文档修订），与任务书的截断写法一致。

## §8 events/ 的事件类型与状态取值

**结论**：目录不在仓库内，只在总控 VM 本地；字段名与层级以任务书脱敏样本为准；`schema_version: 1`；实测 8 个事件：6 个 ACKED、2 个 NEEDS_ATTENTION。

### 数据字典

| 字段 | 类型（按字段名与结构推断） | 含义 | 来源 |
|---|---|---|---|
| `schema_version` | 整数 | 模式版本 | 任务书 |
| `event_id` | 字符串 | 事件唯一 ID | 任务书（字段名）；值未验证 |
| `kind` | 字符串 | 事件类型（枚举值任务书未列出，见未验证清单） | 任务书（字段名）；枚举未验证 |
| `task_id` | 字符串 | 任务编号，如 `T-005` | 任务书 |
| `node_id` | 字符串 | 节点号，如 `node-1` | 任务书 |
| `source_commit_sha` | 字符串（完整 commit SHA） | 来源提交 | 任务书 |
| `source_paths` | 字符串数组 | 来源文件路径 | 任务书 |
| `state` | 字符串 | 事件状态：实测 ACKED、NEEDS_ATTENTION；代码中另有终态 REJECTED、SUPERSEDED、CLOSED_INTERNAL（任务书陈述，未独立验证） | 任务书；RULES.md R6b L49（NEEDS_ATTENTION） |
| `review.verdict` | 字符串 | 评审结论：PASS \| REJECT（与收据同口径） | 任务书 |
| `review.receipt_path` | 字符串 | 收据文件路径 | 任务书 |
| `review.reviewed_at` | 字符串（ISO-8601 UTC） | 评审时间 | 任务书 |
| `delivery.status` | 字符串 | 交付状态 | 任务书（字段名）；取值未验证 |
| `delivery.attempt_count` | 整数 | 交付尝试次数 | 任务书 |
| `approval.status` | 字符串 | 审批状态 | 任务书（字段名）；取值未验证 |
| `approval.operation_id` | 字符串 | 审批操作 ID | 任务书（字段名）；值未验证 |
| `main_ack.acked` | 布尔 | 总控是否已 ACK | 任务书 |
| `main_ack.ack_commit_sha` | 字符串 | ACK 提交 SHA | 任务书 |
| `main_ack.ack_method` | 字符串 | ACK 方式 | 任务书（字段名）；取值未验证 |
| `retry.attempt_count` | 整数 | 重试次数 | 任务书 |
| `retry.wakes` | 整数 | 重唤次数 | 任务书 |
| `retry.last_wake_at` | 字符串（ISO-8601 UTC） | 最近一次重唤时间 | 任务书 |
| `signals[]` | 数组 | 挂接的信号（评论） | 任务书 |
| `signals[].comment_id` | 整数 | 评论 ID | 任务书 |
| `signals[].issue` | 整数 | Issue 号 | 任务书 |
| `signals[].updated_at` | 字符串（ISO-8601 UTC） | 信号更新时间 | 任务书 |
| `timestamps.detected_at` | 字符串（ISO-8601 UTC） | 发现时间 | 任务书 |
| `timestamps.receipt_saved_at` | 字符串（ISO-8601 UTC） | 收据保存时间 | 任务书 |
| `timestamps.main_acked_at` | 字符串（ISO-8601 UTC） | 总控 ACK 时间 | 任务书 |
| `last_error` | 字符串 | 最后一次错误（同 health.json 口径：历史值，非当前错误） | 任务书 |

### 真实 JSON 样本（结构真实；值只用仓库已公开的可核实项，其余写 null）

```json
{
"schema_version": 1,
"event_id": null,
"kind": null,
"task_id": "T-005",
"node_id": "node-1",
"source_commit_sha": "cd7823e089518bde0d0dc6aeda8fd7b52513d98f",
"source_paths": ["results/node-1/T-005-rule-consistency-audit.md"],
"state": null,
"review": {
"verdict": null,
"receipt_path": null,
"reviewed_at": null
},
"delivery": {
"status": null,
"attempt_count": null
},
"approval": {
"status": null,
"operation_id": null
},
"main_ack": {
"acked": null,
"ack_commit_sha": null,
"ack_method": null
},
"retry": {
"attempt_count": null,
"wakes": null,
"last_wake_at": null
},
"signals": [],
"timestamps": {
"detected_at": null,
"receipt_saved_at": null,
"main_acked_at": null
},
"last_error": null
}
```

说明：上例只借用 T-005 的三项仓库已公开事实（任务编号、节点号、交付提交 SHA `cd7823e`、交付文件路径）作结构示意，**不代表某一个真实事件的完整记录**——真实事件文件 node-1 未读到，`event_id`、`kind`、`state` 等值一律不编。`kind` 的枚举值任务书未列出，见未验证清单。

## §9 receipts/ 的验收收据结构

**结论**：目录不在仓库内，只在总控 VM 本地；字段名与层级以任务书脱敏样本为准；共 5 份，对应 T-002～T-005（T-001 无收据；T-006、T-007 是否有收据未验证）。

### 数据字典

| 字段 | 类型（按字段名与结构推断） | 含义 | 来源 |
|---|---|---|---|
| `schema_version` | 整数 | 模式版本 | 任务书 |
| `event_id` | 字符串 | 对应事件 ID | 任务书 |
| `task_id` | 字符串 | 任务编号 | 任务书 |
| `node_id` | 字符串 | 节点号 | 任务书 |
| `version_sha` | 字符串（完整 commit SHA） | 评审的版本提交 | 任务书 |
| `status` | 字符串 | 固定 `REVIEWED` | 任务书 |
| `verdict` | 字符串 | `PASS` \| `REJECT` | 任务书 |
| `summary` | 字符串 | 评审摘要 | 任务书 |
| `reviewed_at` | 字符串（ISO-8601 UTC） | 评审时间 | 任务书 |
| `source_paths` | 字符串数组 | 来源文件路径 | 任务书 |
| `checks[]` | 数组 | 逐项检查 | 任务书 |
| `checks[].name` | 字符串 | 检查项名 | 任务书 |
| `checks[].status` | 字符串 | `PASS` \| `FAIL` | 任务书 |
| `checks[].evidence` | 字符串 | 证据 | 任务书 |

### 真实 JSON 样本（结构真实；值只用仓库已公开的可核实项，其余写 null）

```json
{
"schema_version": 1,
"event_id": null,
"task_id": "T-005",
"node_id": "node-1",
"version_sha": "cd7823e089518bde0d0dc6aeda8fd7b52513d98f",
"status": "REVIEWED",
"verdict": null,
"summary": null,
"reviewed_at": null,
"source_paths": ["results/node-1/T-005-rule-consistency-audit.md"],
"checks": [
{
"name": null,
"status": null,
"evidence": null
}
]
}
```

说明：`status` 为 `REVIEWED` 是任务书给定的固定值；`verdict` 未填——T-005 已被总控验收通过（BOARD.md L13 显示“完成”），按此可推断为 PASS，但本报告不把推断写进样本值，见“推断”标注。收据总数 5 份、对应 T-002～T-005 是任务书给定的事实；T-001 无收据的原因任务书未写，node-1 不猜测。

## §10 logs/health-exceptions.jsonl 的异常记录结构

**结论**：文件不在仓库内，只在总控 VM 本地；**任务书只给了文件名与路径，未给字段清单与样本**——本项无字段可列，结构未验证。

| 项目 | 内容 | 来源 |
|---|---|---|
| 路径 | `logs/health-exceptions.jsonl`（总控 VM 本地） | 任务书“调查范围”第 10 项 |
| 格式 | `.jsonl`：每行一条 JSON 记录（按扩展名与命名推断，**未验证**） | 推断（文件名）；未验证 |
| 字段清单 | 任务书未给，仓库内无文件，node-1 未读到 | 未验证 |
| 样本 | 无 | 未验证 |
| 已知关联 | 文件名表明它记录健康检查异常；`health.json` 的 `last_error` 残留值 `"comments-fetch-failed"` 是一条已知的历史错误（见 §6、§11 案例 4），是否曾写入本文件**未验证** | 任务书；推断 |

Codex 注意：解析层在拿到真实样本前，**不得假设**本文件的字段；首次接入时应先向总控索取一条脱敏样本行，或以“未知结构、按行透传原文”处理。

---
## §11 当前任务状态可能发生冲突的案例

### 案例 1：BOARD 完成 vs Issue OPEN（不是错误，是流程）

- **现象**：BOARD 上 T-001～T-005 全部“完成”，但 Issue #1～#5 全部 OPEN（2026-11-12 实测：OPEN 7 个、CLOSED 0 个）。
- **结论**：不是漏操作。R2、R7 规定完成只体现在 BOARD 与交付提交上，Issue 不回关；Issue #6 正文亦明文写“Issue OPEN 不代表任务未完成”。
- **来源**：BOARD.md L9–13；`list_issues` OPEN/CLOSED 实测 2026-11-12；RULES.md R2 L10–12、R7 L54–58；Issue #6 正文。
- **给 Codex**：任务状态的事实来源是 BOARD + 交付提交 + 收据，**不是** Issue 的 open/closed；Issue 状态不得参与任务状态机。

### 案例 2：巡逻周期 300 秒 vs 180 秒（180 是计划值，不是现状）

- **现象**：v1.1 总体方案批了 180 秒，但生产仍是 300 秒。
- **结论**：生产巡逻周期是 300 秒。证据：RULES.md R6b L46“每 300 秒一次（当前为 300 秒）”；README.md L13（节点 Hook 每 300 秒）、L15（总控 Hook 每 300 秒）；ONBOARDING 注册参数 `poll_interval_secs: 300`；本节点 Hook 注册值 `poll_interval_secs: 300`（2026-11-12 `hooks.view`）；`hooks/patrol.sh` 头部“建议 300–600”。“180”在 RULES、README、ONBOARDING、巡逻脚本中均未出现，只在两份任务书的口径说明里出现（T-006 任务书 L62、T-007 任务书 L44）；任务书明文：180 秒是 v1.1 已批方案值，阶段二改注册未授权未执行，是计划值不是现状。
- **来源**：RULES.md L46；README.md L13、L15；ONBOARDING.md 第 4 步；`hooks/patrol.sh` L10；T-006 任务书 L62；2026-11-12 全仓库 `grep 180` 实测。
- **给 Codex**：Tower 任何界面不得把 180 秒写成现状；如将来改注册，须以 RULES.md R6b 该行的同步修改为准。

### 案例 3：NEEDS_ATTENTION 事件的含义（不是终态，不是失败）

- **现象**：任务书实测 8 个事件中有 2 个 NEEDS_ATTENTION，容易被误读为“失败”或“终结”。
- **结论**：NEEDS_ATTENTION 不是终结状态（RULES.md R6b L49 原文）。它是未确认事件重唤 12 次后转入的待人工处理状态，总控须在 48 小时内归类；48 小时未归类进日报超时清单，超过 7 天升级给 Chen。但 48 小时归类与 7 天升级两级机制尚未在代码中实现，列为后续批次——即目前 NEEDS_ATTENTION 之后无自动流转，须人工处理。
- **来源**：RULES.md R6b L49；任务书实测（8 个事件：6 个 ACKED、2 个 NEEDS_ATTENTION）。
- **给 Codex**：事件状态机里 NEEDS_ATTENTION 须是“待人工”的中间态，不得当成终态展示，不得自动关闭；超时升级逻辑目前不存在，不要按 48 小时 / 7 天写定时器。

### 案例 4：health.json 的 last_error 残留历史错误值

- **现象**：`health.json` 的 `last_error` 残留 `"comments-fetch-failed"`，而同期 `consecutive_api_failures` 与 `consecutive_script_failures` 均为 0，`last_success_at` 为 2026-11-11T19:40:08Z（成功运行在先）。
- **结论**：`last_error` 的语义是“最后一次错误”，不是“当前错误”；成功运行时仍残留历史值。解析层不得把 `last_error` 非空当成“当前失败”，健康判断应以 `consecutive_*_failures` 与 `last_success_at` 为准。
- **来源**：任务书脱敏样本（2026-11-12）；§6 数据字典。
- **给 Codex**：健康面板上 `last_error` 须标注“历史最后一次错误”并配时间（若字段无时间，则只展示文案，不推断发生时间）。

### 案例 5：BOARD 滞后——T-007 已交付，BOARD 仍显示“待领”

- **现象**：node-3 的 T-007 交付提交 `331e4c9` 已在远端 main 内，文件 `results/node-3/T-007-control-tower-architecture-review.md` 已在库内，但同一 HEAD 的 BOARD.md L15 仍写 T-007 为“待领”。
- **结论**：这是 BOARD.md L4 自述的滞后（人工维护、可能滞后数小时），不是交付失败；按 R7，交付触发是 R6b 提交扫描，不是 BOARD 状态变化，总控验收后才改表。
- **来源**：2026-11-12 `git pull`（`106cbca..331e4c9`）与 BOARD.md L15 实测；RULES.md R7 L58；BOARD.md L4。
- **给 Codex**：Tower 不得以 BOARD 状态判断“是否已交付”；交付事实以 `results/` 内文件 + 提交为准，BOARD 只作验收后的展示状态。

### 案例 6：任务书快照过期——BOARD 已从 5 行变为 7 行

- **现象**：T-006 任务书称“BOARD 实测内容（5 行，全部‘完成’，远端 HEAD e24bfc6）”，但 2026-11-12 实测 BOARD 已有 7 行（新增 T-006 node-1 待领、T-007 node-3 待领），远端 HEAD 已是 `331e4c9`。
- **结论**：任务书的快照在其编写时正确，现已过期；不是任务书错误。消费方不得把“5 行”或“全部完成”写死；行数与状态须每次从 BOARD.md 现文读取。
- **来源**：T-006 任务书“脱敏结构与样本”节；2026-11-12 BOARD.md L9–15 与 `git log` 实测（`106cbca` 派 T-006 + T-007；`331e4c9` T-007 交付）。

---

## 附表 A：任务状态案例（7 个任务，2026-11-12 实测）

| 任务 | BOARD 状态 | Issue 状态 | 交付提交（远端 main） | 收据 | 备注 |
|---|---|---|---|---|---|
| T-001 | 完成 | #1 OPEN（2 条评论） | `80d5195` | 无（任务书：收据共 5 份，对应 T-002～T-005） | 旧流程下发过“已领 / 已完成”评论 |
| T-002 | 完成 | #2 OPEN（2 条评论） | node-3 交付（提交 SHA 本报告未逐一核对，见注） | 有（任务书） | node-3 交付；`evidence/step6b/` 为其证据目录 |
| T-003 | 完成 | #3 OPEN（0 条） | `a795444` | 有（任务书） | 曾出现本地提交 `29eb087` 未上远端的交付口径问题，后重推核实 |
| T-004 | 完成 | #4 OPEN（0 条） | `5d71eee`，后修正 `fa4cee5` | 有（任务书） | 修正提交只改报告 1 个文件，4 行 |
| T-005 | 完成 | #5 OPEN（0 条） | `cd7823e` | 有（任务书） | 规则一致性核查：17 项不一致 |
| T-006 | 待领 | #6 OPEN（2 条评论，内容未验证） | 未交付 | 无 | 本任务；Hook 已于 2026-11-12 04:39 唤醒 |
| T-007 | 待领（BOARD 滞后） | #7 OPEN（0 条） | `331e4c9`（node-3 已交付） | 未验证 | BOARD 仍待领，见 §11 案例 5 |

注：T-002 的交付提交 SHA 本报告未逐一核对（任务书的收据口径只说“共 5 份，对应 T-002～T-005”，未给 SHA）；除 T-002 外各任务的交付提交 SHA 均为本报告 2026-11-12 `git log` 实测或本节点交付记录。

## 附表 B：数据异常案例（4 个）

| # | 异常 | 表现 | 定性 | 来源 |
|---|---|---|---|---|
| B1 | `last_error` 残留历史错误 | `health.json` 的 `last_error` 为 `"comments-fetch-failed"`，同期连续失败计数均为 0 且最近成功运行正常 | 语义陷阱，非故障：该字段是“最后一次错误”，不是“当前错误” | 任务书样本；§11 案例 4 |
| B2 | BOARD 状态滞后 | T-007 已交付（`331e4c9`），BOARD 仍“待领” | 正常滞后：BOARD 人工维护，可能滞后数小时 | 2026-11-12 实测；§11 案例 5 |
| B3 | 本地提交谎称交付 | T-003 曾以本地提交 `29eb087` 对外称已推送，实测远端 HEAD 仍为 `6dd3d0c`、文件不存在 | 交付口径事故，已纠正：本地提交不算交付，须以 `git ls-remote` + 远端文件可读为准 | 本节点交付记录（MEMORY.md）；后重推 `a795444` 核实 |
| B4 | 任务书快照过期 | T-006 任务书称 BOARD 5 行全完成（HEAD `e24bfc6`），现为 7 行（HEAD `331e4c9`） | 快照过期，非错误：消费方须每次重读 BOARD 现文 | 任务书；2026-11-12 实测；§11 案例 6 |

## 附表 C：字段映射表（供 Codex 设计后端解析层；“建议映射”列为建议，非观测事实）

| 来源文件 | 来源字段 | 建议映射（后端字段名） | 建议类型 | 备注 |
|---|---|---|---|---|
| BOARD.md | 行（编号/任务/负责人/状态/任务书/Issue） | `tasks[]`：`task_id` / `title` / `owner` / `status` / `task_book_path` / `issue_number` | string / enum | 状态枚举见 §1；`issue_number` 从 Issue 链接提取数字 |
| BOARD.md | 状态说明 | `task_status` 枚举：`PENDING` / `IN_PROGRESS` / `PENDING_REVIEW` / `DONE` / `FAILED` / `REJECTED` | enum | 映射关系为建议：待领→PENDING、进行中→IN_PROGRESS、待验收→PENDING_REVIEW、完成→DONE、失败→FAILED、拒收→REJECTED；BOARD 中文状态须原样保留一份 |
| RULES.md | R6b 重唤与归类 | `event.state`：`ACKED` / `NEEDS_ATTENTION` / `REJECTED` / `SUPERSEDED` / `CLOSED_INTERNAL` | enum | 后三者未独立验证，见未验证清单 |
| tasks/*.md | `版本：vN`（第 9 行） | `task_books[].version` | string | 巡逻只扫前 15 行严格行；无版本字段时按 v1 处理（R7） |
| tasks/*.md | 任务信息块 | `task_books[].owner` / `task_books[].issue_url` | string | 负责人三选一：node-1 / node-2 / node-3 |
| results/node-N/*.md | 文件路径 | `deliveries[].path` / `deliveries[].commit_sha` / `deliveries[].node_id` | string | 文件名须带任务编号（R3）；交付事实以提交为准 |
| health.json | 全部字段 | `health.*`（同名字段直通） | 见 §6 | `last_error` 须标注历史语义；健康判断以 `consecutive_*_failures` + `last_success_at` 为准 |
| scan.json | `scan_cursor` / `comments` | `scan.cursor_sha` / `scan.comments_by_issue` | string / map | `comments` 键为 Issue 号字符串 |
| events/*.json | 全部字段 | `events[]`（同名字段直通） | 见 §8 | `kind` 枚举待总控补齐 |
| receipts/*.json | 全部字段 | `receipts[]`（同名字段直通） | 见 §9 | `verdict` 仅 `PASS` \| `REJECT` |
| logs/health-exceptions.jsonl | 未知 | 首次接入按行透传原文，待样本后再定字段 | — | 见 §10；不得假设字段 |

## 附表 D：不确定字段清单（未验证）

| # | 项目 | 为什么未验证 | 影响 |
|---|---|---|---|
| D1 | `logs/health-exceptions.jsonl` 的字段清单与样本 | 任务书只给了文件名；文件不在仓库内；node-1 未读到原始文件 | 解析层不得假设字段；首次接入须先索取脱敏样本行 |
| D2 | 事件 `kind` 的枚举值 | 任务书只给了字段名，未列枚举 | 事件分类、筛选功能须等总控补齐枚举后再做 |
| D3 | 事件终态 REJECTED、SUPERSEDED、CLOSED_INTERNAL | 只见于任务书陈述；总控 Hook 代码不在仓库内，node-1 未独立验证 | 状态机里可先列出，但须标“未验证”，不得据此写自动流转 |
| D4 | Issue #6 的 2 条评论内容 | 评论列表接口不在免审批只读工具集内，按新流程不走 `call-tool` 去读 | #6 的讨论内容未知；不得猜测 |
| D5 | T-007 是否有验收收据 | 任务书的“5 份收据对应 T-002～T-005”写于 T-007 交付前；T-007 交付后是否新增收据未知 | 收据总数不得写死为 5 |
| D6 | `health.json` 的 `note`、`rate.reset`、`rate.checked_at`、`s3.ledger_available`、`s3.error` 的值与格式 | 任务书只给了字段名，无示例值 | 展示时只列字段名，不编示例值 |
| D7 | `scan.json` 的 `comments[].processed` 语义、`s3_ledger` 各字段的值与格式 | 任务书只给了字段名，无示例值 | 同上 |
| D8 | `events/` 的 `delivery.status`、`approval.status`、`main_ack.ack_method` 的取值 | 任务书只给了字段名，未列枚举 | 同上 |
| D9 | T-002 的交付提交 SHA | 本报告未逐一核对（任务书未给 SHA） | 附表 A 中已注明；不编 SHA |
| D10 | R6b 的 48 小时归类 / 7 天升级机制 | RULES.md L49 明文写“尚未在代码中实现，列为后续批次” | Tower 不得按此写定时器；NEEDS_ATTENTION 目前无自动流转 |

**推断标注**：本报告中凡写“推断”的地方均为推断，不是事实：① 附表 C 的“建议映射”列与建议类型是为 Codex 提供的设计建议，非观测事实；② §9 样本中 `verdict` 未填，T-005 的 PASS 是按 BOARD“完成”推断的，未写入样本值；③ §10 中“.jsonl 每行一条 JSON 记录”是按扩展名与命名的推断；④ §5 中“#3/#4/#5/#7 评论数为 0”是按 API 未返回 comments 字段推断的（工具在 0 条时省略该字段，#1/#2/#6 有评论时字段存在）。

---

## 来源清单（2026-11-12 核查）

**仓库内（远端 main HEAD `331e4c9`，本地 `git pull` 已是最新）**
- BOARD.md（L3–L5、L7、L9–15、L22–27、L31）
- RULES.md（R1 L3–8；R2 L10–12；R3 L14–20；R6a L37–40；R6b L44–49；R7 L52–63；R8 L65–71；R13–R17）
- TASK_TEMPLATE.md（全文）
- tasks/T-001～T-007-control-tower-*.md（版本行均在第 9 行）
- results/node-1/README.md、results/node-2/README.md、results/node-3/README.md
- hooks/patrol.sh（L10、L219、L231–233、L251–257）
- README.md（L13、L15、L28）
- ONBOARDING.md（第 4 步，`poll_interval_secs: 300`）
- `git ls-tree -r HEAD`（health.json、scan.json、events/、receipts/、logs/ 均无记录）
- `git log`（`106cbca` 派 T-006 + T-007；`331e4c9` T-007 交付；`e24bfc6` 第二批文档修订）

**GitHub API（`list_issues`，2026-11-12）**
- state=OPEN：7 条（#1～#7）；state=CLOSED：0 条；评论数 #1:2、#2:2、#6:2，#3/#4/#5/#7 未返回 comments 字段
- Issue #6 正文：https://github.com/xy3293/muse-hub/issues/6
- Issue #7 正文：https://github.com/xy3293/muse-hub/issues/7

**任务书提供的脱敏结构与样本（2026-11-12）**
- tasks/T-006-control-tower-data-survey.md“总控提供的脱敏结构与样本”节：BOARD 实测（5 行，HEAD `e24bfc6`）、Issues 实测（#1～#5 全 OPEN；#1:2、#2:2、#3/#4/#5:0）、health.json 字段与实测例、scan.json 字段、events/*.json 字段与实测（8 个事件：6 个 ACKED、2 个 NEEDS_ATTENTION）、receipts/*.json 字段（共 5 份，对应 T-002～T-005）、关键口径（300 秒 / 180 秒 / node-4 / 署名标记）

**本节点实测（2026-11-12）**
- Hook：`muse-hub-patrol` 已是当前版本 `2026-11-11.3`（与 `release-manifest.md` 的 SHA-256 `f5795685…` 一致），备份 `.last-good` 完好（SHA-256 `7138f44b…`），`dry_run` 通过（silent、board-unchanged、HEAD `331e4c9`），已启用；T-006 唤醒于 2026-11-12 04:39:01
- 本地 `git status`：`results/node-1/_sandbox/` 与 TEST-identity.md 未跟踪、未进仓库

---

*报告人：node-1；调查完成日期：2026-11-12。本报告不含任何真实账号、手机号、Token、密钥、信用卡信息，未修改 BOARD.md / RULES.md / 任何任务书 / 任何结果文件。*
