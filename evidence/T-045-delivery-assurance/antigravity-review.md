# T-045 代码复核意见书

**复核方**：Antigravity
**复核对象**：T-045 Hook / 巡逻唤醒投递保障（Svix 模式落地）
**复核结论**：**PASS**

---

### 一、逐项检查结果

#### 1. 持久状态机（State Machine）
- **实现符合规范**：状态完整覆盖 `queued` → `attempting` → `delivered` / `failed` / `dead`。
- **持久化可靠性**：所有状态变更均写入 `delivery-state.jsonl`，采用 `flush()` + `os.fsync()`，保证进程崩溃或异常退出时持久化日志不丢失；只追加（append-only），具备可审计性。

#### 2. 非阻塞指数退避（Non-blocking Exponential Backoff）
- **退避算法正确**：失败重试间隔按 `base_seconds * 2 ** (attempt - 1)` 计算（默认 60s、120s）。
- **调度非阻塞**：计算得到 `next_attempt_at_epoch` 后直接记录状态并返回（退出码 3），巡逻器可平滑转入 `silent`，不会在进程内使用 `sleep` 挂起阻塞后续轮询，退避到期时在后续巡逻批次被自然拉起。

#### 3. event_id 幂等（Idempotency）
- **幂等键设计**：以 `(event_id, slot)` 为复合键。
- **重复入队防护**：遇到已在状态机中的条目记录 `skipped-duplicate`；已处于 `delivered` 或 `dead` 的条目绝不触发二次唤醒，同时允许 wrapper 在第二阶段安全地补充 `head`/`count` 上下文字段而不破坏既有重试计数。

#### 4. 既有业务提醒代次（Reminder Generations / Slots）
- **分槽设计完备**：引入 `slot` 机制（`initial` / `transition` / `reminder:<generation>`）。
- **预算兼容**：对 `is_reminder: true` 的事件，直接从本地 `$STATE/events/*.json` 索引既有的 `retry.wakes` 代次，既防止了首次投递的去重逻辑误吞到期提醒，又确保了网络/运行时传输级重试不消耗业务提醒的代次预算。

#### 5. 死信清单与日报可见性（Dead-letter & Daily Summary）
- **终态收敛**：达到最大尝试次数（默认 3 次）后，原子转入 `dead` 终态，并追加写入 `$MUSE_HUB_STATE_DIR/dead-letter.jsonl`。
- **日报集成**：`dead-letter-summary.sh` 为只读查询（无状态写入，文件缺失时优雅输出 0），并已在 `bridge-watchdog-summary.sh` 末尾挂接，保证每日 14:10 日报自动呈现过去 24h 死信数及对应 `event_id` 列表。

#### 6. runtime exit() 处理与子进程隔离
- **环境隔离**：平台 `HATCH_HOOK_RUNTIME` 的 `wake()` 函数会在输出 `HATCH_HOOK_RESULT` 后调用 `exit 0`。Python 侧通过 `subprocess.Popen(..., start_new_session=True)` 独立子进程组执行 runtime，主进程捕获返回码与 stdout 校验决策后才推进状态机至 `delivered`。
- **防悬挂保证**：超时（默认 10s）通过 `os.killpg(process.pid, signal.SIGKILL)` 强杀整个子进程组，杜绝孤儿子进程残留。

#### 7. 并发保护与崩溃恢复（Concurrency & Crash Recovery）
- **锁分层明确**：投递状态机使用独立的 `$STATE/.delivery.lock`，与轮询器主锁 `$STATE/.lock` 保持单向顺序（先 `.lock` 后 `.delivery.lock`），不存在死锁路径；多实例并发 `drain` / `enqueue` 被严格序列化。
- **自愈恢复能力**：若进程在 `attempting` 期间被意外中断（如 SIGKILL、断电），下次巡逻 `drain` 拿到锁时，判定旧进程已死，自动将残留的 `attempting` 修正为 `failed`（`interrupted runtime handoff; recovered on next patrol`），保留已消耗的 attempt 次数并按指数退避排期，不会发生无限重试或状态卡死。

---

### 二、边界与语义确认

- **delivered 语义边界**：复核确认代码严格遵守约定，`delivered` 仅代表本地 runtime stdout 成功输出 `HATCH_HOOK_RESULT` 并完成父子进程交接，不代表远程平台或 downstream agent 已经确认到达或处理完毕。
- **最小改动约束**：未引入常驻守护进程，未引入第三方网络依赖，未更改事件文件格式，未改动仓库 `RULES.md`，离线验证用例 10/10 全数通过。

---

### 三、复核裁决

**PASS**，准予合入。
