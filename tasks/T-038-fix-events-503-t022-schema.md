# T-038：修 Control Tower 两个后端小缺陷（events 503＋T-022 schema 异常）

## 背景

T-034 v2 执行（2026-11-16）与 D1/D2 修复（c9ea494）时各发现一个后端缺陷，均未阻塞主流程，留作后续小单。本单一次修完。

## 缺陷 1：`/api/v1/events` 持续 503 SOURCE_UNAVAILABLE

- 发现：T-034 v2 浏览器执行时，`GET /api/v1/events` 始终返回 503 SOURCE_UNAVAILABLE（记录在 `evidence/T-034-artifacts/index.md`）。
- 要求：定位 events 数据源失败原因并修复；修复后 `GET /api/v1/events` 返回 200 且含真实事件数据（或明确的空列表）；回归测试通过。

## 缺陷 2：T-022 任务书触发 `read_book()` 解析异常

- 发现：D1/D2 修复时 Codex 发现，T-022 的内嵌 schema 会触发 `read_book()` 解析异常；当时按任务书要求未改，留作后续。
- 要求：定位异常根因（schema 结构或解析器容错），修复后 T-022 任务书可正常读取；不改动 T-022 任务书内容本身（只修解析器或做兼容处理）；回归测试通过。

## 交付要求（Codex）

1. 在私有库 `xy3293/muse-control-tower` 的 integration 分支上改（基于当前 HEAD，含 T-037 的 systemd 部署 da2247c）。
2. 两缺陷各自定位根因、修复、加回归测试；测试全部通过（后端 pytest）。
3. 修复后重启 systemd 后端服务（`muse-tower-backend`），验证 `/api/v1/events` 返回 200、T-022 任务书可读。
4. 密钥与 token 不得写入仓库文件、日志或 Issue。
5. 做完提交到 integration 分支（不要 push，push 由总控做），附验证结果。

## 验收标准

- `/api/v1/events` 200 且数据真实。
- T-022 任务书读取无异常。
- 后端测试全过；无密钥泄露。

## 执行方

Codex（总控 VM 上跑）。Antigravity 复核。
