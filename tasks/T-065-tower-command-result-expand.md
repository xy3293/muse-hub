# T-065：Tower 指令结果可回溯展开（T14）

## 来源
Chen 直令 2026-11-18 10:01，第二批 T14。现状：done 列表只显示状态与一两句 detail，看不到 result 全文（含 artifacts），出了问题无法回溯当初到底产出了什么。

## 目标
done 列表点一条能展开，看 result 全文：id、status、by、at、detail、artifacts。

## 设计（总控已定，照做）
1. **展开交互**：`CommandsView.tsx` 的 done 列表每条可点击展开/收起（独立开关，不必单开）；展开区显示 result 全文，字段按 key-value 行排布：id、status、by、at（本地时间格式）、detail、artifacts（逐条列出）。字段缺失时该行省略，不显示空值、不报错。
2. **类型**：`commands.ts` 的 `CommandEntry.result` 扩展为 `{ status: string; detail?: string; by?: string; at?: string; artifacts?: string[] }`（8899 的 done 结果文件本就含这些字段，前端按实际返回渲染，缺失即省略）。artifacts 只按文本渲染（SHA/路径原文），**不猜链接**（artifacts 可能属于 muse-hub 或 muse-control-tower，前端没有仓库上下文，猜链接会指错地方）。
3. **状态文案**：展开区 status 按原文显示（done/rejected/failed/cancelled——cancelled 是 T-060 新增的「已撤销」，照实显示）。
4. **静态模式**：done 列表本身只在 live/8899 模式有数据（静态快照不含 commands，T-051 已定），本任务不改变静态模式行为。

## 约束
- 只改前端（CommandsView 相关 + commands.ts 类型 + 测试）；不改后端、不改 8899、不改契约、不新增数据请求。
- 不猜 artifacts 链接；不改提交/刷新逻辑。

## 完成标准
- `bun test` 全过（新增：展开/收起、全文各字段渲染、缺失字段省略、artifacts 逐条、cancelled 状态显示）；`npm run build` 通过。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（bun test 输出 + build 输出）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
