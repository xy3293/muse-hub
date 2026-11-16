# T-047：Tower 卡片实测遥测 · Antigravity 独立复核意见

- 任务：T-047 Tower 卡片加“实测遥测”（借 OverClick 的呈现）
- 执行方：Codex
- 复核方：Antigravity (Gemini 3.8 Flash)
- 复核结论：**PASS（通过）**
- 复核时间：2026-11-16 UTC
- 复核目标：
  - Tower 代码提交：私有库 `xy3293/muse-control-tower` `integration` 分支 [`d70c4056718d17f0bac9823818ad3919f9a28fd3`](https://github.com/xy3293/muse-control-tower/commit/d70c4056718d17f0bac9823818ad3919f9a28fd3)
  - 交付证据：muse-hub 提交 [`70c4c54a11fd48c4177507770c3cfc0db6ac1851`](https://github.com/xy3293/muse-hub/commit/70c4c54a11fd48c4177507770c3cfc0db6ac1851) 及 `evidence/T-047-tower-telemetry/`

---

## 1. 复核要点逐项核验结果

### 要点 1：六字段是否均已加在任务卡上
- **核验判定**：**PASS**
- **证据细节**：
  - 前端组件 [`TaskTelemetry.tsx`](file:///home/hatch/workspace/muse-control-tower-integration/frontend/src/components/TaskTelemetry.tsx) 严格实现了任务书要求的 6 个字段呈现：
    1. `派发→首个提交`：`duration(t?.dispatch_to_first_commit_seconds)`
    2. `首个提交→验收`：`duration(t?.commit_to_acceptance_seconds)`
    3. `总耗时`：`duration(t?.total_seconds)`
    4. `交付提交数`：`${t.delivery_commit_count} 次`（未获取时显示 `未采集`）
    5. `验收轮次（打回）`：`${t.rejection_count} 次`（0 次且状态完成时标注 `0 次（一次通过）`）
    6. `累计额度`：`t?.quota_used ?? '未采集'`
  - 呈现样式：采用网格化定义列表（`<dl className="grid grid-cols-2 ...">`），字体为现有等宽字体（`font-mono`），与现有任务卡片设计系统规范无缝融合。
  - 挂载点：在 [`TasksView.tsx`](file:///home/hatch/workspace/muse-control-tower-integration/frontend/src/views/TasksView.tsx) 的表格单元格、卡片视图、BOARD 外未登记任务（unlisted）以及 [`DetailDrawer.tsx`](file:///home/hatch/workspace/muse-control-tower-integration/frontend/src/components/DetailDrawer.tsx) 详情抽屉中均已统一挂载，无新页面。

---

### 要点 2：三抽样任务（T-023、T-005、T-028）实测遥测与手工计算比对
- **核验判定**：**PASS（0 秒误差，完全符合 ≤ ±1 分钟标准）**
- **抽样确定性**：
  - 基线 BOARD 快照 `1c819c6ea5c708687472c02f61c29a76c2f3dddd` 中 44 个已完成任务按字典序排列后，通过伪随机数 `random.Random(47).sample(sorted(completed), 3)` 确定性抽取得到 `['T-023', 'T-005', 'T-028']`，无主观筛选。
- **复核方独立手算复核与 API 实测对照**：

| 任务 | 指标项 | 派发提交 (Commiter Time) | 首个交付提交 (Commiter Time) | 验收完成提交 (Commiter Time) | 手工精确算式 | 手工秒数 / 分钟显示 | Tower API 实测秒数 | 差值 |
|---|---|---|---|---|---|---|---|---|
| **T-023** | 派发→首交 | `78ce4ee` (08:04:23Z) | `a77a7f1` (08:09:23Z) | — | 08:09:23Z − 08:04:23Z | 300s (5 分钟) | 300s | **0s** |
| | 首交→验收 | — | `a77a7f1` (08:09:23Z) | `6dd2ec6` (08:17:17Z) | 08:17:17Z − 08:09:23Z | 474s (8 分钟) | 474s | **0s** |
| | 总耗时 | `78ce4ee` (08:04:23Z) | — | `6dd2ec6` (08:17:17Z) | 08:17:17Z − 08:04:23Z | 774s (13 分钟) | 774s | **0s** |
| | 交付提交数 | — | 仅 `a77a7f1` 1 个有效交付 | — | 计数 = 1 | 1 次 | 1 | **0** |
| | 打回次数 | — | 无 REJECT 收据，BOARD 无拒收 | — | 计数 = 0 | 0 次（一次通过） | 0 | **0** |
| | 累计额度 | — | 无归属消耗记录 | — | — | 未采集 | null / 未采集 | 一致 |
| **T-005** | 派发→首交 | `42f5ae5` (13:23:05Z) | `cd7823e` (13:28:22Z) | — | 13:28:22Z − 13:23:05Z | 317s (5 分钟) | 317s | **0s** |
| | 首交→验收 | — | `cd7823e` (13:28:22Z) | `496b973` (13:37:25Z) | 13:37:25Z − 13:28:22Z | 543s (9 分钟) | 543s | **0s** |
| | 总耗时 | `42f5ae5` (13:23:05Z) | — | `496b973` (13:37:25Z) | 13:37:25Z − 13:23:05Z | 860s (14 分钟) | 860s | **0s** |
| | 交付提交数 | — | `cd7823e` (496b973 为总控修笔误排除) | — | 计数 = 1 | 1 次 | 1 | **0** |
| | 打回次数 | — | 仅 PASS 收据，BOARD 无拒收 | — | 计数 = 0 | 0 次（一次通过） | 0 | **0** |
| | 累计额度 | — | 无归属消耗记录 | — | — | 未采集 | null / 未采集 | 一致 |
| **T-028** | 派发→首交 | `785eac5` (09:18:32Z) | `fe441a5` (09:23:37Z) | — | 09:23:37Z − 09:18:32Z | 305s (5 分钟) | 305s | **0s** |
| | 首交→验收 | — | `fe441a5` (09:23:37Z) | `2589df5` (10:13:30Z) | 10:13:30Z − 09:23:37Z | 2993s (50 分钟) | 2993s | **0s** |
| | 总耗时 | `785eac5` (09:18:32Z) | — | `2589df5` (10:13:30Z) | 10:13:30Z − 09:18:32Z | 3298s (55 分钟) | 3298s | **0s** |
| | 交付提交数 | — | 仅 `fe441a5` 1 个有效交付 | — | 计数 = 1 | 1 次 | 1 | **0** |
| | 打回次数 | — | 仅 PASS 收据，BOARD 无拒收 | — | 计数 = 0 | 0 次（一次通过） | 0 | **0** |
| | 累计额度 | — | 无归属消耗记录 | — | — | 未采集 | null / 未采集 | 一致 |

- **复算脚本执行**：复核方现场复跑 `python3 evidence/T-047-tower-telemetry/verify.py`，实时请求 Tower 后端端口 `127.0.0.1:8000`，输出确认 3/3 样本完全匹配，秒级差异均为 0。

---

### 要点 3：额度“未采集”与真实性检查
- **核验判定**：**PASS（真实查验，严格守线，无编造）**
- **复核取证**：
  1. 复核方扫描了宿主机全部 46 份收据文件（`~/hooks/state/muse-hub/receipts/*.json`），其实际 JSON 顶层字段并集仅为：
     `['checks', 'event_id', 'node_id', 'reviewed_at', 'schema_version', 'source_paths', 'status', 'summary', 'task_id', 'verdict', 'version_sha']`。不存在任何 token、cost 或额度计数键。
  2. 针对抽样任务对应的 3 份收据全文通读，收据仅记录验收检查点、reviewed_at、verdict 与摘要。
  3. 针对 `tasks/T-023-ab-tick.md`、`tasks/T-005-rule-consistency-audit.md`、`tasks/T-028-step6b-evidence-review-node1.md` 全文检查，均无可归属的任务额度记录（T-028 出现的 Token 均指安全脱敏检查中的 PAT/敏感 Token，非 LLM Token）。
  4. Codex 严格遵守任务书“取不到标 `未采集`，不许编”的要求，返回 `quota_used: null`，`quota_status: "未采集"`，并明确附带说明，未用任何运行时间估算或订阅比例假充消耗。

---

### 要点 4：数据来源合规性
- **核验判定**：**PASS**
- **证据细节**：
  - 遥测计算仅利用：
    1. 本地 Git 提交历史（`git log --first-parent --reverse -- BOARD.md` 及 `git log --no-merges`）；
    2. 现有收据目录（`~/hooks/state/muse-hub/receipts/*.json`）；
    3. Tower 私有库自身交付提交历史（`CT_TELEMETRY_DELIVERY_REPOSITORIES` 只读映射）。
  - 后端通过 `backend/muse_tower/telemetry.py` 在读取 task 时做纯内存投影与缓存，无新增定时写数据库、无埋点代码、无网络 fetch、无任何磁盘写入。
  - 前端无新增页面或跳转路由，全部复用已有卡片及抽屉组件。

---

### 要点 5：契约管理与 caveat 评估
- **核验判定**：**PASS**
- **契约状态核验**：
  - 冻结的 `contracts/muse-control-tower-stage1-openapi-1.1.0.yaml` 经 `git diff` 验证 **0 行改动**（完全冻结）。
  - 新建版本化契约 `contracts/muse-control-tower-stage1-openapi-1.1.1.yaml`，路由保持 13 paths / 17 operations 不变，仅在 `components/schemas` 中新增 `TaskTelemetry` schema，并在 `Task` schema 下新增可选字段 `telemetry: {$ref: '#/components/schemas/TaskTelemetry'}`。
- **关于 Codex 披露的 caveat 评估**：
  > **Caveat 内容**：旧 1.1.0 契约对 `Task` 定义了 `additionalProperties: false`。严格校验 1.1.0 响应格式的旧客户端（如严格 Schema 校验器）会因返回了未声明的 `telemetry` 属性而报错，需要升级引用到 1.1.1。
  - **影响面评估**：
    - 绝大多数普通 REST 客户端（如自带前端、curl、浏览器、常规 JSON 反序列化客户端）均默认忽略未定义字段，不受影响，完全向前向后兼容。
    - 仅有启用了 OpenAPI 强响应校验的测试套件或网关会触发拦截。
  - **合理性与合规性结论**：
    - 任务书明确预料到了契约演化，要求：“若需新增 schema 字段，在 REPORT 里写清新增了哪几个字段、旧客户端是否兼容”。
    - 保持 1.1.0 冻结文件不动、增加 1.1.1、并在 REPORT 和 1.1.1 OpenAPI `x-change-register` 中显式披露该兼容性细节，完全符合软件架构规范与任务书要求，属于规范透明的设计说明，**该 caveat 完全可接受**。

---

### 要点 6：自动化测试复跑与可信度
- **核验判定**：**PASS**
- **复核方实测记录**：
  1. 后端单元测试：
     在 `/home/hatch/workspace/muse-control-tower-integration` 下运行 `PYTHONPATH=backend /home/hatch/workspace/muse-control-tower-backend/.venv/bin/pytest -q`
     **实测结果：`280 passed, 1 warning in 33.48s`**，全数通过。
  2. 前端单元测试：
     在 `/home/hatch/workspace/muse-control-tower-integration/frontend` 下运行 `bun test`
     **实测结果：`27 pass, 0 fail (Ran 27 tests across 5 files in 4.73s)`**，全数通过。
  3. 测试套件覆盖了真实 Git DAG 分支合并去重、总控笔误提交排除、多种签名格式、时区转换、重复打回去重、任务重开、缺失历史等极端边界条件，测试用例可信度极高。

---

### 要点 7：边界条件遵循
- **核验判定**：**PASS**
- **核验细节**：
  - 未引入任何常驻新服务、无新增守护进程，systemd 仍仅维持 `muse-tower-backend` 与 `muse-tower-frontend` 两项服务。
  - `RULES.md` 零改动。
  - 无 force push、无删库，代码提交为基于前序提交的标准 fast-forward。
  - 部署通过更新 `deploy/repair-after-vm-replacement.sh`（增加只读 ACL 配置）及 systemd unit 环境变量，完全复用 T-039 自愈流程，不另起部署链路。

---

## 2. 复核结论与总结

- **综合判定**：**PASS**
- **结论说明**：
  Codex 对 T-047 的交付实现严谨工整，从 Git 与收据派生数据的口径准确无误，抽样任务实测误差为 0 秒；严格遵循“不编造额度”原则；代码架构与契约管理遵循规范演进；自动化测试完全绿灯且复核方独立验证一致。
- **操作注意**：
  按总控指示，本次独立复核仅在本地生成复核意见文件，**不执行 git push**，由总控后续统一推送与推进终验。

---
复核人：Antigravity (Gemini 3.8 Flash)  
签署时间：2026-11-16T19:10:45+08:00
