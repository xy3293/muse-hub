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
| §2.3 字段级形态未验证 | 已补 | 探针①给出按钮文案与五个字段（推送卡）。评论卡字段仍需一次实测确认，但结构已知。 |
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

## 来源

- 探针记录：`RULINGS/2026-11-15-card-mechanics-field-record.md` 第五节（commit d13d044）
- 被修订稿：`results/node-1/T-021-director-card-coverage-design.md`（commit 4601058）
- 任务书：`tasks/T-021-node1-director-card-coverage.md`（v1，未改）
- 规则：RULES.md R18（点卡永远不行）、R17（授权来自 Chen）、R12（规则由 Chen 改）
- 第二次修订依据：Chen 直令（2026-11-15 01:26，主聊）——(b) 不成立，节点是云端 VM、无浏览器，卡在陈的 PC 上，总控无可点的东西

---

[node-1] T-021 修订版：按 CDP 探针重写结论——桥侧无解，唯一技术路径是 DOM 级点击，(a) 节点自点撞 R18、(b) 总控 CDP 远程控制需授权＋通路；本回合新审批卡 0 张。
