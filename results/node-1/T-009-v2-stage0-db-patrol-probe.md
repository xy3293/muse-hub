# T-009 工人丢失修复 v2 Stage 0：DB 关联与巡逻可见性探测

- **编号**：T-009（v1）
- **负责人**：node-1
- **探测日期**：2026-11-12（UTC 09:24–09:28，CST 17:24–17:28）
- **结论先行**：9 项中 6 项已验证、2 项部分验证、1 项巡逻侧不支持、0 项未知。v2 超时判定可以写：`runtime.execute_resolve_runs` 有可靠的任务关联字段（`metadata_json.wake_payload`，须解析 JSONB）和超时终结字段（`status=failed` + `last_error_stage=worker_timeout`）；但 patrol 进程本身打不开 `muse.db`，DB 查询只能由 worker 内的 agent 经 `muse.db` 工具做，巡逻降级方案不能假设 patrol 能查库。巡逻无缓存、无 ETag，403 风险仍在；心跳孤儿退出已实测通过。

## 能力矩阵

| # | 探测项 | 结论 | 一句话证据 |
|---|---|---|---|
| 1 | `muse.db` 路径、schema、只读访问与 patrol 可见性 | 部分验证 | agent 经 `muse.db` 工具可只读查库（已验证）；patrol 进程无任何 DB 访问途径（不支持） |
| 2 | run 行与 task／attempt／wake 事件的可靠关联字段 | 已验证 | `metadata_json.wake_payload` 含任务、版本、HEAD、invocation；`run_id`/`source_ref` 含 invocation UUID；超时三字段齐全 |
| 3 | DB 的 WAL／锁／写入延迟 | 部分验证 | 只读查询不干扰运行时（SELECT-only 角色）；run 行创建近实时；WAL／锁细节未知 |
| 4 | 共享状态目录在 patrol 侧的读写权限 | 已验证 | `/home/hatch/hooks/state/` 可读可写；seen／HEAD／lock 文件均为巡逻每轮写入 |
| 5 | worker 环境变量缺失确认 | 已验证 | `HATCH_HOOK_STATE_DIR`、`HATCH_HOOK_ID` 在 worker 内均未设置；patrol.sh 亦无引用 |
| 6 | 独立 heartbeat 的父进程识别和孤儿退出 | 已验证 | PID＋`/proc/<pid>/stat` starttime 实测：父死后 helper 约 2 秒内退出；starttime 错配 5ms 内退出 |
| 7 | GitHub 访问方式、缓存、ETag、凭据可见性 | 已验证 | patrol 用未认证 curl＋`git ls-remote`；无缓存、无 ETag；节点有 git 凭据（仅供 git 用），gh 未登录 |
| 8 | 当前 patrol 与 Hook 基线确认 | 已验证 | patrol v2026-11-11.3，安装副本 SHA 与仓库版一致；轮询 300 秒；脚本超时 600 秒；`flock -n`＋600 秒 stale 接管 |
| 9 | 能力矩阵（本表） | 已验证 | 见上表；未知项为第 3 项的 WAL／锁细节，未按“已支持”处理 |

> 事实与推断区分：本报告“已验证”均指本任务内实测或实查；标“推断”处为推断；“未知”处明确写出，不作支持处理。

## 1. `muse.db` 的路径、schema、只读访问方式和 patrol 可见性（部分验证）

- **是什么**：`muse.db` 是 PostgreSQL（`/opt/muse/skills/muse_db/references/schema.md` 明示），表 `runtime.execute_resolve_runs` 有完整列文档（见第 2 项）。
- **agent 如何访问（已验证）**：仅通过 agent 的 `muse.db` 工具提交单条有界只读 `SELECT`。本任务用该工具成功查出 5 行真实 run 记录（T-004／T-005／T-006／T-008 各 1 行＋本任务 T-009 当前行 1 行），语句与结果见第 2、3 项。
- **无本地路径、无 DSN（已验证）**：worker shell 内无 `DATABASE_URL`／`PGHOST`／`PGUSER` 等环境变量（`env` 排查无匹配项）；无 `psql` 客户端；`/var/run/postgresql/` 不存在；无本地数据库文件可查。也就是说没有“以什么用户、什么路径、什么命令打开”的 shell 答案——DB 不暴露给 shell。
- **只读保证（已验证）**：`querying.md` 明确工具使用 least-privilege 数据库角色，仅 `SELECT` 指定允许的关系；本任务 3 次查询均为只读，未写库。
- **patrol 可见性（不支持）**：`hooks/patrol.sh` 全文检索 `psql|sqlite|postgres|database|muse.db` 无任何命中；脚本只用 bash＋`curl`＋`jq`＋`git`。结论：**巡逻进程打不开 `muse.db`**。v2 的 DB 查询适配器只能跑在 worker（agent）内，不能放进 patrol.sh；巡逻降级方案必须是不查库的方案（如继续用 seen 文件＋git HEAD）。

