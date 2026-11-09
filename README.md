# muse-hub · 多 Muse 账号总控台

Chen 的四个 Muse 账号协同工作的中间站。四个号不能直接对话，就都到这里来领任务、交结果、对话。

- **总控（本号，主控账号）**：拆任务、写任务书、验收结果、合入主项目、维护 `BOARD.md`、向 Chen 汇报。
- **1 号 研究员**：深挖研究类任务（首个试点：代币化美股研究）。
- **2 号 执行**：长耗时浏览器活（transcript 提取、频道列表重拉等）。
- **3 号 核查 / 写手**：独立复核数字、打磨报告与 README。

## 怎么工作

1. 总控在 `BOARD.md` 登记任务，在 `tasks/` 写任务书，每个任务对应一个 GitHub Issue（任务书 + 对话线程）。
2. 各号的 Hook 每 5–10 分钟巡逻 `BOARD.md`，有派给自己的新任务才唤醒。
3. 干活的号把结果写进自己专属的 `results/node-X/` 目录，在对应 Issue 下回复一句话 + 文件链接。
4. 总控验收通过后更新 `BOARD.md` 状态，合入主项目，向 Chen 汇报。

## 文件索引

| 文件 | 说明 |
|---|---|
| `BOARD.md` | 任务总表（只有总控能改） |
| `RULES.md` | 群规（必读：权限、隔离、脱敏、交接格式） |
| `TASK_TEMPLATE.md` | 任务书模板 |
| `tasks/` | 任务书，每任务一个文件 |
| `results/node-1/`、`results/node-2/`、`results/node-3/` | 各号专属结果目录，互不写入 |
| `hooks/patrol.sh` | Hook 巡逻脚本模板（各号复制到自己的 `~/hooks/scripts/`） |
| `skills/` | 共享自定义 Skills（各号同步到自己的 `~/workspace/custom-skills/`） |
| `ONBOARDING.md` | 给 1/2/3 号的安装指令（Chen 粘贴用） |

## 先看群规

进场之前先读 `RULES.md`。最关键的三条：**BOARD.md 只有总控能改；各号只写自己专属目录；任何文件与 Issue 里严禁出现真实隐私、账号与密钥。**
