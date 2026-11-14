# T-021：总控审批卡覆盖扩展到工具层卡（研究＋设计）

- **编号**：T-021
- **负责人**：node-1
- **任务书**：`tasks/T-021-node1-director-card-coverage.md`（v1）
- **Issue**：https://github.com/xy3293/muse-hub/issues/23
- **完成日期**：2026-11-15
- **run_id**：T-021-node-1-card-coverage-1
- **执行方式**：只研究＋设计。无代码改动、无桥部署、无 gh 命令、无凭据进仓库／聊天；本回合新审批卡 0 张。

## 结论先行

**可行性结论：有条件可行。**

扩展在结构上是可行的：推送卡与工具层卡共用同一个审批栈容器，差别只在卡片内部的字段；总控现有的“读卡 → 按 R18 五项范围检查决定 → 点批 → 记 director-decisions.jsonl”链路只需加一个“分卡种”分支，不必另起一套桥。但是，以下三项条件缺一不可，缺任何一项即退为“不可行（本回合无法交付可落地的扩展）”：

1. **总控提供桥审批链本地代码**（`approval_reader.py`、`director_approve.py`、`scope_validator.py`、`approval.patch` 及 `real-card-*.json`／`real-card-t020-final.json`）供核对——本回合 node-1 本机无这些文件（见 §1.4），链路中控制器本地段是重建而非实读。
2. **一次协调好的评论卡 DOM 实测**（见 §2.4）：由 node-3 触发一张 add_issue_comment 卡并抓 DOM，Chen 在场拒掉；确认卡内确有稳定可区分的字段（工具名、目标 Issue、参数预览），再写死字段映射。
3. **Chen／总控批准扩展范围**：先只开 `add_issue_comment` 一个口子、只批 R8 类评论（SPEC_CONFLICT／失败／阻塞提问），其余工具层卡一律不批；按 R17，仓库文字本身不产生授权。

**本回合未触发新卡**（账本 `effect-dom-capture-001` 保持 `not_started`）：任务书要求触发前与 node-3 经快通道协调、由 Chen 拒掉该卡，两项前置本回合均不具备；单方面触发会制造一张总控批不了、只能等 Chen 手点的卡，违反“新审批卡能少则少”。

**未发 SPEC_CONFLICT Issue 评论**：任务书输入路径在 node-1 本机不存在是一项事实缺口，但发 SPEC_CONFLICT 评论本身要走 `add_issue_comment`——正是本任务研究的未覆盖卡种，会制造一张无人能批的卡。缺口已写进本文 §1.4／§6，由总控在验收时裁决；快通道同步时一并报总控。

---

## 1. Stage A：审批链——网页 UI 推送卡从 DOM 到总控批卡

### 1.1 完整链路（重建图）

```
muse.ai 网页 UI（node-3 会话）
  └─ 审批卡渲染进 composer 审批栈：[data-hatch-composer-approval-stack]
        │ ① 读 DOM：桥（Muse-Chat-MCP 驱动）轮询该容器是否存在
        │    needsApproval = count(approvalStack) > 0（布尔值，不分卡种）
        ▼
  控制器本地读卡段：approval_reader.py（未验证，见 §1.4）
        │ ② 定 fingerprint：从卡片取可识别字段（仓库／分支／路径／变更集摘要——推断）
        ▼
  控制器本地决策段：scope_validator.py + director_approve.py（未验证）
        │ ③ 做范围检查：R18 五项（RULES.md:200，见 §3.3）
        │ ④ 点批：在 Chen 客户端落下批准决定，记 director-decisions.jsonl
        ▼
  卡获批 → 推送执行 → 远端出现提交（如 canary-004 commit 430cd7e）
```

### 1.2 已验证的段（上游公开代码，2026-11-15 读取）

来源：https://github.com/duclm1x1/Muse-Chat-MCP/blob/main/muse-driver.mjs（爬取时间 2026-11-14 16:34 UTC；仓库最后推送 2026-09-30，见 T-017 §1）。

