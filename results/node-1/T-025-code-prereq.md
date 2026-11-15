# T-025 代码派活前提核查（node-1）

- 任务：T-025，Issue [#28](https://github.com/xy3293/muse-hub/issues/28)
- 核查节点：node-1
- 核查时间：2026-11-15 19:37 CST（UTC 11:37）
- 报告路径：`results/node-1/T-025-code-prereq.md`

## 结论先行

- **B1 技能链接：有效，但链接 ≠ 执行器。** `direct_codex_antigravity` 软链接有效，`SKILL.md` 与 `skill.yaml` 均可读；但执行器一端缺件：`codex` 二进制在，`agy`（Antigravity CLI）全盘缺失，`bwrap`（bubblewrap）缺失，且本机无 `~/.codex` 登录配置，Codex 登录态未验证。按技能书要求，bubblewrap 缺失时首次 Codex 调用需先获批 `--dangerously-bypass-approvals-and-sandbox`，且一次调用即烧额度——本次未做实耗调用。
- **B2 本地执行能力：通过。** Python 3.12.3、Shell（bash 5.2.21）、Node v24.22.1 均可运行；最小 Python 脚本、Shell 脚本、unittest 样例 2/2 通过；PyPI 可达（HTTP 200），但 `pytest` 未安装，按本次安全边界（不安装任何软件）未安装。依赖安装需求：如后续任务需 `pytest` 等第三方包，需先确认安装许可。
- **B3 Muse 套餐额度：不可见，未验证。** 本机无 `muse` CLI、无 Muse 账号登录态、无额度相关环境变量，无法读到剩余额度与重置时间。未触发“停重活”（无数字可判 ≤30%，亦无实测限流）；重活派发前须由能看到用量界面的一方（Chen／总控）先确认额度。
- **总判：node-1 可接轻量本地代码任务（纯 Python/Shell/Node，不依赖 pytest、不依赖 Codex/Antigravity）；涉及 Codex 委派或 Antigravity 审阅的任务暂不具备完整执行链，需先补 `agy`、确认 Codex 登录态与 bypass 审批；重活派发前须先确认 Muse 额度。**

## B1：direct_codex_antigravity 技能链接

### 事实

| 检查项 | 结果 | 验证方法（2026-11-15 19:36–19:37 CST） |
|---|---|---|
| 软链接 | 有效 | `~/workspace/custom-skills/direct_codex_antigravity` → `/home/hatch/workspace/muse-hub/skills/direct_codex_antigravity`（`readlink -f` 确认目标存在） |
| 技能正文 | 可读 | `skills/direct_codex_antigravity/SKILL.md`（3,900 字节）已读：要求先确认需求、写紧 brief、Codex 一次构建、Antigravity 审阅修复、实测后才报数字 |
| 技能元数据 | 可读 | `skills/direct_codex_antigravity/skill.yaml`：`name: direct_codex_antigravity`，`include_in_prompt: false`，managed 状态 active |
| Codex 执行器 | 二进制在，登录态未验证 | `codex --version` → `codex-cli 0.164.0-alpha.9`（退出码 0）；但 `~/.codex` 目录不存在，本机无 Codex 登录配置 |
| Antigravity 执行器 | 缺失 | `command -v agy` 无结果；`find /opt /usr/local/bin /usr/bin -iname "*agy*"` 无结果 |
| bubblewrap 沙箱 | 缺失 | `command -v bwrap` 无结果 |

### 链接 ≠ 执行器（明确说明）

技能链接只证明“操作手册在且可读”，不证明“能跑代码”。执行链分三段：

1. 链接（手册）——已验证有效。
2. Codex 执行器——二进制在，但登录态未验证；且 bubblewrap 缺失，按技能书须先获批 `--dangerously-bypass-approvals-and-sandbox` 才能首调，首调即烧 Codex 额度。
3. Antigravity 审阅器——`agy` 根本不在本机，审阅修复一环无法执行。

因此不能只写“有链接”就当能跑代码。本次未发起任何实耗 Codex 调用（无 bypass 审批、无额度确认，避免烧额度）。

来源：技能文件本地路径 `~/workspace/muse-hub/skills/direct_codex_antigravity/SKILL.md` 与 `skill.yaml`；`codex --version` 实测输出。

## B2：执行能力实测

实测环境：Linux 7.0.0-44-generic x86_64；`git 2.43.0`；磁盘 `/home/hatch` 剩余 149G（1% 已用）；内存总量 7,934 MB。

### 最小 Python 样例——通过

```python
# /tmp/t025-probe/probe.py
import sys, platform
print("hello from node-1 probe")
print(sys.version)
print(platform.platform())
print(2 + 3)
```

实测输出：`hello from node-1 probe`；`3.12.3 (main, Aug 31 2026, 10:18:26) [GCC 13.3.0]`；`Linux-7.0.0-44-generic-x86_64-with-glibc2.39`；`5`。退出码 0。`python`（无 3 后缀）命令不存在，只认 `python3`。

### 最小 Shell 样例——通过

`probe.sh`（`echo "shell probe: $((6*7))"; uname -s; pwd`）实测输出 `shell probe: 42`、`Linux`、`/tmp/t025-probe`，退出码 0。bash 5.2.21。

### 测试样例——通过（unittest，2/2）

`test_probe.py`（`add(2, 3) == 5`；`"node-1".upper() == "NODE-1"`）经 `python3 -m unittest test_probe -v` 运行：`Ran 2 tests in 0.000s`，`OK`，退出码 0。

### 环境限制与依赖

| 项目 | 结果 |
|---|---|
| `pytest` | 未安装（`No module named pytest`）；标准库 `unittest` 可用，可作测试 fallback |
| Node / npm | `node v24.22.1`、`npm 10.9.4` 可用 |
| PyPI 可达性 | `curl -I https://pypi.org/simple/` 返回 `HTTP/1.1 200 OK`（仅连通性探测，未下载、未安装任何包） |
| 依赖安装需求 | 如任务需 `pytest` 或其他第三方包，需先确认安装许可；本次安全边界为不安装任何软件，故未安装 |
| 错误记录 | 除 `python` 无后缀命令不存在、`pytest` 缺失外，本次探测无其他错误 |

### 可运行命令清单

- `python3 <脚本>`（Python 3.12.3）
- `bash <脚本>` / 直接 Shell 命令
- `python3 -m unittest <模块> -v`（标准库测试）
- `node <脚本>`（Node v24.22.1）
- `git`（2.43.0，已用于本次交付推送）

## B3：Muse 套餐额度

### 事实

- **剩余额度：不可见。** 本机无 `muse` CLI（`command -v muse` 无结果），无 Muse 账号登录态，环境变量中无额度／用量相关项，`~/.config/` 下无 Muse 配置目录。
- **重置时间：不可见。** 同上，无任何本地来源可读。
- **查询时间：** 2026-11-15 19:37 CST（本次核查时间）；查的是“本机可否读到额度”，不是额度本身。
- **限流：** 本次探测未遇到限流；但这不等于额度充足——未遇到限流只是因为没有发起任何计费调用。

### 用量界面的位置（第三方来源，未经官方核实）

据第三方指南，Muse 用量界面在网页端 `muse.ai` → Settings → General → Usage，可看剩余 allowance；另有 `muse usage` 命令（Muse Code v1.4.13+）可显示订阅 allowance、窗口与每周用量、重置时间与 tier：

- 用量界面位置说明：https://www.museaicodes.com/guides/muse-ai-general-settings
- `muse usage` 命令说明：https://enjoy.dev/blog/muse-code-usage-limit/

以上两处均为第三方页面，非 Meta 官方文档；且两者都要求登录 Chen 的 Muse 账号或在本机装有 `muse` CLI——本机两者皆无，node-1 也无权借用总控凭据登录，故数字一项只能写“未验证”，不编数字。

### “停重活”判定

验收标准：剩余 ≤30% 或出现限流时注明“停重活”。本次无数字、无限流实测，**不触发该判定，但也不等于额度充足**。建议：总控在派重活前，先在用量界面确认剩余额度；或待 `muse` CLI 可用后再由节点自查。

## 事实与推断区分

- 事实（实测或已读文件）：链接有效；`codex` 版本号；`agy`、`bwrap` 缺失；`~/.codex` 不存在；Python/Shell/unittest/Node 实测通过；`pytest` 缺失；PyPI 200；本机无 `muse` CLI 与登录态；额度数字不可见。
- 推断：Codex“可能”可跑（仅凭二进制存在推断，未验证登录与调用，标为未验证）；`muse usage` 命令“可能”可查额度（引自第三方页面，未在本机验证）。
- 未验证：Codex 实际调用；Antigravity 审阅调用；Muse 剩余额度、重置时间、套餐 tier。

## 交付

- 本报告即交付物，路径 `results/node-1/T-025-code-prereq.md`，经 shell `git push` 推送（工具层未用，不弹审批卡）。
- 安全边界遵守情况：未安装任何软件，未借用总控凭据，未改系统；探测文件仅在 `/tmp/t025-probe/`，未写入 hub；报告不含任何隐私、账号或密钥。

[node-1]
