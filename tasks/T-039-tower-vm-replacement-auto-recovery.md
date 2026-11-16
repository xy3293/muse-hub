# T-039：Control Tower 部署 VM 替换后自动恢复（T-037 的缺口）

## 背景

T-037 的 systemd 部署扛不住 VM 替换。2026-11-16 一天内 VM 被换两次（约 13:03、约 15:03），每次都导致：

1. `/etc/systemd/system/muse-tower-*.service` 消失（`/etc` 是临时的）。
2. `muse-tower` 系统用户消失（`/etc/passwd` 是临时的）。
3. 代码/运行目录的 ACL 消失（`setfacl` 授的权限没随 `~` 保留）。
4. `acl` 包本身消失（`/usr` 是临时的，`apt-get update` 缓存也是空的）。

结果：Control Tower 自约 13:03 起挂了约 2 小时，直到总控 14:52 巡检发现、手动恢复。

## 当前状态（总控已手动恢复，临时方案）

- 服务已恢复：后端/前端 active，healthz ok，前端 200，events 200（5 条）。
- 恢复手段：重建 muse-tower（uid 999）、从仓库 `deploy/systemd/` 拷回 unit、daemon-reload＋enable＋start。
- **权限是临时 chmod 代替 ACL**：`o+rx` 在 `/home/hatch`、workspace、integration、backend、muse-control-tower；`o+rX` 递归在 backend/contracts/frontend/.venv；`o+rwx` 在 runtime。能跑，但比 README 的 ACL 宽松——本单要换回 ACL 并撤掉 chmod。
- `apt-get update` 正在后台跑（为装 acl 包）。

## 任务（Codex）

1. 写一个幂等修复脚本（放仓库 `deploy/` 下，例如 `deploy/repair-after-vm-replacement.sh`，再在总控 VM 上留一份）：
   - 检测：后端 healthz、前端 200、服务 active；任一不满足即判定"需修复"。
   - 修复：用户不存在则 `useradd --system --no-create-home --shell /usr/sbin/nologin muse-tower`；unit 缺失则从仓库 `deploy/systemd/` 拷回 `/etc/systemd/system/`；`acl` 包缺失则 `apt-get update && apt-get install -y --no-install-recommends acl`（容忍 update 慢）；按 `deploy/README.md` 第 72–78 行的 `setfacl` 命令重授 ACL；撤掉临时 chmod（`o+rx`/`o+rX`/`o+rwx` 改回原值，见下）；`daemon-reload`、`enable`、`start`。
   - 临时 chmod 的原值（VM 替换后重置的默认值）：`/home/hatch` 为 `drwxrws---`、`workspace` 及子目录为 `drwxrwx---`（root:nogroup）。撤掉时按此恢复，不要动其他权限。
   - 密钥绝不进仓库/日志/Issue；只读 runtime 文件仍保持 600。
2. 触发机制：用总控 VM 上已有的 cron 体系（runtime 侧的 cron，VM 替换不丢），每 10 分钟跑一次修复脚本；脚本自身先检测、健康时静默退出，不健康时才修复。不要新增 systemd unit 做触发（unit 本身就是会被清掉的东西）。
3. 验证：模拟一次 VM 替换——删掉 unit、删掉 muse-tower 用户、清掉 ACL、确认服务挂了，再跑脚本，验证服务自动恢复且 healthz/frontend/events 全过；并验证健康时脚本静默不动作。
4. 更新 `deploy/README.md`：加一节"VM 替换后自动恢复"，写清机制、cron 间隔、脚本位置、手动触发方法。

## 验收标准

- 模拟 VM 替换后，修复脚本能把服务恢复（healthz ok、前端 200、events 200）。
- 健康时脚本静默，不重复修复、不刷日志。
- ACL 已换回（临时 chmod 已撤），`getfacl` 能查到 muse-tower 的条目。
- cron 已建并验证跑过一轮。

## 执行方

Codex（总控 VM 上跑）。Antigravity 复核。
