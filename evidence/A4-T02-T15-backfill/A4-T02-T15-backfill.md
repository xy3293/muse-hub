# A4：T02 / T15 子项补测

执行时间（本次进程实际 UTC 时钟）：2026-11-15T22:29:03Z。执行目录：`/home/hatch/workspace/muse-hub-tests`。证据目录：[`ack/A4-T02-T15/`](ack/A4-T02-T15/)。

## 结论与覆盖边界

| 子项 | 可测性与实测范围 | 结论 |
| --- | --- | --- |
| T02 real receipt isolation / ACKED byte-preservation | 使用隔离目录内 Test 7 的真实旧收据、真实 ACKED 事件；本地新版本提交经 loopback API 输入原 Step 6b poll；检查 SHA 绑定与逐字节保留 | **PASS（本地隔离回放）** |
| T15 terminal-state preservation：ACKED | 使用同一真实 ACKED 事件；回放本地无 MUSE-ACK 的 BOARD 提交；检查事件、收据、main_ack、retry、时间戳 | **PASS（本地隔离回放，ACKED 分支）** |
| T15 terminal-state preservation：REJECTED / SUPERSEDED | 原始 real-home 中两种真实状态各 0 个；未手工改写状态 | **NOT TESTED** |
| Step 6b 真实 GitHub 新版本 / 新无关提交场景 | 本次没有向远端写入；两个 poll 均使用 loopback API，HEAD 由本地 shim 提供 | **NOT TESTED** |

T15 若要求覆盖 ACKED、REJECTED、SUPERSEDED 三种终态，其整体结论仍为 **NOT TESTED（仅 ACKED 分支已覆盖）**。以上本地 PASS 不替代原 Step 6b 真实阶段的 NOT TESTED；原报告未修改。本次无 FAIL。

## 已核对的方法与真实前置

已读取用户指定的 `/home/hatch/workspace/muse-hub-git/evidence/step6b/step6b-test-results.md`，相关原行保存在 [`original-T02-T15-rows.md`](ack/A4-T02-T15/original-T02-T15-rows.md)，原报告 SHA-256 保存在 [`original-report-provenance.json`](ack/A4-T02-T15/original-report-provenance.json)。已读取 `ack/step6b-resume.py`、`ack/step6b-real.py`、`ack/run.sh`、`ack/stub_server.py`、`ack/worker_sim.py` 及对应 T02/T15 说明。

`step6b-resume.py` 包含远端 push；`step6b-real.py` 固定调用生产 Hook 路径，init 分支还读取生产 scan。本次未执行这两个脚本。仅复用其隔离 HOME、前后快照、单次 poll 的方法，以及现有 stub server、收据校验逻辑和历史代码副本。

原始 `real-home/hooks/state/muse-hub/` 中实测：6 个事件（DETECTED=5、ACKED=1、REJECTED=0、SUPERSEDED=0），1 份收据。唯一真实 ACKED 事件与 `ack/step6b-real-ack.after.json` 内对应事件 JSON 一致；收据哈希与旧报告 Test 7 记录一致。未使用生产 T-031/T-032/T-034 的本地状态或收据。

真实前置文件（以下名称在两个目录中相同）：

```text
real-home/hooks/state/muse-hub/events/result-T-904-node-1-bc3206e97018cebe7a4accf0ff1fdfe2b63943a9.json
real-home/hooks/state/muse-hub/receipts/result-T-904-node-1-bc3206e97018cebe7a4accf0ff1fdfe2b63943a9.json
```

| 实测字段 | 值 |
| --- | --- |
| 旧 event_id | `result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` |
| 旧 source_commit_sha / receipt.version_sha | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` |
| 真实 ack_commit_sha | `12cb98b7079763700557be79ee98652a900eb515` |
| 事件字节数 / SHA-256 | 1012 / `8a13bed0bf352582d40f7b66fbc0f88d14190ac424d7d78bb71785e42ccbdf0f` |
| 事件 mtime_ns | `1794299390955262153` |
| 收据字节数 / SHA-256 | 998 / `9f4d2d76a75b6ed96e50bb9f6ca12910eed93dc652d0dde790124ae44b8f8a2c` |
| 收据 mtime_ns | `1794299214780583565` |

本次只读调用 GitHub connector：`GET https://api.github.com/repos/xy3293/muse-hub-test/commits?sha=main&per_page=20`。2026-11-15 22:27:29 UTC 的响应含 10 个提交，HEAD 仍为上述 ACK SHA；完整响应保存在 [`test-repo-commits.api.json`](ack/A4-T02-T15/test-repo-commits.api.json)。没有 ACK 后的新提交可直接用于这两个真实远端场景。