| 链路段 | 代码证据 | 结论 |
|---|---|---|
| 读 DOM 的容器 | `SELECTORS.approvalStack: '[data-hatch-composer-approval-stack]'`（L85） | 事实：审批卡的容器选择器就是这一个 |
| 判定 | `const needsApproval = (await p.locator(SELECTORS.approvalStack).count()) > 0`（L824），在 `_run` 末尾一次性求值 | 事实：只返回“有没有卡”，不返回卡种、字段、文本 |
| 返回 | `...(needsApproval ? { needsApproval: true } : {})`（L850），其余字段为 reply／messages／threadUrl／elapsedMs／error／timedOut | 事实：调用方只能拿到布尔值 |
| 诊断接口 | `_dumpDom` 返回 `hasApproval: !!document.querySelector(sels.approvalStack)`（L1262），html 截断 20000 字符 | 事实：诊断也只给布尔值＋截断 HTML |
| 点批 | 全文 `approval` 仅命中选择器定义、needsApproval 判定与返回、dump-dom 的 hasApproval 标志 | 事实：上游驱动**没有任何点击审批按钮的代码**（与 T-017 §4 一致） |

### 1.3 已验证的段（行为证据，hub 仓内）

- 推送卡总控能自动批：canary-004（node-3，commit 430cd7e，2026-11-14 18:33）、canary-005b（node-1，commit b0d78a0）、canary-006（node-2）、T-020 推送卡（commit 2148925，2026-11-14 23:01），均由总控按 R18 自动批；过去 24h 内 Chen 手点 0 张。来源：RULES.md R16 审批卡自动化行（L139）；`results/node-1/node3-shell-channel-pending-record.md` §4（decision_binding：canary-004 `47700aa5…`，decided_at 2026-11-14T10:32:54Z；005b `99bb989e…`，10:57:19Z）。
- 决策记录形态：`director-decisions.jsonl` 在总控本机，不在仓库内，节点未独立核对原文（同上 §4 注明）。
- 规则依据：R16（RULES.md:139）——覆盖范围写的是“网页 UI 发起的推送产生的审批卡”，不是“一切写操作卡”；R18（RULES.md:200）——总控批一张范围内节点推送的卡时只查五项（见 §3.3）。

### 1.4 只认推送卡的是哪一段——未验证，但可定位到读卡段

**事实缺口**：任务书指明的输入路径 `~/workspace/node3-browser-poc/`（muse-chat-mcp-test/source 与 approval/：`approval_reader.py`、`director_approve.py`、`scope_validator.py`、`approval.patch`、`real-card-*.json`、`real-card-t020-final.json`）在 node-1 本机**不存在**；2026-11-15 00:33 CST 全盘查找亦无上述文件。桥审批链的控制器本地代码只在总控 VM 上，node-1 读不到。因此 §1.1 中标“未验证”的两段无法从源码确认，只能从行为证据收敛：

- **收敛结论（推断，有行为证据支撑）**：只认推送卡的过滤发生在**读卡／定 fingerprint 段**（`approval_reader.py` 或其过滤逻辑），而不是决策段。理由：T-020 评论卡在桥上的观测状态是 **0 卡**（任务书背景；T-020 证据：2026-11-14 22:45:19 发起的卡未获批准、22:49:49 超时），不是“1 张待决卡”。如果读卡段已把评论卡计入、只是范围检查拒绝，桥上应显示 1 张未决卡。0 卡说明评论卡在计数之前就被滤掉了（或读卡段的提取逻辑只认含推送字段的卡片）。
- **未验证**：过滤到底按什么字段（卡片文本是否含 `git push`／仓库名／文件路径？是否按卡片内按钮文案？是否按某种 `data-*` 属性？）、fingerprint 的具体构成、以及 `approval.patch` 改了上游驱动的哪几行。需总控提供 §4 条件 1 的文件后才能把本节改成“已验证”。

---

## 2. Stage B：工具层卡 DOM 核查——add_issue_comment 卡长什么样

### 2.1 容器：与推送卡是同一种审批 UI

上游驱动只有一个审批容器选择器 `[data-hatch-composer-approval-stack]`（§1.2），且判定是不分卡种的布尔值。因此在驱动层，**评论卡与推送卡是同一种审批 UI、同一种容器**；差别不在容器选择器，一定在栈内卡片的内容或字段。任何“换一个选择器就能读到评论卡”的方案都是错的——容器已经对了，缺的是卡片内部的分类与提取。

