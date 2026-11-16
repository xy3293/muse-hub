# T-037：Control Tower Stage 4 —— systemd 部署（服务不再随 VM 更换死亡）

## 背景

Control Tower 测试部署（总控 VM：后端 0.0.0.0:8000＋前端 0.0.0.0:3000）至今已因 VM 更换死亡 **3 次**（2026-11-16 ~02:01、~03:22、~10:05），每次都是手动 nohup 重启。Stage 3 已完成（T-033/T-034 PASS），按 v1.1 计划进入 Stage 4：部署正式化。Chen 2026-11-15 已定：系统级 systemd 服务，应用以独立非 root 系统用户运行。

## 目标

后端＋前端改为 systemd 管理，VM 更换后自动恢复，不再手动重启。

## 现状（总控 2026-11-16 10:05 刚手动重启，已恢复）

- 后端：`~/workspace/muse-control-tower-backend/.venv/bin/uvicorn muse_tower.app:create_app --factory --host 0.0.0.0 --port 8000 --workers 1 --app-dir backend`，工作目录 `~/workspace/muse-control-tower-integration/`（integration 分支，含 D1/D2 修复 c9ea494）。
- 前端：`npx vite --host 0.0.0.0 --port 3000`，工作目录 `~/workspace/muse-control-tower-integration/frontend/`。
- 运行时文件（NOT in repo）：`~/workspace/muse-control-tower/runtime/`——`ct_access_key.txt`、`gh_token.txt`（均 600）、`runtime-config.json`、`tower.db`、`backend.log`、`frontend.log`。
- 后端 env：`CT_ACCESS_KEY_FILE`、`CT_DATABASE`、`CT_ALLOWED_ORIGINS=http://100.111.36.21:3000,http://127.0.0.1:3000`、`CT_GITHUB_REPO=xy3293/muse-hub`、`CT_GITHUB_TOKEN_FILE`、`CT_RUNTIME_CONFIG`。
- 当前验证：`curl http://127.0.0.1:8000/healthz` → `{"status":"ok"}`；前端 `http://127.0.0.1:3000` → 200。

## 交付要求（Codex）

1. 创建独立非 root 系统用户（如 `muse-tower`）运行应用；该用户仅能读运行时文件（密钥文件保持 600、属主为该用户或总控可读）。
2. 写两个 systemd unit（后端、前端），`Restart=always`，`After=network-online.target`；前端依赖后端（`After=muse-tower-backend.service`）。
3. unit 文件与部署说明（安装命令、启停命令、日志查看命令）写入 Control Tower 私有仓库（`xy3293/muse-control-tower`，integration 分支），不进公开的 muse-hub。
4. 在本机安装并启用（`systemctl enable --now`），验证：`systemctl status` 两服务均为 active；`curl /healthz` ok；前端 200；`systemctl restart` 后两者自动恢复。
5. **验证 VM 更换恢复**：无法真的换 VM，改为验证等价项——`sudo systemctl stop` 两服务再 `start`，确认自动拉起；并记录 unit 的 `Restart=always` 与 enable 状态（`systemctl is-enabled` 均为 enabled）。
6. 密钥与 token 不得写入 unit 文件明文（用 `EnvironmentFile` 或 `_FILE` 指向 runtime 目录的现有文件）；不得把 `gh_token.txt`、`ct_access_key.txt` 的内容写进任何仓库文件、日志或 Issue。

## 验收标准

- 两服务均为 systemd 管理、`enabled`＋`active`，重启后自动恢复。
- 后端 `/healthz` ok、前端 200；后端仍返回真实数据（33 任务）。
- 部署文档在私有仓库，含完整启停/排障命令。
- 无密钥泄露（grep 仓库确认）。

## 执行方

Codex（总控 VM 上跑）。Antigravity 复核（部署文档＋unit 正确性）。
