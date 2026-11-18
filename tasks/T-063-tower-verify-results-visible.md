# T-063：Tower verify.sh 结果可视化（T12）

## 来源
Chen 直令 2026-11-18 10:01，第二批 T12。现状：`deploy/verify.sh` 只能在终端跑，页面看不到“最近一次自检什么时候跑的、几项过”。

## 目标
快照里加一个自检区块，页面（RuntimeView）显示：最近一次自检时间、通过 X/Y、失败 Z 项，可展开看逐项 PASS/FAIL。

## 设计（总控已定，照做）
1. **复用快照导出，不新增 timer/cron**：`deploy/snapshot-export.sh` 每次导出时先跑一次 verify.sh（`timeout 60`），把原始输出 + 退出码存临时文件；`frontend/scripts/export_snapshot.py` 解析它，生成结构化结果并写进两处：① `snapshot.json` 的 `verify` 字段（前端静态模式直接读）；② `runtime/verify-state.json`（后端 live 模式读）。
   - 解析规则：行首 `PASS ` → pass，`FAIL ` → fail，`WARN ` → warn；`通过 X/Y，失败 Z 项` 一行作交叉核对（对不上时以逐行计数为准，detail 注明）。结果 JSON：`{ran_at, exit_code, total, passed, failed, warned, checks: [{name, status, detail}]}`。
   - verify 本身失败/超时不影响快照导出：超时记一条 status 为 `timeout` 的结果（exit_code 写超时值）；无原始输出时沿用上一次的 verify-state.json（不清空、不写空结果）。
   - 手动跑 export_snapshot.py 且无新 verify 输出时：沿用现有 verify-state.json，不覆盖。
2. **后端**：新增 `GET /api/v1/runtime/verify`（或并入 `/api/v1/runtime`——选改动最小的），读 `runtime/verify-state.json`；文件缺失/损坏/ran_at 超过 20 分钟 → 该项 unavailable（source_meta 注明），不 fail 全端点。契约走 1.1.1（新字段 OPTIONAL），**不改冻结的 1.1.0 文件**。
3. **前端**：RuntimeView 加「部署自检」区块：最近一次自检时间（本地格式）、通过 X/Y、失败 Z 项，可展开看逐项（PASS 绿 / FAIL 红 / WARN 黄）；无数据或过期显示「暂无自检数据」/「数据过期」。
4. **部署收尾（规则 ⑲）**：改 `deploy/snapshot-export.sh` 必须同步持久副本 `~/hooks/scripts/snapshot-export.sh`（两份 diff 一致）；导出后 best-effort 给 verify-state.json 补 `setfacl -m u:muse-tower:r--`（像采样器一样；acl 缺失时忽略，下次导出再补）。修复脚本已覆盖 snapshot-export.sh 的恢复，不另加项。

## 约束
- 只读展示 + 导出时跑自检：不改 verify.sh 本身、不改自检判据、不新增定时任务、不新增凭据、不输出 token 值。
- verify 超时/失败不阻塞快照导出；路径用绝对路径（不要用 $HOME 拼关键路径，见 T-052 教训）。

## 完成标准
- 后端 pytest 全过（新增：fixture verify-state.json 解析、缺失/过期降级）；前端 bun test 全过（新增：自检区块渲染、展开、过期态）；`npm run build` 通过；解析函数有单测（正常/超时/空输出三种）。
- 隔离实例 LIVE 验证：手动跑一次导出脚本，`GET /api/v1/runtime/verify` 返回 200 且与 verify.sh 当次输出一致（逐项对得上，贴输出）。
- 快照验证：手动导出一次，`snapshot.json` 含 `verify` 字段且内容与 verify-state.json 一致。
- `deploy/verify.sh` 跑一次，全 PASS（贴输出）；快照导出脚本两份 diff 一致；`bash -n` 通过。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（pytest + bun test + build 输出 + LIVE /api/v1/runtime/verify 输出 + 快照 verify 字段 + verify.sh 输出）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
