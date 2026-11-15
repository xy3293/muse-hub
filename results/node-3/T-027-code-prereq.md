# T-027 代码派活前提核查（node-3）

- 任务：T-027 代码派活前提核查（node-3），A/B 包 B1+B2+B3 步
- 任务书：tasks/T-027-code-prereq-node3.md
- Issue：https://github.com/xy3293/muse-hub/issues/34
- BOARD 行：https://github.com/xy3293/muse-hub/blob/main/BOARD.md（T-027，node-3，待领）
- 核查时间：2026-11-15 22:23–22:30 CST（14:23–14:30 UTC）
- 执行状态：STARTED（首项实质工作即探测完成后）→ 核查完成 → WAITING_APPROVAL（本报告待推送审批）
- 排队说明：任务书要求按 T-022 → T-024 → T-027 顺序排队；T-022、T-024 均已完成并验收，本任务无排队阻塞。

## 结论先行

- **B1 技能链接：有效，但链接不等于执行器。** `direct_codex_antigravity` 软链接有效，`SKILL.md` 与 `skill.yaml` 均可读，克隆已同步到 9943e5a；但执行器一端缺件：`codex` 二进制在（0.164.0-alpha.9），`codex login status` 明确返回 Not logged in（`~/.codex` 下只有 tmp，无登录配置）；`agy`（Antigravity CLI）全盘缺失；`bwrap`（bubblewrap）缺失。按技能书要求，bubblewrap 缺失时首次 Codex 调用需先获批 `--dangerously-bypass-approvals-and-sandbox`，且一次调用即烧 Codex 额度——本次未做任何实耗调用。
- **B2 本地执行能力：通过。** Python 3.12.3、Shell（bash 5.2.21）、Node v24.22.1、git 2.43.0 均可运行；最小 Python 脚本、Shell 管道、unittest 样例 2/2 通过；PyPI 可达（HTTP 200）；`pytest` 未安装，按本次安全边界（不安装任何软件）未安装。依赖安装需求：如后续任务需 `pytest` 等第三方包，需先确认安装许可。
- **B3 Muse 套餐额度：不可见，未验证。** 本机无 `muse` CLI、无 Muse 账号登录态、无额度相关环境变量，`~/.config/` 下无 Muse 配置目录（只有一个放巡逻节点标识的 muse-hub 目录）。剩余额度与重置时间均无数字可报。未触发“停重活”（无数字可判是否 ≤30%，亦无实测限流）；重活派发前须由能看到用量界面的一方（Chen／总控）先确认额度。
- **总判：node-3 可接轻量本地代码任务（纯 Python/Shell/Node，不依赖 pytest、不依赖 Codex/Antigravity）；涉及 Codex 委派或 Antigravity 审阅的任务暂不具备完整执行链，需先补 `agy`、恢复 Codex 登录态、获批 bypass；重活派发前须先确认 Muse 额度。**

## B1：direct_codex_antigravity 技能链接

### 事实

| 检查项 | 结果 | 验证方法（2026-11-15 22:23–22:24 CST） |
|---|---|---|
| 软链接 | 有效 | `~/workspace/custom-skills/direct_codex_antigravity` → `/home/hatch/workspace/muse-hub/skills/direct_codex_antigravity`（`readlink` 确认目标存在） |
| 技能正文 | 可读 | `skills/direct_codex_antigravity/SKILL.md` 已读：要求先确认需求、写紧 brief、Codex 一次构建、Antigravity 审阅修复、实测后才报数字 |
| 技能元数据 | 可读 | `skills/direct_codex_antigravity/skill.yaml`：`name: direct_codex_antigravity`，`include_in_prompt: false`，managed 状态 active |
| 技能文件在库 | 已跟踪、已同步 | `git ls-files skills/direct_codex_antigravity/` 列出 SKILL.md 与 skill.yaml；克隆已同步到 9943e5a（`git pull --ff-only` 成功） |
| Codex 执行器 | 二进制在，未登录 | `codex --version` → `codex-cli 0.164.0-alpha.9`（退出码 0）；`codex login status` → `Not logged in`（退出码 1）；`~/.codex` 下只有 tmp |
| Antigravity 执行器 | 缺失 | `command -v agy` 无结果；`find /opt /usr/local/bin /usr/bin -iname "*agy*"` 无结果 |
| 沙箱 | 缺失 | `command -v bwrap` 无结果（bubblewrap 不在） |

### 推断

1. 技能链接本身完好，同步方式可靠（git pull 即同步技能）。
2. Codex 执行器——二进制在，但明确未登录；且 bubblewrap 缺失，按技能书须先获批 `--dangerously-bypass-approvals-and-sandbox` 才能首调，首调即烧 Codex 额度。登录恢复需走 OAuth／设备码流程，不在本任务范围内，未发起。
3. Antigravity 审阅器——`agy` 根本不在本机，审阅修复一环无法执行。

因此不能只写“有链接”就当能跑代码。本次未发起任何实耗 Codex 调用（无 bypass 审批、无额度确认，避免烧额度）。

来源：技能文件本地路径 `~/workspace/muse-hub/skills/direct_codex_antigravity/SKILL.md` 与 `skill.yaml`；`codex --version` 与 `codex login status` 实测输出。

## B2：执行能力实测

实测环境：Linux 7.0.0-44-generic x86_64；git 2.43.0；磁盘 `/home/hatch` 剩余 149G（1% 已用）；内存总量 7,934 MB；`/tmp` 为 512M tmpfs。

### 最小 Python 样例——通过

文件 `/tmp/t027-probe/test_sample.py`（探测用临时文件，不在仓库内）：

```python
def add(a, b):
    return a + b

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0

if __name__ == "__main__":
    test_add()
    print("sample test passed")
```

