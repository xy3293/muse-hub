# T-036 独立代码复核报告 (Antigravity Review)

复核日期：2026-11-16
复核方：Antigravity (独立复核)
总体结论：**PASS**

---

## 1. 复核范围与文件核对

复核目标为修复 `/home/hatch/hooks/scripts/director-watch-poll.sh` 中旧消息缓存淘汰后重复首次唤醒问题（方案②）。

| 文件 | 路径 | SHA256 校验和 |
| --- | --- | --- |
| 审查脚本（修改后） | `/home/hatch/hooks/scripts/director-watch-poll.sh` | `06668486757c049f37e2e026652264a038bbaf06d5e994d2984c21030e659ff0` |
| 基准脚本（修改前） | `/home/hatch/workspace/muse-hub-tests/T-036/director-watch-poll.before.sh` | `8e4a733e84edf2bf41f3a9bf9ce7f1a24fa7e4fca1d666a05ab82a0141ab9085` |
| 备份脚本 | `/home/hatch/hooks/scripts/director-watch-poll.sh.last-good-20261116-T036` | `8e4a733e84edf2bf41f3a9bf9ce7f1a24fa7e4fca1d666a05ab82a0141ab9085` |

---

## 2. 差异与代码逻辑分析

经 `diff -u` 独立比对，本次修改严格限定在 node-3、node-1、node-2 三个节点的消息处理分支，无多余修改：

1. **node-3 分支（第 551–556 行）**：
   将 `add_wake` 从 `if [[ ! -f "$event_file" ]]` 块之后移入块内，放在 `atomic_write "$event_file" "$event_json"` 之后。
2. **node-1 分支（第 634–639 行）**：
   同样将 `add_wake` 移入 `if [[ ! -f "$event_file" ]]` 块内，在原子写入新事件文件后调用。
3. **node-2 分支（第 717–722 行）**：
   同样将 `add_wake` 移入 `if [[ ! -f "$event_file" ]]` 块内，在原子写入新事件文件后调用。
4. **缓存更新保留**：
   三个分支中的 `nodeX_watch_updated="$(... .seen_msg_hashes = ...)"` 均完整保留在 `if` 块外部，确保历史消息即使未触发唤醒，仍正常参与窗口滑动维护。
5. **行为核实**：
   - **旧消息去重**：当旧消息因超出 50 个 hash 上限被 `seen_msg_hashes` 淘汰后，重新扫描时因 `$event_file` 已存在，跳过新建事件并跳过 `add_wake`，成功阻止重复唤醒。
   - **新消息首次唤醒**：新消息到达时 `$event_file` 不存在，执行原子写入并正常调用 `add_wake`。
   - **到期提醒不受影响**：事件重试与到期提醒由独立的重试扫描循环处理，未在本次修改路径中，提醒机制完全保留。

---

## 3. 独立命令执行结果

所有命令均由 Antigravity 独立执行，验证结果如下：

### 3.1 语法检查
- **命令**：`bash -n /home/hatch/hooks/scripts/director-watch-poll.sh`
- **结果**：退出码 `0`，无任何语法错误输出。

### 3.2 完整场景验证
- **命令**：`python3 /home/hatch/workspace/muse-hub-tests/T-036/verify_poll.py`
- **结果**：退出码 `0`，6 个测试用例全部 **PASS**。
- **最新证据目录**：`/home/hatch/workspace/muse-hub-tests/T-036/run-20261115T224101010234Z`

用例明细：
1. `baseline-reproduces` (基准复现)：
   - 退出码 0，修改前脚本在 50 个缓存淘汰后输出了 5 个旧消息首次唤醒（`is_reminder: false`），精确复现故障。
2. `old-messages-dry-run` (修改后旧消息 dry-run)：
   - 退出码 0，决策为 `silent`，原因 `no-change`，唤醒数 `0`，状态文件无任何变更。
3. `old-messages-default-path-dry-run` (默认路径 dry-run)：
   - 退出码 0，在未显式传递 `MUSE_HUB_STATE_DIR` 时，正确使用测试 HOME 下默认状态目录，决策 `silent`，唤醒数 `0`。
4. `new-messages-dry-run` (新消息 dry-run)：
   - 退出码 0，三节点各新增 1 条消息，精确输出 3 个新消息唤醒（`is_reminder: false`），无旧消息混入。
5. `due-retry-still-reminds` (到期重试提醒)：
   - 退出码 0，到达重试时间的旧事件精确触发 1 个到期提醒唤醒（`is_reminder: true`，reason: `muse-hub-activity-reminder`）。
6. `new-messages-persist-and-repeat` (实际落盘与二次重轮询)：
   - 退出码 0，首轮落盘后触发 3 个唤醒；紧随其后的第二轮轮询即使 hash 淘汰，因事件落盘而输出 `silent / no-change`，唤醒数 `0`，事件文件内容不变。

---

## 4. 生产环境配置与依赖路径核查

1. **默认 STATE_DIR**：
   - 脚本第 16 行：`STATE_DIR="${MUSE_HUB_STATE_DIR:-$HOME/hooks/state/muse-hub}"`，生产默认路径保持不变。
   - 真实路径存在性核实：`/home/hatch/hooks/state/muse-hub` 实际存在且包含 events、receipts 等结构。
2. **相对 Ledger Adapter 与 TMP 路径**：
   - 脚本第 17 行：`S3_ADAPTER="$SCRIPT_DIR/../ledger/adapter.py"` -> `/home/hatch/hooks/ledger/adapter.py` 实际存在。
   - 脚本第 18 行：`export TMPDIR="$SCRIPT_DIR/../tmp"` -> `/home/hatch/hooks/tmp` 实际存在。

---

## 5. 发现与边界说明

1. **修改范围纯粹性**：
   本次改动完全符合方案②要求，未调整通用 `add_wake`、未修改审批卡/平台投递/重试扫描逻辑，未改动 hook 调度配置或生产状态。
2. **去重边界**：
   方案②以 `$EVENTS_DIR` 下的持久化事件文件为长期去重依据。如果未来事件文件被外部运维操作清理，且对应消息已从 50 个内存 hash 中移出，重新轮询会再次视为新消息。在正常运行（事件保留）前提下，去重安全可靠。

---

## 6. 最终审定结论

**VERDICT: PASS**
脚本修改正确，完全达到预期目标，无阻断性问题。
