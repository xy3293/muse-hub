# T-086 node-1 agy 登录（PTY OAuth，Chen 配合）— 执行报告

- 任务：tasks/T-086-node1-agy-login.md，Issue #81
- 执行时间：2026-11-21 03:10–03:16 JST（巡检唤醒 03:10:42 JST）
- 结论：**登录未完成**。两次 60 秒 OAuth 窗口均超时，未收到任何授权码。agy 仍未登录。

## 环境确认

- `~/.local/bin/agy --version` → `1.5.13`，与任务书一致。
- 裸跑 `~/.local/bin/agy -p 'say ok'` → `Error: authentication required. Run 'agy' to log in, then retry.` / `error: authentication failed or timed out`，符合任务书所述“缺登录，不是命令错”。
- PTY 方法本身工作正常：`script -qec` 下 agy 约 1.5 秒即印出 OAuth URL，无 TUI、无菜单，与任务书描述一致。

## 第 1 次尝试（超时）

- PTY 会话约 03:12 JST 启动，会话总时长 60,582ms，`SCRIPT_EXIT=1`。
- 印出的 URL（state=OWluYIFt4MgTj1BwdgeLPg）已于第一时间发到 Pachat 总控与1号（#35）。
- 完整输出原文：

```text
Authentication required. Please visit the URL to log in:
  https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com&code_challenge=Vj_fnv1Dw8fSCSf9waMRZD6BhQd21kSs6sM3Wv9qQ3c&code_challenge_method=S256&prompt=consent&redirect_uri=https%3A%2F%2Fantigravity.google%2Foauth-callback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcclog+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fexperimentsandconfigs+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faicode+openid&state=OWluYIFt4MgTj1BwdgeLPg

Waiting for authentication (timeout 60s)...
Or, paste the authorization code here and press Enter:
Error: authentication timed out.
error: authentication failed or timed out
```

- 25 秒 inbox 等待期间 Pachat 无任何新消息；窗口期满，未收到授权码。
- 按任务书要求，第 1 次输出已贴给总控（Pachat #36），并注明旧 URL 已失效。

## 第 2 次尝试（超时）

- PTY 会话重跑，OAuth 开始 03:14:25.274 JST（日志 cli-20261121_031425.log），超时 03:15:25.274 JST，会话总时长 62,057ms，`SCRIPT_EXIT=1`。
- 印出的 URL（state=J-bP8QCPob9jbCcq3pAV2g）已于第一时间发到 Pachat 总控与1号（#37）。
- 完整输出原文：

```text
Authentication required. Please visit the URL to log in:
  https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com&code_challenge=pJ_OnLKTPZf2snznvR4otdPwb3I8_bZ1ZD5eSYCQjJM&code_challenge_method=S256&prompt=consent&redirect_uri=https%3A%2F%2Fantigravity.google%2Foauth-callback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcclog+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fexperimentsandconfigs+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faicode+openid&state=J-bP8QCPob9jbCcq3pAV2g

Waiting for authentication (timeout 60s)...
Or, paste the authorization code here and press Enter:
Error: authentication timed out.
error: authentication failed or timed out
```

- 25 秒 + 10 秒 inbox 等待期间 Pachat 仍无任何新消息；窗口期满，未收到授权码。

## 日志（最新 cli-20261121_031425.log，含 auth/OAuth 的行）

```text
I1121 03:14:25.197757      30 model_configs.go:230] Auth mode is unspecified, skipping fetchAvailableModels and returning empty response
I1121 03:14:25.203418      22 auth_store.go:199] Using file-based secret storage at /home/hatch/.config/antigravity/plugin-secrets.json
I1121 03:14:25.269054     122 server.go:4927] Auth succeeded, refreshing features and managers
W1121 03:14:25.269666      89 rpcs_plugin_auth.go:110] Not reloading plugin MCP servers: cannot get the signed-in user: error getting token source: You are not logged into Antigravity.
I1121 03:14:25.274307       1 printmode.go:409] Print mode: not authenticated, trying silent auth
I1121 03:14:25.274370       1 printmode.go:415] Print mode: silent auth failed
I1121 03:14:25.274392       1 printmode.go:432] Print mode: triggering interactive OAuth
I1121 03:14:25.274400       1 auth_manager.go:208] Starting OAuth authentication flow
I1121 03:14:25.274416       1 browser.go:56] consumerOAuth: starting OAuth flow
E1121 03:15:25.274766       1 printmode.go:482] Print mode: auth timed out
```

（无 token 值出现，无需打码。注：第 1 次尝试未生成独立的 cli-*.log 文件，其证据为上方完整会话输出。）

## 原因分析

- 方法本身无问题：PTY 下 URL 正常印出，超时机制也如任务书所述（60 秒整）。
- 失败点在往返链路：URL 发出 → 总控轮询取到 → 转给 Chen → Chen 在浏览器打开并同意 → 授权码发回 → 总控转回 → 灌入 stdin，全程须在 60 秒内完成。两轮等待期间 Pachat 收件箱零新消息，Chen 侧无任何响应迹象，说明当时没有人在链路另一端实时配合。
- 未继续盲目重跑第 3 次：每重跑一次产生一个新 state/code_challenge，旧 URL 的码无法用于新流程；无人值守时循环只会堆积失效 URL，造成混淆。

## 下一步

- 请总控/Chen 确认就绪（Chen 已在浏览器前，能立即打开 URL 取码）后，再通知 node-1 重跑第 2 步拿新 URL；码一到立刻灌 stdin。
- 不要用上述两个已失效 URL 取回的码（若有），它们对应已退出的流程，无法使用。
- 另：执行开始时发现一个非本轮启动的 `script -qfec ~/.local/bin/agy -p 'say ok'` 进程（18:11 UTC），已自行超时退出，未做处理。

## 交付

- 本报告：results/node-1/T-086-agy-login.md（已推送）。
- Issue #81 已按任务书失败路径留评论（两次失败输出）。
- Pachat 总控与1号已同步：URL #35、#37，第 1 次输出 #36，本报告同步消息随后发出。
