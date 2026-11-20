# Antigravity 换号流程（实测，2026-11-21）

背景：Chen 的 ChatGPT 订阅到期，Codex 随之停用；新订阅 Google AI Pro，Antigravity 账号从旧 Google 账号 `zz3391806387@gmail.com` 换到新账号 `uuiby503@gmail.com`。本流程在总控 VM 上实测通过（2026-11-21 02:20 JST），写给 1、2、3 号节点复用。

**安全红线：本文只写路径与方法，不贴任何 token / 凭证值。token 文件内容绝不进 git、Issue、群聊、聊天记录。**

## 换的是什么

- 换的是 **Antigravity CLI（`agy`）的 OAuth token**，文件路径：`~/.gemini/antigravity-cli/antigravity-oauth-token`（600 权限）。
- 浏览器会话本身不换——浏览器只用来完成一次 OAuth 同意。浏览器里登录的是哪个 Google 账号，换出来的 token 就归属哪个账号。
- `agy` **没有 `login` / `logout` 子命令**，也没有设备码流程。唯一登录方式：浏览器 OAuth（授权码流程）。

## 步骤（总控 VM 实测）

1. **备份旧 token**（回滚用）：

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token ~/.gemini/antigravity-cli/antigravity-oauth-token.old-backup-20261121
   ```

   备份文件保持 600 权限。回滚时把备份拷回原路径即可。

2. **删掉当前 token**：

   ```bash
   rm ~/.gemini/antigravity-cli/antigravity-oauth-token
   ```

3. **在 PTY 下跑 agy，让 stdin 保持活着**（关键一步）：

   ```bash
   script -qec "~/.local/bin/agy -p 'say ok'" /tmp/agy-login.typescript
   ```

   后台跑，**不要接任何输出管道**。agy 会印出一条 OAuth 授权 URL，然后等 60 秒。

   为什么必须用 PTY：agy 要从 stdin 读回粘贴的授权码。`< /dev/null` 会让码递不进去（白白等 60 秒超时）；stdin 是普通管道或已关闭时 agy 秒退，报错 `Run 'agy' to log in`，不等你。

4. **在已登录新 Google 账号的浏览器里打开那条 URL**，点同意；回调页会显示一串授权码。

   浏览器不必在跑 agy 的同一台机器上——只要码能贴回 agy 的 stdin 就行。URL 与码的传递只走总控/节点自己的通道，不进公开库。

5. **把授权码粘进 agy 的 stdin**（PTY 输入），agy 换 token、写新 token 文件，然后回答 `say ok`。

6. **验证生效**：
   - `~/.local/bin/agy -p 'say ok'` 直接回答，不再弹授权；
   - `~/.local/bin/agy models` 列出新账号的模型清单（见下）；
   - token 文件 mtime 更新为换号时间。

## 三个坑（实测踩过）

| 做法 | 结果 |
|---|---|
| stdin 用 `< /dev/null` | URL 印得出，码递不进去，60 秒超时，码作废 |
| stdin 用普通管道或关闭 | agy 约 3 秒 fail fast：`Run 'agy' to log in`，不等待 |
| stdout 接 `\| head` 之类管道 | URL 被块缓冲，等进程退出才看得见，拿不到 URL |

## 无浏览器环境（节点）能不能做？

**结论：纯无浏览器做不完——同意那一步必须有个浏览器。但浏览器不必在节点本机上。**

- **路径 A（走 OAuth，推荐）**：节点按上面 3–5 步跑，OAuth URL 发出来后，由任一有浏览器的人/桥接浏览器打开（须已登录目标 Google 账号），把码贴回节点 agy 的 stdin。节点本机不需要桌面浏览器，只需要 stdin 能收码。
- **路径 B（拷凭证文件，无浏览器时的保底）**：把已登录机器上的 `~/.gemini/antigravity-cli/antigravity-oauth-token` 拷到节点的同一路径，权限设 600。token 文件是可移植的，拷过去即用；多机共用同一账号额度。传文件只走安全通道，不进 git/Issue/群聊，不贴文件内容。
- **设备码：没有。** `agy` 不提供设备码流程，不要等它。

## 新账号可用模型（2026-11-21 `agy models` 实测）

```
gemini-4-neon-high / xhigh / medium / low
gemini-4-argon-medium / high / low
gemini-4-hydrogen-high / xhigh / medium / low
gemini-pro-orchestrator-neon / gemini-pro-orchestrator-g1-pro
gemini-3.8-flash-high / medium / low
claude-opus-5-5-low / medium / high
```

注意：**默认模型仍是 `gemini-3.8-flash-high`**（当日日志实测）。想用更强的模型须显式指定，例如：

```bash
~/.local/bin/agy --model gemini-4-neon-high -p "..."
```

旧账号时期默认模型同样是 Gemini 3.8 Flash（High）。新账号的增量是 Gemini 4 系列（Neon / Argon / Hydrogen）与 Claude Opus 5.5 的使用权，不是默认模型变强。
