# T-052：T-039 恢复脚本真正恢复 snapshot timer（enable --now + 恢复后验证 active）

Chen 直令（2026-11-18 03:51，P1-1）。只做这一件事，别扩范围。

## 背景

- T-039 自动恢复脚本：`deploy/repair-after-vm-replacement.sh`（Tower integration 分支）＋持久副本 `~/hooks/scripts/repair-after-vm-replacement.sh`（T-039 cron 跑的就是持久副本）。两副本目前一致（193 行）。
- 现状：脚本里已经有 `systemctl enable` + `systemctl start muse-tower-snapshot-export.timer`（主流程约 177–178 行，`check_snapshot_timer()` 重试里约 51–52 行），也有 `check_snapshot_timer()` 自检（is-active + NextElapse 非 infinity + 快照文件 150 秒内推进，不满足重试一次，仍不行 exit 2 记 PARTIAL）。
- 但恢复仍反复报 `PARTIAL（timer 未起）`：2026-11-17 05:41 1053 秒、09:21 321 秒、11:21 973 秒、13:34 375 秒、17:31 330 秒、19:21 323 秒。服务每次都起来了，timer 自检每次都过不去。Chen 的判断：昨天（cfdae54）只加了“自检报 PARTIAL”，没加真正让 timer 活过来的恢复动作。
- Chen 直令：把 `enable --now snapshot-export.timer` 写进恢复脚本，并且恢复后验证它 active。

## 做什么（Codex）

1. **恢复动作改成原子命令**：主流程里服务恢复后，把分开的 `systemctl enable` + `systemctl start muse-tower-snapshot-export.timer` 改成一条 `systemctl enable --now muse-tower-snapshot-export.timer`。`check_snapshot_timer()` 里的重试也同样改成 `enable --now`。
2. **恢复后验证 active**：`enable --now` 之后立刻验证两项，缺一不可：
   - `systemctl is-active muse-tower-snapshot-export.timer` 输出 `active`；
   - `systemctl show -p NextElapseUSecMonotonic --value` 非 `0` 且非 `infinity`（有排定的下次触发）。
   - 任一项不满足：把 `systemctl status muse-tower-snapshot-export.timer` 的关键行打到 stderr 做诊断，再 `enable --now` 重试一次；仍不满足就按现有口径走 PARTIAL（exit 2），不要静默通过。
3. **查清为什么现在的 enable+start 不够用**（这是本任务的核心，不只换一行命令）：
   - 核对装到 `/etc/systemd/system/` 的 timer 单元文件里是否真有 `OnActiveSec=1min`（cfdae54 加的）；若没有，说明安装步骤漏了，修安装步骤；
   - 查 `~/hooks/state/muse-hub/logs/snapshot-refresh.log`，看 timer 触发后导出是否成功（git fetch/推送失败会让快照不推进，自检自然失败）；
   - 评估 150 秒等待窗口是否够：timer 首触发在 start 后约 1 分钟（OnActiveSec），导出本身（git fetch + 合并 + 导出 + 提交 + 推送）要多久；若窗口不够，说明原因，不要擅自把窗口放大——先报数，让总控定。
   - 把根因写进报告：一句话，哪一环掉的。
4. **两副本同步**：改 Tower 仓库 `deploy/repair-after-vm-replacement.sh`（integration 分支），再同步到持久副本 `~/hooks/scripts/repair-after-vm-replacement.sh`，改完 `diff` 两副本必须一致。
5. **不碰**：T-039 cron 体、snapshot-export.sh、timer 单元文件本身（除非第 3 步证实单元文件就是错的——那就连单元文件一起修，并写明）、RULES.md、BOARD.md（除任务行外）。

## 验收（Codex 自测，写进报告）

- `bash -n` 两副本都通过；
- 两副本 `diff` 无差异；
- 在当前健康系统上验证：手动跑一次 timer 恢复逻辑（或等效操作），`is-active` 为 active、`NextElapse` 非 infinity、手动触发一次导出后快照 mtime 推进；
- 报告含：根因一句话、改了哪几行（行号）、上述三项验证的命令输出；
- 报告末尾按 C11.2 写三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若失败两次，停手并贴 ATTEMPT 1 与 ATTEMPT 2 的差异表，不要试第三条路。

## 交付

- Tower integration 分支提交 SHA（deploy/repair-after-vm-replacement.sh）；
- 持久副本已同步（`diff` 干净）；
- 预期：认领 5 分钟＋主体 30 分钟＋验收 10 分钟，约 45 分钟。