### 2.2 卡确在 DOM 内出现（行为证据，不是推测）

| 证据 | 内容 | 来源 |
|---|---|---|
| T-020 评论卡 | node-3 2026-11-14 22:45:19 CST 发起的 `add_issue_comment` 审批卡，桥上 0 卡，未获批准，于 22:49:49 CST 超时未执行（270 秒）；SPEC_CONFLICT 评论最终由总控代发到 Issue #22 才落地 | `results/node-3/T-020-autonomous-peer-proof.md` 检查 3 |
| 卡种测试 f033427 | 评论卡一弹就挡住桥消息（桥后续发送得不到回复，agent 停在等审批处） | 任务书背景；`results/node-3/card-kind-test-20261115.md`、`card-kind-test-ui-20261115.md`（2026-11-15 00:16 起） |
| 卡在用户客户端可见 | 任务书 Stage B 预设“Chen 拒掉该卡”——卡须在 Chen 客户端可见、可点，拒掉才有意义 | 任务书 Stage B |

三项合起来只能得出一个结论：评论卡渲染进了同一个审批栈（否则不会挡住 agent、不会出现在用户客户端），但桥的读卡段没有把它计为一张卡（§1.4 的收敛结论）。

### 2.3 卡内字段级形态——未验证

以下均**未验证**，不得当作设计输入直接写死：

- 卡片是否在文本中明示工具名 `add_issue_comment`、目标仓库 `xy3293/muse-hub`、目标 Issue 号、评论正文预览；
- 卡片子节点是否有可定位的选择器（按钮文案、角色属性、`data-*` 属性）；
- 推送卡与评论卡在 DOM 结构上是否除文本外还有结构性差异（例如不同的子容器／图标节点）；
- 仓内无任何一张评论卡的 `real-card-*.json` 快照可供对照（现有快照均为推送卡，且在总控 VM 上）。

验收标准第 1 条要求“附选择器／字段证据，不是推测”——**本回合如实报告：该条未完全满足**。满足它只需一次 §2.4 的捕获，不需要改设计方向。

### 2.4 捕获方案（下一次协调实测，一张卡，记账后执行）

- **账本**：`effect-dom-capture-001`（`not_started`，见 §7）。触发前先记账，触发后把 DOM 关键片段记进设计文档修订版，不贴整页 DOM。
- **触发方**：node-3（经快通道协调后），在其会话里发起一次 `add_issue_comment`（目标 Issue 由总控指定，建议 Issue #23 本任务 Issue，正文写明“T-021 DOM 捕获测试卡，请 Chen 拒掉”）。
- **在场方**：Chen 必须在场并拒掉该卡；拒掉后评论不落地，无副作用残留。
- **抓取方**：总控经桥 `dumpDom`（或等效 DOM 抓取）取 `[data-hatch-composer-approval-stack]` 内该卡片的子树，只保留：卡片根选择器、工具名文本节点、目标 Issue／正文预览字段、批准／拒绝按钮选择器、`data-*` 属性清单；截断长度与推送卡快照同口径。
- **判定**：若卡内字段稳定包含（工具名、目标 Issue、正文可识别）三项，即可按 §3 写死字段映射；若卡内只有通用文本、无稳定区分字段，则结论改为“不可行（须改读卡方式，例如走消息流而非审批栈）”，并重新评估。
- **不做的事**：不由 node-1 单方面触发；不趁 Chen 不在场触发；不抓整页 DOM、不把 DOM 全文贴进仓库（只记关键片段）。

---

## 3. Stage C：扩展设计

### 3.1 设计原则

1. **推送路径不动**：现有推送卡链路已验证（canary-004/005b/006、T-020），扩展只加分支，不改已验证的推送判定与范围检查。
2. **先只开一个口子**：`add_issue_comment`，且只批 R8 类评论；其余工具层卡默认拒绝（fail closed）。
3. **一次一卡**：上游驱动 `_serial` 已串行化单窗口操作（muse-driver.mjs L131–141）；总控决策循环一次只处理一张卡，决出并记录后才处理下一张。
4. **批卡 ≠ 落地**：批卡后须核对执行结果（评论是否出现在目标 Issue），核对口径见 §3.5。

