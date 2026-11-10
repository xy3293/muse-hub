# Muse Hub 交付报告（2026-11-10）

## 【部署信息】

Hook ID：`director-watch-muse-hub`；脚本：`~/hooks/scripts/director-watch-wrapper.sh`（调用 `director-watch-poll.sh`）；状态持久目录：`~/hooks/state/muse-hub/`。

跨重启已确认：Step 1 基线的 02:39 状态文件在 ~02:45 重启后存活，Stage A 审计已核实。生产扫描游标为 `fd0ba0c8628af1b8f30bfd140634a8cb335e3920`；Issue #1 评论 2 条（ID `6747509854`、`6747528416`），均已处理。Step 6b 结束时 Hook 仍关闭，生产仓库未写入。

## 【当前实现盘点】

已存在的功能：结果版本独立登记、扫描游标与 ACK 分离、评论新增/编辑关联既有事件、无关总控提交不误 ACK、验收收据持久化及复用、BOARD 写入经审批并核实远端、精确 ACK 后更新事件。Test 7 已在隔离 real-home 串通收据恢复与轮询器确认。

缺失和风险：真实评论删除、真实 Compare 大分页、T02 收据隔离及 T15 终态保持子项尚无对应实测；生产 Hook 已于 Step 7 重开并对账通过（见末节）。

运行时能力不确定项：Muse 通知实际到达时延、托管 Hook 原 worker 的原生恢复接口，以及 kill 信号中断后的恢复行为，现有证据未确认；收据检查点恢复已有实测。

## 【修改清单】

涉及文件：`~/hooks/scripts/director-watch-wrapper.sh`、`~/hooks/scripts/director-watch-poll.sh`、`step6b-resume.py`、测试仓库 `README.md`、`BOARD.md`、`/home/hatch/workspace/muse-hub-tests/test-repo.muse-github-snapshot-sync.json`。

兼容性/迁移：Step 6b 状态隔离于 real-home，受保护的 15 个文件哈希未变；生产状态迁移留待重开时对账，保留未 ACK 队列。

状态机及 event_id/ack 规则：结果以 `result:<task_id>:<node_id>:<完整源提交 SHA>` 标识、评论信号按评论 ID 与更新时间关联；收据绑定事件和源版本，扫描不等于确认，只有核实可信 author-login、对应 BOARD 变更及 `MUSE-ACK task=<task_id> node=<node_id> event=<event_id> verdict=PASS` 后才 ACK（Test 7 实测 `DETECTED → ACKED`）。

## 【验证证据】

主证据：`/home/hatch/workspace/muse-hub-tests/ack/step6b-test-results.md`。以下状态直接引用既有证据，未重新验证。

| 测试编号 / 检查 | 结果 | 证据文件名 / 说明 |
| --- | --- | --- |
| 本地回归 | PASS | `step6b-resume-regression-output.txt`：74 PASS, 0 FAIL；exit 0。 |
| Token / authenticated gate | PASS | `step6b-real-resume-gate-20261110.rate.json`。 |
| 空仓库 | PASS | `step6b-resume-empty-refs.stdout`、`step6b-resume-empty-commits.json`。 |
| baseline 快照 | PASS | `step6b-resume-baseline-push.json`、`step6b-resume-baseline-commits.json`。 |
| init / baseline poll | PASS | `step6b-real-baseline.{before,after}.json`、`step6b-real-baseline.stdout`。 |
| T01 | PASS | `step6b-real-T01.{before,after}.json`、`step6b-real-T01.stdout`；连续提交全部登记。 |
| T02 version identity | PASS | `step6b-real-T02.{before,after}.json`、`step6b-real-T02.stdout`；新版本独立事件，旧事件不变。 |
| T02 收据隔离 / ACKED 字节保持子项 | NOT TESTED | 设计如此：该场景未创建真实 worker 收据，也没有 ACKED 事件；不得以版本身份测试替代。 |
| T03 | PASS | `step6b-resume-issue-create.json`、`step6b-resume-comment-add.json`、`step6b-real-T03.after.json`；评论关联结果，无额外 issue_signal。 |
| T04 comment edit | PASS | `step6b-resume-comment-{edit,read}.json`、`step6b-real-T04.after.json`；同一评论编辑后识别更新时间。 |
| T04-delete / delete-add count cancellation | NOT TESTED | 设计如此：完整 live 工具目录无 delete-comment 工具，未执行删除。 |
| T15 unrelated director commit | PASS | `step6b-resume-T15-author.json`、`step6b-real-T15.{before,after}.json`；无 MUSE-ACK 的总控提交未确认事件。 |
| T15 终态保持子项 | NOT TESTED | 设计如此：该真实场景仅覆盖既有 DETECTED 状态，无 ACKED/REJECTED/SUPERSEDED 事件。 |
| T18-real | NOT TESTED | 设计如此：Compare 分页需 more than 100 commits，超出 20-commit budget；本地 T18-sim 为独立证据。 |
| T-904 / Test 7 准备 | PASS | `step6b-real-test7.{before,after}.json`、`step6b-real-test7.stdout`、`step6b-test7-handoff.md`。 |
| Test 7 interruption/recovery/ACK | PASS | `step6b-real-ack.{before,after}.json`、`step6b-real-ack.stdout`及 real-home 内收据、事件文件；时间线见下。 |
| 最终远端对账 | PASS | 主证据记录 ACK 后远端读取及轮询器 ACKED 转换；`step6b-resume-final-commits.json`、`step6b-resume-final-board.json`仅为 ACK 前快照。 |
| 生产保护 | PASS | `step6b-resume-protected-{before,after}.json`、`step6b-resume-hook-status.json`；受保护文件未变，Hook 仍关闭。 |

