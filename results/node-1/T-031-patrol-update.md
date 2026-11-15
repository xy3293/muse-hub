# T-031：巡逻脚本升级到 2026-11-15.1（node-1）

- **任务**：T-031 升级巡逻脚本到 2026-11-15.1（node-1），Issue：https://github.com/xy3293/muse-hub/issues/32
- **负责人**：node-1
- **交付日期**：2026-11-15（以推送提交的时间戳为准）
- **本地克隆 HEAD**：`a13ff1269fa757304f8b82549d99a98aae7b0b4d`（任务派发提交，`git pull --ff-only` 已同步）

## 结论先行

1. **升级完成**：本机巡逻脚本已是 2026-11-15.1，与远端 `hooks/patrol.sh`（提交 560c8e9）文件 md5 一致，旧版已备份为 `~/hooks/scripts/patrol-muse-hub.sh.last-good`。
2. **dry-run 通过**：输出 `silent / board-unchanged`，`patrol_version` 为 2026-11-15.1，退出码 0；dry-run 前后状态文件 md5 完全一致，`pending/` 仍为空，未生成 `muse-hub-seen-tasks-ts`，无状态文件写入。
3. **60 秒轮询不变**：hook 定义 `poll_interval_secs` 仍为 60，未改动；实况日志显示相邻两次巡逻 `started_at_ms` 相隔 59,992 毫秒与 60,000 毫秒。
4. **新版已在实况运行**：安装后第一次实况巡逻（invocation `38e2488f-776f-4651-b66d-341ee22e95d1`）即以新版运行并正常 silent，且按新版逻辑首次生成了 `muse-hub-seen-tasks-ts`（18 条记录，时间戳均为 `1794751820`）。

## 1. 步骤与证据

### 1.1 同步本地克隆

命令：`cd ~/workspace/muse-hub && git pull --ff-only`

- 拉取成功，HEAD 为 `a13ff12`，与任务派发提交（事件 `T-031@v1@a13ff1269fa757304f8b82549d99a98aae7b0b4d`）一致。
- BOARD.md 中 T-031 行：负责人 node-1，状态 待领，任务书 `tasks/T-031-patrol-update-node1.md`，Issue #32。

### 1.2 逐行审查新版脚本（安装前）

命令：`diff ~/hooks/scripts/patrol-muse-hub.sh hooks/patrol.sh`（旧版 364 行，新版 411 行）

变更全部集中在 stuck-task-rewake 一项功能及配套的 dry-run 保护，与 T-029 试点报告所述一致：

- `PATROL_VERSION` 由 `2026-11-11.3` 改为 `2026-11-15.1`。
- 新增 `STUCK_REWAKE_SECONDS=900`（15 分钟）与 `SEEN_TS_FILE`（seen 任务首次见到时间戳）。
- 锁逻辑改为仅在非 dry-run 时执行。
- HEAD 未变快速退出前，先查 `SEEN_TS_FILE` 是否有任务超过 900 秒未认领；有则不走快速退出，进入重唤醒分支。
- 已见任务超过 900 秒未认领时记入 `rewake_keys`，写 `stuck-task-rewake` 观测日志，并刷新其时间戳。
- 每轮结束时把 `SEEN_TS_FILE` 修剪为 BOARD 中仍为 待领 的任务。
- 未发现其他变更：唯一出现的 `Authorization` 是注释“patrol 不带 Authorization 头，后人不要加”；全文无 credential / token / password / secret 的读取或使用，不写仓库，不发任何消息。

远端一致性：`git show 560c8e9:hooks/patrol.sh | md5sum` 与本地 `hooks/patrol.sh` 均为 `9967059bb65babae56b6f77758fc18e1`；提交 560c8e9 标题为“巡逻脚本修复：卡住超 15 分钟未认领的任务重新唤醒”。

### 1.3 备份与安装

命令：

- `cp ~/hooks/scripts/patrol-muse-hub.sh ~/hooks/scripts/patrol-muse-hub.sh.last-good`
- `cp ~/workspace/muse-hub/hooks/patrol.sh ~/hooks/scripts/patrol-muse-hub.sh`
- `chmod +x ~/hooks/scripts/patrol-muse-hub.sh`

