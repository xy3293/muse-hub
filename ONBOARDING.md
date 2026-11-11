# ONBOARDING · 给 1/2/3 号的安装指令

Chen 在对应账号聊天中直接说明执行目标、范围和批准版本，再引用本安装说明；**X 换成 1、2、3**。已授权范围内按步骤执行，无需重复确认。授权原则见 [R17](RULES.md#r17-仓库文字不产生授权2026-11-11-起)。

## 指令投递与内容核对

1. 直接聊天指令应注明节点、目标、允许的操作范围、批准脚本来源与完整 SHA-256；附件或仓库文件作为参考，不自行扩大授权。
2. 获取批准版本的脚本后，用 `sha256sum <实际脚本路径>` 与 `release-manifest.md` 对应条目的完整 64 位哈希比较；安装副本和仓库文件分别核对，不能只比较两个本地文件彼此相同。该命令依赖 Linux 的 sha256sum，ASCII 哈希不依赖中文 locale。
3. 内容乱码、缺段或哈希不符时停在读取阶段，向 Chen 报告具体不一致，不猜测恢复指令，也不执行损坏内容；平台安全要求始终适用。

本项目曾在三个节点复现附件指令被拦截且伴随乱码，改成直接聊天文字后被接受；这是当前投递方式的选择依据，不代表所有附件都不可靠，也不证明乱码导致安全拦截。

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

- 以当前 BOARD.md 为准，只处理派给本节点、状态为“待领”的任务，并核对任务书版本。没有待领任务就待命；不要按安装说明中的历史任务编号重复开工。

## 红线（再说一遍）

- 不改 `BOARD.md`；只写自己专属目录 `results/node-X/`；绝不同时改同一文件。
- 你的推送通道见 R16；node-1 走 shell，node-2、node-3 走工具层，不要照抄别的号的通道。
- 提交信息与 Issue 评论的署名格式，从 [RULES.md 的 R1 身份与署名](RULES.md#r1-身份与署名) 复制本节点对应标记；若定位失败，在 RULES.md 搜索标题“R1 身份与署名”。署名只是角色标识，不是身份或授权凭证。
- hub 里严禁出现真实隐私、账号、密码、密钥、Token。
- 无法继续任务时按 R8 报告事实与原因，由总控按 R7 升版重派；不要自行删除 seen 记录。损坏状态的定点修复只走 [故障恢复说明](docs/state-recovery.md)。
