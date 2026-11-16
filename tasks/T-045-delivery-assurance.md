# T-045：Hook / 巡逻唤醒的投递保障（借 Svix 模式）

- Issue：#43
- 执行：Codex；复核：Antigravity；验收：总控
- 工作区：muse-hub 仓库（`~/workspace/muse-hub-git/`）＋本地 Hook 脚本（`~/hooks/scripts/`，以仓库 `hooks/` 为准绳，改完同步）

## 先说清：借的是什么模式，为什么不换库

借的是 **Svix 的投递保障模式**，不是 Svix 服务本身：
1. 投递状态机：queued → attempting → delivered / failed / dead；
2. 重试与指数退避：失败按指数退避重试 N 次（建议 3 次），每次记录 attempt 时间与结果；
3. 幂等键：同一事件重复投递只处理一次（我们已有 event_id，用它当幂等键）；
4. 死信可见：超过 N 次仍失败的事件写进死信清单，并在日报里列出来。

为什么不换库（不引入 Svix 服务）：
- Svix 是一个常驻 webhook 服务，不是能嵌进来的库；引入它等于新增一个常驻服务，Chen 已明令不许。
- 我们的唤醒是"叫醒一个 agent 去干活"，不是 webhook 投递；场景不同，只能借模式，不能直接套服务。
- 所以：自己实现这四条模式，代码留在现有 Hook / 轮询脚本里，不新增服务、不新增依赖。

## 现状问题（实测过）

唤醒投递 20 分钟级延迟、不保证到达、丢唤醒无法感知。现在的核心病是"丢了没人知道"——第 4 条（死信可见）是重点。

## 要做的事

1. 在唤醒投递路径（`director-watch-poll.sh` 的 wake / 事件投递处，以及 `director-watch-wrapper.sh` 的唤醒调用处）加投递状态机：
   - 每个待投递事件（event_id）有状态：queued → attempting → delivered / failed / dead；
   - 状态持久化到本地 state（`~/hooks/state/muse-hub/` 下的新文件，例如 `delivery-state.jsonl`，只追加、可审计），不要只放内存；
   - 幂等：同一 event_id 重复投递只处理一次（查 state，已 delivered / 已在处理中则跳过并记一笔）。
2. 重试与指数退避：
   - 投递失败（目标无响应 / 超时 / 返回错误）后按指数退避重试，建议 3 次（第一次立即或短间隔，之后翻倍）；
   - 每次 attempt 记录时间、结果、错误摘要；
   - 重试上限可配（写死 3 次也可，但要写在文件头注释里，改得动）。
3. 死信清单：
   - 超过 N 次仍失败的事件进死信（状态 dead），写进死信清单（`~/hooks/state/muse-hub/dead-letter.jsonl`，或 muse-hub `evidence/dead-letter.md`——选其一，任务书里写清选了哪个、为什么）；
   - 死信清单要能在日报里列出来：给日报脚本留一个可读的汇总入口（例如一个 `dead-letter-summary.sh` 或在现有 `bridge-watchdog-summary.sh` 旁加一段），输出"过去 24h 死信数 + event_id 列表"。
4. 不改现有事件语义：event_id、事件文件格式、MUSE-ACK 流程不动；只加投递保障层。
   - 实现选用本地 `$MUSE_HUB_STATE_DIR/dead-letter.jsonl`（默认 `~/hooks/state/muse-hub/dead-letter.jsonl`），与投递 journal 同目录、只追加，避免巡逻为记录失败去提交仓库；`dead-letter-summary.sh` 提供日报只读入口，现有 `bridge-watchdog-summary.sh` 引用。
5. 保住现有备份习惯：改 `director-watch-poll.sh` 前先拷 `.last-good` 备份；`bash -n` 必须过；写完跑一次 `bash -n`。

## 验收（Codex 自己先跑，Antigravity 复核，总控终验）

人为让投递失败（例如断网、或把目标地址改成不可达、或关掉目标进程），验证四点并贴证据：
1. 重试发生（attempt 记录 ≥2 次，时间间隔呈退避）；
2. 状态推进（queued → attempting → failed → dead 全链路有记录）；
3. 死信出现（死信清单里有该 event_id）；
4. 日报可见（日报汇总入口能列出该死信）。

证据：把失败演练的日志、state 文件片段、死信清单片段、日报汇总输出贴进 `evidence/T-045-delivery-assurance/REPORT.md`，推到 muse-hub。

## 边界

- 不换仓库总线；不引入常驻新服务（Svix / 向量库 / SSO 都不许）；不改 RULES.md。
- 不碰 Chen 的 PC；不改 ACL、不动 Tailscale。
- 只做投递保障，不重构整个轮询器；改动面尽量小。
