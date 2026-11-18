# T-061：Tower 节点页显示“最近一次指令 + 最近一次桥发”（T10）

## 来源
Chen 直令 2026-11-18 10:01，第二批 T10。现状：节点页只显示状态（active/idle/stale）与当前任务，回答不了“这个号最近被谁叫、什么时候、结果如何”。

## 目标
节点页每号显示两行：最近一次指令（谁发的、什么时候、结果如何）+ 最近一次桥发（task_id、什么时候、结果如何）。无数据时显示「暂无」，不编造。

## 数据源（总控已核实，照做）
1. **最近一次指令**：muse-hub `commands/done/*.result.json` + `commands/pending/*.json`（后端经 GitHub live 读，与现有 BOARD 读取方式一致）。取该节点的最新一条：notify_node（target=node-N）或 dispatch（payload.assignee=node-N），按 created_at/at 取最大。展示：指令 id、action、时间、status、detail（截断 80 字，title 悬停看全文）。
   - 注意：T-060 新增的 `cancelled` 状态也要能显示（若最新一条是撤销结果，照实显示「已撤销」）。
2. **最近一次桥发**：总控本机三个发送日志 `~/workspace/node3-browser-poc/send_log.json`（node-3）、`send_log_node1.json`（node-1）、`send_log_node2.json`（node-2）。格式为 JSON dict（key 为发送流水号，插入顺序即时间顺序，取最后一项为最近一次）；每条 `{task_id, account, status, reply, elapsed_ms, needs_approval, error, sent_at}`——`sent_at`（UTC ISO，如 `2026-11-18T02:07:58Z`）是总控 2026-11-18 刚补的字段，**老记录没有 sent_at，读到缺失时时间显示「未知」，不许用文件 mtime 或 task_id 猜时间**。展示：task_id、sent_at、status（ok/error/blocked_approval/timeout/unknown）、reply 预览（截断 80 字）或 error。
   - 后端以 muse-tower 身份读这三个文件：读权限由总控在验收时补（现场 ACL + 恢复清单见改动项 3）；文件是 root 0600 且原子替换（mkstemp + os.replace），`send_node.py` 每次写完会 best-effort 补 `setfacl -m u:muse-tower:r--`。读不到时后端把该项记为 unavailable（source_meta 注明），不让整个端点失败。Codex 测试用 fixture，不依赖现场 ACL。
3. **契约**：Node 模型加两个 OPTIONAL 字段 `last_command`、`last_bridge_send`，走 1.1.1 契约（T-047 模式），**不改冻结的 1.1.0 文件**。

## 改动项（全部）
1. 后端：Node 模型 + service 读取（指令：GitHub commands/done+pending；桥发：三个本地 send_log 文件）；读不到任一来源时该项 unavailable，不 fail 整个 `/api/v1/nodes`。
2. 前端：NodesView 每节点加两行（最近一次指令 / 最近一次桥发）；无数据「暂无」；时间用本地格式；reply/detail 截断 80 字（title 悬停看全文）。
3. 部署收尾（规则 ⑲：新常驻依赖同一次改动进恢复清单）：`deploy/repair-after-vm-replacement.sh`（仓库 + 持久副本一致）加 send_log 三文件读 ACL 恢复（`u:muse-tower:r--`）+ 目录 `~/workspace/node3-browser-poc/` 的 `u:muse-tower:r-x`；`deploy/verify.sh` 加检查（send_log 三文件 muse-tower 可读；修复脚本含 send_log ACL 行）。判据沿用 `sudo -n -u muse-tower test -r`（T-058 模式）。
4. 静态快照：nodes 快照已含新字段（exporter 原样导出），前端静态模式同样显示；无数据「暂无」。

## 约束
- 只读，不写：后端不写 send_log、不写 commands、不发桥消息；不改 send_node.py（总控侧已改好）；不新增凭据、不输出 token 值。
- 老记录无 sent_at 时时间写「未知」，不许猜；任一来源不可读时该项 unavailable，不 fail 全端点。
- 路径用绝对路径（不要用 $HOME 拼关键路径，见 T-052 教训）。

## 完成标准
- 后端 pytest 全过（新增：fixture send_log（含无 sent_at 老记录）+ fixture commands/done 的读取与排序、来源不可读降级）；前端 bun test 全过（新增：两行渲染、无数据暂无、截断）；`npm run build` 通过。
- 隔离验证：模拟一次原子替换（mkstemp + os.replace 写新记录）后，muse-tower 仍可读该文件（贴 `sudo -n -u muse-tower test -r` 结果）；或如实报告读不到并给出原因（不许编造通过）。
- 隔离实例 LIVE 验证：用真实 send_log + commands 数据起一个隔离后端实例，`GET /api/v1/nodes` 返回 200 且三节点含新字段（贴输出）；muse-tower 真实可读性由总控验收时核（ACL 已补后重启后端再验）。
- `deploy/verify.sh` 跑一次，全 PASS（贴输出）；修复脚本两份 diff 一致；`bash -n` 通过。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（pytest + bun test + build 输出 + 隔离实例 /api/v1/nodes 输出 + verify.sh 输出 + 原子替换可读验证）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
