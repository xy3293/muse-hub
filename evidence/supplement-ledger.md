# 补件台账（节点 agy / bwrap / Codex 登录）

跟踪三节点补件状态。基线见 A5 归档（`evidence/step7-risk-quota-archive.md`，2026-11-16 快照：agy 全缺 3/3、bwrap 全缺 3/3、Codex 登录未验证 3/3、node-2 技能软链接缺失）。本文件记后续变化；A5 归档本身不改。

## bwrap

| 节点 | 状态 | 证据 | 时间 |
| --- | --- | --- | --- |
| node-3 | **已装好**：`bubblewrap 0.9.0`，`/usr/bin/bwrap`，`ii bubblewrap 0.9.0-1ubuntu0.3` | 节点自报＋复核输出（`bwrap --version`、`dpkg -l`） | 2026-11-16 08:05 完成（07:51 开跑） |
| node-1 | **已装好**：`bwrap 0.9.0` | 节点自报"bwrap 已是 0.9.0，装完了" | 2026-11-16 09:12 前完成 |
| node-2 | **已装好**：`bwrap 0.9.0`，无待批卡 | 节点自报"已经跑完了……bwrap --version 还是 0.9.0，没什么要补跑的" | 2026-11-16 09:12 前完成 |

注意：**节点 env 不持久**。node-1 报过"上次装的 0.9.0 已随 VM 更换消失"。apt 类补件每次会话要重装，每次一张分享卡。见 ONBOARDING.md「节点能力边界」。

## Codex 登录

| 节点 | 状态 | 备注 |
| --- | --- | --- |
| node-1/2/3 | **节点侧不可用**（Chen 2026-11-16 直令） | `codex login` 需浏览器回调节点本机 localhost，节点不接受入站（与 T-034 隧道问题同源）。重活继续在总控 VM 上跑。 |

## agy

| 节点 | 状态 | 备注 |
| --- | --- | --- |
| node-1/2/3 | 二进制缺，需 Chen 授权 | 纯 CLI（无需桌面），下载源需 Google 账号，下完再 `agy login`（Google OAuth）。 |
