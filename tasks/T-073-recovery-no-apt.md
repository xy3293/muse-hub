# T-073 恢复路径去 apt 依赖（换机恢复 <120 秒）

- Issue: #68
- 执行方：Codex（总控 VM 本地）
- 来源：Chen 直令 2026-11-19 20:09（恢复太慢 763–904 秒，把 apt 依赖从恢复路径里拿掉）
- 边界：不改 RULES；不动 Tower 业务代码；只改恢复脚本与依赖打包方式。不引入新的外部服务。

## 问题

2026-11-19 当天 6 次换机，恢复耗时 226 / 763 / 829 / 904 / 247 / 226 秒，4 次超 600 秒阈值。恢复日志已定性：耗时大头在 apt 装 acl（约 9 分钟）；10:11 一轮脚本退出码 100，失败于 `apt-get update`（apt lists 锁被开机 os-intent replay 占住）。每次换机都要联网 apt 装 acl，装一次 9 分钟，抢不到锁就直接失败一轮。

## 要求

1. **把 acl 的 .deb 预置到本地**：当前版本 `acl_2.3.2-1build1.1_amd64.deb`（39,398 字节，sha256 `0beec20d005bb4b3138ac9c99ab7c10a06acaf1ea1ad4e10ad760e56561edd58`，现存于 `/var/cache/apt/archives/`，但 /var 随换机丢失）存进 Tower 仓库 `deploy/packages/`，恢复时 `dpkg -i` 直接装，不联网、不抢锁。acl 依赖 `libacl1 (= 2.3.2-1build1.1), libc6 (>= 2.38)`——先确认 libacl1 是否在新镜像里默认存在；若不能确认，把 libacl1 的 .deb 也一起预置（现在联网时用 `apt-get download` 取）。包的 sha256 写进 `deploy/packages/` 下的清单文件备查。
2. **装不上也不能挡住服务**：`dpkg -i` 失败时，先用 chmod 降级方案把两服务拉起来（宁可权限宽松也要先可用），然后后台再补 ACL，并在恢复日志标 `DEGRADED（ACL 未装，临时 chmod）`。注意：acl 没装上时 `setfacl` 命令本身不存在，降级路径一律只用 chmod/chgrp/chown，不许调 setfacl。
3. **恢复耗时目标 < 120 秒**（现在 226–904 秒）。按这个目标改，并在交付里贴实测数字与分段耗时。
4. **恢复脚本里凡是会等网络的步骤，一律加短超时（20 秒）并快速失败**，不许卡 9 分钟。apt 相关行从恢复路径里彻底删掉。

## 现状（总控已核实，写进 spec 免得重复查）

- 恢复脚本两份拷贝目前完全一致：`/home/hatch/hooks/scripts/repair-after-vm-replacement.sh`（实际跑的那份）与 Tower 仓库 `deploy/repair-after-vm-replacement.sh`。仓库拷贝是源头，两份改完必须 diff 一致。
- apt 块在脚本约 208 行：`if ! command -v setfacl` 之后两行 `apt-get -o DPkg::Lock::Timeout=600 update` / `install -y --no-install-recommends acl`。这是全脚本唯一的 apt 调用。
- 脚本其余等待点：`healthy()` 的 urllib 超时已是 5 秒；`check_snapshot_timer` 最多等 150 秒 × 2 轮（等快照文件 mtime 前进，不是网络等待，但它占时钟大头——分析 <120 秒目标能否达成时必须算上它；不许悄悄删掉这个自检，若目标达不到，贴分段实测并单独报）。
- 当前本机 acl 已装（`ii acl 2.3.2-1build1.1`），`setfacl` 在 `/usr/bin/setfacl`。

## 验收

- 贴 `dpkg -i` 那段的代码位置（文件 + 行号）与本地包路径；
- 实测恢复耗时（目标 < 120 秒）与是否 DEGRADED，分段耗时（服务重启、timer 首轮导出等待、自检）；
- 确认恢复路径里已无 apt-get 调用（grep 证据）；
- acl 替代方案评估：若认为 acl 根本可以不要（setgid + 精确 chmod 等效），写清等效性证据——能不能在不装 acl 的前提下让 Vite 读到 `.vite-temp`。只评估、写进交付报告；主线仍按 .deb 预置实现，除非等效性已证实且更简单，那也要在报告里明确写出并给出证据，不许悄悄换方案。

## 验证方法（Codex 自己跑）

- `bash -n` 过脚本；改完两份拷贝 diff 一致。
- 端到端实测：先停掉两服务 + 快照 timer，再跑修复脚本并计时，确认恢复后 healthy、timer 自检通过，贴实际耗时；确认全程无 apt 进程（apt 相关行已删 + `/var/log/apt/history.log` 无新增）。
- 离线装验证：`dpkg -i` 已装同版本是安全重装，可直接验证离线安装路径；DEGRADED 路径用 PATH 屏蔽 setfacl 的子 shell 演练（不许真卸载 acl）。
