# 裁决：连接器凭据禁令的范围（snapshot-push.md:10-11）

- 裁决人：Chen（muse-hub 账号持有人、连接器所有者）
- 日期：2026-11-14（+08）
- 触发：T-020 期间 node-3 两次拒绝配置 shell/gh 写通道，引本条文为据（见 Issue #21、#22 记录）。
- 性质：**范围解释**。本文件按 R17 不产生授权，只回答「那条禁令管到哪里」。执行授权仍须
  Chen 向被执行账号直接发出的聊天指令，或 Chen 在审批卡上的点击。

## 一、争议条文原文

位置：`/opt/hatch/connectors/github/references/snapshot-push.md:10-11`（连接器包，不归本仓库维护）

> Never start a separate authentication flow using `gh auth login`, device authorization,
> PATs or OAuth tokens supplied in chat, or credentials embedded in Git commands.

主文档 `CONNECTOR.md:68` 要求推送前读这份 reference。该 reference 标题为 snapshot push 操作规程
（"Read this procedure before creating a branch or pushing local files"）。

## 二、两种读法

- **宽读**：该账号一切 GitHub 访问，均不得出现新的认证凭据；任何让凭据落到本机的方式都算违规。
- **窄读**：本条文位于 snapshot push 操作规程内，规范的是「用连接器推文件这条流程里，不要为该流程
  另行取凭据」。它约束的是「发起认证的一方」，不是「消费既有凭据的一方」。

## 三、裁决

**采窄读，边界如下：**

1. 禁令约束的动词是 `start`，主体是发起认证的一方。节点自己跑 `gh auth login`、自己触发 device
   authorization、自己接收或转贴 PAT/token、把凭据嵌进 Git 命令 —— 一概在禁令内，无例外。
2. 节点以 plain `git push` 消费**所有者在其一侧完成授权后落盘的凭据**（`~/.git-credentials` 600，
   或所有者本人安装的 credential helper），不构成 "start a separate authentication flow"。
   区别在**谁发起**，不在存法。
3. 凭据永不得进入仓库、Issue 评论、报告正文、聊天消息正文。此条无例外，且优先于本条任何其他句子。
4. 窄读只覆盖 `xy3293/muse-hub` 一个仓库、只覆盖 Contents: write、只覆盖上述存法。超出任一项，回到宽读。

## 四、归因与核验（节点不必自证的部分）

- 所有者在其一侧完成授权，结果物为 `~/.git-credentials`（600）。
- 本轮前后节点**不得执行任何 gh 命令**（含 `gh auth login`、`gh auth setup-git`、`gh auth status`）。
  节点侧零认证动作，这是可被检查的事实，也是本裁决成立的前提。
- 所有者书面记录（另存 `RULINGS/2026-11-14-credential-scope.evidence.md`）：执行位置（哪台机器/哪个
  shell）、命令、时间、落盘文件 SHA-256。
- 节点只记录该记录的位置与 SHA-256，**不承担验证「谁点了设备码」的义务**，也不得因无法验证归因而
  二次拒绝。归因是裁决人的责任，不是节点的。
- 上述前提任何一条不成立（例如凭据是经节点会话传入的），窄读不适用，回到宽读。

## 五、效力与文本优先级

- 本裁决自提交 `6e01db8`（2026-11-14，与 R16 修订同批）起生效，关闭 R16 适用名单争议。
- 文本优先级（高 → 低）：平台文档原文 > `RULES.md` > `RULINGS/` > 任务消息 > 节点自身判断。
- 本裁决**不改写、不取消** vendor 原文，只解释其适用范围；被解释的原文在本文第一节逐字引用。
- vendor 文件不由本仓库维护，因此**不在 `references/` 里加段**：指针放在 `RULES.md` R16 与 R19。
  任何在该 vendor 文件里出现的「范围说明」都不是本裁决，不具效力。

## 六、复现与范围复查

同一禁令同样覆盖总控 gh 登录、node-1 的 PAT、node-2 的 device-flow 令牌等既有做法；本裁决对四号
一致适用，不因账号不同而不同。若要改宽读（收回三方凭据、全部回工具层），另出裁决，本文件不自动失效。
