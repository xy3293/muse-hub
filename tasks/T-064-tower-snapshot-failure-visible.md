# T-064：Tower 快照失败要可见（T13）

## 来源
Chen 直令 2026-11-18 10:01，第二批 T13。现状：导出失败时页面只表现为数据变旧，不说明原因；用户无法区分“还没到刷新时间”与“导出挂了”。

## 目标
导出失败时，页面顶部明确写「上一次导出失败：<原因>，数据停留在 <上次成功导出时间>」。不许只是数据变旧。

## 设计（总控已定，照做）
1. **导出状态文件**：`deploy/snapshot-export.sh` 每次运行（成功或失败）都写 `export-status.json`（与 snapshot.json 同目录两份：`tower-static/export-status.json` 与 `tower-static/dist/export-status.json`；原子写，写完 best-effort `setfacl -m u:muse-tower:r--`）。内容：`{last_attempt_at, last_success_at, last_failure_at, last_failure_reason}`。成功时 last_failure_at/reason 保持上一次的值（不清空——失败仍是“上一次失败”）；失败时更新 last_failure_at/reason，last_success_at 不动。
   - 原因取导出失败的原始错误（一行，截断 100 字），如 `git fetch failed`、`exporter TimeoutError`；不要自己编原因，拿不到就写「未知原因」。
2. **后端（live 模式）**：读 `~/hooks/state/muse-hub/logs/snapshot-refresh.log`（T-056 告警解析已读此文件，复用解析），在运行时数据里加 `last_export_failure: {at, reason} | null` + `last_export_success_at`。文件缺失/无失败记录时为 null，不 fail 端点。契约走 1.1.1（新字段 OPTIONAL），**不改冻结的 1.1.0 文件**。
3. **前端**：顶部固定健康栏（T-055 的 DataTime）加失败横幅：仅当最近一次尝试失败（last_failure_at 晚于 last_success_at）时显示，红色，文案固定为「上一次导出失败：<原因>，数据停留在 <上次成功导出时间>」（时间本地格式；无成功记录时写「暂无成功导出」）。最近一次尝试成功时不显示横幅。live 模式读后端字段，静态模式读 `./export-status.json`（相对路径，`cache: 'no-store'`；文件缺失时无横幅，不报错）。
4. **静态快照**：export-status.json 不进 snapshot.json（snapshot.json 只在成功时写，失败时它本身就是旧的）；前端静态模式单独取 export-status.json。

## 约束
- 不改导出成功路径、不改快照格式、不改 T-055 的年龄色带（失败横幅是额外一行，不是替代）；不新增定时任务、不新增凭据、不输出 token 值。
- 原因只取原始错误，不编造；路径用绝对路径（不要用 $HOME 拼关键路径，见 T-052 教训）。

## 完成标准
- 后端 pytest 全过（新增：日志解析 last_failure/last_success、无失败记录、文件缺失降级）；前端 bun test 全过（新增：失败横幅渲染、成功时无横幅、静态缺文件无横幅、原因截断）；`npm run build` 通过。
- 隔离验证：模拟一次导出失败（坏 base-url 或断网），export-status.json 正确记录失败原因且 last_success_at 不动；随后成功一次，横幅消失（贴两次文件内容）。
- LIVE 验证：后端端点返回的 last_export_failure 与日志最后一行 FAILED 一致（贴输出）。
- 快照导出脚本两份 diff 一致；`bash -n` 通过。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（pytest + bun test + build 输出 + 失败/成功两次 export-status.json + LIVE 端点输出）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