## 使用的代码与隔离方式

从已有 `ack/run.wDtnvV/fault-T19/hooks/scripts/director-watch-poll.sh` 副本删除 `test_faults.py:syntax()` 注入的末尾 `\nif then\n`，恢复为 [`director-watch-poll.step6b.sh`](ack/A4-T02-T15/director-watch-poll.step6b.sh)。恢复后 SHA-256 为 `1e564c9826b55ed93671e75dc80da4f997bb1ce8e86011e82532c5cbe6b275a0`，与旧 `step6b-resume-protected-before.json` 记录完全一致。未读取或修改当前生产 poll。

收据 helper 使用已有 `ack/step6-before/save-receipt.sh`，SHA-256 为 `25882d1bd617f4585e4e4724eea9a3e97aa6e0d002beab41530af6d9a4210308`，同样与历史记录一致。上述两个脚本及两个 shim 的 `bash -n` 均 exit 0；详见 `syntax-*.command.json` 和 [`code-provenance.json`](ack/A4-T02-T15/code-provenance.json)。

每项从真实 ACKED 事件、收据各复制一份（保留 mtime），单独使用 `ack/A4-T02-T15/{T02,T15}/real-home`。未带入原始 5 个 DETECTED 事件，未执行它们的重试。`MUSE_HUB_REPO=xy3293/muse-hub-test`、`HATCH_HOOK_DRY_RUN=0`；`GITHUB_API_BASE` 指向 `127.0.0.1`。git shim 仅接受测试仓库的 ls-remote，curl shim 仅放行该 loopback 地址。原 stub server 只在新副本中替换了仓库路由。没有修改既有 harness 文件。

本地 `ack/A4-T02-T15/test-repo` 从原 `test-repo` 复制后建立独立 Git 历史，remote 数量为 0。以下 SHA 均为本地真实 Git 提交，未推送；该历史没有声称接续远端 ACK 提交。

| 本地提交 | SHA |
| --- | --- |
| 快照基线 | `a7c0747538a94d8f51d00057ca0c7dd4e225ce22` |
| T02：仅修改 `results/node-1/T-904-step6b.md`，version 改为 2 | `ed683b18b8eed3758f1389a5488c6a7d0218b790` |
| T15：仅修改 BOARD.md，提交消息无 MUSE-ACK | `880a52bd0390c1081c718bfa4f00e11e4bc60b61` |

实际执行命令：

```bash
cd /home/hatch/workspace/muse-hub-tests
python3 -B ack/A4-T02-T15/run.py > ack/A4-T02-T15/run.stdout 2> ack/A4-T02-T15/run.stderr
```

exit 0；`run.stderr` 为空。驱动 [`run.py`](ack/A4-T02-T15/run.py) 保存了各命令 argv、exit、stdout、stderr 和每项 poll 的环境构造。驱动拒绝覆盖已有运行证据，本次只执行一次，共 2 次 poll；没有运行原全量回归或重跑主项。

## T02 实测

输入真实 v1 ACKED 事件和真实 v1 收据，回放本地 v2 提交。游标从本地基线推进到 `ed683b18b8eed3758f1389a5488c6a7d0218b790`。poll exit 0，RESULT 为 `wake / muse-hub-activity`，只列出新 `result:T-904:node-1:ed683b18b8eed3758f1389a5488c6a7d0218b790`，`unacked_count=1`。完整原始 RESULT 见 [`T02.stdout`](ack/A4-T02-T15/T02.stdout)。

新事件为 DETECTED、review=null、main_ack.acked=false；事件总数从 1 增至 2，收据仍为 1。旧 ACKED 事件和旧收据的字节数、SHA-256、mtime_ns 在 before、after、final 三份快照中均与上表一致。

仅调用现有 `worker_sim.py` 的纯校验函数 `valid()`：同一真实收据对旧事件返回 true，对新事件返回 false；未运行模拟 worker 的语义验收或副作用流程。另用历史真实 helper 做绑定校验：

| helper 调用输入 | 实测结果 |
| --- | --- |
| 旧 event_id + 原真实收据 | exit 0，返回已有旧收据路径，内容与 mtime 不变 |
| 新 event_id + 同一原真实收据 | exit 1，stderr 为 `ERROR invalid or incomplete receipt`；stdout 为空 |

