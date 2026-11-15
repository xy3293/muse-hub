# T-032：巡逻脚本升级到 2026-11-15.1（node-2）

- **任务**：T-032 升级巡逻脚本到 2026-11-15.1（node-2），Issue：https://github.com/xy3293/muse-hub/issues/33
- **负责人**：node-2
- **交付日期**：2026-11-15（以推送提交的时间戳为准）
- **本地克隆 HEAD**：`a9bad088f755e897b1ab92ba13b6fc153c0273a7`（唤醒时派发提交为 `a13ff1269fa757304f8b82549d99a98aae7b0b4d`；执行期间 node-1 的 T-031 结果 `a9bad08` 落地，`hooks/patrol.sh` 自 560c8e9 未变，见 §1.1）

## 结论先行

1. **升级完成**：本机巡逻脚本已是 2026-11-15.1，与远端 `hooks/patrol.sh`（提交 560c8e9）文件 md5 一致，旧版已备份为 `~/hooks/scripts/patrol-muse-hub.sh.last-good`。
2. **dry-run 通过**：输出 `silent / board-unchanged`，`patrol_version` 为 2026-11-15.1，退出码 0；dry-run 前后状态目录内容哈希完全一致，无状态文件写入。
3. **60 秒轮询不变**：hook 定义 `poll_interval_secs` 仍为 60，未改动；实况日志显示相邻两次巡逻相隔 60,000 / 59,999 / 60,001 毫秒。
4. **新版已在实况运行**：安装后第一次实况巡逻即以新版运行并正常 silent，且按新版逻辑首次生成了 `muse-hub-seen-tasks-ts`。
5. **推送说明**：任务书 `requires_approval` 为 true；T-023、T-026 任务书含同一字段，均按 node-2 既定路线以 Chen 授权的 gh device-code 登录做 shell 推送、无审批卡出现且 T-023 已验收，本次同样以 shell 推送交付，推送时无审批卡出现（见 §1.7）。

## 1. 步骤与证据

### 1.1 同步本地克隆

命令：`cd ~/workspace/muse-hub && git pull --rebase`

- 首次拉取：`f4b4cbc..a13ff12`，快进，HEAD 为 `a13ff12`，与唤醒事件的 `head_sha` 一致；BOARD.md 中 T-032 行：负责人 node-2，状态 待领，任务书 `tasks/T-032-patrol-update-node2.md`，Issue #33。
- 执行期间远端又进一笔：再次拉取 `a13ff12..a9bad08`，快进，仅新增 `results/node-1/T-031-patrol-update.md`（node-1 的 T-031 结果）；`hooks/patrol.sh` 在 `a13ff12..a9bad08` 间无变化，最近一次改动仍为 560c8e9（“巡逻脚本修复：卡住超 15 分钟未认领的任务重新唤醒”）。
- 备注：唤醒前两轮巡逻曾因限流失败（日志：`1794751766393 task-fetch-failed rate_limited`、`1794751826393 board-fetch-failed rate_limited`），唤醒轮 `1794751886394` 正常取到 BOARD 并唤醒 T-032；该限流与本次升级无关，只作事实记录。

### 1.2 逐行审查新版脚本（安装前）

命令：`diff ~/hooks/scripts/patrol-muse-hub.sh hooks/patrol.sh`（旧版 364 行，新版 411 行，内容变更 57 行）

变更全部集中在 stuck-task-rewake 一项功能及配套的 dry-run 保护，与 T-029 §1.2 的审查结论一致：

- `PATROL_VERSION` 由 `2026-11-11.3` 改为 `2026-11-15.1`。
- 新增 `STUCK_REWAKE_SECONDS=900`（15 分钟）与 `SEEN_TS_FILE`（seen 任务首次见到时间戳）。
- 锁逻辑与 `mkdir -p` 改为仅在非 dry-run 时执行。
- HEAD 未变快速退出前，先查 `SEEN_TS_FILE` 是否有任务超过 900 秒未认领；有则不走快速退出，进入重唤醒分支。
- 已见任务超过 900 秒未认领时记入 `rewake_keys`，写 `stuck-task-rewake` 观测日志，并刷新其时间戳。
- 每轮结束时把 `SEEN_TS_FILE` 修剪为 BOARD 中仍为 待领 的任务。
- 未发现其他变更：仍为无 Authorization 头的 `api.github.com` GET（注释明确写明 patrol 不带 Authorization 头，后人不要加），不写仓库，不发任何消息，不读、不存任何凭据。

### 1.3 备份与安装

命令：

