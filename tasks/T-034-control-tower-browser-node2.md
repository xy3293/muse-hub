# T-034 Control Tower Stage 3 独立浏览器测试（node-2）

- 任务：Control Tower Stage 3 独立浏览器测试，按 v1.1 Stage 3 node-2 一节
- Issue：#36（muse-hub）
- 交付物：`results/node-2/T-034-control-tower-browser-test.md`（node-2 独立评审报告）
- 执行产物：`evidence/T-034-artifacts/`（总控 VM 侧执行，12 张 PNG＋`index.md`）
- 预期：45 分钟

## v2 变更记录（R7）
- 授权：Chen（2026-11-16 03:16 CST 直令，T-034 改路径）
- UTC 时间：2026-11-15 19:16 UTC
- 改了什么：执行机从 node-2 改为总控 VM（VM 的 Tailscale 不接受入站，Windows→VM:3000 refused，node-2 直连被沙箱禁、走代理也 Empty reply，两条“打进去”的路都不成立；能出站的是 VM，那就让 VM 干活、结果推仓库，node-2 从仓库取）。node-2 职责改为独立评审（核对 12 张截图＋`index.md` 是否真实、有无冒充）。不走桥中转（不往 8787–8789 POST 数据），直推 git。

## 背景

Control Tower 后端＋前端已集成并部署在总控 VM 上（integration 分支 d211bd5，合同 1.1.0 冻结于 db649ab；D1/D2 修复已合入 c9ea494）。后端 257 测试通过，前端 23 测试通过，冒烟 371 检查通过，前端已接真实 API（真实 muse-hub 数据：33 任务、3 节点）。

## 测试地址（v2：总控 VM 本地）

- 前端：http://127.0.0.1:3000（总控 VM 本地，执行机即部署机，一定通）
- API Key：总控 VM 本地读取 `~/workspace/muse-control-tower/runtime/ct_access_key.txt`，经 AccessKeyModal 输入（不要写进报告、不要写进 Issue、不要写进提交、不要出现在截图里）
- 首次打开会弹 API Key 输入框（AccessKeyModal），输入 Key 即可进入。

## 测试内容（12 项，逐项截图＋步骤＋预期＋实际＋复现条件）

1. 首页加载。
2. 节点列表。
3. 任务筛选。
4. 任务搜索。
5. 任务详情。
6. 运行监控。
7. 备注保存。
8. 待办创建和修改。
9. 页面刷新。
10. 手机端布局。
11. 错误提示。
12. 空数据状态。

每个失败项提供：页面截图、操作步骤、预期结果、实际结果、复现条件。

## 执行要求（v2，总控 VM）

- 用 headless 浏览器（playwright），对 `http://127.0.0.1:3000` 逐项跑。
- 每项产出一张 PNG，落到 `evidence/T-034-artifacts/`，命名 `01-home.png` … `12-empty-state.png`。
- 另写 `evidence/T-034-artifacts/index.md`：每项一行，含 URL、viewport（1440x900 或 390x844）、执行 UTC 时间、HTTP 状态码、关键断言结果（通过/不通过＋依据）。
- 截图必须是真实渲染结果；不许用 curl 拿 HTML 冒充截图。手机端布局项必须真的用移动 viewport，不得缩放桌面版截图冒充。
- 若某项确实跑不出（比如需要登录态），照实记 FAIL＋原因，不要跳过、不要编。

## node-2 独立评审职责（v2）

- 从仓库取 `evidence/T-034-artifacts/`（12 张 PNG＋`index.md`），逐项核对：截图是否真实渲染（同尺寸重复、像素级相同、缺 viewport 差异都会被抓）、断言是否有依据、FAIL 项原因是否成立。
- 评审报告写到 `results/node-2/T-034-control-tower-browser-test.md`，只报告问题，不直接修改前端代码。
- 报告在约定路径，无密钥、无凭据（API Key 绝不写入报告）。

## 规则

- 只报告问题，不直接修改前端代码。
- 报告在约定路径，无密钥、无凭据（API Key 绝不写入报告）。
- 只写最简短的文字：认领评论只写“已领 T-034”，提交说明只写“T-034 浏览器测试”。
