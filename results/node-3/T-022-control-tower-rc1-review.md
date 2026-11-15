# T-022：Control Tower Stage 1 合同 1.1.0-rc.1 独立审查（node-3）

- 审查对象：任务书 `tasks/T-022-control-tower-rc1-review-node3.md`（v1）附件一 OpenAPI 1.1.0-rc.1 全文 + 附件二架构决策书 v1.1-rc.1 全文。
- 审查方法：YAML 抽出后机器解析（路径/操作/安全方案/全部 36 个 schema 逐个核对），关键语义逐条读原文；行号以任务书文件为准（附件一 YAML 起于任务书第 35 行）。
- 审查边界：只依据任务书所附文本。v1.1 原文、T-006/T-007 原文、审计原始记录不在材料内，凡结论依赖它们的，均以「文本内一致性」为限标注；需外部事实的标「需总控核实」，不猜。

## 结论

**PASS（附冻结前条件）。**

合同文本层面未发现使 rc 不可冻结的实质冲突：17 操作 / 13 路径经解析核实与两文件所称一致；七维状态模型自洽，归一化优先顺序在决策书 §2.1 给出且无循环；单租户 Tower API Key 方案在合同层完整；C01–C12 在文本内逐项闭环。冻结签收前必须处理下列 F1–F3 三项（均为规范完整性问题，不推翻 rc 的结构结论），并按决策书 §6 完成 D 项取证与另两方核查。

## 逐项审查表

| # | 审查项 | 结论 | 依据摘要 |
|---|---|---|---|
| 1 | 状态模型自洽性与归一化 | 通过（附 F1/F3） | 七维正交（Task，任务书 543–563 行附近）；五类真实场景逐一可表达（见下）；优先顺序在决策书 §2.1：冲突→unverified、完整验收→accepted、当前修订 REJECT→rejected、BOARD 完成而证据不足→unverified、NEEDS_ATTENTION→needs_attention、其余按 parked/resuming/checkpointed→delivered→BOARD 待验收/进行中/待领/失败推导、缺失或矛盾→unknown。顺序无循环、无互相覆盖漏洞 |
| 2 | 权限与安全边界 | 通过 | towerKey 为 header apiKey（`X-CT-Access-Key`），17 操作中 16 个要求、仅 /healthz 免验（逐操作核实）；签发（运维侧 systemd credential 加载、常数时间比较）、轮换/失效（替换后重启或热加载使旧钥失效，责任在总控，决策书 §1）、浏览器侧仅会话内存持有、GitHub PAT 与 VM 凭据明确不下发浏览器；全部写操作校验精确 Origin、缺失即拒、无 CORS、无 cookie；Error 体不回显路径/凭据/堆栈；白名单算法（规范化、fd 打开、禁未知 symlink、按任务 ID 校验）可执行，精确绝对路径待 VM 核实（O26，部署子门禁自带阻断）；SQLite 仅存 notes/todos 与刷新元信息、WAL、备份责任在总控，频率/留存明确留待总控定 |
| 3 | 过度设计（对照 CH-01–CH-17） | 通过（附建议） | N01–N20 在决策书 §5 逐项标注 NEW 并给出来源，YAML 另有 x-new-design-origins；未发现把新增冒充原文要求的情况。可议的超前量集中在 Event 子结构（见非阻塞建议），且均以 nullable/保留 null 限定了成本，不构成冻结障碍 |
| 4 | 可实现性抽查（Task、Event、ReceiptEvidence、Runtime、RefreshResult） | 有条件通过（F1–F3） | 五个 schema 结构完整、required 与 nullable 配合一致、additionalProperties:false 与 CH-17 变更纪律自洽；问题集中在派生语义与未验证枚举的「在 YAML 内不可见」，见阻塞清单 |
| 5 | 审计闭环 C01–C12 | 文本内闭环（附需总控核实项） | 逐项见下表 |

