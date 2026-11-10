# Step 6b Test 7 handoff — scenario ready; chain NOT TESTED

Prepared 2026-11-10 UTC after the App access grant. T-904 was pushed and polled successfully. Stop here: the coordinator runs the real interruption/recovery chain separately. No worker was spawned and no receipt or ACK was created in this run.

| Field | Actual evidence |
| --- | --- |
| Task / node | T-904 / node-1 |
| Repository / branch | xy3293/muse-hub-test / main |
| Result SHA | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` |
| event_id | `result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` |
| Issue | [#1](https://github.com/xy3293/muse-hub-test/issues/1), ID 6303007785; exactly one test Issue |
| Existing comment | ID 6762499129; belongs to T-903, added then edited; no T-904 comment exists |
| Cursor before | `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` |
| Cursor after | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` |
| health.remaining | 4874 (test7 poll health; not a later rate estimate) |
| Event state | DETECTED; main_ack.acked=false; review=null; approval NONE; delivery NOT_SENT; signals=[] |
| Test HOME | `/home/hatch/workspace/muse-hub-tests/real-home` |
| Event file | `/home/hatch/workspace/muse-hub-tests/real-home/hooks/state/muse-hub/events/result-T-904-node-1-bc3206e97018cebe7a4accf0ff1fdfe2b63943a9.json` |
| Receipt path | `/home/hatch/workspace/muse-hub-tests/real-home/hooks/state/muse-hub/receipts/result-T-904-node-1-bc3206e97018cebe7a4accf0ff1fdfe2b63943a9.json` — absent; coordinator must validate then save |
| Source path | `results/node-1/T-904-step6b.md` |
| Remote BOARD | At T-904 head, unique T-904 row remains 待验收; includes unrelated T15 note |
| Final head | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9`; 9 total commits including provider initial commit |
| Approvals in preparation | 12 requests; 8 pushes + Issue + comment add/edit + approved comment read |

Exact RESULT:

```text
RESULT {"decision":"wake","reason":"muse-hub-activity","payload":{"events":[{"event_id":"result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9","kind":"result_revision","task_id":"T-904","node_id":"node-1","source_commit_sha":"bc3206e97018cebe7a4accf0ff1fdfe2b63943a9","is_reminder":false,"is_transition":false}],"needs_attention":[],"head":"bc3206e97018cebe7a4accf0ff1fdfe2b63943a9","unacked_count":6,"needs_attention_count":0}}
```

Acceptance criteria from Issue #1 and the committed fixture: task=T-904 and node=node-1 match the result path; version=1; scope=isolated muse-hub-test fixture. The coordinator must inspect the exact result SHA and record its own semantic validation in a complete receipt. Scenario preparation does not claim acceptance or chain success.

Evidence: `step6b-resume-T-904-push.json`, `step6b-real-test7.before.json`, `step6b-real-test7.after.json`, `step6b-real-test7.stdout`, `step6b-resume-final-board.json`, `step6b-resume-final-commits.json`, `step6b-resume-run-summary.json`, and `step6b-test-results.md`. Full preparation log: `step6b-resume-full-run.log`. Sync provenance: `/home/hatch/workspace/muse-hub-tests/test-repo.muse-github-snapshot-sync.json` (8 confirmed pushes).

协调员执行时必须读取 `WORKER_PROMPT.md` 与 `RECEIPT.md` 的全文；其中写死的生产仓库 `xy3293/muse-hub` 和生产 Issue #1 **必须替换为本次测试仓库与实际测试 Issue**。所有进程（包括 save-receipt.sh 与轮询器）显式使用上述测试 HOME；轮询器另设 `MUSE_HUB_REPO=xy3293/muse-hub-test`、`GITHUB_API_BASE=https://api.github.com`，并通过环境提供 `GITHUB_TOKEN`，不得持久化 token。不得启动 Hook，不得写生产状态或生产仓库。

执行顺序：LOAD_EVENT → CHECK_RECEIPT → VALIDATE_IF_NEEDED → SAVE_RECEIPT → RECONCILE_REMOTE → HANDLE_APPROVAL → NOTIFY_IF_NEEDED → WAIT_FOR_EXACT_ACK。完整有效收据须绑定该 event_id 和完整 version_sha，使用真实 save-receipt.sh 持久化；在收据保存后、远端写入前中断，保留事件及收据。恢复时证明复用了同一收据（内容及 mtime 不变），跳过重复语义验收，先对账远端再处理审批；通知成功不等于 ACK。

PASS 后的 BOARD 推送仍需 Chen 审批，必须使用 snapshot-push 规范。ACK 提交须修改 BOARD.md、作者 login 为 xy3293，任务唯一行变成「完成」，提交消息独占一行 `MUSE-ACK task=T-904 node=node-1 event=<实际完整 event_id> verdict=PASS`。只有真实轮询器核验并写入 ACKED 才算链路成功；不得手工设置终态。协调员保留中断前后事件、收据哈希/mtime、审批 operation_id、通知记录、实际 ACK SHA、轮询输出及游标证据。


This run stopped after preparation. The real interruption/recovery/receipt/ACK chain remains NOT TESTED until the coordinator executes it.