新版本收据路径不存在，残留 `.tmp-*` 数量为 0；没有生成新验收结论。证据为 `T02-save-old-{control,as-new}.{command.json,stdout,stderr}`、[`T02.before.json`](ack/A4-T02-T15/T02.before.json)、[`T02.after.json`](ack/A4-T02-T15/T02.after.json)、[`T02.final.json`](ack/A4-T02-T15/T02.final.json)。结论：**PASS，仅限上述本地隔离回放与收据绑定检查**；真实 worker 对新版本的端到端行为、真实 GitHub 新版本轮询为 **NOT TESTED**。

## T15 实测与缺失分支

使用独立 HOME，只带入真实 T-904 ACKED 事件和收据。回放本地 BOARD 提交，游标 `ed683b18b8eed3758f1389a5488c6a7d0218b790` → `880a52bd0390c1081c718bfa4f00e11e4bc60b61`。API fixture 的 author.login 为 xy3293，是本地模拟字段；未声称本地 Git 提交具有真实 GitHub 总控身份。

poll exit 0，原始输出：

```text
RESULT {"decision":"silent","reason":"no-change","payload":{"head":"880a52bd0390c1081c718bfa4f00e11e4bc60b61","unacked_count":0,"needs_attention_count":0,"comments_total":0}}
```

事件总数仍为 1，状态仍为 ACKED；main_ack、retry、timestamps 及整个事件文件字节均未改变，事件和收据 mtime_ns、SHA-256 与上表一致。证据：[`T15.fixture.json`](ack/A4-T02-T15/T15.fixture.json)、[`T15.before.json`](ack/A4-T02-T15/T15.before.json)、[`T15.after.json`](ack/A4-T02-T15/T15.after.json)、[`T15.stdout`](ack/A4-T02-T15/T15.stdout)。ACKED 分支结论：**PASS（本地隔离回放）**。

REJECTED / SUPERSEDED 分支：真实隔离状态中均为 0。现有回归目录中的合成终态不作为真实前置；本次未手工赋终态，也未构造拒收结论或远端 REJECT ACK。所用 Step 6b poll 中 SUPERSEDED 仅出现在终态判断，没有生成该状态的赋值分支。因此这两种真实终态保留结论均为 **NOT TESTED**。

真实 GitHub 场景缺口：测试远端 HEAD 仍为既有 ACK，没有其后的新结果版本或新无关 BOARD 提交；本次所有写操作限定本地，故未调用 push、commit/create、评论或其他远端写接口来补造触发提交。真实 ACKED 前置已经存在，但“真实远端新增触发提交”的环节没有执行，保留 **NOT TESTED**。

## 关键证据与范围核验

- [`summary.json`](ack/A4-T02-T15/summary.json)：两项本地结果、未覆盖范围及 poll RESULT。
- [`prerequisites.json`](ack/A4-T02-T15/prerequisites.json)：真实前置数量、完整事件、原始文件 SHA/mtime。
- [`requests.jsonl`](ack/A4-T02-T15/requests.jsonl)：2 次 poll 各 3 个 loopback GET（Compare、commit、comments），共 6 个；BOARD contents 请求为 0。
- [`run.stdout`](ack/A4-T02-T15/run.stdout)、`run.stderr`：完整执行输出；所有 `*.command.json` 记录单次命令及退出码。
- [`local-commits.json`](ack/A4-T02-T15/local-commits.json) 与本地 `test-repo/.git/`：3 个本地提交及对象。
- [`originals.before.json`](ack/A4-T02-T15/originals.before.json)、[`originals.after.json`](ack/A4-T02-T15/originals.after.json)：原 real-home/test-repo 的 18 个文件加 5 个既有 harness 文件，共 23 个文件的哈希、字节数、mtime_ns 完全一致。
- [`verification.json`](ack/A4-T02-T15/verification.json)：再次核验原文件、两项共 4 个种子文件的字节/mtime、本地提交改动路径、无 remote、两次 poll 与 6 个 loopback GET，结果 PASS。
- [`SHA256SUMS`](ack/A4-T02-T15/SHA256SUMS)：报告及本次证据文件哈希清单（不含 `.git` 内部文件）。

写入均位于本测试目录及 poll 使用的 `/tmp` 临时目录；原 real-home/test-repo 未变。除用户明确指定的历史测试报告外，未读取生产 muse-hub 文件或状态；没有读取当前生产 Hook，没有修改或启动 Hook/巡逻，没有远端写操作、安装软件或系统配置修改。本报告不对未读取的生产文件声明哈希核验结果。