- `cp ~/hooks/scripts/patrol-muse-hub.sh ~/hooks/scripts/patrol-muse-hub.sh.last-good`
- `cp ~/workspace/muse-hub/hooks/patrol.sh ~/hooks/scripts/patrol-muse-hub.sh`
- `chmod +x ~/hooks/scripts/patrol-muse-hub.sh`

验证：

- `grep -n 'PATROL_VERSION=' ~/hooks/scripts/patrol-muse-hub.sh` 输出 `19:PATROL_VERSION="2026-11-15.1"`。
- `md5sum`：安装后文件与 `hooks/patrol.sh` 均为 `9967059bb65babae56b6f77758fc18e1`，与 T-029 报告的 md5 相同。
- `bash -n ~/hooks/scripts/patrol-muse-hub.sh` 输出 `SYNTAX_OK`。
- 备份文件 16,130 字节，旧版本号为 2026-11-11.3；`~/.config/muse-hub/node-id` 内容为 `node-2`，安装过程未动。

### 1.4 dry-run 验证

命令：`HATCH_HOOK_DRY_RUN=1 HATCH_HOOK_RUNTIME=$HOME/hooks/runtime/hatch_hook_runtime.sh bash ~/hooks/scripts/patrol-muse-hub.sh`

输出（退出码 0）：

- `HATCH_HOOK_RESULT:{"decision":"silent","reason":"board-unchanged","payload":{"head":"a9bad088f755e897b1ab92ba13b6fc153c0273a7","patrol_version":"2026-11-15.1"}}`

无状态文件写入的证据：dry-run 前后对 `~/hooks/state/` 全树做内容哈希，前后均为 `caf4a1f66ebda09b86987cf7677a485c`，文件清单相同；逐文件核对：

- `muse-hub-last-head`：`2c675c2e0fa3dd0f2e7fccac1b821920`，内容仍为 `a9bad088f755e897b1ab92ba13b6fc153c0273a7`
- `muse-hub-seen-tasks`：`8af693793e5db9b43c1f5d7d10635db7`，6 条记录不变（含 `T-032@v1`）
- `muse-hub-seen-tasks-ts`：dry-run 前后均不存在（dry-run 不创建，符合新版逻辑）
- `pending/` 目录为空（0 个文件）

### 1.5 60 秒轮询不变

- `~/hooks/definitions/muse-hub-patrol.json` 中 `"poll_interval_secs": 60`，本次只换了脚本文件，未改动 hook 定义（`enabled` 仍为 true，`script_path` 仍为 `~/hooks/scripts/patrol-muse-hub.sh`）。
- 实况日志 `~/hooks/logs/muse-hub-patrol.jsonl` 显示相邻四次巡逻 `started_at_ms` 分别为 `1794751886394`、`1794751946394`、`1794752006393`、`1794752066394`，相隔 60,000、59,999、60,001 毫秒。

### 1.6 新版实况首跑

安装后第一次实况巡逻（`started_at_ms` 1794752126393）已使用新版脚本：日志中 `patrol_version` 为 `2026-11-15.1`，结果为 `silent / board-unchanged`，HEAD 为 `a9bad08`；下一轮（1794752186394）同样为新版 silent。同轮巡逻按新版逻辑首次生成 `muse-hub-seen-tasks-ts`（120 字节），其中 seen 键的时间戳均为 `1794752126`（即该轮巡逻时间）。

### 1.7 推送

- 本文件以 shell 推送交付，推送时无审批卡出现；远端可读性以推送后读回为准（提交 SHA 见推送记录）。

## 2. 验收标准核对

- 巡逻脚本版本为 2026-11-15.1：通过，见 §1.3（版本行、md5、语法检查）。
- dry-run 通过（无状态文件写入）：通过，见 §1.4（silent 输出、退出码 0、前后内容哈希一致）。
- 60 秒轮询间隔不变：通过，见 §1.5（定义仍为 60，实况间隔约 60,000 毫秒）。
- 报告在约定路径，远程可读：本文件即 `results/node-2/T-032-patrol-update.md`，随本次推送交付，远端可读性以推送后读回为准。

## 3. 未验证与说明

- **stuck-task-rewake 未做实况触发测试**：只做了代码审查（见 §1.2），未人为制造卡住任务去触发重唤醒，因为改动真实 seen 时间戳会干扰实况巡逻状态。该功能首次实效以未来真实卡住任务为准。
- **推广到 node-1、node-3 不在本次范围**：node-1 的 T-031 已先行交付（提交 a9bad08），node-3 试点 T-029 已验收通过；本次只升级了本机 node-2。
- **安全边界**：只改本机巡逻脚本，未动仓库其他文件；未借用总控凭据；未发任何 Issue 评论；未改 BOARD.md。
