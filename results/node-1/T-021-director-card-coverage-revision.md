# T-021 修订版：总控审批卡覆盖扩展到工具层卡（按 CDP 探针重写结论）

- **编号**：T-021（修订版）
- **负责人**：node-1
- **任务书**：`tasks/T-021-node1-director-card-coverage.md`（v1，未改）
- **Issue**：https://github.com/xy3293/muse-hub/issues/23
- **修订日期**：2026-11-15
- **修订依据**：`RULINGS/2026-11-15-card-mechanics-field-record.md` 第五节（commit d13d044，Chen 侧 CDP 探针，2026-11-15 01:2x）
- **被修订稿**：`results/node-1/T-021-director-card-coverage-design.md`（commit 4601058）
- **本回合新审批卡**：0 张（只读文件＋shell git push，不点任何卡）
- **第二次修订**（2026-11-15，Chen 直令）：(b) 不成立——节点是云端 VM、无浏览器，卡在陈的 PC 上，总控无可点的东西；(b) 重写为「陈的 PC 上的点卡代理（CDP）」，总控只是请求方。
- **第三次修订**（2026-11-15，Chen 直令）：桥侧已通——桥有 `GET /v1/muse/approvals` 与 `POST /v1/muse/approvals/{id}/approve`，评论卡可读可批，走 director_override 路径；「桥侧无解」与「唯一路径是 DOM 点击」作废。
- **第四次提交**（2026-11-15，总控 REJECT 6882009564 后重交）：补评论卡字段级证据（§1.3）、补残留缺口清单（§6）、修正文末标记行。

## 1. 修订说明：4601058 的结论为什么要改

### 1.1 四条探针结论与 4601058 的核对

| 探针结论 | 与 4601058 是否一致 | 说明 |
|---|---|---|
| ① 卡是内联组件（节点自己会话，输入框上方）；待批卡两个按钮「允许」「拒绝」；正文五个字段 Action、Account、Branch or ref、Repository owner、Repository；历史卡同结构、无按钮、显示「已允许 · N 小时前」 | 一致（补空白） | 与 4601058 §2.1「同容器同 UI、差别在卡内字段」一致；补了我 §2.3 未验证的字段级形态。注意：五个字段是探针那张推送卡的字段，评论卡的字段会不同（Issue／正文），但「内联组件＋允许／拒绝按钮」的结构是通用的。 |
| ② 没有服务端审批接口：WebSocket 帧加密（base64 密文，无明文 JSON）；12 个候选 REST 路径全返 SPA HTML；桥 approvals 显示 0 卡不是 bug，是不存在这个接口 | **不一致，推翻前提** | 4601058 §1.4 推断「只认推送卡的过滤在读卡段（approval_reader.py）」，并在 §3.2/§3.3 设计「改 approval_reader.py 加卡种分支、加 listApprovals()、改 director_approve.py 分派点批」。依据是桥上观测为 0 卡而非 1 张未决卡。但实测是根本不存在服务端审批接口——桥显示 0 卡不是过滤 bug，是没有这个接口可接。**桥侧改代码无解，不是工作量问题。** §3.2/§3.3 的设计作废。 |
| ③ 点「允许」＝立即执行：点击后 4 秒内出现「请求已获批」，随后提交 031acfb 落远端，blob 回读一致（探针文件已由 Chen 用 PAT 删，485b0e4） | 一致（补空白） | 与 4601058 §3.5「批卡 ≠ 落地，须批后核对」一致；探针示范了核对做法（blob 回读），且证实点允许后确实立即执行。 |
| ④ 唯一技术路径是 DOM 级点击；能点卡的实体只有两类：(a) 节点自己、(b) 陈的 PC 上持有登录态的点卡代理（CDP） | **重构结论** | 4601058 的结论「有条件可行（三条件：桥本地代码＋评论卡 DOM 捕获＋范围批准）」不再成立。条件 1（桥本地代码）因②作废；条件 2（DOM 捕获）改途——DOM 知识仍需要，但用途是 (b) 的按按钮文案点击，而不是给桥代码写字段映射；条件 3（范围批准）仍需要，但现在落在 (a)/(b) 的选择上。注：RULINGS 第五节原文把 (b) 写成「总控远程控制节点会话」，Chen 已直令纠正——总控无可点的东西，(b) 是陈 PC 上的点卡代理，总控只是请求方。 |

### 1.2 结论（第三次改写）

**桥侧已通：读卡＋批卡接口存在，评论卡可读可批，走 director_override 路径。**