真实“abort → 恢复 → ACK”时间线（Test 7）：

- 准备：T-904 源提交 `bc3206e97018cebe7a4accf0ff1fdfe2b63943a9`；事件 `result:T-904:node-1:bc3206e97018cebe7a4accf0ff1fdfe2b63943a9`。
- Worker A：验收 5/5 checks PASS，保存 verdict PASS 收据；mtime `2026-11-10 08:26:54.780583565 +0000`，998 bytes，SHA-256 `9f4d2d76a75b6ed96e50bb9f6ca12910eed93dc652d0dde790124ae44b8f8a2c`。随后在 SAVE_RECEIPT 检查点受控停止，不是 kill 信号。
- Worker B：验证并复用同一收据；前后哈希、mtime 和大小相同，无重复语义验收、无新收据、无收据修改；先对账远端 BOARD 的 T-904 待验收状态，再经 Chen 批准推送 BOARD 和精确 MUSE-ACK，提交 `12cb98b7079763700557be79ee98652a900eb515`。
- 远端核实：ACK 提交 author 为 `xy3293`，仅修改 `BOARD.md`，提交信息恰为 MUSE-ACK 行；T-904 完成，其余行不变。
- 轮询器确认：`main_acked_at=2026-11-10T08:29:50Z`，事件 `DETECTED → ACKED`，`main_ack.acked=true`，`ack_method=muse-ack-commit`，`ack_commit_sha=12cb98b7079763700557be79ee98652a900eb515`，verdict PASS；游标推进至该 ACK 提交，`unacked_count 6 → 5`。轮询后收据哈希、mtime 仍未变。Worker B 与推送的独立时间戳未在主证据给出。

## 【Quota】

优化前后 agent turns / 重复验收次数：尚未测得。额度节约幅度：尚未测得。Test 7 的收据复用不作为前后对照测量。

## 【审批和安全】

现有证据未见未经用户批准的 GitHub 写入。审批请求共 13 张：恢复运行 12 张，Test 7 BOARD 推送 1 张；其中 12 次变更调用，1 次被连接器归为需审批的读取。均成功，无过期、拒绝或重试。CLI 不提供审批操作 ID/UI 收据，无法独立目视核对卡片数；记录见 `step6b-resume-write-requests.jsonl`，Test 7 审批记录为 `connector-attempt-df1b8c550de06b93ee88cf7dc71eb340e3b546dfa628fd141e1a3aa0b747ad6d`，决定 `allow_once`。

审批过期处理：保留事件及收据，停留 `WAITING_APPROVAL` 并重新申请；推送状态未知时先读远端对账，核实生效才继续确认，未生效且批准仍有效才重试，不得绕过审批或提前 ACK。本轮无审批过期实测。

回滚步骤：由总控停用 Hook 并备份当前配置、脚本、状态；导出全部未 ACK 事件及收据；恢复已备份的旧配置、脚本并接回旧 Pending 入口；按远端 ACK 与本地队列对账后再恢复运行。不得删除未 ACK 事件，不得改写成功的远端结果制造通过。

## 【未解决风险】

- Muse 投递延迟仍不可控。
- author-login ACK 认证本身较弱（设计如此，无 GPG/签名校验）。

## 【报告位置与后续执行】

报告本地路径：`/home/hatch/workspace/muse-hub-delivery-report-2026-11-10.md`。

Hook 重开与对账（Step 7 执行，2026-11-10 16:50 +08）：Hook `director-watch-muse-hub` 已启用，仍指向 `~/hooks/scripts/director-watch-wrapper.sh`，轮询 300 秒；启用前 dry_run 返回 silent / no-change（head `fd0ba0c8`，unacked 0，needs_attention 0，comments_total 2）。完整对账：Compare `fd0ba0c8...HEAD` 为 identical、0 个新提交；Issue #1 评论恰为 2 条（ID `6747509854`、`6747528416`，均已处理，无新增/编辑/删除）；游标未移动（仍为 `fd0ba0c8`，与远端 HEAD 一致）；无 pending、无 NEEDS_ATTENTION；唯一事件 T-001 为 ACKED。Stage B 至此结束。
