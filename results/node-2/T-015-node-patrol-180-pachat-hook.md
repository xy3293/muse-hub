# T-015 节点巡逻 180 秒＋Pachat 盯梢 Hook

- **任务**：T-015 节点巡逻 180 秒＋Pachat 盯梢 Hook
- **负责人**：node-2
- **Issue**：https://github.com/xy3293/muse-hub/issues/16
- **任务书版本**：v1
- **核查／执行时间**：2026-11-14 02:47–02:50 CST（2026-11-13 18:47–18:50 UTC）；Stage B 补测 2026-11-14 02:55–02:57 CST（2026-11-13 18:55–18:57 UTC）
- **结论先行**：Stage A 完成，Stage B 完成（Hook 约 46 秒内唤醒，总群回帖 #26）。是否正式通过以总控在 GitHub 定为准。

## 结论

- Stage A：完成。GitHub 巡逻 Hook 已是 180 秒、已启用；Pachat 盯梢 Hook 已新装、120 秒一轮、已启用，两处 dry-run 均为 silent。
- Stage B：完成。总控在总群 @ 到达后约 46 秒，Pachat 盯梢 Hook 叫醒一轮（invocation `f677dc07-406f-421a-b638-8195467bfe76`），已在总群回帖 #26 确认。是 Hook 叫醒、不是定时巡查看到的。

## Stage A1：GitHub 巡逻改 180 秒

- 本回合开始时核查：`hooks.view muse-hub-patrol` 显示 `poll_interval_secs=180`、`enabled=true`，`updated_at_ms=1794497562622`。改动本身已在本回合开始前到位，本回合未重复改注册，只核对并记录（任务书：若已是 180，直接核对并记录，不重复改）。
- dry-run 验证：`hooks.dry_run muse-hub-patrol`，`silent`，原因 `board-unchanged`，`head=f50cdc9ae64bbf3ffe41b898e17b30b8a52b0b82`，`patrol_version=2026-11-11.3`，invocation `a4c41230-ba72-4f07-8c82-98eaa09a3a92`，耗时 1172 ms。
- 改后核对：`hooks.view` 仍为 180 秒、`enabled=true`。脚本本身未改。

## Stage A2：新装 Pachat 盯梢 Hook（120 秒一轮）

- CLI 验证：`node ~/.pachat/pachat.mjs inbox --json` 能返回 JSON。核查时 `needsYou=0`、`unreadGroups=0`、`cursor=55411`；总群 `lastSeq=24`、总控与 2 号 `lastSeq=5`，均无未读。只用本号自己的 CLI 与 token，未用总控或任何人的 token。
- 脚本：`~/hooks/scripts/pachat-inbox-watch.sh`，4053 字节，`bash -n` 通过，`.last-good` 备份已留（同名文件，内容一致）。grep 检查写坏模式（`if[[`、`if!`、`"=~ *]]`）无命中；脚本内无秘密，token 由 CLI 自己读 `~/.pachat/token`。
- 脚本逻辑：每轮 `timeout 20 node $HOME/.pachat/pachat.mjs inbox --json`；取消息失败则 log 后 silent；wake 条件为 `mentionsYou + repliesToYou + fromYourOwner + recalled > 0`，或 `memberCount == 2` 且 `unread > 0`；其余 silent；去重为同一群＋同一 lastSeq 一小时内不重复 wake，状态文件在 `~/hooks/state/pachat/inbox-state.json`，dry-run 不写状态；wake payload 只含群 id、名称、lastSeq 与计数，不含消息正文。
- 注册：`hooks.add`，id `pachat-inbox-watch`，`poll_interval_secs=120`，`script_timeout_secs=60`，delivery 为本号主聊。
- dry-run 验证：`silent`，原因 `no-new-message-for-me`，invocation `242e4419-bcfc-4ce0-87df-6574cbefda1a`，耗时 654 ms。
- 启用后核对：`hooks.enable` 后 `hooks.view` 显示 `enabled=true`、120 秒。启用后首次真实运行 invocation `e68503c8-ccd0-40cb-8595-ed8a3a07c2f9`，`silent`，原因 `no-new-message-for-me`，耗时 555 ms。

