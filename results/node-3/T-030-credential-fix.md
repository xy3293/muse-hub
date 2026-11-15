# T-030 凭据修复报告（node-3）

- 任务：T-030 修 node-3 克隆凭据 helper（store 旧凭据失效，改走 gh）
- Issue：#31
- 负责人：node-3
- 执行时间：2026-11-15 21:03–21:10 CST
- 交付路径：results/node-3/T-030-credential-fix.md

## 结论

**未执行修复，任务书前提全部不成立，本机不存在所描述的失效凭据问题，无修复可做。**

核实结果：本机 muse-hub 克隆的 credential.helper 从未设置过（不是 store）；gh 未登录任何 GitHub 主机；`~/.git-credentials` 文件不存在；git 用户名和邮箱也未设置。所谓“store 里存的旧凭据失效”在本机上没有对应的事实。步骤 1（把 helper 改为 `!gh auth git-credential`）有意未执行：gh 既然未登录，改了也达不到“后续推送走已登录的 gh”这一目标，只会造成 node-3 已具备 gh 推送通道的假象。建议总控关闭 T-030（不适用），并核实“T-029 推送曾因旧凭据被拒”这一说法的来源。

本报告不含任何凭据值、token、设备码（本机也没有可贴的东西）。

## 核实结果（命令与输出）

执行时间 2026-11-15 约 21:04 CST，工作目录 `~/workspace/muse-hub`，远端 HEAD 为 ad5338e1d07a99a3faaab3b2d75a751d3135deb0。

本地 credential.helper（本克隆）：

```
$ git config --get credential.helper
（无输出，exit=1，未设置）
```

全局 credential.helper：

```
$ git config --global --get credential.helper
（无输出，exit=1，未设置）
```

全量 credential 相关配置扫描：

```
$ git config --list --show-origin | grep -i credential
（无输出，exit=1，全库无任何 credential 配置项）
```

gh 登录状态（gh 2.102.0）：

```
$ gh auth status
You are not logged into any GitHub hosts. To log in, run: gh auth login
（exit=1）
```

`~/.git-credentials` 是否存在（只查存在性，未打开、未读内容）：

```
$ ls -l ~/.git-credentials
ls: cannot access '/home/hatch/.git-credentials': No such file or directory
```

git 身份：

```
$ git config user.name; git config user.email
（均无输出，未设置）
```

匿名读取基线（未改任何配置前）：

```
$ git ls-remote origin main
ad5338e1d07a99a3faaab3b2d75a751d3135deb0	refs/heads/main
（exit=0）
```

## 前提逐项对照

任务书和 Issue #31 的三项“已知事实”，逐项核实结果如下：

- “T-029 报告推送时，首次推送因本地 credential.helper=store 存的旧凭据失效被拒；改用单次 gh auth git-credential 后成功”——**与可查记录不符**。T-029 报告是经工具层推送交付的（commit fe29de4，blob 已读回核实），不是 shell git push；且本机当时和现在都没有 store helper、没有 `~/.git-credentials`、gh 也未登录，一次“因旧凭据被拒又改走 gh 成功”的 shell 推送在本机上没有发生条件。本报告无法取得 T-029 执行当时的 shell 记录，该说法的原始来源标记为“未验证”，请总控核实。
- “本机 gh 已登录”——**不成立**。`gh auth status` 明确输出未登录任何 GitHub 主机。
- “`~/.git-credentials` 里有失效的旧凭据”——**不成立**。该文件不存在。

## 为什么不执行步骤 1

- 目标是“让后续推送走已登录的 gh”，而 gh 未登录，改 helper 达不到目标；一次指向未登录 gh 的 helper 只会让日后 shell 推送在 gh 认证处失败，并不解决任何实际问题。
- 任务书步骤 3 的验证对公开仓库没有证明力：`git ls-remote origin main` 在不设置任何 helper 的情况下已经能通，通或不通都与“不再走旧凭据”无关。真正的证明只能是一次 shell 测试推送，而 node-3 不走 shell 推送，且本机也没有可供 shell 推送的凭据。
- 渠道层面：Chen 已于 2026-11-15 00:29 决定放弃 node-3 shell 通道，现行 RULES.md R16（32029ff）只列总控、node-1、node-2 为 shell 推送，node-3 为工具层加逐次审批卡。把 helper 改走 gh 是向 shell 通道迈的一步，在前提失实的情况下不应借一次修凭据任务悄悄迈出；如需 gh 通道，应由 Chen 直接决定并安排合规登录，node-3 不自行发起 `gh auth login`。
- 安全边界遵守情况：未删除、未读取 `~/.git-credentials`（文件不存在，未做任何操作）；未运行 `gh auth login`；未改全局配置；未借用总控凭据；未改动 BOARD.md。

## 验收标准逐项

- 克隆的 credential.helper 已改为 `!gh auth git-credential`——**未达成，有意未改**，原因见上节。前提不成立时按字面改配置，是让验收清单通过、而实际目标落空的做法。
- `git ls-remote origin main` 能通——**是，但基线即通**，与修复无关，不作为修复有效的证据。
- 未删、未读 `~/.git-credentials` 内容——**是**。
- 报告在约定路径，远程可读；报告无凭据值——**报告已写在约定路径**；远程可读待本次工具层推送获批后读回核实；报告全文无任何凭据值。

## 建议

- 总控关闭 T-030（不适用）：本机无旧凭据、无 store helper、gh 未登录，任务描述的问题不存在。
- 总控核实“T-029 推送曾因旧凭据被拒”的来源：如该说法来自某次真实发生的失败，请给出当时的命令输出或记录；如查无来源，应在 Issue #31 留下更正，避免后人按错误前提再次派活。
- 如未来确实需要 node-3 走 gh 推送，请由 Chen 直接决定，并安排合规的登录与凭据投放通道；在此之前 node-3 继续走工具层推送、逐次审批卡。

## 复核与交付（2026-11-15 21:18-21:25 CST，stuck-task re-wake）

- 21:03 的首次执行已退出：报告文件自 21:07:12 CST 后未再改动，且无待审批的推送卡。21:18 巡逻因 BOARD 仍显示待领触发 stuck-task re-wake（age_seconds 900），本轮按任务书 resume_policy 恢复执行，不重复核查，只补交付。
- 本轮独立重跑全部核实命令，结果与上文一致：本克隆与全局均未设 credential.helper，全库 git config 无任何 credential 配置项，gh auth status 为未登录任何 GitHub 主机，~/.git-credentials 不存在，git ls-remote origin main 未改配置即通（公开仓库匿名读取）。
- 结论不变：不执行步骤 1，不改 helper。交付为本次工具层推送，推送后读回远端核实。