## 2. run 行与 task／attempt／wake 事件的可靠关联字段（已验证）

表 `runtime.execute_resolve_runs`（主键 `run_id`；唯一键 `UNIQUE(worker_kind, source_ref)`）。以下字段名来自 schema 文档并经真实行核实：

| 字段 | 含义与实测值（脱敏） |
|---|---|
| `run_id` | `event-hook:<invocation UUID>`，如 T-006 行为 `event-hook:bb3e8bff-…` |
| `source_ref` | `event-hook:muse-hub-patrol:<invocation UUID>`，与 `run_id` 的 UUID 部分一致 |
| `worker_kind` | 恒为 `event_hook` |
| `lane_key` | 恒为 `event-hook:muse-hub-patrol` |
| `metadata_json.invocation_id` | 与 `run_id` 的 UUID 部分一致 |
| `metadata_json.wake_payload.tasks` | 任务关联主字段。新格式为对象数组，如 `[{"task_id":"T-005","version":"v1"}]`；旧格式为字符串数组，如 `["T-004"]`。**两种格式并存，适配器必须都处理** |
| `metadata_json.wake_payload.event_id` | `T-006@v1@<head_sha>` 形式，任务＋版本＋HEAD 三合一 |
| `metadata_json.wake_payload.node`／`head_sha`／`patrol_version` | 如 `node-1`／`106cbca8…`／`2026-11-11.3` |
| `metadata_json.wake_reason` | `new-task-assigned` |
| `worker_started_at` | 非空即证明 worker 已启动；T-006 行：`2026-11-11T20:39:01.290695+00:00` |
| `status`／`last_error_stage`／`last_error_message`／`worker_phase` | 超时终结四字段（见下） |
| `created_at`／`updated_at` | 超时行的差值恒为 600.0x 秒 |

**超时判定（已验证，三例一致）**：`status='failed'` ＋ `last_error_stage='worker_timeout'` ＋ `last_error_message='timed out waiting for execute-resolve turn completion'` ＋ `worker_phase='execute'`。实测：

- T-004（`1a9ecdab-…`）：created `2026-11-10T18:44:04.729402Z` → updated `18:54:04.755935Z`（＋600.03 秒）
- T-006（`bb3e8bff-…`）：created `2026-11-11T20:39:01.275212Z` → updated `20:49:01.31175Z`（＋600.04 秒）
- T-008（`bcd1d277-…`）：created `2026-11-11T21:59:04.522193Z` → updated `22:09:04.572613Z`（＋600.05 秒）
- 对照 T-005（`73c9e37e-…`）：`completed_notified`，`terminal_decision='notify_main_agent'`，373.9 秒完成

**注意**：表里没有独立的 `task_id` 列，任务关联必须解析 `metadata_json`（`querying.md` 允许的函数含 `jsonb_extract_path_text`，可抽取 `wake_payload` 子字段）。`wake_payload.event_id` 是最稳的单字段关联键（任务＋版本＋HEAD），`tasks` 数组是次选（须兼容新旧两种格式）。

## 3. DB 的 WAL／锁／写入延迟（部分验证）

