# muse-hub 发布基线（release-manifest）

节点验收时对照本文件，不是只比“本地两文件 SHA 相同”。

## 批准基线

- 批准 commit SHA：`6cbeb9de300e661a51cda1387e85d200379b9613`（阶段二F 修复提交）
- 发布记录 commit：本文件所在的提交（见 `git log --oneline -1 -- release-manifest.md`）；批准 commit 与发布记录 commit 的 `hooks/patrol.sh` 内容相同（SHA-256 一致，已核对）。
- `hooks/patrol.sh` SHA-256：`f5795685b88e44f06fe806e94c0192a2598b978830ec8052d78edc8cfb2245a3`（按 `git show 6cbeb9d:hooks/patrol.sh` 的字节算）
- `PATROL_VERSION`：`2026-11-11.3`
- seen 文件格式：`task_id@vN`，每行一个，例如 `T-003@v1`
- 迁移失败计数文件：`$STATE_DIR/muse-hub-migration-failures`（内容一个数字；第 3 次连续失败 wake，原因 `seen-migration-failed-3x`）
- pending 记录：`$STATE_DIR/pending/<event_id>.json`，event_id 为稳定键 `task_id@vN@head_sha`
- 锁文件：`$STATE_DIR/muse-hub.patrol.lock`（flock）
- 诊断日志：`$STATE_DIR/logs/api-diagnostics.jsonl`，超 5MB 轮转，当前文件 + 3 个归档约 20MB 上限
- wake 载荷格式：`tasks` 为对象数组，例如 `[{"task_id":"T-003","version":"v1","legacy":false}]`，另带稳定 `event_id`
- 任务书版本行格式：单独一行 `版本：vN`（无列表前缀、无加粗、无 HTML 注释），在任务书前 15 行内；4 本任务书与模板均已按此格式写好

## 回滚组合

- last-good 脚本：commit `715076e` 的 `hooks/patrol.sh`，`PATROL_VERSION="2026-11-11.2"`，SHA-256 `9259a961f2e335113617744d9fb13a12c86decbb05b1019c65811241c2cef0b5`
- 对应 seen 格式：`task_id@vN`（与新版相同，回滚不需要转换 seen 文件）
- 备份时点：`2026-11-11T10:52:35Z`（修复提交时间，UTC）
- 回滚步骤（每号在自己号里做，5 分钟内）：
  1. 先确认 pending 已排空：跑一遍新版脚本（它会 replay 投递），或确认 `$STATE_DIR/pending/` 为空。旧版脚本不读 pending，未排空就回滚会丢投递。
  2. 停 Hook。
  3. `cp ~/hooks/scripts/patrol-muse-hub.sh.last-good ~/hooks/scripts/patrol-muse-hub.sh`（last-good 必须是 715076e 版，核对 `PATROL_VERSION="2026-11-11.2"`）。
  4. `hooks.dry_run` 通过后再 `hooks.enable`。
- 注意：回滚到 2026-11-11.2 版会丢掉迁移容错（空行/CRLF）与迁移失败升级（3 次 wake），回滚后 seen 文件里若有空行会再次迁移失败；回滚前先确认 seen 文件无空行、无 CRLF。

## 已解决（本批之前挂着的）

- 任务书版本行格式：4 本任务书与模板已改成严格行 `版本：v1`，不再判 malformed-version。
- 2D 的 D1（迁移 awk 容错）与 D2（迁移失败计数与 3 次唤醒）已在本批实现。

## 已知限制

- `director-watch-poll.sh` 未动；本基线只覆盖 `hooks/patrol.sh` 与任务书版本行格式。
- 巡逻脚本里加了一行 `export LC_ALL=C.UTF-8`（全角冒号正则需 UTF-8 区域环境）；节点升级消息里要提醒各号确认该行生效。
