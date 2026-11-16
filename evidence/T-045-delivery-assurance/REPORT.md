# T-045：Hook / 巡逻唤醒投递保障

## 借的是什么模式、为什么不换库

借用 Svix 的投递保障模式：持久化投递状态机、指数退避、以现有 `event_id` 幂等去重，以及失败耗尽后的死信可见性。实现放在现有 Hook 脚本内，继续由现有巡逻调度驱动，不引入 Svix 服务、不换仓库总线，也不新增第三方依赖。我们的目标是唤醒 agent；现有 Hook runtime 的 `wake()` 只输出 `HATCH_HOOK_RESULT` 后退出，并不返回平台或 agent 的到达回执。因此 `delivered` 仅表示本地 runtime 交接成功，不能用来证明平台已送达或业务已处理；MUSE-ACK 继续沿用原流程。

死信选用本地 `$MUSE_HUB_STATE_DIR/dead-letter.jsonl`（默认 `~/hooks/state/muse-hub/dead-letter.jsonl`）：与投递状态放在同一现有 state 目录，追加可审计，不让巡逻为了记死信去提交仓库。日报使用只读汇总入口列出过去 24h 的死信数及 event_id。

## 实现与配置

- `hooks/delivery-assurance.py`：仅 Python 标准库，复用现有 Python、Bash、jq；`delivery-state.jsonl` 只追加并 flush/fsync，独立 `.delivery.lock` 串行入队及交接，避免与 poll 的 `.lock` 重入。
- poll 的 `add_wake` 在推进游标/评论索引前持久入队；wrapper 读取队列，轮询为 silent、API 故障或脚本健康告警去重时仍检查到期投递。退避只存下一次时间，由原有巡逻驱动，不在生产进程里 sleep。
- 默认**共尝试 3 次**（首次 + 2 次重试），失败后分别等待 60、120 秒；实际尝试发生在到期后的下一轮巡逻。`MUSE_DELIVERY_MAX_ATTEMPTS` 可设 1–20，`MUSE_DELIVERY_BASE_SECONDS` 默认 60，`MUSE_DELIVERY_TIMEOUT_SECONDS` 默认 10。次数和退避基数在入队时保存，不因重启或重复入队重置。
- 幂等沿用 `event_id`。首次投递使用 `initial` 槽，已有业务提醒使用 `reminder:<retry.wakes>`，转人工提示使用 `transition`；同一槽已投递/正在处理/已死信时只记 `skipped-duplicate`，不重复处理。原本下一代业务提醒继续正常交接，传输重试不修改业务预算或事件文件。
- 异常退出、超时、缺少/无效 runtime 结果都记 failed；超时杀掉 runtime 子进程组。进程中断留下 attempting 时，下轮记录 interrupted failure 后按剩余次数续投。先落死信、再写 dead，补终态时按 `(event_id, slot)` 去重死信。
- `dead-letter-summary.sh` 只读输出过去 24h 死信数和 event_id；现有 `bridge-watchdog-summary.sh` 末尾调用该入口。不存在死信文件时输出 0；不为汇总创建 state。

## 备份、语法与本机同步

修改前已先复制：

```text
/home/hatch/hooks/scripts/director-watch-poll.sh.last-good
/home/hatch/hooks/scripts/director-watch-poll.sh.last-good-T045
SHA256: 4cb2ac74a5f6845eff71b408953f27ff7c1afce67e2b7f97c0ba15b5910ad375
```

wrapper、日报入口另存各自 `.last-good-T045`。仓库原先只有 `hooks/patrol.sh`，此次把已安装 poll/wrapper/日报脚本纳入 `hooks/` 后局部修改；与原始本机基线的差异见同目录三个 `.diff`，poll 仅增加 helper 路径和 `add_wake` 入队。

以下均退出 0：

```bash
for name in director-watch-poll.sh director-watch-wrapper.sh dead-letter-summary.sh bridge-watchdog-summary.sh; do
  bash -n "hooks/$name" || exit 1
  bash -n "/home/hatch/hooks/scripts/$name" || exit 1
done
python3 evidence/T-045-delivery-assurance/verify.py
```

已先安装 helper 和汇总依赖，再原子替换 wrapper，最后原子替换 poll；本机 `~/hooks/scripts/` 与仓库逐字节一致。默认 state 仍为 `~/hooks/state/muse-hub`；已验证显式覆盖及临时 HOME 默认路径，确认生产 `../ledger/adapter.py` 和 `../tmp` 存在。

| 文件 | 安装后 SHA256 | 与仓库 |
| --- | --- | --- |
| `director-watch-poll.sh` | `32127479ceec22ae42a3f52cba65adb86e28c1fa4c2ab7215c257ea7e0901505` | 一致 |
| `director-watch-wrapper.sh` | `221358a8111fc6fab9ab07be30ec566e1bc5d1c47110ac4086ebbd52fbe1b71e` | 一致 |
| `delivery-assurance.py` | `8c063f67440801db3a023d31de13bab8727c7dfae1942537d40422a58831056d` | 一致 |
| `dead-letter-summary.sh` | `291ad9109b4b2feb2545831bd21dbe80de67ca3d0051371dae6dc4670ba8de88` | 一致 |
| `bridge-watchdog-summary.sh` | `39641d45cc3b994e1a3dabc482ddc412f72696fa0b6bc59f176b1b7d318084cb` | 一致 |