- 桥侧已通：三台 POC 桥（8787/8788/8789，分别对 node-3/node-1/node-2）本来就有 `GET /v1/muse/approvals` 和 `POST /v1/muse/approvals/{id}/approve`。评论卡能被读到（action="Post a GitHub issue comment"，extraction_status=partial）；之前"0 卡"是因为缺 parameters/effects 等 push 卡专有字段 → 被判 partial → 批准被 `incomplete approval read` 拒绝。Chen 在 shim 里加了 5 行：`director_override:true` 时由桥自动补 `snapshot_sha256` / `decision_binding` / `fingerprint`（由 expected 算出），其余校验一条不减（指纹必须一致、卡片变化即拒绝、每卡只允许一次尝试、audit 独占文件）。实测：`{"ok":true,"status":"approved"}`，评论真实发出（Issue #23，comment 6881839124，探针用，已请总控删除）。补丁在三台桥上都已生效，备份 `muse-openai-shim.mjs.director-binding-backup`。
- 「桥侧无解」作废：上一版按 d13d044 第五节「无服务端审批接口」推出桥侧无解，是把两层混了——d13d044 探的是 Muse 产品服务端接口（不存在）；而桥是本地 shim，有自己的读卡／批卡接口（存在）。真正卡住的是桥自身的校验（partial 卡被 `incomplete approval read` 拒绝），Chen 的 director_override 补丁已通。
- 「唯一路径是 DOM 点击」作废：DOM 点击（代理）不再是唯一路径；桥 API 是正路。
- 剩余约束：partial 卡必须由总控读 body_text 后判断（不能只看 action）；每卡一次尝试；审计文件为独占写入，失败不可重试。
- 与 R18 的关系：点卡者仍是总控（总控调桥的 approve 接口批卡），本方案符合 R18，不需要改规则。节点自己点卡仍撞 R18（(a) 不变）。

### 1.3 评论卡字段级证据（已实测确认）

来源：总控 2026-11-15 02:05 实测（Issue #23 评论 6881939525；验收见 Issue #23 评论 6882009564）。本路径走桥 API（`GET /v1/muse/approvals` 返回 JSON），**DOM 选择器不适用——验收 1 的"选择器"由以下 API 字段清单替代**。桥接口记录见 RULINGS 第六节（c543e56）；partial 卡必读 body_text 原文见 R18 流程补（1268ba7）。

| 字段 | 值 |
|---|---|
| approval_id | derived-a7292c1af01a1bbb1459b3306e24cdcc50c72844ce35f3508b278dbc1c5d52f7 |
| fingerprint | b9246dc4c1185214e084ab94a89d53a060c6ce0cf63b7ca3101a4d3eb0e3835c |
| action | Post a GitHub issue comment |
| extraction_status | partial |
| field_states | parameters / effects / permissions / creation_scope 均 missing |
| structured_fields | action；account=xy3293；repository_owner=xy3293；repository=muse-hub；issue=23；content=评论正文（见 snapshot.body_text） |
| snapshot.body_text（原文，照 Issue #23 评论 6881939525 抄） | 【3号】点卡通路验证：本评论由总控读卡、按 R18 范围判断、经桥点批后发出，用于验证评论卡（partial）审批路径。 |
| buttons | 允许／拒绝 |
| status | pending |

说明：snapshot.body_text 即该卡要发的评论正文（structured_fields 的 content）。总控批卡前读 body_text 原文核验，确认正文符合 R8／任务范围后才调 approve。

---

## 2. 两条路径：规则冲突点与前置条件

### (a) 节点自点

- **做法**：节点在自己的会话里点卡的「允许」按钮。驱动本身无点按钮的代码（4601058 §1.2 已验证），需补点按钮的能力；但这一步是次要的，主要障碍在规则。
- **规则冲突点**：与 R18 直接冲突。R18：「点卡永远不行：不点、不绕、不重新定义」。节点点自己的审批卡，正是这条禁的动作。
- **前置条件**：
  1. Chen 改 R18（按 R12，规则由 Chen 改）。这是规则变更，不是技术工作；在 R18 改之前，(a) 不可用。
  2. 节点会话内具备定位并点击「允许」按钮的能力（按按钮文案点；卡内按钮文案已由探针确认：允许／拒绝）。
  3. 点批前仍须做 R18 五项范围检查（4601058 §3.4 的思路可沿用），且点批后核对执行结果（§3.5）。

### (b) 桥 director_override 路径（第三次修订：正路）

