# 凭据轮换记录：node-2 明文 PAT（2026-11-15 17:1x +08）

## 起因
node-2 于 2026-11-14 的直令消息里收到一枚明文 PAT（GitHub 上名为 `muse-hub-push-3`），
该值此后一直留在其聊天记录中；同一枚也曾写入本机 `~/.git-credentials`。属 R5 红线暴露面。

## 处置（按时间）
1. 定位：GitHub 设置页 fine-grained token 列表仅一枚 `muse-hub-push-3`（token id 22756756，
   创建 2026-11-11，到期 2027-02-09，仓库 xy3293/muse-hub，Contents: RW）。经会话验证（sudo）后进入详情页。
2. 新凭据：node-2 自行执行 `gh auth login --hostname github.com --git-protocol https --scopes repo`
   走 device flow；设备码由 Chen 在已登录浏览器（本地 Chrome，profile `muse/profiles/github`）批准。
   **token 全程未进入任何聊天正文。**
   首个设备码 `449D-3328` 因会话验证耗时过期，重取后成功。
3. node-2 自检：`gh auth setup-git` → `gh auth status`（已登录 xy3293）→ `git ls-remote origin main` 成功
   → `git push --dry-run origin main` 返回 `Everything up-to-date`（exit 0），**全程未弹审批卡**。
4. 旧 token 撤销：在上述浏览器内删除 `muse-hub-push-3`；删除后以旧值调 `GET /user` 返回 **401**，确认失效。
   Chen 侧本地副本改名归档为 `muse/gh_pat3.txt.dead-20261115`（值不再可用）。
5. 残留：旧值文本仍存在于 node-2 的聊天记录里，但已失效（401），不构成可用凭据；记录不做删除以免改动审计。

## 结论
- node-2 现有凭据形态：`gh` OAuth 令牌（设备码获取，落盘由 gh 管理），`credential.helper=!gh auth git-credential`；
  `~/.git-credentials` 不存在（0 行），无明文 PAT。
- 仓库侧不再有任何 PAT 值；Chen 侧仅保留 dead 存档。
- 该轮换未产生审批卡，未改动仓库文件（node-2 仅做了一次 pull --rebase 同步，无推送内容变更）。
