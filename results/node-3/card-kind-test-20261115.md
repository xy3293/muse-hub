# 卡种测试记录（终端 git push）

- 时间：2026-11-15 00:16 起（CST）
- 测试内容：node-3 在本地终端用 plain `git push` 推本文件到 origin main，验证 R16 的 24h shell 通道；不跑任何 gh 命令，不使用聊天传入的凭据。
- 本机凭据状态（推送前实测）：`~/.git-credentials` 不存在；`credential.helper` 未设置（所有 scope 均无）；`~/.config/gh/` 不存在；gh 未登录。
- 终端推送结果：见本文件最终版与主聊汇总（推送尝试的报错、远端 HEAD 前后对照在提交后补记于 checkpoint/汇总；本文件经网页 UI 通道上远端）。