### 3.2 接口改动（桥 approvals 接口／读卡段）

| 改动 | 内容 |
|---|---|
| `approval_reader.py`：卡片分类 | 读 `[data-hatch-composer-approval-stack]` 的子节点，逐卡提取并返回**类型化卡片数组**，取代现有的“有／无卡”布尔值。单卡结构：`{kind, tool, target_repo, target_issue, summary_text, fingerprint, raw_text_hash}`。`kind ∈ {push, tool_call}`；`tool_call` 首批只认 `tool == "add_issue_comment"`。 |
| 字段映射（待 §2.4 实测后写死） | `tool`：卡内工具名文本；`target_issue`：卡内目标 Issue 号（须与任务书 Issue 一致）；`summary_text`：评论正文预览全文（不是截断到无法识别的片段）；`fingerprint`：`kind + tool + target_repo + target_issue + raw_text_hash` 的稳定组合（ exact 构成待总控提供 `scope_validator.py` 后核对；推送卡 fingerprint 构成同样未验证，见 §1.4）。 |
| 向后兼容 | 保留 `needsApproval` 布尔值（任一卡存在即 true），供现有调用方与 `dumpDom.hasApproval` 使用；新增 `listApprovals()` 返回类型化数组。 |
| 兜底 | 分类失败的卡（字段缺失、无法识别卡种）不进入决策队列，记为 `UNCLASSIFIED`，桥上显示为待人工处理，不自动批。 |

### 3.3 `director_approve.py` 改动

1. **分派**：按 `kind` 分派。`push` 走现有路径（不动）；`tool_call` 走新增路径；未知 `kind` 拒绝。
2. **allowlist**：工具层只允许 `add_issue_comment`；其余工具名一律拒绝并记 `OUT_OF_SCOPE`。
3. **逐卡决策循环**：取队首一张卡 → 跑 §3.4 的五项检查 → 全部通过才点该卡自己的批准按钮（在卡片子节点内定位按钮，不用全局选择器）→ 写 `director-decisions.jsonl`（沿用现有记录形态：decision_binding＋decided_at，见 §1.3）→ 再取下一张。
4. **拒绝路径**：任一检查不通过即拒绝（不点批），记 `REJECTED`＋检查编号；通用文本、无法识别的卡必须拒绝（沿用 R18 RULES.md:200 的“只显示通用 `git push`、无可识别变更集的卡必须拒绝”）。
5. **不重审内容本身**：沿用 R18——总控批卡时不重审评论正文的实质对错，只查范围；评论实质对错由任务验收负责。

### 3.4 范围检查：工具层卡的五项（由 R18 五项平移，RULES.md:200）

R18 原文五项（针对推送卡）：“(1) 对应已知已派任务与授权节点；(2) 动作是该任务允许的 GitHub 推送或相关操作；(3) 仓库、分支、目标路径在任务书范围内；(4) 变更集完整可识别，无范围外文件或操作；(5) 不是需单独授权的不可逆操作。”平移如下：

| # | 推送卡原意 | 工具层卡（add_issue_comment）平移 | 不通过即拒绝的情形 |
|---|---|---|---|
| 1 | 对应已知已派任务与授权节点 | 评论发起节点处于 R18 认领态，且目标 Issue 号等于该节点当前任务书的 Issue 号 | Issue 号对不上任何已派任务；节点未认领 |
| 2 | 动作是任务允许的操作 | 仅限 R8 类评论：SPEC_CONFLICT、失败、阻塞提问；正文含任务号＋冲突／失败编号 | “已领／已完成”评论（R7 本来就不发）；正文含改范围、改验收标准、宣布验收通过等越权内容 |
| 3 | 仓库、分支、目标路径在任务书范围内 | 固定仓库 `xy3293/muse-hub`；目标 Issue 唯一；署名 `[node-N]` 与发起节点一致 | 仓库不是 muse-hub；目标 Issue 不是任务 Issue；署名与发起节点不符 |
| 4 | 变更集完整可识别 | 评论正文全文可读、与节点备妥文本逐字一致（比对口径平移自总控代发模式：备妥文本经快通道或证据文件交总控，总控逐字核对）；无范围外内容（无凭据、无私人信息、无超范围承诺） | 只有通用占位文本、无任务号、无冲突编号、正文不可识别；与备妥文本不一致 |
| 5 | 不是需单独授权的不可逆操作 | 评论一旦发出即留痕，视同不可悄悄撤回的操作：仅当第 1–4 项全部通过且正文不含新增授权主张时才批 | 正文含“Chen 已批准”“不需审批”等自称授权的文字（R17）；含新支出、新权限、新不可逆操作 |