- **做法**：总控调桥的 `POST /v1/muse/approvals/{id}/approve`（带 `director_override:true`），桥自动补 `snapshot_sha256` / `decision_binding` / `fingerprint` 后批卡。桥在陈的 PC 上（8787/8788/8789），补丁已生效。第二次修订的「陈 PC 上的点卡代理」不再是独立路径——桥本身就是陈 PC 上那个能点的东西，director_override 是它的批卡接口；总控通过桥 API 批卡。
- **规则冲突点**：无冲突。点卡者仍是总控——总控做 R18 五项范围检查后调 approve 接口，是总控在履行审批职责；节点不点自己的卡。**本方案符合 R18，不需要改规则。**
- **前置条件**：
  1. 总控读卡：调 `GET /v1/muse/approvals` 读到待批卡；partial 卡（extraction_status=partial）必须由总控读 body_text 后判断（不能只看 action 是否为 "Post a GitHub issue comment"，须看正文内容是否符合 R8／任务范围）。
  2. 总控做 R18 五项范围检查（§3.4 思路沿用）。
  3. 调 approve 时带 `director_override:true`；桥自动补三字段，其余校验一条不减（指纹必须一致、卡片变化即拒绝、每卡只允许一次尝试、audit 独占文件）。
  4. 批后核对执行结果（评论是否出现在目标 Issue；探针示范：Issue #23 comment 6881839124 已发出）。
- **约束**：partial 卡必须由总控读 body_text 后判断；每卡一次尝试；审计文件为独占写入，失败不可重试。
- **风险**：director_override 是总控的越权开关（自动补三字段），须只用于 partial 卡且只由总控调用；若被滥用（用它绕过校验），等于绕过指纹／变化检查。须把每次 director_override 调用记进可核日志（卡 id＋body_text 摘要＋时间＋结果），供事后核。

---

## 3. 成本判断（第三次修订）

第二次修订的成本判断（维护陈 PC 上的点卡代理＋总控到代理的协调通道）**作废**——桥 API 已通，不再需要另设代理。修正后：

- **桥即代理**：三台 POC 桥在陈的 PC 上，director_override 补丁已生效；总控调桥 API 批卡，无需另开通道、无需跨网暴露 CDP。
- **剩余成本**：总控每次批 partial 卡须读 body_text 做判断（人工判断成本）；director_override 调用须记可核日志；桥的补丁（5 行＋备份 `muse-openai-shim.mjs.director-binding-backup`）须随桥维护。
- **风险转移**：风险从「代理登录态泄露」转到「director_override 被滥用」——若有人用它绕过指纹／变化检查，即绕过 R18 的范围核查。须以日志＋只总控可用约束。

---

## 4. 4601058 哪些内容作废、哪些保留

**第三次修订注**：下表按第一次修订（桥侧无解）写。第三次修订后：§3.2/§3.3 的桥代码改动仍不采用，但原因变了——不是"无接口可接"，而是 Chen 已用 shim 补丁（director_override，5 行）通了桥，我原设计的「改 approval_reader.py 加卡种分支、listApprovals()」不是实际走的路；§2.4 协调捕获（DOM 抓卡）作废——桥 API 直接读卡（extraction_status=partial），无需 DOM 捕获。

| 4601058 内容 | 处置 | 原因 |
|---|---|---|
| §3.2 桥接口改动（approval_reader.py 加卡种分支、listApprovals()） | **作废** | 无服务端审批接口可接（探针②）。 |
| §3.3 director_approve.py 改动（按 kind 分派、点卡内批准按钮） | **作废**（作为桥代码改动） | 同上。思路可转用于 (b)：总控（请求方）点批前仍须分派与范围检查，但点批动作由陈 PC 上的代理执行，不在桥代码里，也不在总控手里。 |
| 结论「有条件可行（三条件）」 | **作废** | 路径本身错了（见 §1.2）。改为 (a)/(b) 两条路径。 |
| §1.2 驱动只给布尔值、无点按钮代码 | 保留 | 仍是事实；且说明 (a) 需补点按钮能力。 |
| §2.1 同容器同 UI | 保留 | 探针①印证。 |
| §2.3 字段级形态未验证 | **已实测确认** | 评论卡字段证据见 §1.3（总控 2026-11-15 02:05 实测，Issue #23 评论 6881939525）：approval_id、fingerprint、action、extraction_status=partial、field_states、structured_fields、snapshot.body_text 原文、buttons、status 均已写入。路径走桥 API（GET 返回 JSON），DOM 选择器不适用，验收 1 的"选择器"由 API 字段清单替代。 |
| §3.4 五项范围检查（R18 平移） | 保留（改途） | 作为点批前的决策检查，(a)/(b) 都用得上；落点从桥代码改到点批主体（节点或总控）。 |
| §3.5 批后核对、一次一卡、防重放、超时 | 保留 | 探针③示范了核对做法（blob 回读）；一次一卡与防重放仍是点批时的必要约束。 |
| §2.4 协调捕获方案（effect-dom-capture-001） | 改途 | 不再为桥代码写字段映射；改为为 (b) 确认评论卡的按钮文案与字段（若走 (b) 且要批评论卡）。本回合仍不触发（未批 (b)，不制造新卡）。 |

