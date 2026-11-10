# Step 6b resumed real-stage results

2026-11-10 UTC. Resumed after the App access grant. The full local regression ran before remote writes and passed **74 PASS, 0 FAIL**, exit 0 (`step6b-resume-regression-output.txt`, artifacts `run.wDtnvV`). The regression's real-stage NOT TESTED lines describe its local-only harness; actual real-stage evidence is below.

Token availability: `gh auth token` exited 0; stdout/stderr discarded. No token was printed, logged or persisted. New gate label `resume-gate-20261110` preserves the previous gate: limit=5000, remaining=4987, threshold=30, reset=1794300474 (2026-11-10 08:47:54 UTC). Gate passed. Driver unchanged during this resume; `step6b-resume.py` only performs the snapshot provenance checks, one push and atomic sync-record append, with no retries.

| Test / check | Status | Actual evidence |
| --- | --- | --- |
| Local regression | PASS | 74 PASS, 0 FAIL; exit 0; `step6b-resume-regression-output.txt`. |
| Token / authenticated gate | PASS | exit 0; limit 5000 / remaining 4987 / reset 1794300474; `step6b-real-resume-gate-20261110.rate.json`. |
| Empty repository | PASS | `step6b-resume-empty-refs.stdout` empty, git ls-remote exit 0; `step6b-resume-empty-commits.json` explicitly reports 409 Git Repository is empty. |
| Baseline snapshot | PASS | README.md + BOARD.md only; provider-confirmed SHA below; `step6b-resume-baseline-push.json`; durable adjacent sync record saved. Provider also created initial commit `b7cc93baceed7fa3a708bf0d1908f9ac624a3901`; `step6b-resume-baseline-commits.json`. |
| init / baseline poll | PASS | Silent/no-change, zero events, cursor unchanged at baseline; `step6b-real-baseline.{before,after}.json` and `.stdout`. |
| T01 | PASS | Three separate commits T-900/T-901/T-902; exactly three result events with the corresponding full SHA in event_id and payload. Cursor baseline → T-902; `step6b-real-T01.{before,after}.json` and `.stdout`. |
| T02 version identity | PASS | T-900 v2 copied from fixture and committed; old/new event_ids are `result:T-900:node-1:<v1/v2 SHA below>`. Old event JSON unchanged; exactly one new result in RESULT, four stored events. `step6b-real-T02.{before,after}.json` and `.stdout`. |
| T02 real receipt isolation / ACKED byte-preservation | NOT TESTED | No real worker receipt was created; no ACKED event exists. These optional subcases are not claimed as PASS. |
| T03 | PASS | Exactly one Issue, #1 (ID 6303007785); T-903 commit below; one comment ID 6762499129, body `T-903 node-1 version=94f03f6465070dfbfa71e9da989953eb525d666e`. Exactly one new result event; signal points to Issue 1/comment 6762499129 at 08:18:12Z; no extra issue_signal. `step6b-resume-issue-create.json`, `step6b-resume-comment-add.json`, `step6b-real-T03.after.json`. |
| T04 comment edit | PASS | Same comment ID and count=1; task/node/SHA retained with `edit-marker=step6b-T04`; updated_at 2026-11-10T08:18:12Z → 2026-11-10T08:18:47Z. Remote read before poll confirmed count/body/timestamp. Poll index and latest signal contain new timestamp; event count remains five, cursor unchanged. `step6b-resume-comment-{edit,read}.json`, `step6b-real-T04.after.json`. |
| T04 delete / delete-add count cancellation | NOT TESTED | By design: complete live catalogue advertises no delete-comment tool. No deletion performed or fabricated. |
| T15 unrelated director commit | PASS | BOARD-T15 copied and pushed; `author.login=xy3293`, no MUSE-ACK line (`step6b-resume-T15-author.json`). Silent/no-change; all five events main_ack.acked=false, every state unchanged; `step6b-real-T15.{before,after}.json`. |
| T15 terminal-state preservation | NOT TESTED | This real run has no ACKED/REJECTED/SUPERSEDED event; only existing DETECTED states were exercised. |
| T18-real | NOT TESTED | By design: more than 100 commits for Compare pagination exceeds the 20-commit budget. No bulk commits or comments. Local T18-sim is separate evidence. |
| T-904 / test7 scenario preparation | PASS | Commit and full event_id below; one new result event; cursor T15 → T-904, health.remaining=4874. Handoff filled with actual evidence; `step6b-real-test7.{before,after}.json`, `.stdout`, `step6b-test7-handoff.md`. |
| Test 7 interruption/recovery/ACK agent chain | PASS | Worker A validated T-904 (5/5 checks PASS) and saved the receipt (SHA-256 `9f4d2d76a75b6ed96e50bb9f6ca12910eed93dc652d0dde790124ae44b8f8a2c`, mtime 2026-11-10 08:26:54.780583565 +0000, 998 bytes, verdict PASS), then stopped (controlled interruption at the receipt checkpoint). Worker B resumed from the receipt: verified it complete/valid (hash/mtime identical before and after, 998 bytes), REUSED it with no duplicate semantic review, no new receipt, no modification; reconciled remote BOARD (T-904 待验收); pushed BOARD with the exact MUSE-ACK line (SHA `12cb98b7079763700557be79ee98652a900eb515`, approved by Chen). Remote verified independently: head `12cb98b7…`, ACK commit message exactly the MUSE-ACK line, author xy3293, files [BOARD.md] only, remote BOARD shows T-904 完成 with all other rows unchanged. Real poller then verified the ACK: event transitioned DETECTED → ACKED, main_ack.acked=true, ack_commit_sha `12cb98b7079763700557be79ee98652a900eb515`, ack_method `muse-ack-commit`, verdict PASS, main_acked_at 2026-11-10T08:29:50Z; cursor advanced to `12cb98b7…`; unacked_count 6 → 5. Receipt hash/mtime unchanged after Worker B and after the poll. Caveat: the interruption was a controlled checkpoint stop (Worker A was briefed to stop after SAVE_RECEIPT), not a kill signal; the receipt-reuse/ACK core is genuinely exercised. Evidence: `step6b-real-ack.{before,after}.json`, `.stdout`; receipt + event file in real-home. |
| Final remote reconciliation | PASS | After the Test 7 ACK push: head is the ACK commit `12cb98b7079763700557be79ee98652a900eb515`; 10 total commits (9 before + 1 ACK push). Remote BOARD.md shows T-904 完成, all other rows still 待验收, T15 note intact. `step6b-resume-final-commits.json` / `step6b-resume-final-board.json` capture the pre-ACK state (head=T-904, 9 commits, T-904 待验收); the post-ACK state was verified independently via `gh api` (head + BOARD contents + ACK commit detail) and by the poller's ACKED transition. |
| Production protection | PASS | All 15 protected file hashes unchanged in `step6b-resume-protected-{before,after}.json`. Hook remains disabled (`step6b-resume-hook-status.json`). All driver state is under isolated real-home; production repository was not written. |