### 审查项 1 的场景核对（任务书点名五类）

- **BOARD 滞后**：七维并列、互不覆盖；derived 按证据链推导，BOARD 显示「待领」时仍可由完整证据得出 accepted（决策书 §2.1、§6 用例）。
- **Issue OPEN**：issue_state 仅作关联事实，「Issue state never determines completion」（Task description），§6 用例「Issue OPEN 但 ACK/收据齐→accepted」与合同一致。
- **远端未交付**：DeliveryEvidence 以远端提交可读为唯一交付标准；`not_delivered`（已确认不存在）与 `unverified`（无证据）在决策书 §2.1 明确区分——本地声称已推而远端未见的情形不会被误记为已交付。
- **收据 REJECT**：verdict REJECT → 当前修订 derived=rejected；REJECT 明确不等价于 FAIL；BOARD「拒收」无匹配拒收证据时不推定验收 REJECT。
- **证据冲突**：source_conflicts[] 结构化记录（dimension/sources/reason/evidence_refs），验收置 unverified，明确禁用「最近 PASS 自动覆盖」。

### 审查项 5：C01–C12 闭环表

| 项 | 闭环位置 | 判断 |
|---|---|---|
| C01/C02 | YAML paths（解析实测 13 路径 / 17 操作，node_id、task_id 参数在位）；决策书 §3 操作清单 | 文本内已修复（v1.1 §10 原文不在材料内，以两文件互相一致为准） |
| C03/C04 | Task 七维 + SourceConflict；决策书 §2.1 | 已修复 |
| C05/C06 | DeliveryEvidence / ReceiptEvidence（1:N，含 T-004 两份 `5d71eee6`、`fa4cee5` 并列保留、superseded 须显式证据）/ AckEvidence；决策书 §2.1 完整验收规则 | 已修复 |
| C07 | Event 全家（state/kind/review/delivery/approval/main_ack/retry/signals/timestamps），未知值保留 null，last_error_historical 与当前状态分离 | 已修复（枚举定版见 F2） |
| C08 | Runtime 双 PatrolSide（节点侧 300 秒 / 总控侧 60 秒，独立来源与观测时间，历史值明令不得作当前值） | 已修复 |
| C09 | 决策书 §1（SQLite 边界、WAL、备份责任） | 已修复，但备份频率/留存为总控待定参数——**需总控核实**其运维验收安排 |
| C10/C11 | NotePatch/TodoPatch 明示 last-write-wins 且不承诺 409；POST /refresh 定义 409 REFRESH_IN_PROGRESS 与 RefreshResult 语义一致 | 已修复 |
| C12 | 决策书 §6 冻结门槛与签收流程（本审查即其一环） | 流程已立；三方核查是否齐备——**需总控核实**（Codex、Antigravity 两方状态不在材料内） |

D1–D10 按决策书 §4 仍受证据约束（D4 不得猜、D5 需重查、D9 SHA 不猜），未被文本强行封闭，与「不猜」纪律一致；其取证结果**需总控核实**。

## 阻塞问题清单（冻结阻塞项：不处理不得签收冻结；不推翻 rc 本身）

**F1 — derived_status 的归一化规则只存在于决策书散文，YAML 内不完整。**
位置：附件一 `Task`（任务书第 543–563 行附近，description 仅给出 accepted 的成立条件）；完整优先顺序在附件二 §2.1。
问题：合同的两个消费方中，Antigravity 按 §6 以 YAML 生成类型并核查页面消费，Codex 以 YAML 建 Pydantic 类型——只读 YAML 的实现方无法从 YAML 得知 derived_status 的完整推导（例如 needs_attention 与 parked 的先后、BOARD 各态到 derived 各值的映射在 YAML 内无任何指引）。派生状态是本合同的核心语义，不应只活在配套散文里。
修正建议：在 YAML 的 Task schema 增加 `x-normalization` 扩展（或等效 description 全文）写入 §2.1 的优先顺序与映射表，使 YAML 自足；决策书保留为理由说明。

