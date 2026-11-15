| T02 version identity | PASS | T-900 v2 copied from fixture and committed; old/new event_ids are `result:T-900:node-1:<v1/v2 SHA below>`. Old event JSON unchanged; exactly one new result in RESULT, four stored events. `step6b-real-T02.{before,after}.json` and `.stdout`. |
| T02 real receipt isolation / ACKED byte-preservation | NOT TESTED | No real worker receipt was created; no ACKED event exists. These optional subcases are not claimed as PASS. |
| T15 unrelated director commit | PASS | BOARD-T15 copied and pushed; `author.login=xy3293`, no MUSE-ACK line (`step6b-resume-T15-author.json`). Silent/no-change; all five events main_ack.acked=false, every state unchanged; `step6b-real-T15.{before,after}.json`. |
| T15 terminal-state preservation | NOT TESTED | This real run has no ACKED/REJECTED/SUPERSEDED event; only existing DETECTED states were exercised. |
| T15 | `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` |
| T02 | wake / muse-hub-activity | 4 | `01873dc5d12224ad80559203942e274a813a4d43` → `7b84059db2379ad1ba093b82c47dd4db43f0e9a5` | 4922 |
| T15 | silent / no-change | 5 | `94f03f6465070dfbfa71e9da989953eb525d666e` → `9d4e3b985b7de3b12e226cde2b650d8b70ec15ad` | 4888 |
