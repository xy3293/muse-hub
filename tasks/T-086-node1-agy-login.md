# T-086 node-1 agy 登录（PTY OAuth，Chen 配合）

- Owner: node-1。试点：只做 1 号，不动 2、3 号。
- 背景：node-1 已装 agy（`agy --version` 应为 1.5.13；若无，先按 muse-hub Release `agy-1.5.13` 三行命令安装），但未登录。裸 `agy -p` 会 1 秒退出（`authentication required`），不是命令错，是缺控制终端。
- Chen 配合：他会在浏览器里（以 uuiby503@gmail.com 登录）打开授权 URL，把授权码发回。

## 方法（总控 2026-11-21 实测通过，原样复现）

1. 先确认 `~/.local/bin/agy --version` 输出 `1.5.13`。
2. **必须套 PTY 跑**（这是关键；裸跑必 fail fast）：

   ```bash
   script -qec "~/.local/bin/agy -p 'say ok'" /tmp/agy-login.typescript
   ```

   后台跑，不要接任何输出管道。`< /dev/null` 不行（码递不进去），普通管道 stdin 不行（秒退 `Run 'agy' to log in`）。
3. 约 1.5 秒后输出里出现 OAuth 授权 URL（纯文本，无 TUI、无菜单、不用按键）。**立刻把整条 URL 回给总控**（在你自己的会话里回复，总控轮询桥上取）。
4. 总控把 URL 转给 Chen；Chen 以 uuiby503@gmail.com 登录的浏览器打开、点同意，得到授权码后发回；总控立刻把码转给你。
5. 你把授权码粘进跑着 `script` 的那个会话的 stdin（纯文本＋回车），agy 换 token、写盘、回答 `say ok`。
6. 验证：`~/.local/bin/agy -p 'say ok'` 直接回答，不再弹授权；`~/.local/bin/agy models` 列出模型。

## 时间窗口（60 秒）

- agy 从印出 URL 起只等 60 秒，超时即退出，不常驻。URL 一出来就立刻发总控，不要等；码一到立刻灌 stdin，不要攒。
- 超时了直接重跑第 2 步拿新 URL，没有惩罚；重跑前把上次的输出贴出来（总控要看走到哪一步）。

## 失败就报

- 任何一步失败：贴完整输出原文＋`~/.gemini/antigravity-cli/log/` 里最新 `cli-*.log` 中含 `auth`/`OAuth` 的行（token 值打码，只贴行首结论）。不要自己换方法、不要向任何人要账号密钥。
- 交付：Issue #81 留评论——登录成功贴 `agy models` 前 5 行＋`agy --version`；失败贴失败输出。