## Confirmed remote snapshot SHAs

| Push | Full provider-confirmed SHA |
| --- | --- |
| baseline | `943a91b2b297ec71a899a50da8825c2dc25d0524` |
| T-900 | `d62c24d7adf40c99d9fbdb1beca07c356e5874c1` |
| T-901 | `1b2cf75aeeb92f0b60349c24cb1a01a516641cc4` |
| T-902 | `01873dc5d12224ad80559203942e274a813a4d43` |
| T-900-v2 | `7b84059db2379ad1ba093b82c47dd4db43f0e9a5` |
| T-903 | `94f03f6465070dfbfa71e9da989953eb525d666e` |
| T15 | `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` |
| T-904 | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` |
| T-904 BOARD ACK push (Test 7) | `12cb98b7079763700557be79ee98652a900eb515` |

Every success was appended to `/home/hatch/workspace/muse-hub-tests/test-repo.muse-github-snapshot-sync.json` by writing a unique `.tmp-<id>` file and atomically replacing the record. Sync metadata was excluded from every NUL-delimited, NUL-terminated push manifest. Each subsequent push has saved list_commits and selected-path base/head comparison evidence under `step6b-resume-<label>-pre-commits.json` and `-path0-{base,head}.json`. No divergence was observed.

Issue: [xy3293/muse-hub-test #1](https://github.com/xy3293/muse-hub-test/issues/1). Comment: [6762499129](https://github.com/xy3293/muse-hub-test/issues/1#issuecomment-6762499129), added once and edited once. No T-904 comment was added; it has no signal yet and uses the same Issue as its task specification.

**Approval requests issued: 13** (12 in the resume run + 1 for the Test 7 BOARD push): 9 push-files, 1 issue_write, 1 add_issue_comment, 1 update_issue_comment, 1 issue_read/get_comments (the connector classifies this read as approval-required). Thus **12 mutating connector calls**, plus 1 approved read. All returned successful provider results; no expiry, rejection or retry occurred. The CLI exposes no approval operation ID/UI receipt, so independent visual card-count verification is unavailable. `step6b-resume-write-requests.jsonl` records the 12 resume-run invocations; the Test 7 BOARD push approval is recorded as `connector-attempt-df1b8c550de06b93ee88cf7dc71eb340e3b546dfa628fd141e1a3aa0b747ad6d` (observed decision: allow_once, approved). Prior failed run's one approval is historical and excluded from this resume count.

## Poll results and cursors

| Poll | RESULT | Events stored | Cursor before → after | health.remaining |
| --- | --- | --- | --- | --- |
| baseline | silent / no-change | 0 | `943a91b2b297ec71a899a50da8825c2dc25d0524` → `943a91b2b297ec71a899a50da8825c2dc25d0524` | 4977 |
| T01 | wake / muse-hub-activity | 3 | `943a91b2b297ec71a899a50da8825c2dc25d0524` → `01873dc5d12224ad80559203942e274a813a4d43` | 4934 |
| T02 | wake / muse-hub-activity | 4 | `01873dc5d12224ad80559203942e274a813a4d43` → `7b84059db2379ad1ba093b82c47dd4db43f0e9a5` | 4922 |
| T03 | wake / muse-hub-activity | 5 | `7b84059db2379ad1ba093b82c47dd4db43f0e9a5` → `94f03f6465070dfbfa71e9da989953eb525d666e` | 4906 |
| T04 | wake / muse-hub-activity | 5 | `94f03f6465070dfbfa71e9da989953eb525d666e` → `94f03f6465070dfbfa71e9da989953eb525d666e` | 4902 |
| T15 | silent / no-change | 5 | `94f03f6465070dfbfa71e9da989953eb525d666e` → `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` | 4888 |
| test7 | wake / muse-hub-activity | 6 | `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` → `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` | 4874 |
| ack (Test 7 ACK verification) | silent / no-change | 5 | `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9` → `12cb98b7079763700557be79ee98652a900eb515` | 4852 |

Exact RESULT payloads (full event IDs and SHAs):

baseline:

```text
RESULT {"decision":"silent","reason":"no-change","payload":{"head":"943a91b2b297ec71a899a50da8825c2dc25d0524","unacked_count":0,"needs_attention_count":0,"comments_total":0}}
```

T01:

```text
RESULT {"decision":"wake","reason":"muse-hub-activity","payload":{"events":[{"event_id":"result:T-902:node-1:01873dc5d12224ad80559203942e274a813a4d43","kind":"result_revision","task_id":"T-902","node_id":"node-1","source_commit_sha":"01873dc5d12224ad80559203942e274a813a4d43","is_reminder":false,"is_transition":false},{"event_id":"result:T-900:node-1:d62c24d7adf40c99d9fbdb1beca07c356e5874c1","kind":"result_revision","task_id":"T-900","node_id":"node-1","source_commit_sha":"d62c24d7adf40c99d9fbdb1beca07c356e5874c1","is_reminder":false,"is_transition":false},{"event_id":"result:T-901:node-1:1b2cf75aeeb92f0b60349c24cb1a01a516641cc4","kind":"result_revision","task_id":"T-901","node_id":"node-1","source_commit_sha":"1b2cf75aeeb92f0b60349c24cb1a01a516641cc4","is_reminder":false,"is_transition":false}],"needs_attention":[],"head":"01873dc5d12224ad80559203942e274a813a4d43","unacked_count":3,"needs_attention_count":0}}
```

T02:

```text
RESULT {"decision":"wake","reason":"muse-hub-activity","payload":{"events":[{"event_id":"result:T-900:node-1:7b84059db2379ad1ba093b82c47dd4db43f0e9a5","kind":"result_revision","task_id":"T-900","node_id":"node-1","source_commit_sha":"7b84059db2379ad1ba093b82c47dd4db43f0e9a5","is_reminder":false,"is_transition":false}],"needs_attention":[],"head":"7b84059db2379ad1ba093b82c47dd4db43f0e9a5","unacked_count":4,"needs_attention_count":0}}
```

T03:

```text
RESULT {"decision":"wake","reason":"muse-hub-activity","payload":{"events":[{"event_id":"result:T-903:node-1:94f03f6465070dfbfa71e9da989953eb525d666e","kind":"result_revision","task_id":"T-903","node_id":"node-1","source_commit_sha":"94f03f6465070dfbfa71e9da989953eb525d666e","is_reminder":false,"is_transition":false}],"needs_attention":[],"head":"94f03f6465070dfbfa71e9da989953eb525d666e","unacked_count":5,"needs_attention_count":0}}
```

T04:

```text
RESULT {"decision":"wake","reason":"muse-hub-activity","payload":{"events":[{"event_id":"result:T-903:node-1:94f03f6465070dfbfa71e9da989953eb525d666e","kind":"result_revision","task_id":"T-903","node_id":"node-1","source_commit_sha":"94f03f6465070dfbfa71e9da989953eb525d666e","is_reminder":false,"is_transition":false}],"needs_attention":[],"head":"94f03f6465070dfbfa71e9da989953eb525d666e","unacked_count":5,"needs_attention_count":0}}
```

T15:

```text
RESULT {"decision":"silent","reason":"no-change","payload":{"head":"9d4e3b985b7de3b12e226cde2b650d8b70ec15ad","unacked_count":5,"needs_attention_count":0,"comments_total":1}}
```

test7:

```text
RESULT {"decision":"wake","reason":"muse-hub-activity","payload":{"events":[{"event_id":"result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9","kind":"result_revision","task_id":"T-904","node_id":"node-1","source_commit_sha":"bc3206e97018cebe7a4accf0ff1fdfe2b63943a9","is_reminder":false,"is_transition":false}],"needs_attention":[],"head":"bc3206e97018cebe7a4accf0ff1fdfe2b63943a9","unacked_count":6,"needs_attention_count":0}}
```

ack (Test 7 ACK verification — silent because the ACK commit creates no new result event; it transitions the existing T-904 event DETECTED → ACKED, so unacked_count drops 6 → 5):

```text
RESULT {"decision":"silent","reason":"no-change","payload":{"head":"12cb98b7079763700557be79ee98652a900eb515","unacked_count":5,"needs_attention_count":0,"comments_total":1}}
```

Full run log: `step6b-resume-full-run.log`; execution transcript: `step6b-resume-run-output.txt`; machine-readable summary: `step6b-resume-run-summary.json`. Test 7 ACK verification evidence: `step6b-real-ack.{before,after}.json`, `.stdout`. Prior failed evidence remains preserved, including `step6b-before-resume-test-results.md` and the original gate label. No remote write used curl; the driver used authenticated read requests only.