运行 `python3 /tmp/t027-probe/test_sample.py`，输出 `sample test passed`，退出码 0。Python 3.12.3，`pip3` 在 `/usr/bin/pip3`。

### 测试样例（unittest）——通过 2/2

文件 `/tmp/t027-probe/test_calc.py`，`python3 -m unittest test_calc -v` 输出：

```text
Ran 2 tests in 0.000s

OK
```

退出码 0。

### Shell 样例——通过

`echo "hello shell" | tr a-z A-Z` 输出 `HELLO SHELL`；`/tmp` 可写；`date`、`df`、`free` 均正常。

### 可运行命令与环境限制

| 命令 | 版本／结果 |
|---|---|
| `python3` | 3.12.3，可运行 |
| `pip3` | 在 `/usr/bin/pip3`，未实测安装（安全边界禁止安装） |
| `bash` | 5.2.21，可运行 |
| `node` | v24.22.1，可运行 |
| `npm` | 10.9.4，可运行 |
| `git` | 2.43.0，可运行 |
| `codex` | 0.164.0-alpha.9，二进制可运行，但未登录（见 B1） |
| `agy` | 缺失 |
| `bwrap` | 缺失 |
| `pytest` | 未安装（`python3 -m pytest` → No module named pytest） |

### 依赖安装需求与错误

- 实际遇到的错误：`pytest` 缺失。按任务书安全边界“不安装任何软件”，本次未安装；后续任务若需 pytest 式测试，需先确认安装许可，或改用标准库 `unittest`（已验证可用）。
- PyPI 可达：`curl https://pypi.org/simple/` 返回 HTTP 200（4.58 秒），网络安装通道本身是通的，只是本次未用。
- 其余探测均无错误。

## B3：Muse 套餐额度

### 事实

- **剩余额度：不可见。** 本机无 `muse` CLI（`command -v muse` 无结果），无 Muse 账号登录态，环境变量中无额度／用量相关项（只按名字匹配到 PATH 与 JARVIS_TRACE_CONTEXT，未打印任何变量值），`~/.config/` 下无 Muse 配置目录（仅有 `muse-hub/node-id`，那是巡逻 Hook 的节点标识文件，与套餐无关）。
- **重置时间：不可见。** 同上，无任何本地来源可读。
- **查询时间：** 2026-11-15 22:26–22:27 CST（14:26–14:27 UTC），结论为“不可见”。
- **限流：** 未观测到。本次未发起任何烧额度的调用，无从触发限流；也没有收到任何限流信号。

### 推断

- “停重活”条件无法判定：无数字可判剩余是否 ≤30%，亦无实测限流；因此既不断言停重活，也不反向保证额度充足。**重活派发前，须由能看到用量界面的一方（Chen／总控）先确认额度。**
- 与 node-1 的 T-025 报告结论一致（同机型环境下 B3 同样不可见），属于本机环境的固有限制，不是本轮探测失误。

来源：本机实测（`command -v muse`、环境变量名匹配、`~/.config/` 目录清单）；对照 `results/node-1/T-025-code-prereq.md` 的 B3 一节。

## 验收标准对照

- B1：技能链接有效（链接路径与验证方法见上表）；已明确说明链接不等于执行器（Codex 未登录、agy 缺失、bwrap 缺失）。
- B2：最小 Python、Shell 及测试样例均已实测，可运行命令、环境限制、依赖安装需求和错误均已记录。
- B3：已查用量界面可及的全部本地来源，结果为不可见，已注明查询时间；未触发“停重活”，但重活须先由 Chen／总控确认额度。
- 报告在约定路径 `results/node-3/T-027-code-prereq.md`，待推送后远程可读。

## 执行附记

- Issue #34 正文与任务书一致（经 GitHub connector `search_issues` 读回；`get_issue` 未被 MCP 服务端提供，`list-tools` 曾一次返回 503，重试后恢复）。Issue #34 链接：https://github.com/xy3293/muse-hub/issues/34
- 同步本轮：`git pull` 初次因本地未跟踪文件 `results/node-3/T-030-credential-fix.md` 与远程同名文件冲突而中止；核对该文件与远程提交 d5483ea 的内容完全相同后删除本地副本，并丢弃本地对 `results/node-3/T-016-node-patrol-180-pachat-hook.md` 的未推送修改（已被总控作废的 Stage B 补写），随后 `git pull --ff-only` 成功同步到 9943e5a。BOARD.md 未改；成功任务不发 Issue 评论。
- 本报告只做探测与记录，未安装任何软件，未改系统，未借用任何凭据，未发起 Codex／Antigravity 调用。
- 补记（2026-11-15 22:54 CST 巡逻重唤）：重唤时本报告仍为本地未推送状态（不在 HEAD、不在远端），前一执行已退出、无待决审批卡；本轮复核了关键结论（`codex login status` 仍为 Not logged in，bash 5.2.21、git 2.43.0、磁盘剩余 149G 均与上文一致），未改动正文结论，仅补本条后一次推送交付。
- 补记（2026-11-15 23:09 CST 巡逻重唤，本轮）：重唤时报告仍为本地未推送状态（HEAD 仍为 4b39e21）；前两次推送卡分别于 22:29、22:41 CST 发起、均超时未批；本轮于 23:18 CST 复核关键结论（技能链接有效、`codex login status` 仍为 Not logged in、Python 3.12.3、bash 5.2.21、node v24.22.1、git 2.43.0、磁盘剩余 149G、agy/bwrap/muse 均缺失、最小 Python 与 Shell 样例通过）与上文一致，未改动正文结论；另有一枚 23:08 CST 发起的 Issue #34 评论审批卡待决，非本轮发起，本轮未动；仅补本条后一次推送交付。
