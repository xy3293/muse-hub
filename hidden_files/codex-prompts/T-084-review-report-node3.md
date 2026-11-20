# T-084 验收审查报告（node-3 独立核验）

## 结论

**PASS**

被审对象：xy3293/muse-control-tower，分支 agy/T-084，提交 000c736f96286d8b4518cc9a36459b6a88de5014。相对 integration 基线共 12 个 frontend/src/ 文件（11 改、1 新增测试）。本报告所有结论均为审查者在本机独立复跑/复核的结果；两项因执行环境不在本节点而未执行的验证（deploy/verify.sh、真实浏览器核对）单列于第 5 节，附替代证据，请总控决定合并前是否在部署机补跑。

## 第 0 步：权限

- 首轮（2026-11-21 02:37 CST）：连接器读默认分支成功，但 agy/T-084 经 GitHub API 返回 404（分支未推远端），已停手并在 Issue #80 报告。
- 总控补推分支后（02:45 CST 起复核）：连接器可读 agy/T-084 全树，提交与任务书一致，继续审查。

## 1. 设计稿 §5 人话对照表逐项落地（首屏 + 主列表）

逐项核对（设计稿 muse-hub design/control-tower-redesign-gemini.md 第五节，共 8 行）：

1. 快照旧字段 → 「数据更新于 X 前 / 数据已过期，X 前更新」：已落地。components/DataTime.tsx：过期横幅与顶栏均输出相对时间（如「数据已过期，23 分钟前更新」格式），新鲜时保留「新鲜 · 数据更新于 …」。
2. 备忘与待办 (SQLite) → 待办与备忘：已落地。views/NotesTodosView.tsx 标题与说明改完，DutyDesk 折叠区计数文案同步改为「待办与备忘」。
3. WAL / PATCH / 503 → 写入受阻，服务暂不可用（原始码进详情）：已落地。新增 api/errors.ts formatUserError：503 / SOURCE_UNAVAILABLE / SQLite / WAL / PATCH 命中时摘要统一为「写入受阻，服务暂不可用」，原始码、HTTP 状态、原始消息只进折叠详情（App.tsx、AlertBanner、CommandsView、NotesTodosView 均已接入）。
4. 运行时监控 / Runtime Health → 节点状态：已落地。views/RuntimeView.tsx 标题、卡片、错误文案全量替换。
5. Stage 2 / Stage 3 / (CH-11) 直接删除：已落地。OverviewView 删除 (CH-11)，RuntimeView 删除 (CH-11) 与 (O16/O20)，AccessKeyModal 删除 (CH-08 / N05)。
6. commit 哈希 → 已提交交付（详情内可复制完整哈希）：已落地。DutyDesk 列表以「已提交交付」标记替代哈希；DetailDrawer 内完整哈希收入折叠区并带「复制完整哈希」按钮（审查者渲染核对：完整哈希只出现在 details 折叠区内，折叠区外无短哈希）。
7. Heartbeat timeout / Unknown → 节点失联（已超过 X 分钟无响应）：已落地。DutyDesk nodeState 输出「节点失联（已超过 N 分钟无响应）」；失联定义与 T-082/T-083 一致——有在身任务且 age >= 24h 才算失联，无任务为「空闲」，代码核对：lost = !!current_task_id && age >= 24 * HOUR。
8. Payload queued → 指令已发出，预计 1–3 分钟内生效：已落地。CommandsView 第 274 行原文渲染该句。

附带符合任务书要求的折叠化：DetailDrawer 把提交哈希与交付记录、打回与验收明细、耗时拆分、状态明细全部收入 details 折叠区；裁决标签人话化（PASS → 通过、REJECT → 打回、SUPERSEDED → 已替代）。

## 2. 首屏与主列表零工程术语（独立重跑 grep）

范围界定：App 默认页签为 overview，渲染的是 DutyDesk（App.tsx 第 28、82 行），加顶栏 DataTime 与 Navbar——此即首屏；主列表为 DutyDesk 的待处理/等待/折叠列表。

- 源码级 grep（新分支 frontend/src 下 App.tsx、views/、components/、design-system/，模式 Stage|SQLite|WAL|503|CH-11|Runtime Health|运行时监控|Heartbeat 与 7 位以上十六进制片段）：**零命中**（两条命令 grep 退出码均为 1）。
- 渲染级核对（审查者自写脚本，react-dom/server 以 mock 数据渲染）：DutyDesk 渲染 5770 字符零命中且含「已提交交付」；DetailDrawer 折叠区之外零命中。
- 全 src 扫描的其余命中均不在渲染范围：types/api.ts（生成的合同类型注释与 503 响应键）、tests/（含本次新增测试的反向断言）、api/mock-* 与 api/snapshot.ts（内部错误构造与模拟数据，展示层一律经 formatUserError 转换）、api/errors.ts（匹配模式本身）。
- 例外说明：views/OverviewView.tsx 经核对未被 App 引用（仅测试引用），为未挂载的遗留视图；其引用的 FreshnessIndicator 完整模式仍含 (NB-N04)、partial=true、源名直显（含 sqlite 源），见观察项 1。

