# T-013 Pachat 群消息即时唤醒节点核实

- **结论先行：目前没有“群消息→节点即时唤醒”的链路。最接近的可行路径是现有 10 分钟查收＋GitHub 派发＋300 秒 Hook 巡逻，全链路约 5–15 分钟（不含总控反应时间，总控侧未验证）；真“秒级即时唤醒”需要给每个节点新建唤醒基础设施，6 种 wake 方式中没有一种能直接用于本机上的 Muse。**
- 核查日期：2026-11-12；核查人：node-1（Chen Muse[node-1]）。
- 任务：[T-013](https://github.com/xy3293/muse-hub/blob/main/tasks/T-013-pachat-instant-wake-verification.md)，Issue [#14](https://github.com/xy3293/muse-hub/issues/14)。
- 派发实测：总控 Pachat #7 消息 2026-11-12 14:01 UTC（总控与1号群）；GitHub 派发提交 `bf0723c`，2026-11-12 22:00:46 +0800（= 14:00:46 UTC），两者基本同时。

## 1. 群里任意消息能唤醒，还是只有 @ 某节点才唤醒？

**结论：只有 @／回复／owner 发帖能触发 wake-up；普通群消息不能。**

- 证据：官方文档 https://pachat.ai/install.md（2026-11-12 核查）第 4 节：“Wake-ups … come only when you are mentioned or replied to, or your owner posts in your group”（L221–222）；第 5 节：“With a wake-up, Pachat starts you the moment someone mentions you or replies to you”（L228–229）。
- 触发条件（原文，L221–222、L265–268）：被 mention、被 reply、owner 在群里发帖；wake-up 至多每 10 分钟一次（owner 发帖除外，立即唤醒），每天 30 次；失败重试一次；连续 3 次失败则关闭并邮件通知 owner。
- 普通消息（其他 agent 或人发的非 @ 消息）只进入 inbox 的 `unread` 计数，等下一次定时查收才被看到。本次实测：总控 #7 消息是 owner agent（总控）发帖、无 @，node-1 靠 10 分钟定时查收在 22:04:48 CST 发现，未被即时唤醒。
- 补充：inbox 判定“需要你”的字段是 `fromYourOwner`、`mentionsYou`、`repliesToYou`、`recalled`、`unread`（install.md L419–420）。

## 2. listener 是什么、前提是什么？云端 Muse 能不能用？

**结论：listener 是跑在 owner 电脑上的常驻进程，替 Pachat 在群消息到达时启动 agent；node-1 不满足前提，不能用；总控侧未验证。**

- 是什么（install.md L275–280、L278–280）：“it keeps a connection to Pachat open and runs you on that computer the moment a group needs you. It runs you for one group at a time, and each group has its own session of you”；需要 macOS 或 Linux、Node 18+、一个无需终端即可运行的 agent 命令（`codex`、`claude`）。
- 前提（L283–289、L309–314）：必须 owner 明确同意（“install it only once your owner says yes”）；无人值守运行，每次启动消耗 owner 的 plan；装为开机启动项，文件在 `~/.pachat`；每天最多启动 agent 100 次（`--max-runs` 可调低）；电脑关机或睡眠时无法唤醒，消息等电脑恢复后才处理；`~/.pachat/notes.md` 存放给 listener 启动的各次运行的指令。
- node-1 实测（2026-11-12 14:06 UTC，`listen status` 输出）：“Not set up here… Pachat's wake-ups for you are off. Runs today: 0. Groups with a session: 0.” 未安装 listener。
- 云端 Muse 能不能用：**不能直接用**。node-1 运行环境是 Linux 虚拟机 `htch-runtime`（`uname` 实测），不是 Chen 的电脑；且本机无 `muse` 命令（`command -v muse`：absent；`claude`：absent；仅 `codex` 存在于 `/opt/hatch-image/bin/codex`，Node v24.22.1）。listener 要求“跑在主人电脑上的 agent”，本节点不在 Chen 的电脑上运行，安装前提不成立。总控（Chen 总控muse）是否跑在 Chen 电脑上、能否装 listener：**未验证**（本节点无法观测总控的运行环境）。

## 3. `wake` 的 webhook／email 等方式对 Muse 是否适用？

**结论：6 种 wake 方式中，没有一种能直接唤醒本机上的 Muse；每种都缺一个前置。**

- node-1 当前状态实测（2026-11-12）：`wake` 输出 “Not set up. Kinds: grok, openclaw, claude_routine, webhook, email, listener.”；`checkin` 输出 “You check Pachat every 10 minutes.”（已按 10 分钟上报）。
- 逐种核对（install.md L243–268，表＋说明）：
| kind | 要什么前置 | 对本机 Muse 是否适用 |
|---|---|---|
| `grok` | Grok Bot routine 的 webhook URL＋key | 否。只适用于 Grok Bot routine，不适用于 Muse。 |
| `openclaw` | OpenClaw 网关 `https://<gateway>/hooks/agent`＋hooks token | 未验证。OpenClaw 里跑的 agent 能进 Pachat 群，但 Muse 账号能否接入 OpenClaw 无官方说明（T-011 已标注未验证），不得假设能直连。 |
| `claude_routine` | Claude Code routine 的 API trigger URL＋token | 否。只适用于 Claude Code routine。 |
| `webhook` | 一个收到 POST 就启动一次运行的 URL＋其期望的 `Authorization: Bearer <key>`；Pachat POST JSON（`text`、`events`、`inbox`），任意 2xx 即算已启动 | 否。本机 Muse 没有对外暴露“收到 POST 即启动运行”的 URL；平台是否提供此类触发器**未验证**、无证据。且任务书禁止编造 URL，不得凭空填写。 |
| `email` | Pachat 从 `wake@pachat.ai` 发邮件到 owner 邮箱；要求“any agent that can run when an email arrives” | 否（目前）。Pachat 能发邮件，但本侧没有任何“邮件到达即启动 Muse 运行”的机制；需新建邮件触发运行器，属未验证的新基建。 |
| `listener` | 见第 2 问 | 否，见第 2 问。 |
- 节点能不能各配一个：wake 设置是按 agent 配的（`GET/PUT /api/v1/wake` 带各 agent 自己的 token；CLI `wake set` 用本机 token）。每个节点理论上可各配一种，但**总控不能替节点配**：文档中没有总控代配他人 wake 的接口或说明，配 wake 需要该 agent 自己的 token／URL／secret；且任务书禁止使用总控或任何人的 Pachat token（R5）。此点为“文档中无此能力”的否定性结论，标注为**未验证其反面**（未找到代配接口，不等于已证明不存在）。

## 4. 每个节点是独立 Muse 账号，要即时唤醒，各需要什么？总控能不能替它们装？

**结论：每个节点各需一整套唤醒前置（自己的机器或触发端点、自己的 token、自己的额度、自己的设置）；总控不能替它们装。**

- 各需要什么（按第 3 问的表，逐节点）：
- listener 路径：该节点运行所在的机器须是 owner 的电脑（macOS/Linux、Node 18+、可无人值守运行 agent 命令）、owner 明确同意、开机启动项、该节点的 `~/.pachat/notes.md`。本节点不在 Chen 电脑上，此路不通。
- webhook 路径：该节点须有一个能接收 POST 并启动一次 Muse 运行的 URL＋secret；目前无此端点，需新建。
- email 路径：须有一个监听 owner 邮箱（wake@pachat.ai 来信）并启动该节点 Muse 运行的服务；目前无此服务，需新建。
- 无论哪条路：各节点用自己的 Pachat token（不得共用、不得用他人 token，R5）、各消耗自己的 Muse 额度／plan（listener 每次启动都消耗 owner 的 plan，install.md L283）。
- 总控能不能替它们装：**不能**。listener 要装在各节点运行的机器上并由 owner 逐个批准，总控没有这些机器的访问权；wake 设置需各 agent 自己的 token；文档无总控代装、代配的说明。node-2、node-3 各自的运行环境与 wake 状态：**未验证**（本节点无法观测）。
- node-1 现状小结：check-in 每 10 分钟（已上报 Pachat）；wake 未设置；listener 未安装；运行于 Linux VM（非 Chen 电脑）。

## 5. 最可行路径的全链路时延（逐段拆）

最可行路径（不新建基建）：群消息 → node-1 每 10 分钟查收 →（如需派发）总控读消息并在 GitHub 派发 → Hook 每 300 秒扫 BOARD → worker 启动干活。

| 段 | 时延 | 依据（2026-11-12） |
|---|---|---|
| Pachat 发现（群消息→节点看到） | 0–10 分钟，均值约 5 分钟 | node-1 check-in 每 10 分钟（`checkin` 实测）；若 wake 已配且被 @／回复：至多每 10 分钟一次，owner 发帖立即唤醒（install.md L267）。本次 T-013：总控 14:01 UTC 发帖，node-1 22:04:48 CST（14:04:48 UTC）查收发现，约 4 分钟。 |
| 总控中转（节点看到→GitHub 派发） | **未验证，无数字** | 任务书背景称“总控每小时轮询收件箱”为待核实说法，不得采信；规程 1.1 已取消“忙时半小时检查、固定值守窗口”，总控现行检查节奏无本节点可观测的证据。规程 1.1 另要求总控派发后 15 分钟安排一次远端复查（`Pachat-GitHub-工作交流与任务交付规程.md` L12）。本段是最不确定、可能最长的一段。 |
| GitHub 派发（总控写任务书＋提交） | 约 1 分钟内（总控动手后） | 本次实测：派发提交 `bf0723c` 22:00:46 +0800，与 Pachat #7 消息 14:01 UTC（22:01 CST）基本同时；`git push` 本身为秒级。 |
| Hook 巡逻（派发→worker 被唤醒） | 0–5 分钟 | Hook 每 300 秒扫 BOARD（T-006/T-009 已验证，巡逻 300 秒；RULES.md R6）。注意 T-004/T-006 曾出现 wake 后 worker 在 600 秒超时内丢失的故障模式（T-008/T-009 结论），巡逻 wake 是 fire-and-forget，无 worker 启动确认。 |
| worker 启动（唤醒→开始干活） | **未验证，无数字；上限 600 秒** | T-008/T-009 证实 worker 能启动（`worker_started_at` 非空），但启动耗时未实测；单个 execute 回合 600 秒超时边界（checkpoint-spec §10）。 |
| **合计** | **约 5–15 分钟（不含总控中转段）** | 下限：消息恰在查收前到达＋巡逻恰在派发后触发；上限：查收 10 分钟＋巡逻 5 分钟。总控中转段未验证，实际端到端可能显著长于此。 |

- 若 wake 可用（目前不可用），Pachat 发现段可缩至：owner 发帖立即、@／回复至多 10 分钟节流；其余各段不变，全链路仍受总控中转＋300 秒巡逻支配，仍为分钟级，不是秒级。
- 补充实测：本次 T-013 从总控发帖（14:01 UTC）到本 worker 开始执行任务书核查（约 14:06 UTC），约 5 分钟——其中含本轮 inbox-check 定时任务本身的启动等待；属于上述区间的下限附近，不代表最坏情况。

## 6. 最终 verdict：有条件做到

**有条件做到——但“即时”只能做到分钟级，且需满足下列条件；秒级即时唤醒目前做不到。**

- 能做到的部分（已有）：Pachat 群消息 → 10 分钟查收 → GitHub 派发 → 300 秒巡逻 → worker 干活，全链路约 5–15 分钟（不含总控反应时间）。本任务本身就是该链路跑通的一例。
- 做不到的部分（阻断点）：
1. Pachat 的 6 种 wake 方式无一种能直接唤醒本机 Muse（第 3 问表）：grok／claude_routine 是别家平台的；openclaw 接 Muse 未验证；webhook 缺可启动运行的 URL；email 缺邮件触发运行器；listener 要求跑在 Chen 电脑上，本节点不在其上。
2. 总控不能替节点装 wake／listener（第 4 问）；每节点须各自具备前置。
3. 即使 wake 配好，Pachat 侧仍有每 10 分钟一次、每天 30 次的节流；且唤醒后仍须经过总控派发（GitHub）＋300 秒巡逻，秒级不可能。
- 有条件做到的条件与成本：
1. **零新增成本路径（推荐先用）：** 保持 node-1 每 10 分钟查收（已在跑）；总控侧明确并公布检查节奏（目前未验证、规程 1.1 已取消固定值守窗口，需总控定）；接受分钟级时延。成本：每次查收跑一次 agent 回合（T-011 指出：3 节点 × 每 10 分钟查收，额度消耗在各 agent 自身套餐；一次查收的 token 量未实测）。
2. **缩短查收间隔：** `checkin set 5`（最小 5 分钟，install.md L214），发现段缩至 0–5 分钟；成本：查收回合数翻倍。是否改、改到几分钟由 Chen 定。
3. **新建 email 触发运行器：** 配 `wake set --kind email`，另建监听 owner 邮箱、收到 wake@pachat.ai 邮件即启动对应节点 Muse 运行的服务；成本：新服务＋邮箱访问授权＋可靠性验证，工作量未评估。**未验证**能否打通。
4. **listener 路径：** 仅当某节点实际跑在 Chen 的电脑上且 Chen 明确同意时才适用；本节点不适用。成本：开机启动项＋每次启动消耗 Chen 的 plan＋每天最多 100 次。
5. **webhook 路径：** 需平台提供“收到 POST 即启动运行”的 URL；目前无证据表明 Muse 提供，需向平台方核实。**未验证**。
- 建议下一步（供总控／Chen 定）：先用路径 1 跑着，实测一次 10 分钟查收的 token／额度消耗再定间隔；email／webhook 任选其一做一次打通试验前，先由总控确认 owner 邮箱触发与平台触发能力是否存在。

## 方法与来源

- 官方文档：https://pachat.ai/install.md（2026-11-12 14:05 UTC 爬取，第 4、5 节、listener 小节、“Every check-in”小节）。
- 本机实测（2026-11-12 14:06 UTC）：`node ~/.pachat/pachat.mjs inbox`（`you` 为 Chen Muse[node-1]，总控与1号 1 条未读）；`read SXE8fZGVdqIdRRTQ`（#7 为 T-013 派发）；`wake`（Not set up）；`checkin`（每 10 分钟）；`listen status`（未安装，wake-ups off）；`uname`（Linux htch-runtime）；`command -v muse/claude`（absent）、`codex`（/opt/hatch-image/bin/codex）、Node v24.22.1。
- Hub 内来源：`tasks/T-013-pachat-instant-wake-verification.md`；`Pachat-GitHub-工作交流与任务交付规程.md`（1.1 立即执行版）；`RULES.md` R6；`docs/checkpoint-spec.md`；`results/node-1/T-011-ai-agent-group-chat-comparison.md`（Pachat wake-up 种类、额度讨论、未验证项）；T-008/T-009（600 秒超时、wake fire-and-forget）。
- 未安装 listener，未改任何 wake／checkin 设置，未使用他人 token；报告与 checkpoint 均无秘密（R5）。
- 事实与推断已分开标注；“未验证”处均已写明，不得当作结论引用。

---
T-013 Pachat 群消息即时唤醒节点核实 · 2026-11-12 · 结论：有条件做到（分钟级），秒级即时唤醒目前无可用链路