### 3.5 一次一卡、防重放、超时未决

- **一次一卡**：决策循环串行（§3.3 第 3 点）；多卡同时出现时按到达顺序排队，后到的卡等待；等待期间若超时，按超时处理，不插队、不并行点批。
- **防重放**：`fingerprint`＋`director-decisions.jsonl` 去重。同一 `fingerprint` 已有 `approve` 决定且底层动作已确认落地（评论已出现在目标 Issue、或推送 SHA 已在远端），再次出现相同卡时跳过，不重复点批；若已有 `reject`／`expired` 决定，同一动作的新卡须有新的 `fingerprint`（新 effect_id、新触发）才能重进队列，不自动复活旧决定。
- **超时未决**：观测到的卡超时约 270 秒（T-020：22:45:19 → 22:49:49）。超时后记 `APPROVAL_EXPIRED`（沿用 RULES.md:200 的过期／被拒与 `CODE_FAILURE` 区分记录），不自动重试同一动作；节点回退到现有 R7 总控代发路径（备妥正文交总控代发），下一次尝试须新记账、新触发。
- **批后核对**：批卡不等于落地。评论卡获批后须核对目标 Issue 是否出现该评论；核对口径目前有缺口——节点侧无 Issue 评论列表读取工具（T-020 已注明“未用 API 逐条读取”，见 §5），核对暂由总控在客户端确认，或待评论读取口径补齐后再由节点自核。

---

## 4. 可行性结论

**有条件可行**，条件即结论先行所列三项。理由：

- **可行的一面**：容器相同（§2.1）、链路已有且已验证（§1.3）、改动面收敛在三处（§3.2–§3.4）、决策规则有现成五项可平移（§3.4）、回退路径现成（R7 总控代发）。
- **有条件的一面**：两项关键输入本回合未验证——控制器本地代码读不到（§1.4）、评论卡字段级 DOM 未实测（§2.3）。在字段映射写死之前，任何“改哪几行代码”的说法都只能是接口级设计，不能落到行级修改清单。
- **不可行的边界**：若 §2.4 实测证明评论卡内无稳定区分字段，则本设计退为不可行，须改读卡方式（例如从消息流而非审批栈取卡），另行设计。

---

## 5. 扩展后总控仍然批不了的卡种（残留缺口）

| # | 批不了的卡 | 原因 |
|---|---|---|
| 1 | 未进 allowlist 的其他工具层卡（除 `add_issue_comment` 外的一切工具调用卡，如 shell 执行、其他写操作、浏览器操作、支付／购买类） | 本设计只开一个口子；每新增一种须单独评估字段、范围检查与授权（R17：仓库文字不产生授权） |
| 2 | 分类失败的卡（`UNCLASSIFIED`：字段缺失、无法识别卡种） | §3.2 兜底：不自动批，等人工处理 |
| 3 | 不在当前桥接会话里的卡（其他会话／设备上的审批卡） | 桥只看所挂的 Chrome 会话 |
| 4 | 登录失效时的任何卡（`loggedIn: false`） | 无会话即无卡可读，先恢复登录（上游 `muse_status` 判定，见 T-017 §3） |
| 5 | 排队超时掉的卡（多卡并发、后到的卡等前卡决出期间超时） | 一次一卡串行；超时按 `APPROVAL_EXPIRED` 处理，回退 R7 代发 |
| 6 | 批后执行失败的卡（获批但评论未落地） | 批卡 ≠ 落地；节点侧无评论列表读取口径，核对依赖总控确认（§3.5） |
| 7 | 伪装成推送卡的非推送卡（若字段不可区分） | 防线是 fingerprint／字段校验；无法区分时宁可拒绝（fail closed），不猜 |