## 3. 数字口径与可点元素

- 数字口径不变：11 个文件的 diff 逐行审完，变更均为文案、标签映射与折叠结构；计数与阈值逻辑未动（dutyMetrics 未改、nodeState 24h/2h 阈值未改、DataTime 仅新增过期文案的空格处理、CommandsView 180 秒计时未改）。无任何数据字段或统计口径变更。
- 可点元素：首屏与主列表按钮均保留原 onClick（onTask/onNode/onCommand/发指令/重试），无 href="#" 或空 href（grep 零命中）；详情抽屉、折叠区、复制按钮均有实际处理函数。未见死链接，未见新增永久加载状态（loading 仍由原 snapshot 加载流程驱动）。

## 4. 约束

- 无重型依赖：frontend/package.json 与 bun.lock 相对基线零变更（blob 一致）。
- 无动效/渐变/玻璃拟态：本提交未新增任何 animate-/gradient/backdrop-blur/transition 类（diff 增行 grep 零命中），且反向移除了 AccessKeyModal 的 animate-in 与 backdrop-blur-xs 及多处 transition。全 src 无 gradient。既存基线见观察项 2。
- 数据只来自 snapshot.json：diff 未新增任何 fetch/axios/WebSocket 调用；静态模式仍只读 ./snapshot.json；写入在静态模式仍被拒绝（SOURCE_UNAVAILABLE 人话化后展示）。
- 单人不做登录：未新增登录/权限体系；AccessKeyModal 为既存本地密钥配置，仅文案简化。

## 5. 独立重跑验证

在本节点以连接器逐文件重建 agy/T-084 工作树（/tmp 临时副本，未改动任何仓库）后复跑：

- 后端 pytest：**333 passed**（venv 按 backend/pyproject.toml 依赖新建；其中 test_verify.py 3 项需部署机路径 /home/hatch/workspace/muse-hub-git/evidence/pending-decisions.md，本机以符号链接指向本机 muse-hub 克隆后全过）。
- 前端 bun test：**83 passed, 0 failed**（含本次新增 src/tests/copy-cleanup.test.tsx 4 项全过；Stage 3 集成测试经 CT_TEST_PYTHON 指向上述 venv 自启后端 fixture 后全过）。
- 前端构建：**通过**（默认与 VITE_STATIC_MODE=true 两种模式均构建成功，仅 sourcemap 警告）。
- deploy/verify.sh：**未执行**。该脚本核查对象是部署机的实时环境（硬编码 muse-control-tower-integration 路径、systemd 定时器、muse-tower 用户、运行态文件与已部署服务 HTTP 探活），在本节点运行无意义。其代码侧等价物 backend/tests/test_verify.py 19 项全过。如需 28/29 口径数据，请总控在部署机补跑。
- 浏览器核对：**未能以真实浏览器执行**。云端浏览器拒绝访问本机回环地址（127.0.0.1:8901 返回 invalid_request，对照 example.com 可正常打开；本机 curl 该地址 200，服务本身正常）。替代证据为第 2 节的服务端渲染核对（真实组件 + mock 数据渲染后 grep）与全量测试复跑。

## 6. 观察项（不阻塞本次结论，非 T-084 引入）

1. 未挂载的遗留视图 views/OverviewView.tsx + components/FreshnessIndicator.tsx 完整模式仍含工程文案（(NB-N04)、partial=true/false、源名直显 sqlite/vm_local、Ref: local:controltower.db）。当前用户不可见；若将来重新挂载，工程术语会回到总览页，建议后续批次清理或删除。
2. design-system 既存基线（T-084 未触碰的文件）：Card.tsx 含 backdrop-blur-md，tokens.ts/Badge.tsx/Skeleton.tsx/Button.tsx 含 animate-pulse/animate-ping/animate-spin（状态点、骨架屏、加载转圈，属功能指示而非装饰动效），OverviewView 既存 hover:scale 与 transition 类。与本任务「不新增」约束不冲突，是否清零请总控另行定夺。
3. RuntimeView/NodesView/EventsView 使用的 FreshnessIndicator 紧凑模式仍显示英文 FULL/PARTIAL 徽标，不在本次 grep 清单与首屏/主列表范围内，记录备查。

## 证据索引

- 基线与对象：integration 与 agy/T-084 两棵 frontend 树 blob 对比（66 文件，差 12 个）；12 文件逐个 diff 全文审查。
- 命令与结果：源码 grep（两组模式，退出码 1 = 零命中）；渲染核对脚本输出（DutyDesk 5770 字符零命中、DetailDrawer 折叠外零命中）；bun test 83/83；pytest 333/333；vite build 成功（两种模式）。
- 审查者未改动 Tower 任何代码；本地副本仅在 /tmp 临时目录。