验证：

- `grep -n 'PATROL_VERSION=' ~/hooks/scripts/patrol-muse-hub.sh` 输出 `19:PATROL_VERSION="2026-11-15.1"`。
- `md5sum`：安装后文件与 `hooks/patrol.sh` 均为 `9967059bb65babae56b6f77758fc18e1`。
- `bash -n ~/hooks/scripts/patrol-muse-hub.sh` 输出 `SYNTAX_OK`。
- 备份文件 16,130 字节，旧版本号为 2026-11-11.3；`~/.config/muse-hub/node-id` 内容为 `node-1`，安装过程未动。

### 1.4 dry-run 验证

命令：`HATCH_HOOK_DRY_RUN=1 HATCH_HOOK_RUNTIME=$HOME/hooks/runtime/hatch_hook_runtime.sh bash ~/hooks/scripts/patrol-muse-hub.sh`

输出（退出码 0）：

- `HATCH_HOOK_RESULT:{"decision":"silent","reason":"board-unchanged","payload":{"head":"a13ff1269fa757304f8b82549d99a98aae7b0b4d","patrol_version":"2026-11-15.1"}}`

无状态文件写入的证据：dry-run 前后逐文件核对 md5 均不变：

- `muse-hub-last-head`：`610c3da64cba189b9b224205c439a019`（内容 `a13ff1269fa757304f8b82549d99a98aae7b0b4d`）
- `muse-hub-seen-tasks`：`59256495cb962127f8d639b71920ac70`（18 条记录，含 `T-031@v1`）
- `muse-hub-migration-failures`：`897316929176464ebc9ad085f31e7284`
- `pending/` 目录为空（0 个文件）；`muse-hub-seen-tasks-ts` 在 dry-run 后仍不存在

### 1.5 60 秒轮询不变

- `~/hooks/definitions/muse-hub-patrol.json` 中 `"poll_interval_secs": 60`，本次只换了脚本文件，未改动 hook 定义（`enabled` 仍为 true，`script_path` 仍为 `~/hooks/scripts/patrol-muse-hub.sh`）。
- 实况日志 `~/hooks/logs/muse-hub-patrol.jsonl` 显示相邻三次巡逻 `started_at_ms` 分别为 `1794751699991`、`1794751759983`、`1794751819983`，间隔分别为 59,992 毫秒与 60,000 毫秒。

### 1.6 新版实况首跑

安装后第一次实况巡逻（invocation `38e2488f-776f-4651-b66d-341ee22e95d1`，`started_at_ms` 为 `1794751819983`）已使用新版脚本：日志中 `patrol_version` 为 `2026-11-15.1`，结果为 `silent / board-unchanged`。同轮巡逻按新版逻辑首次生成 `muse-hub-seen-tasks-ts`，其中 18 个 seen 键的时间戳均为 `1794751820`（即该轮巡逻时间）。

## 2. 验收标准核对

- 巡逻脚本版本为 2026-11-15.1：通过，见 §1.3（版本行、md5、语法检查）。
- dry-run 通过（无状态文件写入）：通过，见 §1.4（silent 输出、退出码 0、状态文件 md5 不变）。
- 60 秒轮询间隔不变：通过，见 §1.5（定义仍为 60，实况间隔约 60,000 毫秒）。
- 报告在约定路径，远程可读：本文件即 `results/node-1/T-031-patrol-update.md`，随本次推送交付，远端可读性以推送后读回为准。

## 3. 未验证与说明

- **stuck-task-rewake 未做实况触发测试**：只做了代码审查（见 §1.2），未人为制造卡住任务去触发重唤醒，因为改动真实 seen 时间戳会干扰实况巡逻状态。该功能首次实效以未来真实卡住任务为准。
- **安全边界**：只改本机巡逻脚本，未动仓库其他文件；未借用总控凭据；未发任何 Issue 评论；未改 BOARD.md。
