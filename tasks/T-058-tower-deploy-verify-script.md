# T-058：Tower 部署自检 deploy/verify.sh（Chen T8）

## 来源
Chen 直令 2026-11-18 04:06，T1–T8 之 T8。意义：换 VM 后跑这一条就够了，不用逐项人肉检查。

## 目标
一条 `deploy/verify.sh`，一次跑完全部检查，输出 PASS/FAIL 清单。退出码：全 PASS 为 0，任一 FAIL 为非 0。

## 检查项（全部，只读，不修复）
1. `muse-tower-backend` service：`systemctl is-active` 为 active。
2. `muse-tower-frontend` service：`systemctl is-active` 为 active。
3. 后端健康：`curl -f http://127.0.0.1:8000/healthz` 为 200。
4. 前端可达：`curl -f http://127.0.0.1:3000/` 为 200。
5. 快照新鲜：`tower-static/snapshot.json` 的 `refreshed_at` 距今 < 20 分钟（>20 分钟为 FAIL，10–20 分钟为 WARN，不计 FAIL）。
6. 快照 timer：`muse-tower-snapshot-export.timer` 为 active，且 `NextElapseUSecMonotonic` 非空、非 0、非 infinity。
7. 恢复清单完整（T-039 清单）：
   - `/etc/systemd/system/muse-tower-backend.service` 与 `muse-tower-frontend.service` 存在。
   - `/etc/systemd/system/muse-tower-snapshot-export.{service,timer}` 存在，且 timer 单元含 `OnActiveSec=1min`（T-039 cfdae54 的修复，缺了就是 FAIL）。
   - 持久副本 `~/hooks/scripts/repair-after-vm-replacement.sh` 与仓库 `deploy/repair-after-vm-replacement.sh` 一致（diff）。
   - 持久副本 `~/hooks/scripts/snapshot-export.sh` 存在。
   - 凭据文件存在且权限正确：`runtime/ct_access_key.txt` 与 `runtime/gh_token.txt` 为 600（不存在或权限不对为 FAIL）。
8. 快照导出脚本可执行：`bash -n` 通过 `deploy/snapshot-export.sh` 与 `deploy/repair-after-vm-replacement.sh`。

## 输出格式
每行一项：`PASS <检查名>` 或 `FAIL <检查名>：<原因>`，WARN 单列 `WARN <检查名>：<原因>`。末尾一行汇总：`通过 X/Y，失败 Z 项`。不输出密钥、不输出 token 值。

## 约束
- 只读检查，不修复、不重启、不改配置。发现 FAIL 只报告，不自动修。
- 路径用绝对路径 `/home/hatch/...`（脚本可能经 sudo 跑，`$HOME` 会变成 /root，见 T-052 教训；不要用 `$HOME` 拼关键路径）。
- `bash -n` 通过；`shellcheck` 如可用则过（无 shellcheck 时跳过并注明）。

## 验收
- Codex 交付到 Tower integration 分支（`deploy/verify.sh` + 执行权限）；Antigravity 独立复核 PASS；总控验收（收据 + BOARD + MUSE-ACK 一次提交）。
- 验收证据：在当前健康系统上跑一次，输出全 PASS（或仅 WARN）清单，贴输出。

## C11.2（三行，Codex 交付时附上）
- 打算：一句话说清方案
- 最可能失败的两处：1) … 2) …
- 第一次失败后我会改什么：一句话
- 若第二次仍失败：停手，按 C11 咨询，不再试第三条路