- **只读查询不干扰运行时（已验证）**：`muse.db` 工具只接受单条有界只读 `SELECT`，角色为 SELECT-only（`querying.md`）；本任务的 3 次查询均未写运行时数据库，未修改任何内部表。
- **写入延迟（已验证）**：本任务当前 run 行（`72b71147-…`）在唤醒后即刻可查：created `2026-11-12T09:24:01.894025Z`，`worker_started_at` `09:24:01.915458Z`（相差 21 毫秒），查询时 `status='pending'`、`worker_phase='execute'`。run 行创建近乎实时；超时终结行的 `updated_at` 精确落在 created＋600.0x 秒。v2 用 `updated_at - created_at` 判定超时是可行的。
- **WAL 模式、锁机制（未知）**：DB 不在本地暴露（无文件、无 socket、无管理接口、无 `psql`），无法核实 WAL 开关与锁类型。**未知，不得在设计中按“已支持”处理**。若 Codex 需要该信息，须由能接触数据库服务端的一方提供，本节点无法探测。

## 4. 共享状态目录在 patrol 侧的读写权限（已验证）

- 路径：巡逻脚本 `STATE_DIR="$HOME/hooks/state"`，即 `/home/hatch/hooks/state/`，与 worker 侧同一目录（T-008 已验证 worker 侧）。
- 目录现状（2026-11-12 实查）：`drwxrws--- root:nogroup`；本 worker shell（`whoami`＝root）`test -r`／`test -w` 均通过。
- 巡逻每轮写入的直接证据：`muse-hub-seen-tasks` 含 7 行（`T-001@v1`、`T-003@v1`、`T-004@v1`、`T-005@v1`、`T-006@v1`、`T-008@v1`、`T-009@v1`），`muse-hub-last-head` 为 `7937df389e122b2486c89849c1cad54acd1f7f6e`，`muse-hub.patrol.lock` 存在（0 字节），`logs/` 目录存在。以上文件 mtime 均为 2026-11-12 09:23–09:24，即本轮巡逻刚写过。
- 推断：读写权限依赖 root 身份运行；若 patrol 改为非 root 用户运行，本结论需重测。

## 5. worker 环境变量缺失确认（已验证）

- 本 worker shell 内直接确认：`HATCH_HOOK_STATE_DIR` 未设置，`HATCH_HOOK_ID` 未设置。
- `hooks/patrol.sh` 全文检索上述两变量名，无任何引用。
- 结论：原始路径 `/home/hatch/hooks/state/` 作为显式配置；不要指望从环境变量读取状态目录。

## 6. 独立 heartbeat 的父进程识别和孤儿退出（已验证）

实测方法（小规模，`/tmp` 临时脚本，测后已清理）：父进程取自身 `/proc/$$/stat` 第 22 字段（starttime，自系统启动的时钟节拍数）作为启动标识；helper 以 `nohup` 后台运行，每 0.5 秒检查两点——`/proc/<ppid>` 是否存在、当前 starttime 是否等于记录值；任一不满足即自行退出。

- **测试 A（父进程被杀）**：父进程 pid 16727、starttime 591242；`kill -9` 父进程后，helper 在 09:27:04.000（UTC）记录 `parent gone -> exit` 并退出；`kill -0` 确认 helper 已不存在。从父死到 helper 退出约 2 秒内。
- **测试 B（防 PID 复用比较逻辑）**：向 helper 传入错误 starttime（99999999999），helper 在 5 毫秒内记录 `starttime mismatch` 并退出，证明 PID＋starttime 比较逻辑生效；即使 PID 被新进程复用，starttime 不同也会触发退出。
- 结论：父进程识别用 PID＋starttime（`/proc/<pid>/stat` field 22）；父进程消失后 helper 自行退出。满足 v2“心跳须为独立后台进程”的前提。

## 7. GitHub 访问方式、缓存、ETag 能力和凭据可见性（已验证）

