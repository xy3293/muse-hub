# T-059：恢复脚本补 T-054 采样器与 T-056 告警 ACL 检查

## 来源
维护日志规则 ⑲（新增常驻组件必须同一次改动进 T-039 恢复清单）；T-054 交付时 Codex 已给出采样器检查行，T-056 交付时总控补了告警 ACL——两者都还没进 `deploy/repair-after-vm-replacement.sh`。不补：下次换 VM 后恢复脚本不重建采样器 cron、不补 evidence//logs/ 读 ACL，告警端点降级为 unavailable、采样状态停在旧值，T-058 的 verify.sh 会直接 FAIL。

## 目标
改 `deploy/repair-after-vm-replacement.sh`（仓库）+ 同步持久副本 `~/hooks/scripts/repair-after-vm-replacement.sh`，使换 VM 后恢复流程重建并自检以下新增组件；改动后跑一次 `bash -n`，并在当前系统上跑一次恢复脚本的自检段（只读验证，不实际重启服务），确认新检查通过。

## 改动项（全部）
1. **采样器脚本**：恢复时检查持久副本 `~/hooks/scripts/tower-runtime-sampler.sh` 存在、可执行、与仓库 `deploy/tower-runtime-sampler.sh` 一致（diff）；不一致则从仓库重装。
2. **采样器 cron**：恢复时确认 runtime cron `muse-tower-runtime-sampler-1min` 已注册（每分钟）；未注册则重建（定义文件在 `~/workspace/goals/muse-control-tower/crons/minutely/muse-tower-runtime-sampler-1min__interval@1m.md`，按该定义重建）。
3. **采样状态文件**：恢复后自检 `runtime/monitor-state.json` 的 sampled_at 距今 ≤180 秒、root 所有、muse-tower 可读、other 无权限；不满足则记 PARTIAL（不升级为失败，不触发 >600s 上报）。
4. **告警 ACL**：恢复时给 muse-tower 补读 ACL：`~/workspace/muse-hub-git/evidence/`（r-x）+ `tower-recovery-log.md`（r--，默认 ACL 一并设）；`~/hooks/state/muse-hub/logs/`（r-x）+ `snapshot-refresh.log`（r--，默认 ACL 一并设）。注意：`backend/muse_tower/alerts.py` 已由现有 `setfacl -R -m u:muse-tower:rX backend` 覆盖，不用重复加。
5. **告警端点自检**：恢复后自检 `GET /api/v1/runtime/alerts` 返回 200 且两来源 available；不满足则记 PARTIAL。

## 约束
- 只改恢复脚本（仓库 + 持久副本，两份 diff 一致）；不改采样器脚本、不改 cron 定义、不改 verify.sh、不改 ACL 以外的任何东西。
- 路径用绝对路径 `/home/hatch/...`（不要用 $HOME 拼关键路径，见 T-052 教训：sudo 下 HOME=/root）。
- bash -n 通过；不输出密钥、不输出 token 值。
- 自检新增项失败时记 PARTIAL（exit 2），不改为失败（exit 100），不触发上报。

## 完成标准
- 仓库 `deploy/repair-after-vm-replacement.sh` 与持久副本一致（diff 为空）。
- `bash -n` 两份都通过。
- 在当前健康系统上跑一次恢复脚本的自检段（或等价只读验证），新检查全部通过，贴输出。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（bash -n 输出 + 自检段输出）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
