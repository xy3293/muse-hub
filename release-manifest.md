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

- 节点当前实际 last-good：无 `PATROL_VERSION` 的原始版本 `hooks/patrol.sh`，SHA-256 `7138f44b225ea03575f67fc20c7809c939efc2d516fdc76d7cf1f5748631e8c0`（总控已核对：`git show 8a9c7a9:hooks/patrol.sh` 的 SHA-256 与 node-1、node-2、node-3 上报的值一致）。注意：commit `715076e` 的 2026-11-11.2 版只在中间提交里存在过，从未分发到节点，**不是**节点的 last-good。
- 对应 seen 格式：原始脚本用 `grep -qx` 精确匹配裸 `task_id`，读不懂 `@v1` 格式；回滚后 seen 必须是迁移前的裸格式。
- 备份时点：`2026-11-11T13:37:08Z`（本次修正时间，UTC）
- 回滚步骤（每号在自己号里做，5 分钟内）：
  1. 先确认 pending 已排空：跑一遍新版脚本（它会 replay 投递），或确认 `$STATE_DIR/pending/` 为空。原始脚本不读 pending，未排空就回滚会丢投递。
  2. 停 Hook。
  3. **硬性前置，必须同时恢复 seen 到迁移前的裸格式**：`cp ~/hooks/state/muse-hub-seen-tasks.bak ~/hooks/state/muse-hub-seen-tasks`。只回滚脚本、不恢复 seen，原始脚本判重失效，会对每个已迁移任务反复唤醒。
  4. `cp ~/hooks/scripts/patrol-muse-hub.sh.last-good ~/hooks/scripts/patrol-muse-hub.sh`（last-good 必须是上面 SHA-256 对应的原始版本，核对无 `PATROL_VERSION`）。
  5. `hooks.dry_run` 通过后再 `hooks.enable`。
- `.bak` 是为回滚保留的，禁止手工删除。
- 注意：回滚到原始版本会丢掉全部新版能力（去重键 `task_id@vN`、迁移、pending、flock、严格版本解析）；回滚后 seen 文件里若有空行或 `@v` 行，原始脚本会按裸 `task_id` 匹配，行为以原始脚本为准。

## 已解决（本批之前挂着的）

- 任务书版本行格式：4 本任务书与模板已改成严格行 `版本：v1`，不再判 malformed-version。
- 2D 的 D1（迁移 awk 容错）与 D2（迁移失败计数与 3 次唤醒）已在本批实现。

## 已知限制

- `director-watch-poll.sh` 未动；本基线只覆盖 `hooks/patrol.sh` 与任务书版本行格式。
- 巡逻脚本里加了一行 `export LC_ALL=C.UTF-8`（全角冒号正则需 UTF-8 区域环境）；节点升级消息里要提醒各号确认该行生效。

## 对等节点推行（2026-11-14，Chen 批准）

- RULES.md 新增 R18（对等节点自主执行：决策权表、SPEC_CONFLICT＋PARKED、有界重试、去重、批卡接口）；R6a／R6b 巡逻周期同步为生产值 60 秒；R16 增加审批卡自动化说明（三节点 canary-004／005b／006 已 live 验证）。
- TASK_TEMPLATE.md 增加任务书 v2 字段（`contract_revision`、`run_id`、`last_progress_at`、幂等键复用 `effect_id`）与自主执行一节。
- `docs/checkpoint-spec.md` 增加 §12 v1.1 增补（`last_progress_at`、`PARKED` 状态、后台进程适用范围补充；§1–§11 未改写）。
- 验证任务 T-019（node-2）、T-020（node-3）各 6 项检查，共 12 项；本次提交的 SHA 见总控日报与当日记忆记录。
