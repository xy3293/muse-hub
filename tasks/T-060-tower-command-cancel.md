# T-060：Tower 指令可取消 — pending 指令页面撤销（T9）

## 来源
Chen 直令 2026-11-18 10:01，第二批 T9。现状：pending 里的指令发错了只能等它被执行，没有撤销入口。

## 目标
指令面板上，pending 里的每条指令能点“撤销”；撤销后消费端跳过它，不再执行。

## 设计（总控已定，照做，不要另发明协议）
1. **撤销走现有通道，不动 8899**：前端提交 `{ action: 'cancel', target: 'total', payload: { cancel_id: '<待撤销的 CMD-id>' } }`，经现有 `POST /api/command` 发出（`commands.ts` 的 submit 路径 + `X-CT-Command-Token`，401 仍报「指令 token 不正确」）。8899 只负责像其它指令一样写 pending 文件，**不需要改**。
2. **消费端语义（总控侧执行，不在本次代码范围内，写进协议文档备查）**：总控收到 action=cancel 后，`git mv commands/pending/<target>.json → commands/cancelled/<target>.json`，并写 `commands/done/<target>.result.json`（`{ id, status: "cancelled", by: "总控", at, detail: "已撤销", artifacts: [] }`）。若目标已有 done 结果（done/rejected/failed），撤销判 rejected：撤销指令自己的 result 写 rejected（detail“目标已处理，撤销无效”），目标原样不动。撤销指令自己也总有一份 `commands/done/<cancel-id>.result.json`。
3. **协议文档**：新建 `frontend/src/api/commands-protocol.md`（与 `commands-auth.md` 并列），写清 5 个 action（dispatch/board_status/notify_node/query/cancel）、pending/result 文件格式、`cancelled` 状态值、`commands/cancelled/` 目录、上述竞态规则。这是前端、8899、总控三方共读的契约。**不碰冻结的 1.1.0 契约**（指令通道不在 1.1.0 内，是 8899 层）。
4. **前端**：`CommandsView.tsx` 的 pending 列表每条加“撤销”按钮；**两次点击确认**（第一点击进入待确认态，第二点击才提交，防误触）；提交后显示指令 ID +「已入队，预计 1–3 分钟被处理」（与其它指令一致）；done 列表把 status `cancelled` 渲染为「已撤销」（与 done/rejected/failed 区分）；30 秒自动刷新接管后续状态变化（T-054 已有，不动它）。静态模式：不显示撤销按钮；任何提交尝试仍走 `COMMAND_UNAVAILABLE`（T-051 规则：静态模式不假装能写）。
5. **类型**：`commands.ts` 的 `CommandRequest` 增加 cancel 变体；`CommandEntry.result.status` 已是 string，`cancelled` 直接可用，不用改类型结构。

## 约束
- 只改前端 + 协议文档；不改 8899、不改巡逻脚本、不改后端、不新增凭据、不写真实 token 值进代码或测试。
- 静态模式不假装能写；token 缺失时提交按钮禁用（T-053 已有逻辑，复用）。

## 完成标准
- `bun test` 全过（新增：撤销提交 payload 形状、cancelled 渲染、静态模式无撤销按钮、401 处理）；`npm run build` 通过。
- grep 确认无真实 token 值；diff 只有本次 intended 文件。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（bun test 输出 + build 输出）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
