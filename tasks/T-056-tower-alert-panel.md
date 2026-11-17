# T-056：告警面板 — 看门狗与监督者日志汇总（Chen T6）

## 来源
Chen 直令 2026-11-18 04:06，T1–T8 之 T6。

## 目标
把告警与恢复记录汇总进一个页面区块，按时间倒序看最近 50 条。

## 现状与数据源（Codex 先读，再动手）
- muse-hub `evidence/tower-recovery-log.md`：Tower 恢复日志，每次 VM 替换后的恢复都有一行（时间、VM 启动时间、退出码、PARTIAL/失败/成功、耗时秒数、是否触发上报、事后核查）。**这是最主要的告警记录来源。**
- `~/hooks/state/muse-hub/logs/snapshot-refresh.log`：快照导出日志，每行 `OK: ... pushed <sha>` 或 `FAILED: <原因>`。在 VM 本地，不在 git 里，但后端能读到。
- `evidence/T-039-vm-replacement-auto-recovery/`：T-039 相关文档目录，可作补充。
- **注意**：Chen 的看门狗（他 PC 上）的 ALERT/RECOVER 快报目前只发到总控聊天，**没有落到本地结构化日志文件**。不要编造看门狗告警条目。本任务的数据源就是上面两个日志文件；若以后看门狗告警落盘了，再接。报告里写明这一边界。

## 任务
1. **后端**：新增一个只读端点（或给 `Runtime` 加可选字段，二选一，Codex 定，以不破坏 1.1.0 为准），返回最近 50 条告警/恢复记录，倒序。每条：`at`（ISO 时间）、`source`（`recovery-log` | `snapshot-refresh`）、`level`（`info` | `warning` | `error`：PARTIAL/失败为 warning/error，成功为 info；FAILED 导出为 warning）、`summary`（一句话，如「恢复 PARTIAL 335 秒」或「快照导出失败：git fetch 失败」）、`ref`（可选，如提交 SHA）。
   - 解析 `tower-recovery-log.md`：每行是一条记录，时间取行首日期时间；级别按「失败/error」「PARTIAL/warning」「成功/info」分。
   - 解析 `snapshot-refresh.log`：每行取时间戳与 OK/FAILED。
   - 两个来源合并后按时间倒序，取最近 50 条。文件读不到时返回空列表 + `source_meta` 注明，不要让整个端点失败。
   - 新增字段/端点走版本化契约（1.1.1），可选，不得破坏 1.1.0 客户端。
2. **前端**：在 `RuntimeView` 内加「告警」区块（与 T-054 的运行时监控区块并列，不要另起页面）：倒序列表，最近 50 条；每条显示时间、来源、级别徽章（info 灰 / warning 黄 / error 红）、一句话摘要。无记录时显示「暂无告警记录」。
3. 静态模式：快照里没有告警数据时，该区块显示「静态快照不含告警数据」，不要假装有数据、不要发请求。

## 约束
- 只读，不写日志、不改 hook、不改看门狗。
- 不编造告警：无数据源的条目不显示，不要写假时间、假级别。
- 测试：后端解析测试（各取几行真实日志断言级别与倒序）+ 前端渲染测试；`bun test` 与后端 pytest 全过；`npm run build` 通过。

## 验收
- Codex 交付到 Tower integration 分支；Antigravity 独立复核 PASS；总控验收（收据 + BOARD + MUSE-ACK 一次提交）。
- 验收证据：在线 Tower 告警区块截图或 API 返回（最近 50 条倒序，含至少一条真实 PARTIAL/失败记录）。

## C11.2（三行，Codex 交付时附上）
- 打算：一句话说清方案
- 最可能失败的两处：1) … 2) …
- 第一次失败后我会改什么：一句话
- 若第二次仍失败：停手，按 C11 咨询，不再试第三条路