- **巡逻怎么读 GitHub**：先 `git ls-remote https://github.com/xy3293/muse-hub.git HEAD` 判 HEAD（`patrol.sh` L219）；HEAD 变了才用 `curl` 调 GitHub Contents API 取 BOARD／任务书（`fetch_content`，L126–133），`Accept: application/vnd.github.raw+json`。
- **无认证**：`fetch_content` 不带 `Authorization` 头，L123 注释明文写“patrol 不带 Authorization 头，后人不要加”。未认证 Contents API 限额下 403 仍可能发生（T-008 已记录）。
- **无缓存、无 ETag（已验证）**：全文检索 `cache|etag|if-none` 无命中；每次 fetch 用 `mktemp` 生成临时 body／headers 文件，用后删除；失败时只把状态码、限额头、错误分类追加记入 `state/logs/api-diagnostics.jsonl`（5MB 轮转，约 20MB 上限）。`~/.cache` 下只有无关的 `hatch-thumbnails`，无 GitHub 缓存。
- **节点凭据（有，类型说明，不贴值）**：`~/.git-credentials` 存在（200 字节，权限 600），`git credential.helper` 为 `store`——该凭据只服务 git（`ls-remote`／`push`）；`gh` CLI 未登录（`gh auth status` 提示未登录任何 host）。结论：节点有可复用的已授权 git 凭据，但 patrol 的 curl 并不使用它；若要给 patrol 的 API 请求加认证或 ETag，需另行设计凭据注入方式，不得把 token 写进脚本或结果文件。
- **对 v2 的含义**：巡逻 403 的缓解不能靠“复用现有 ETag／缓存”（不存在），只能靠减少请求（已有 HEAD 门控）、退避重试或认证注入三选一。

## 8. 当前 patrol 与 Hook 基线确认（已验证）

- `patrol.sh` 版本：`PATROL_VERSION="2026-11-11.3"`（L19）；安装副本 `~/hooks/scripts/patrol-muse-hub.sh` 的 SHA-256 与仓库 `hooks/patrol.sh` 完全一致，均为 `f5795685b88e44f06fe806e94c0192a2598b978830ec8052d78edc8cfb2245a3`。
- Hook 定义（`~/hooks/definitions/muse-hub-patrol.json`）：`enabled=true`，`poll_interval_secs=300`，`script_timeout_secs=600`，`script_path=~/hooks/scripts/patrol-muse-hub.sh`，`delivery.surface=main`。
- `flock` 状态：非阻塞 `flock -n` 于 `$STATE_DIR/muse-hub.patrol.lock`；锁忙则静默 `lock-busy` 退出；仅当锁文件 mtime 超过 600 秒才执行 stale 接管（删锁重取）。锁文件存在，mtime 2026-11-12 09:23（本轮巡逻）。
- 600 秒超时基线：见第 2 项，T-004／T-006／T-008 三行 created→updated 均为 600.0x 秒，与 `script_timeout_secs=600` 一致。

## 9. 能力矩阵

见文首矩阵表。汇总：已验证 6 项（2、4、5、6、7、8），部分验证 2 项（1、3），不支持 1 项（巡逻侧访问 `muse.db`，属第 1 项的子结论），未知 1 处（第 3 项的 WAL／锁细节）。未知项未在设计建议中按“已支持”处理。

## 给总控的 v2 设计建议（推断，非探测结论）

1. 超时判定查询应以 `metadata_json.wake_payload.event_id`（`T-xxx@vN@<head>`）为关联键，`status='failed' AND last_error_stage='worker_timeout'` 为终结条件，`worker_started_at IS NOT NULL` 为启动证据；`tasks` 数组须兼容对象／字符串两种格式。
2. DB 查询只能由 worker 内 agent 执行，不得写入 patrol.sh；巡逻降级方案沿用 seen 文件＋`git ls-remote` HEAD 门控。
3. 心跳 helper 采用 PID＋`/proc/<pid>/stat` starttime 识别父进程，父死自退（本任务已实测）。
4. 巡逻 403 缓解需新增设计（退避／认证注入／本地 BOARD 缓存），现有脚本无缓存、无 ETag 可复用。
5. WAL／锁细节本节点无法探测，如 Codex 需要，由服务端一方补。

## 探测方法与限制

- 只读探测：未修改生产 `patrol.sh`，未新增定时任务／Hook，未修改 BOARD.md／RULES.md／任务书／任何结果文件，未写运行时数据库；心跳实测脚本放 `/tmp`，测后已删除，无残留进程。
- 查询工具：`muse.db` 只读 SELECT（3 次），shell 只读命令（`grep`／`sha256sum`／`stat`／`test -r/-w`／`ls`／`cat` 状态文件）。
- 本报告无秘密、无编造数字、无编造来源；所有时间戳、SHA、字段名均来自实测输出；示例 UUID 已截断脱敏。

T-009 探测完成，2026-11-12。
