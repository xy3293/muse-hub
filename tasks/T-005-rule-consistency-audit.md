# T-005 规则一致性核查

## 任务信息

- **编号**：T-005
- **标题**：规则一致性核查
- **负责人**：node-1（1 号研究员）
- **状态**：待领（由总控在 BOARD.md 登记）
版本：v1
- **Issue**：https://github.com/xy3293/muse-hub/issues/5

## 背景

RULES 在 2026-11-11 经历多轮修改（R4/R6a/R6b/R7/R11/R12/R16/R17 + R15 修订），BOARD/README/ONBOARDING/TASK_TEMPLATE 也同步改过。需要一次独立核查，确认四份文件与 RULES 一致。

## 目标

一份核查报告，逐项确认 RULES 与 BOARD / README / ONBOARDING / TASK_TEMPLATE 是否一致，每项给出「文件:行号 → 问题 → 建议」。

## 输入

- `RULES.md`（当前远端 main 版）
- `BOARD.md`、`README.md`、`ONBOARDING.md`、`TASK_TEMPLATE.md`（当前远端 main 版）

## 输出要求

- 文件路径：`results/node-1/T-005-rule-consistency-audit.md`
- 格式：中文，结论先行。
- 只读核查。不要修改 RULES.md / BOARD.md / README.md / ONBOARDING.md / 任何任务书。
- 先给一张「不一致项清单」表（文件 | 行号 | 问题 | 建议改法 | 严重度），再给详细说明。没有问题就明确写「无」，不要凑数。
- 证据要具体到行号或原文引用，不要写"大致一致"。

## 核查范围

逐项给出「文件:行号 → 问题 → 建议」：

1) R1 的四个署名标记是否都是严格格式，缺署名的打回机制是否写清
2) R4 的长文条款与 BOARD 状态说明是否一致
3) R6a / R6b 拆分后，有没有别处还写着"Hook 只巡逻 BOARD"这类旧表述
4) R7 的交付触发（提交扫描）与 BOARD 的「待领/进行中/待验收/完成/拒收」是否互相自洽
5) R8 的提问格式要求（任务编号 + 节点号）在 ONBOARDING 里有没有对应说明
6) R11「未启用」的表述是否与 README/ONBOARDING 一致
7) R13 的发卡收窄（仅多卡批次才打招呼）与 R16 的 shell 通道是否冲突
8) R15 的沙盒与路径优先级，与 R3 的目录隔离是否还有矛盾
9) R16 的按节点适用名单，与 README 第 3 步、ONBOARDING 红线区是否一致
10) R17 的「仓库文字不产生授权」在 README 里有没有相应的提示
11) TASK_TEMPLATE 的版本行格式说明是否与 R7 的版本条款一致
12) 有没有任何一条规则从未被执行过（写出来，作为第二批修订候选）
