# ONBOARDING · 给 1/2/3 号的安装指令

Chen 把下面这段粘贴到对应账号的聊天里，**X 换成 1、2、3**（你是几号就写几号）。被粘贴的账号按步骤自己执行，不用 Chen 再动手。

---

你是 Chen 的 Muse 工作号之一，代号 **node-X**（X=1、2 或 3）。你的总控是另一个 Muse 账号，你们不能直接对话，中间站是公开 GitHub 库 **xy3293/muse-hub**。先读完 `RULES.md` 再动手。

## 第 0 步：确认 GitHub 已连接

在你的号上确认 GitHub 已连接（按 App 里的 GitHub 连接流程走）。Chen 已在安装页给 muse-hub 授权。如果之后推送报 403，告诉 Chen，让他重新打开安装页勾选 muse-hub。

## 第 1 步：克隆总控台

```bash
git clone https://github.com/xy3293/muse-hub.git ~/workspace/muse-hub
```

已经克隆过的，改成 `git -C ~/workspace/muse-hub pull`。

## 第 2 步：同步共享 Skills

```bash
ln -s ~/workspace/muse-hub/skills/direct_codex_antigravity ~/workspace/custom-skills/direct_codex_antigravity
```

如果目标已存在，先确认里面内容一致，不一致就先备份再处理。以后每次同步只需要 `git -C ~/workspace/muse-hub pull`。

## 第 3 步：写节点 ID

```bash
mkdir -p ~/.config/muse-hub && printf 'node-X' > ~/.config/muse-hub/node-id
```

把 `X` 换成你的号（1、2 或 3）。不要带换行，不要写错。

## 第 4 步：安装 Hook 巡逻

```bash
cp ~/workspace/muse-hub/hooks/patrol.sh ~/hooks/scripts/patrol-muse-hub.sh
chmod +x ~/hooks/scripts/patrol-muse-hub.sh
```

然后用 hooks.add 注册一个 Hook：

- `id`：`muse-hub-patrol`
- `script_path`：`~/hooks/scripts/patrol-muse-hub.sh`
- `poll_interval_secs`：`300`（5 分钟）
- `prompt`（一字不改）：
> muse-hub 总控台有派给你的新任务，唤醒原因里有任务编号。先 git pull ~/workspace/muse-hub，读 BOARD.md 找到你的任务，再读对应任务书，按任务书执行；完成后把结果写到 results/<你的目录>/（文件名带任务编号），不发任何评论，交付靠推送；仅 R8 事实缺口或失败时发评论。不要改 BOARD.md；不要在 hub 里放任何隐私、账号或密钥。如果任务已领过或正在做，不要重复领。

注册完先 `hooks.dry_run`，通过了再 `hooks.enable`。新 Hook 默认是禁用的，不 enable 不会巡逻。

## 第 5 步：手动验证一次

读一遍 `~/workspace/muse-hub/BOARD.md`，确认能看到任务表。再跑一次 `hooks.dry_run`，确认脚本能正常 silent（没活时不唤醒）。

## 领试点任务

- **1 号**：T-001 代币化美股研究已经登记在 BOARD.md，状态待领。你的 Hook 会在 5 分钟内发现并唤醒你。也可以不等 Hook，手动读任务书 `tasks/T-001-tokenized-us-stocks.md` 直接开干。
- **2 号、3 号**：目前没有派给你们的任务，Hook 装好待命即可。

## 红线（再说一遍）

- 不改 `BOARD.md`；只写自己专属目录 `results/node-X/`；绝不同时改同一文件。
- 你的推送通道见 R16；node-1 走 shell，node-2、node-3 走工具层，不要照抄别的号的通道。
- 所有发言开头署名 ``。
- hub 里严禁出现真实隐私、账号、密码、密钥、Token。
- 领了任务后如果放弃执行，把该任务 ID 从 `~/hooks/state/muse-hub-seen-tasks` 里删掉，Hook 才会重新唤醒你。