## Stage B：真消息唤醒实测（完成）

- 测试 @ 到达：2026-11-13T18:55:07.284Z（2026-11-14 02:55:07 CST），总群（群 id `deqv6pzanBeowpj4`）seq 25，发件人 Chen 总控muse，内容：“T-015 Stage B 唤醒测试：@ Chen Muse[node-2]，请确认你的 Pachat Hook 是否唤醒（看 Hook 日志，不是定时巡逻）。1 号、3 号请不要回这条。”
- Wake 记录：Pachat 盯梢 Hook 日志 `~/hooks/logs/pachat-inbox-watch.jsonl`，invocation_id `f677dc07-406f-421a-b638-8195467bfe76`，`started_at_ms=1794596153377`（18:55:53.377Z），`outcome=wake`，`reason=pachat-message-needs-you`，耗时 999 ms。@ 到达至 Hook 轮询相隔约 46 秒，在任务书约 2 分钟标准内。
- 是 Hook 叫醒、不是定时巡查：上一轮 Hook 轮询 18:53:53 UTC 为 `silent`（`no-new-message-for-me`），发生在 @ 到达之前；本轮是 Hook 120 秒轮询直接 wake，去重状态 `~/hooks/state/pachat/inbox-state.json` 记为该群 lastSeq 25。
- 群里确认回帖：总群 seq 26（reply to #25），内容：“收到 #25：Pachat Hook 在约 46 秒内叫醒我一轮，wake 记录 invocation_id f677dc07-406f-421a-b638-8195467bfe76（@ 消息 18:55:07 UTC，Hook 轮询 18:55:53 UTC，相隔约 46 秒），是 Hook 叫醒、不是定时巡查看到的。T-015 Stage B 是否通过以 GitHub 推送为准，请总控定。”CLI 返回 `sent: true`。
- 先前测试请求：2026-11-14 02:48 CST 左右，在总控与 2 号单聊（群 id `3uV1tER7OaX7x8Wy`）发消息 #6：“Pachat Hook 已启用，请总控在总群 @ 我一句做唤醒测试。”当时等了两个 25 秒 inbox 等待周期，总群仍无总控 @；本次 @ 于次日 02:55 CST 到达后补测通过。
- 验收：Stage B 实测通过（Hook 日志有 wake 记录、群里有确认回帖）；正式是否通过以总控在 GitHub 定为准。

## 其他说明

- 10 分钟 Pachat 收件箱定时巡查（cron `pachat-checkin`）本回合未动、未删。任务书未写它与 120 秒 Hook 是共存还是替代，本回合不擅自决定；当前事实是两者都在跑。未验证：本回合未重新核查该 cron 的启用状态。
- 推送方式：Stage A 回合先 `git pull --rebase` 同步远端（远端 HEAD `f50cdc9`，为 node-1 的审批信号探测提交），本地 APPROVAL_PROBE_001 提交被 rebase 为新 SHA `9e73e13`（原 `196e747`），工作区干净后再提交本结果文件并一次推送。推送凭据为 `gh` 登录（xy3293）＋ credential helper `!gh auth git-credential`，此前 `git ls-remote origin HEAD` 测试通过。Stage B 本回合为任务书允许的第二次推送：只改本结果文件一次推送，不发 Issue 评论。
- 未验证：无。Stage B 的 wake 分支已由真实 @ 验证通过。

## 事实与推断

- 事实：以上 Hook 注册值、dry-run invocation 与耗时、CLI 返回的计数与 cursor、Pachat 发帖 #6、两次等待均无新消息，均为本回合实际核查或执行结果。
- 推断：无。未做任何推断性结论。
