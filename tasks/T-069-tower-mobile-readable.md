# T-069：Tower 移动端可用（T18）

## 来源
Chen 直令 2026-11-18 14:01，第三批 T18。现状：8899 面板按桌面宽度写的，手机打开任务状态与指令列表要么挤在一起、要么横向溢出——出门在外想看一眼进度都看不清。

## 目标
手机打开 8899 能看清任务状态与指令列表，不需要全部功能，能看不崩即可。

## 设计（总控已定，照做）
1. **只改前端样式与布局**（Tailwind 现有体系，不新增依赖、不引新库）：先查 `index.html` 有无 viewport meta，没有就补 `<meta name="viewport" content="width=device-width, initial-scale=1">`；再按移动端逐个修三个视图——TasksView（任务状态列表 + 筛选行）、CommandsView（pending/done 列表）、OverviewView（计数与区块）。
2. **验收线（只认这三条，多一分不做）**：
   - 390×844 视口（iPhone 尺寸）下，三个视图无横向溢出（`document.documentElement.scrollWidth <= 390`）、无文字重叠遮挡、任务状态与指令状态能读清。
   - 筛选行与按钮在窄屏换行排列，不挤出屏幕；详情抽屉与表单在窄屏不撑破布局（能用即可，不要求好用）。
   - 桌面端布局与行为不变（bun test 全过 + build 通过即为回归证据）。
3. **验证方法**：Playwright 无头 Chromium（本机已有缓存 `~/.cache/ms-playwright/chromium-1255`），本地 `python -m http.server` 起静态 dist，390×844 截图三个视图 + 逐页量 scrollWidth；截图与测量结果贴进交付报告。总控验收时会自己重跑一遍。
4. **不做的事**：不改后端、不改 8899、不改契约、不做手势/离线/PWA、不重排桌面布局。

## 约束
- 只改前端；不新增依赖；不改后端、不改 8899、不改契约。
- 移动端只求「能看不崩」，不许借机重做桌面样式。

## 完成标准
- `bun test` 全过；`npm run build` 通过。
- Playwright 移动端验证通过（三个视图无横向溢出、无文字重叠，截图为证）。
- 提交并推到 integration 分支。

## 交付报告（回给我时附上）
- 交付 commit SHA（integration 分支）
- 验证证据（bun test 输出 + build 输出 + 三个视图的 390×844 截图路径与 scrollWidth 测量值）
- C11.2 三行：打算 / 最可能失败的两处 / 第一次失败后改什么；若第二次仍失败：停手，按 C11 咨询，不再试第三条路
- 尝试差异表（若有失败重试，写 ATTEMPT 1 与 ATTEMPT 2 的差异）

注意：不要自审，不要改任务书外的东西。开始。