生产汇总入口只读检查输出 `唤醒投递(过去24h): 死信 0 条; event_id: (无)`；失败演练全部使用隔离 HOME/state，没有向生产队列注入测试事件。

## 人为失败验收：PASS

时间：`2026-11-16T10:57:43.032451+00:00`。完整可重跑脚本见 `verify.py`，运行记录见 `verification.txt` 和 `summary.json`，**12/12 场景通过**。测试夹具使用临时目录和离线 git/curl，runtime 的 wake 被替换为返回 23 的函数；恢复测试使用实际 runtime 原始实现并捕获 stdout，不交给平台。

测试参数仅在夹具里缩短为总尝试 3 次、退避基数 1 秒；不修改生产默认值。测试 event_id：`issue:43:T045-injected-failure:2026-11-16`。

### 1. 重试发生且呈退避

完整日志：`failure-log.json`。每次均捕获失败摘要：

```text
attempt 1: delivery failed (1 events): runtime exit 23: injected delivery failure
attempt 2: delivery failed (1 events): runtime exit 23: injected delivery failure
attempt 3: delivery failed (1 events): runtime exit 23: injected delivery failure
```

三次 attempting 的实际间隔：**1.178 秒、2.166 秒**（排定间隔为 1、2 秒，另含 wrapper 启动开销）。首次失败后立即再巡逻，确认未到期不增加 attempt；delivered/dead 再入队也不会重新交接。

### 2. 状态完整推进

原始只追加日志：`failure-state.jsonl`；以下仅投影验收相关字段：

```jsonl
{"at": "2026-11-16T10:57:25.903Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "queued", "attempt": 0}
{"at": "2026-11-16T10:57:26.071Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "attempting", "attempt": 1, "error": null}
{"at": "2026-11-16T10:57:26.074Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "failed", "attempt": 1, "retry_delay_seconds": 1.0, "error": "runtime exit 23: injected delivery failure"}
{"at": "2026-11-16T10:57:27.249Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "attempting", "attempt": 2, "retry_delay_seconds": 1.0, "error": null}
{"at": "2026-11-16T10:57:27.253Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "failed", "attempt": 2, "retry_delay_seconds": 2.0, "error": "runtime exit 23: injected delivery failure"}
{"at": "2026-11-16T10:57:29.415Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "attempting", "attempt": 3, "retry_delay_seconds": 2.0, "error": null}
{"at": "2026-11-16T10:57:29.418Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "failed", "attempt": 3, "retry_delay_seconds": 4.0, "error": "runtime exit 23: injected delivery failure"}
{"at": "2026-11-16T10:57:29.418Z", "event_id": "issue:43:T045-injected-failure:2026-11-16", "state": "dead", "attempt": 3, "retry_delay_seconds": 4.0, "error": "runtime exit 23: injected delivery failure"}
```

可见 `queued → attempting → failed → attempting → failed → attempting → failed → dead`，尝试计数 1、2、3，各次包含时间和错误摘要。

### 3. 死信出现

`dead-letter.jsonl` 原始片段（演练副本；运行时实际位置在所选 state 下）：

```jsonl
{"event_id":"issue:43:T045-injected-failure:2026-11-16","slot":"initial","attempt":3,"reason":"muse-hub-activity","event":{"event_id":"issue:43:T045-injected-failure:2026-11-16","kind":"issue_signal","is_reminder":false,"is_transition":false},"context":{},"max_attempts":3,"base_seconds":1.0,"next_attempt_at_epoch":1794826653.4186609,"state":"dead","action":"attempts-exhausted","at":"2026-11-16T10:57:29.418Z","error":"runtime exit 23: injected delivery failure","retry_delay_seconds":4.0}
```

### 4. 日报可见

只读入口 `bash hooks/dead-letter-summary.sh`，设置演练 state 后输出（`daily-summary.txt`）：

```text
唤醒投递(过去24h): 死信 1 条; event_id: issue:43:T045-injected-failure:2026-11-16
```

既有日报入口集成输出（离线桥响应；`daily-full.txt`）：

```text
桥与看门狗(过去24h): alert 0 条, recover 0 条; 最长未恢复 0 分钟; 当前: node-3: ok/已登录, node-1: ok/已登录, node-2: ok/已登录
唤醒投递(过去24h): 死信 1 条; event_id: issue:43:T045-injected-failure:2026-11-16
```

另已覆盖：成功后去重、并发 enqueue/drain、保留不同代次提醒、超时/无效回包后恢复、attempting 中断恢复、脚本健康告警失败续投、dry-run 零状态写入、默认路径与覆盖路径、日报排除 24h 前及未来记录、完整 poll→入队→下一 silent 轮询仍交接；事件文件哈希保持不变。

## 独立复核与边界

Antigravity 基于内嵌完整 helper/wrapper/日报代码、poll 差异及当时 10 项验证结果，完成**只读代码复核：PASS**。原始输出见 `antigravity-review.md`；该复核没有独立执行测试，随后补充的两项验证只改测试夹具，最终 Codex 自测为上述 12 项。

本次保障止于本地 Hook/runtime 交接。现有平台没有到达回执：平台吞掉/延迟唤醒但本地已成功输出时，无法据此自动判 failed/dead；`delivered` 不表示 agent 已启动或处理完成。输出后、delivered 持久化前若被强杀，下轮可能再次交接，不能宣称下游 exactly-once。未改事件格式、event_id、MUSE-ACK、RULES、总线或巡逻频率；未新增服务/依赖，未碰 Chen 的 PC、ACL 或 Tailscale。总控终验仍按原任务流程进行。