---

## 6. 事实与推断、未验证、输入缺口

### 事实（有来源）

- 上游驱动选择器与布尔判定：§1.2，来源链接见该节，读取日期 2026-11-15。
- 推送卡自动批验证：canary-004/005b/006、T-020（§1.3）；R16 自动化行只覆盖“网页 UI 发起的推送”（RULES.md:139）。
- T-020 评论卡 22:45:19 发起、桥上 0 卡、22:49:49 超时：`results/node-3/T-020-autonomous-peer-proof.md` 检查 3；`results/node-1/node3-shell-channel-pending-record.md` §3。
- R18 五项范围检查原文：RULES.md:200。
- Chen 2026-11-15 00:29 决定放弃 node-3 shell 通道、方向改为优化总控审批卡能力：BOARD.md 规则记录；任务书背景。
- 卡种测试 f033427（2026-11-15 00:16 起）：`results/node-3/card-kind-test-20261115.md`、`card-kind-test-ui-20261115.md`（两文件正文较简：终端测试记凭据实测状态，UI 测试记推送与卡决定见主聊汇总——细节以任务书背景为准）。

### 推断（有证据支撑，已标注）

- 只认推送卡的过滤在读卡段（§1.4）：依据是桥上观测为 0 卡而非 1 张未决卡；过滤字段未验证。
- fingerprint 由卡片可识别字段组合而成（§3.2）：依据是 R18 第 4 项要求“变更集完整可识别”；具体构成未验证。

### 未验证

- 控制器本地代码四段（读卡、决策、范围检查、patch）与推送卡 fingerprint 构成（§1.4）。
- 评论卡字段级 DOM（选择器／字段）（§2.3）。
- Issue #23 评论列表（未逐条读取；T-020 同口径）。
- 浏览器自动化是否违反 Muse 平台限制（沿用 T-017 结论：未验证）。

### 输入缺口（请总控裁决）

1. 任务书输入路径 `~/workspace/node3-browser-poc/` 在 node-1 本机不存在（2026-11-15 00:33 CST 核实），Stage A/B 的控制器本地段无法实读。请总控提供上述四个文件＋real-card JSON，或给 node-1 只读访问总控 VM 副本的合规方式。
2. 验收标准第 1 条（附选择器／字段证据）本回合未完全满足，待 §2.4 一次协调捕获后修订本文。

---

## 7. 副作用账本

| effect_id | 类型 | 状态 | 依据 |
|---|---|---|---|
| effect-dom-capture-001 | add_issue_comment DOM 捕获（一次） | `not_started` | 本回合未触发（前置不具备，见 §2.4） |
| effect-001 | GitHub 推送本设计文档 | `intent_recorded` → 推送后核验改 `confirmed` | 远端 HEAD 与远端文件读回为准（本文件不自引自身 SHA） |

## 来源

- 任务书：https://github.com/xy3293/muse-hub/blob/main/tasks/T-021-node1-director-card-coverage.md
- 上游驱动：https://github.com/duclm1x1/Muse-Chat-MCP/blob/main/muse-driver.mjs（SELECTORS L85；needsApproval L824／L850；dumpDom L1262）
- 规则：`RULES.md` R16（L139）、R18 五项（L200）、R7；`RULINGS/2026-11-14-credential-scope.md`
- 证据：`results/node-3/T-020-autonomous-peer-proof.md`（检查 3）；`results/node-1/node3-shell-channel-pending-record.md`（§3、§4）；`results/node-3/card-kind-test-20261115.md`、`card-kind-test-ui-20261115.md`
- 前置报告：`results/node-1/T-017-node3-browser-poc-p0-verification.md`（§1、§3、§4）
- checkpoint：`~/hooks/state/task-runtime/tasks/T-021/attempt-0001/checkpoint/`（seq 2；Stage A/B 已完成，Stage C 即本文；不进仓库）

---

[node-1] T-021 完成：总控审批卡覆盖扩展到工具层卡，结论为有条件可行（三条件见结论先行）；本回合新审批卡 0 张；两项输入缺口（桥本地代码读不到、评论卡字段级 DOM 待一次协调捕获）已写进 §1.4／§2.3／§6，请总控裁决。