---

## 5. 副作用账本

| effect_id | 类型 | 状态 | 依据 |
|---|---|---|---|
| effect-t021-revision-push-001 | GitHub 推送本修订稿 | `intent_recorded` → 推送后核验改 `confirmed` | 远端 HEAD 与远端文件读回为准 |
| effect-dom-capture-001 | add_issue_comment DOM 捕获（一次） | `not_started`（改途，见 §4） | 本回合不触发 |

**本回合新审批卡：0 张。** 只读文件（RULINGS 第五节、4601058 稿）＋ shell git push；未点任何卡、未碰凭据、未改 RULES/RULINGS、未改任务书。

## 6. 扩展后总控仍批不了的卡种（残留缺口）

> 不回避：以下卡种即使走 director_override 路径，总控仍批不了（或必须拒绝）。每条标注是"实测"（有直接证据）还是"推断"（由规则／机制推出，未直接实测）。

| # | 批不了的卡 | 原因 | 实测／推断 |
|---|---|---|---|
| 1 | add_issue_comment 之外的其他工具层卡（如 shell 执行、其他写操作、浏览器操作、支付／购买类） | 本扩展只开 add_issue_comment 一个口子（R18 流程补 1268ba7：首批只开 add_issue_comment）。其余工具层卡不在 allowlist，director_override 也不覆盖；每新增一种须单独评估字段、范围检查与授权（R17）。 | 推断 |
| 2 | extraction 完全失败、拿不到 snapshot 的卡 | 批卡须凭 fingerprint（由 snapshot 算出）核对；extraction 完全失败即无 snapshot、无 fingerprint 可核，无法确认卡片身份与内容，只能拒绝（fail closed）。 | 推断 |
| 3 | 内容截断、无法完整核验的推送卡 | R18 要求变更集完整可识别；只显示通用 `git push`、无可识别变更集的卡必须拒绝。驱动 dumpDom 截断 HTML 至 20000 字符（4601058 §1.2），若截断后变更集无法完整核验，只能拒绝。 | 推断（R18 规则与驱动截断为代码证据；"截断到无法核验"这一具体情形未单独实测） |
| 4 | 分类失败的卡（UNCLASSIFIED：字段缺失、无法识别卡种） | 4601058 §3.2 兜底：分类失败不进入决策队列，不自动批，等人工处理。 | 推断 |
| 5 | 不在当前桥接会话里的卡（其他会话／设备上的审批卡） | 桥只读所挂的浏览器会话（8787/8788/8789 各对一个节点）；其他会话的卡桥读不到，无法批。 | 推断 |
| 6 | 登录失效时的任何卡 | 无会话即无卡可读；先恢复登录（上游 muse_status 判定，见 T-017 §3）。 | 推断 |
| 7 | 排队超时掉的卡（多卡并发、后到的卡等前卡决出期间超时） | 一次一卡串行；超时按 APPROVAL_EXPIRED 处理（约 270 秒），不自动重试同一动作；回退 R7 总控代发。 | 推断（270 秒超时本身为实测，见 T-020） |
| 8 | 批后执行失败的卡（获批但评论未落地） | 批卡 ≠ 落地；须批后核对（评论是否出现在目标 Issue）。若获批后未落地，不重复点批，改走 R7 代发／人工处理。 | 推断 |

## 来源

- 探针记录：`RULINGS/2026-11-15-card-mechanics-field-record.md` 第五节（commit d13d044）
- 被修订稿：`results/node-1/T-021-director-card-coverage-design.md`（commit 4601058）
- 任务书：`tasks/T-021-node1-director-card-coverage.md`（v1，未改）
- 规则：RULES.md R18（点卡永远不行）、R17（授权来自 Chen）、R12（规则由 Chen 改）
- 第二次修订依据：Chen 直令（2026-11-15 01:26，主聊）——(b) 不成立，节点是云端 VM、无浏览器，卡在陈的 PC 上，总控无可点的东西

---

[node-1] T-021 修订版：桥侧已通，评论卡走 director_override 路径，点卡者仍是总控，符合 R18，不需改规则；本回合新卡 0 张。
