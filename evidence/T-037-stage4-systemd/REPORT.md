# T-037 验收报告：Control Tower Stage 4 systemd 部署

- 任务：T-037（Issue #39），执行方 Codex，复核方 Antigravity
- 交付提交（私有库 xy3293/muse-control-tower，integration 分支）：`da2247c9678aacd5b3156a5c6bf91cd6b13291ec`（已推远端）
- 验收结论：**PASS**

## 交付内容（3 文件，345 行）

- `deploy/README.md`（291 行）：部署文档——安装、启停、日志查看、排障命令
- `deploy/systemd/muse-tower-backend.service`（31 行）
- `deploy/systemd/muse-tower-frontend.service`（23 行）

## Codex 交付自述

- sudo 可用；应用以独立非 root 用户 `muse-tower` 运行
- 两服务均 `enabled`、`active`，`Restart=always`
- healthz ok、前端 200；真实任务 37 条，部署前后相同
- restart、stop/start、进程退出自动恢复验证均通过
- 两份密钥保持 600；仓库及日志扫描零匹配

## 总控独立核验（2026-11-16 10:35）

- `git log`：da2247c 在 c9ea494 之上，工作区干净
- `systemctl is-enabled`：backend、frontend 均为 enabled
- `systemctl is-active`：两者均为 active
- `curl 127.0.0.1:8000/healthz` → `{"status":"ok"}`
- `curl 127.0.0.1:3000` → 200
- `id muse-tower` → uid=999，非 root
- unit 文件在位：`/etc/systemd/system/muse-tower-{backend,frontend}.service`
- 密钥扫描：deploy/ 无 ct_access_key 前缀匹配

## Antigravity 复核：PASS（2026-11-16 10:37）

5 项全过：unit 配置正确、部署文档完整一致、服务真实状态健康、密钥未泄露（精确特征交叉匹配＋git grep 零匹配）、交付完整性（3 文件、干净、基于 c9ea494）。

## 背景

测试部署此前因 VM 更换死亡 3 次（2026-11-16 ~02:01、~03:22、~10:05），均手动 nohup 重启。本次 systemd 化后，VM 更换由 systemd 自动恢复，不再手动重启。
