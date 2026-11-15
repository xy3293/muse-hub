# T-036：修轮询去重——旧消息重复唤醒

任务日期：2026-11-16。执行：Codex；独立复核：Antigravity。验收结论：**PASS**。

## 修改

本机文件：`/home/hatch/hooks/scripts/director-watch-poll.sh`。

采用方案②：node-3、node-1、node-2 三个消息分支的 `add_wake` 均移入 `if [[ ! -f "$event_file" ]]`，放在事件原子落盘之后。修改后的行号分别为 554–556、637–639、720–722；完整差异见 `director-watch-poll.diff`。

故障原因：`seen_msg_hashes` 只保留 50 个 hash；此外 `unique` 会按字典序排序，并非严格按最近收到顺序保留。旧 hash 不在缓存时，原代码虽不重建事件，却无条件调用 `add_wake`。扩大窗口无法阻止已淘汰的历史消息再次唤醒，所以以持久事件文件约束首次唤醒更可靠。缓存更新仍在条件外，容量保持 50。

本次只调整消息首次唤醒判定。通用 `add_wake`、到期提醒/重试、审批卡和平台投递逻辑均无修改。

备份：`/home/hatch/hooks/scripts/director-watch-poll.sh.last-good-20261116-T036`；交付目录另有 `director-watch-poll.before.sh`。

## 验证

命令：

```sh
bash -n /home/hatch/hooks/scripts/director-watch-poll.sh
python3 /home/hatch/workspace/muse-hub-tests/T-036/verify_poll.py
```

`bash -n`：退出码 0。完整脚本隔离验证：6 个场景全部 PASS。

| 场景 | 结果 |
| --- | --- |
| 修改前复现：50 个缓存 hash 均不含旧消息，旧事件已存在 | 错误输出 5 个首次唤醒；其中 node-1 对应 T-021/T-025/T-028，另覆盖 node-2/node-3 |
| 修改后旧消息 dry-run | `silent / no-change`，0 个唤醒，状态文件内容不变 |
| 不设 `MUSE_HUB_STATE_DIR` 的默认目录 dry-run | `silent / no-change`，0 个唤醒，默认落在测试 HOME 下 `hooks/state/muse-hub` |
| 三节点各新增一条消息 dry-run | 恰好 3 个首次唤醒，无旧消息混入，状态内容不变 |
| 旧事件 DETECTED 且已到重试时间 | 恰好 1 个 `is_reminder: true`，保留原有提醒行为 |
| 隔离状态中实际落盘后再次轮询 | 第一轮恰好 3 个首次唤醒；第二轮 `silent / no-change`，事件文件内容不变 |

使用完整脚本与真实 ledger adapter；仅通过 PATH 替身提供离线 GitHub/桥响应并拦截 git fetch，避免真实投递和仓库 refs 变更。覆盖 ACKED、NEEDS_ATTENTION、DETECTED（未到期及到期）、CLOSED_INTERNAL、SUPERSEDED 旧事件。dry-run 校验对比整个隔离状态目录的文件内容 hash。原始 stdout/stderr、fixture、汇总由 `latest-run.txt` 指向。

静态检查见 `static-checks.json`：生产默认 `STATE_DIR` 仍为 `$HOME/hooks/state/muse-hub`；生产相对路径 `../ledger/adapter.py`、`../tmp` 存在。环境变量覆盖路径与默认路径均已实跑。

验证边界：这是隔离状态/离线响应下的完整轮询验证，不是线上桥端到端验证。保留的事件文件是方案②的去重依据；事件文件若被另行删除，之后该消息可能重新作为首次发现处理。合法到期提醒仍按原机制执行。

## 范围与交付

未推送生产仓库；未修改 BOARD/Issue；未修改 `alerts/` 审计文件；未修改 wrapper、Hook 配置或启停服务。脚本已在本地修改，正式启用由总控处理。

## Antigravity 独立复核

**PASS**，未发现阻断问题。完整独立审查结论见 `antigravity-review.md`，任务书见 `antigravity-brief.md`。

Antigravity 已独立对比源码、执行 `bash -n` 并重跑上述 6 个场景，全部通过。独立验证证据目录：`run-20261115T224101010234Z/`。Codex 首轮验证证据目录：`run-20261115T223737244022Z/`。

所审脚本 SHA256：`06668486757c049f37e2e026652264a038bbaf06d5e994d2984c21030e659ff0`。复核期间仅向当前 CLI 会话授予必要工具/目录权限以完成无交互检查，未修改全局配置；前期权限不足的尝试未被计为复核通过。
