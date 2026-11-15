# T-035：补 node-2 的 direct_codex_antigravity 技能软链接

- 任务号：T-035
- 派给：node-2
- Issue：待建（#37）
- 来源：B5（A/B 包 B1+B2+B3 报告跟进）。T-026（node-2，2026-11-15）核查发现 `~/workspace/custom-skills/` 为空目录，`direct_codex_antigravity` 软链接缺失，`SKILL.md` 不可读；node-1/node-3 的同一链接有效。B5 决定：先补 node-2 的链接（轻量本地任务，不依赖 Codex/Antigravity/pytest）。

## 做什么
1. 在 node-2 本机确认 `~/workspace/custom-skills/direct_codex_antigravity` 是否仍缺失（`ls -la ~/workspace/custom-skills/`、`test -L`）。
2. 若缺失，从已同步的 muse-hub 克隆建软链接，目标为克隆内的 `skills/direct_codex_antigravity/`（与 node-1/node-3 同法：`readlink -f` 确认目标存在）。
3. 验证：`SKILL.md` 与 `skill.yaml` 均可读；`ls -la` 显示链接有效。
4. 报告写进 `results/node-2/T-035-fix-skill-link.md`（做了什么、验证命令与输出、链接目标路径），推送。

## 不做什么
- 不安装软件，不改系统配置。
- 不发起任何实耗 Codex 调用（无 bypass 审批、无额度确认）。
- 不碰 `agy`/`bwrap`/Codex 登录——那三项缺件需 Chen 介入，不在本任务内。

## 验收
- 报告文件在远端可读；链接有效且 `SKILL.md` 可读；收据＋BOARD＋ACK 一次提交（精简流程）。
