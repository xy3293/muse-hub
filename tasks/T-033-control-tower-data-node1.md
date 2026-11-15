# T-033 Control Tower Stage 3 数据真实性核查（node-1）

- 任务：Control Tower Stage 3 数据真实性核查（node-1），按 v1.1 Stage 3 node-1 一节
- Issue：待建（muse-hub）
- 交付物：`results/node-1/T-033-control-tower-data-authenticity.md`
- 预期：30 分钟

## 背景

Control Tower 后端＋前端已集成（integration 分支 d211bd5，合同 1.1.0 冻结于 db649ab）。后端 235 测试通过，前端 23 测试通过，冒烟 371 检查通过，前端已接真实 API（用真实 muse-hub 数据验证过：32 任务、3 节点）。

## 核查内容（逐项给证据，不只给结论）

1. BOARD 数据是否正确：后端读到的 BOARD 任务数、状态分布，与远端 muse-hub BOARD.md（HEAD 0d921a0）逐项比对。
2. Issue 是否正确关联：任务与 Issue 编号的映射是否正确。
3. 任务版本是否正确区分：同一任务多版本（交付、修正、收据）是否按 version_sha 区分，不混淆。
4. 收据与交付是否匹配：收据 event_id / version_sha 是否指向真实交付提交。
5. Hook 状态是否准确：health / scan 状态是否与远端 Hook 记录一致。
6. 数据更新时间是否正确：freshness / refreshed_at 是否真实，不用假时间。
7. 是否出现模拟数据冒充真实数据：全库搜 Mock / SYNTHETIC / 假数据，确认无一处 Mock 数据以真实数据名义展示。

## 方法

- 克隆私库 `xy3293/muse-control-tower`（integration 分支 d211bd5），读 `backend/muse_tower/github.py`、`normalize.py`、`service.py` 的数据映射逻辑。
- 读远端 muse-hub（`xy3293/muse-hub`，公开库）BOARD.md、Issues、收据，逐项比对。
- 可本地运行后端测试（`backend/tests/`）辅助验证；不改代码，不推代码。
- 每项写：检查方法、比对结果、PASS/FAIL、证据（文件＋行号或提交号）。

## 验收

- 7 项全有方法＋结果＋证据；有问题写清缺陷（文件＋行号＋复现），无问题写 PASS。
- 报告在约定路径，无密钥、无凭据。
- 只写最简短的文字：认领评论只写“已领 T-033”，提交说明只写“T-033 数据真实性核查”。
