# muse-hub 发布基线（release-manifest）

节点验收时对照本文件，不是只比“本地两文件 SHA 相同”。

## 批准基线

- 批准 commit SHA：`715076e706feba490337ce363233e08b2b392b64`（阶段二E 修复提交）
- 发布记录 commit：本文件所在的提交（见 `git log --oneline -1 -- release-manifest.md`）；批准 commit 与发布记录 commit 的 `hooks/patrol.sh` 内容相同（SHA-256 一致，已核对）。
- `hooks/patrol.sh` SHA-256：`9259a961f2e335113617744d9fb13a12c86decbb05b1019c65811241c2cef0b5`（按 `git show 715076e:hooks/patrol.sh` 的字节算）
- `PATROL_VERSION`：`2026-11-11.2`
- seen 文件格式：`task_id@vN`，每行一个，例如 `T-003@v1`
- pending 记录：`$STATE_DIR/pending/<event_id>.json`，event_id 为稳定键 `task_id@vN@head_sha`
- 锁文件：`$STATE_DIR/muse-hub.patrol.lock`（flock）
- 诊断日志：`$STATE_DIR/logs/api-diagnostics.jsonl`，超 5MB 轮转，当前文件 + 3 个归档约 20MB 上限
- wake 载荷格式变化：`tasks` 已改为对象数组，例如 `[{"task_id":"T-003","version":"v1","legacy":false}]`，另带稳定 `event_id`

## 回滚组合

- last-good 脚本：commit `0b011af` 的 `hooks/patrol.sh`，`PATROL_VERSION="2026-11-11.1"`，SHA-256 `e382cf1bc44ad2726cd50ac6b5caffb45868e6f785954505200e2b4b6bb8a847`
- 对应 seen 格式：`task_id@vN`（与新版相同，回滚不需要转换 seen 文件）
- 备份时点：`2026-11-11T10:35:54Z`（本文件写入时，UTC）
- 回滚步骤（每号在自己号里做，5 分钟内）：
  1. 先确认 pending 已排空：跑一遍新版脚本（它会 replay 投递），或确认 `$STATE_DIR/pending/` 为空。旧版脚本不读 pending，未排空就回滚会丢投递。
  2. 停 Hook。
  3. `cp ~/hooks/scripts/patrol-muse-hub.sh.last-good ~/hooks/scripts/patrol-muse-hub.sh`（last-good 必须是 0b011af 版，核对 `PATROL_VERSION="2026-11-11.1"`）。
  4. `hooks.dry_run` 通过后再 `hooks.enable`。

## 已知限制（验收前必读）

- 现有 4 本任务书的版本行是 `- **版本**：v1 <!-- 版本：v1 -->`，行首不是 `版本`，**不匹配**新版严格解析（只扫前 15 行严格行 `^版本[:：][[:space:]]*v[0-9]+$`）。按新版解析器，这 4 本任务书都会被判为 `malformed-version`，本轮不唤醒、不写 seen/pending。这是任务书数据格式问题，不是脚本 bug；修任务书格式是下一批的事，节点升级前总控会先修。
- 2D 的 D1（迁移 awk 容错：空行/CRLF）与 D2（迁移失败计数与 3 次唤醒）本批未做，仍挂着；迁移代码保持 2C 原样。
- 本基线只覆盖 `hooks/patrol.sh`。`director-watch-poll.sh` 未动。