**F2 — Event 家族未验证枚举在 YAML 内不可见，消费方会当作已定版。**
位置：附件一 `Event.kind`（任务书第 662 行附近，无枚举）、`EventDelivery.status` / `EventApproval.status`（第 618、627 行附近，自由字符串）、`AckEvidence.ack_method`（第 527 行附近，自由字符串）、`Event.state` 五值中 REJECTED/SUPERSEDED/CLOSED_INTERNAL 三值。
问题：决策书 §2.2 明确上述枚举「未证实」、三值「未经独立验证」，但 YAML 里没有任何标注，Event description 只含糊提及「kind and several subfield enums not verified」。按 D 项纪律这些值不得靠猜封闭，冻结前只有两条合规路径：取证定版，或在 YAML 内逐字段显式标注 unverified 并冻结「保留 null/原值」的消费规则。
修正建议：二选一并落字到 YAML 字段级（x-verified: false 或 description 标注），不要只留在决策书。

**F3 — Task.event_status 与 Event.state 类型不一致。**
位置：附件一 `Task.event_status`（任务书第 577 行附近，`type: string, nullable: true`，无枚举）与 `Event.state`（五值枚举）。
问题：决策书 §2.1 规定 event_status 取「最后可靠事件状态」，即其值域应是 Event.state 的值域；YAML 却一处枚举、一处自由字符串，前端无法按枚举穷举渲染，后端也无法校验。
修正建议：统一为同一枚举（抽成共享 schema 引用），或在 Task.event_status 的 description 明示其为原始字符串透传及理由。

## 非阻塞建议

1. `ReceiptEvidence.status`（任务书第 491 行附近）枚举只有 REVIEWED 一个值且 nullable：要么该字段恒为 REVIEWED 属冗余，要么存在未列出的收据状态（如解析失败/待审）。建议冻结前说明其语义，或删除该字段。
2. `Runtime` 的 description 把带日期的观测值（「director observed 60s … on 2026-11-15」）写进合同正文；PatrolSide 的结构本身是「观测值」设计、没有问题，但合同 description 里的 dated 观测会随时间变成误导。建议把观测实例移入示例，description 只留规则。
3. `SourceMeta.current_error_code`（任务书第 422 行附近）为自由字符串，而同合同 `Error.code` 是 8 值枚举；建议 current_error_code 引用同一枚举，避免两套错误词表漂移。
4. listNotes / listTodos 的 GET 未定义 503，而 x-response-policy 的 503 表述是全域的。本地 SQLite 源不可用时的状态码（500 还是 503）建议在合同里写明一句，消除实现分歧。
5. `Overview` 同时内嵌完整 Runtime 与完整 Event 数组，与 /runtime、/events 的响应重复度高；Stage 1 数据量下可接受，若任务/事件量增长，recent_events 建议改为摘要形态。此项仅提示，不要求本版处理。
6. `ReceiptCheck.evidence` 为自由文本，仅靠 description 写「Sanitized」约束；脱敏是本合同多处依赖的机制（Error、健康日志同理），建议在决策书补一句脱敏的执行方式（如统一的出站过滤函数）作为实现验收点。
7. YAML 的 x-new-design-origins 未覆盖 N19/N20（仅决策书 §5 有），追溯索引两文件不完全对称，建议补齐。

## 过程说明（与任务书默认流程的两处偏差，均按 Chen 在主聊的直接指令）

- 任务书交付节要求不发 Issue 评论；本任务按 Chen 2026-11-15 主聊直令，在 Issue #24 发了一条认领/开工进度评论（comment 6889654085），未发其他评论。
- 同一直令要求认领后将 BOARD 的 T-022 状态由「待领」改为「进行中」，该改动随本报告同批推送（单次推送内含两文件）；BOARD 其余行未动。
