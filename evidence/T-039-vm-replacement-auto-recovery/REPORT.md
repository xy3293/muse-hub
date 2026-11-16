# T-039 验收报告：Control Tower 部署 VM 替换后自动恢复

- 任务：T-039（Issue #41），执行方 Codex，复核方 Antigravity
- 交付提交（私有库 xy3293/muse-control-tower，integration 分支）：`bc979215e49c3c56eb030d26bca189ad72664609`（已推远端）
- 验收结论：**PASS**

## 背景

T-037 的 systemd 部署扛不住 VM 替换。2026-11-16 一天内 VM 被换两次（约 13:03、约 15:03），每次都清掉 /etc unit、muse-tower 用户、ACL、acl 包，Tower 挂约 2 小时才被总控巡检发现。总控手动恢复后（临时 chmod 顶上，再换回 ACL），开本单做耐久修复。

## 交付内容（2 文件，173 行）

- `deploy/repair-after-vm-replacement.sh`（126 行，可执行）：幂等修复脚本。先检测（后端 healthz 200、前端 200、两服务 active），健康时静默退出；不健康时拿锁、重建用户、从 deploy/systemd/ 拷回 unit、缺 acl 时自动安装、按 README 重授 setfacl（含 .vite/.vite-temp rwX）、撤临时 chmod、daemon-reload/enable/restart、探针通过才报成功。
- `deploy/README.md`（50 行）：新增"VM 替换后自动恢复"一节（机制、cron 间隔、脚本位置、手动触发方法、验证记录）。
- 持久副本已安装到 `/home/hatch/hooks/scripts/repair-after-vm-replacement.sh`（与仓库版一致）。
- cron 已注册：`muse-tower-vm-replacement-auto-recovery-10min`，每 10 分钟一轮，健康时静默。

## Codex 交付自述

- 删 unit、用户、ACL 后模拟替换，脚本成功恢复服务；healthz、前端、events 均 200，events 5 条。
- acl 包缺失时自动安装；健康时静默、无重启。
- 密钥内容未变、权限 600，仓库及服务日志扫描通过。
- 未完全验收的两项已记 README：cron 尚未注册验证（总控已补注册并手动触发一轮成功）；/home/hatch setgid 位读回 0770。

## 总控独立核验（2026-11-16 15:20）

- `git log`：bc97921 在 49466db 之上，工作区干净。
- 脚本 `bash -n` 通过；健康时直接跑返回 exit 0、无输出（静默正确）。
- 服务 active；healthz ok；前端 200；events 200（5 条）。
- cron 手动触发一轮（fede316f）：succeeded，无错误。
- 密钥抽查：ct_access_key.txt、gh_token.txt 均为 600、属主 muse-tower。

## Antigravity 复核：PASS（2026-11-16 15:23）

5 项全过：脚本存在且两副本一致、健康检测静默正确、修复逻辑完整（含用户/unit/acl/setfacl/撤 chmod/探针）、密钥零泄露（600 属主＋全仓库逐字节扫描 0 匹配）、README 新章节完整（机制、间隔、路径、手动触发、验证记录）。
