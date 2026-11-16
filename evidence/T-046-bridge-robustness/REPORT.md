# T-046：CDP 桥层鲁棒性

状态：**本地改完、待部署**。仅修改本地桥源码副本；未连接 Chen 的 PC、未部署三台 live 桥。等待 Antigravity 复核、总控终验；部署由总控另行与 Chen 协调。

## 借的是什么模式、为什么不换库

借的是任务书归纳的 browser-use / playwright-mcp 的 DOM 判定模式：多信号交叉验证、轮询快照 diff、矛盾态 reload 后重试一次、逐次记录判定依据。实现继续使用现有 Playwright/CDP，全部 detector 代码保留在 `muse-driver.mjs`，没有新依赖。playwright-mcp 是 MCP 服务器，引入会多一层服务；browser-use 是通用 agent 框架，超出了本桥识别单个界面审批状态的需求。当前缺陷在单信号判定，不需要换库或桥形态。这是对任务书设计的实现说明，本次没有开展第三方库评测。

## DOM 证据与适用范围

**本次三种场景全部是模拟 DOM，使用真实本地 Chromium 渲染；没有当前生产页面实测。** 测试使用全新的临时 browser context，所有页面请求由 Playwright `route.fulfill` 本地响应，没有连接生产浏览器、发送消息到 Muse 或点击真实审批按钮。

选择器先核对了本地源码和历史卡片快照 `node3-browser-poc/approval/real-card-canary-006.json`：历史读卡结果中的决策按钮是 `允许 / 拒绝`，现有 reader 也使用 `Approve / 允许`；保留原来的 approval-stack 与 composer 选择器。历史 JSON 是读卡快照，不能还原几何布局。`允许一次 / 总是允许` 等是任务书指定的兼容词汇；分享卡布局和暂停提示在本次 fixture 中构造，不能视为真实页面 DOM 已确认。

## 实现

- **栈内多信号**：A＝审批栈存在；B＝栈内存在已识别的审批按钮；C＝同一个按钮可见，且与 composer root 的可视区域相交。可视区域取 composer root、浏览器 viewport 与滚动/裁剪祖先区域的交集；检查非零尺寸、display、visibility、opacity、hidden、aria-hidden。A/B/C 全真才认定栈内真卡；仅 A 为真是空容器；B 真但 C 假记为 `unavailable_card`，不混记为空容器。
- **分享卡独立分支**：枚举栈外 composer 或语义 dialog/审批卡区域里的审批按钮，同样检查可见与可视区域。普通 Share 工具栏按钮不属于审批词汇。栈外信号独立记录在 `externalButtons`，不伪造栈内 A/B/C。
- **暂停兜底**：composer 中可见的发送暂停/等待审批提示，或“非空草稿＋Send 禁用＋非 busy/非生成中”，均可构成发送暂停信号。没有任何可见审批控件时返回 `suspected_share_card`，保持 `needsApproval=true` 并进入自愈。草稿中的“Sending is paused”文字不作为 UI 提示；空输入框的普通 disabled Send、正常生成也不单独触发。
- **轮询 diff**：每 150ms 取一次语义快照，连续两次一致才采信；单轮最长约 2500ms，未稳定则采用最后快照，记 `stable:false / reason:unstable_timeout`。每个样本记录 `changed`，每次结论记录命中信号。
- **自愈一次**：对“发送暂停但无可见卡”的矛盾态，先记录 `started` 和原因，reload（10 秒上限），等待 editor 可见（3 秒上限），再进行一次稳定性轮询。记录 `recovered / unresolved / failed`。相同页面、URL 的连续矛盾态只尝试一次，后续记 `already_retried`；观察到正常态后才重新允许下一次自愈。这里的“重试”只重检 DOM，不重复发送 prompt，不执行审批。
- **接入点**：`status()` 经 `_serial` 运行 detector；`_run()` 等待回复期间每隔至少 1 秒检查一次，发现审批便提前返回；收尾复用同一 detector。无需再等完整回复超时才能看到卡。
- **接口**：未修改 `muse-server.mjs`、`muse-openai-shim.mjs`、审批读取/点击/指纹代码或卡片返回结构。`needsApproval` 仍是等待界面审批的布尔值，疑似分享审批按任务书要求可保守返回 true。未更换总线、未引入常驻新服务、未改 RULES、ACL 或 Tailscale。

## 留痕位置

默认写 **源码目录下 `detector-log.jsonl`**，独立于 `send_log.json`；可用 `MUSE_DETECTOR_LOG=/absolute/path/detector-log.jsonl` 指定位置。日志含 UTC 时间、上下文、样本序号、变化标记、稳定性、A/B/C、标准按钮标签及可见性、暂停信号、结论、自愈结果。没有记录 prompt、卡正文、Cookie 或 Token。文件首次创建权限为 0600；写文件失败会把错误和该条证据写到 stderr，避免静默丢日志。验收通过实例级路径将日志隔离到本目录的 [logs/](logs/)。

## 三种场景验收

| 场景（全部模拟） | A | B | C | 补充依据 | needsApproval | 结论 |
| --- | --- | --- | --- | --- | --- | --- |
| 真审批卡 | true | true | true | `允许` 按钮可见且在 composer 可视区域内 | true | `approval_card` |
| 空容器 | true | false | false | 栈内无审批按钮；没有暂停信号 | false | `empty_container` |
| 分享卡（栈外） | false | false | false | `externalButtons` 中 `允许一次` 可见且在区域内；暂停提示可见 | true | `external_approval` |

三条原始判定日志如下；均为连续两次快照一致后采信：

```jsonl
{"at":"2026-11-16T10:58:49.973Z","event":"decision","context":"acceptance","attempt":0,"stable":true,"samples":2,"signals":{"A":true,"B":true,"C":true},"stackCount":1,"buttons":[{"label":"允许","visible":true,"inComposerViewport":true}],"externalButtons":[],"sendPaused":false,"pauseEvidence":{"pauseText":false,"blockedDraft":false,"generating":false},"contradiction":false,"needsApproval":true,"conclusion":"approval_card"}
{"at":"2026-11-16T10:58:50.420Z","event":"decision","context":"acceptance","attempt":0,"stable":true,"samples":2,"signals":{"A":true,"B":false,"C":false},"stackCount":1,"buttons":[],"externalButtons":[],"sendPaused":false,"pauseEvidence":{"pauseText":false,"blockedDraft":false,"generating":false},"contradiction":false,"needsApproval":false,"conclusion":"empty_container"}
{"at":"2026-11-16T10:58:51.110Z","event":"decision","context":"acceptance","attempt":0,"stable":true,"samples":2,"signals":{"A":false,"B":false,"C":false},"stackCount":0,"buttons":[],"externalButtons":[{"label":"允许一次","visible":true,"inComposerViewport":true}],"sendPaused":true,"pauseEvidence":{"pauseText":true,"blockedDraft":false,"generating":false},"contradiction":false,"needsApproval":true,"conclusion":"external_approval"}
```

对应 fixture 与完整日志：

- [真审批卡 HTML](fixtures/approval-card.html)、[完整日志](logs/approval-card.jsonl)。
- [空容器 HTML](fixtures/empty-container.html)、[完整日志](logs/empty-container.jsonl)。
- [分享卡 HTML](fixtures/share-card.html)、[完整日志](logs/share-card.jsonl)。

## 自愈与变化检测证据

[recovery-success.jsonl](logs/recovery-success.jsonl)：初始无 stack、无审批按钮但有暂停提示，先判“疑似分享卡”；reload 后模拟页面出现栈外审批按钮，第二轮判“有卡”。下面是带时间、原因及重试结果的两条自愈记录：

```jsonl
{"at":"2026-11-16T10:59:01.215Z","event":"recovery","context":"acceptance","outcome":"started","reason":"send_paused_without_visible_card","signals":{"A":false,"B":false,"C":false},"stackCount":0,"buttons":[],"externalButtons":[],"sendPaused":true,"pauseEvidence":{"pauseText":true,"blockedDraft":false,"generating":false},"contradiction":true,"needsApproval":true,"conclusion":"suspected_share_card"}
{"at":"2026-11-16T10:59:01.439Z","event":"recovery","context":"acceptance","outcome":"recovered","signals":{"A":false,"B":false,"C":false},"stackCount":0,"buttons":[],"externalButtons":[{"label":"允许一次","visible":true,"inComposerViewport":true}],"sendPaused":true,"pauseEvidence":{"pauseText":true,"blockedDraft":false,"generating":false},"contradiction":false,"needsApproval":true,"conclusion":"external_approval"}
```

[recovery-unresolved.jsonl](logs/recovery-unresolved.jsonl)：暂停状态持续存在，得到 `started → unresolved → already_retried`，两次 detector 调用总共只 reload 一次，始终保留 `needsApproval=true`。[recovery-failed.jsonl](logs/recovery-failed.jsonl) 模拟 reload 抛错，记录 failed 并保留疑似态。

[dom-change.jsonl](logs/dom-change.jsonl) 记录按钮从无到有的 diff，再等待两次一致；[unstable-timeout.jsonl](logs/unstable-timeout.jsonl) 持续改变按钮标签，约 2.5 秒退出并留下 `unstable_timeout`。

## 验证命令与结果

工作目录为 `~/workspace/muse-hub-git`，除非另有标注。

```bash
node --test evidence/T-046-bridge-robustness/acceptance.mjs
# 22 passed / 0 failed；真实 Chromium 159.0.8154.6，页面全部模拟。

# 工作目录：~/workspace/node3-browser-poc
node --test test_approval_patch.js test_director_snapshot.mjs
# 193 passed / 0 failed，包含 GET /v1/muse/approvals 透传、指纹与单次审批约束。
node --test --test-skip-pattern='driver.status computes approval from DOM count=' test_needsApproval_patch.js
# 19 passed / 0 failed。显式排除两条旧“容器数量即审批”的用例；它们已被本次多信号 fixture 替代。

# 工作目录：桥源码 source/
node --check muse-driver.mjs
# exit 0
```

[acceptance.log](acceptance.log)、[approval-regression.log](approval-regression.log)、[shim-regression.log](shim-regression.log) 保存完整输出。22 项新测试还覆盖隐藏/零尺寸/屏外/裁剪、多个按钮不能拼凑 C 信号、草稿文本防误判、稳定性超时、单次自愈和串行状态读取；完整 chat 路径验证原始多行 prompt 原样发送一次、正常回复及单调输出、审批提前返回、reload 后不重复提交 prompt。

仓库要求的两条在线检查也尝试了，**均未通过环境前置条件，不能算在线验收通过**：

```bash
# 工作目录：桥源码 source/；隔离 profile，取消任何现有 CDP 地址。
env -u MUSE_CDP MUSE_PROFILE_DIR=/tmp/t046-selftest-profile MUSE_HEADLESS=1 npm run selftest
# exit 1：本机没有 channel=chrome 所需的 /opt/google/chrome/chrome。
env -u MUSE_SHIM_URL MUSE_CLI_AUTOSTART=0 node muse-cli.mjs 'Say hello in three words.' < /dev/null
# exit 1：本地 127.0.0.1:8787 没有 shim；禁用自动启动以保持本次仅本地验证。
```

见 [selftest.log](selftest.log) 和 [cli.log](cli.log)。模拟验收使用本机已有 Chromium 的显式 executablePath，无安装新依赖。可通过 `MUSE_SOURCE_DIR` 和 `T046_CHROMIUM_EXECUTABLE` 覆盖复跑时的源码和浏览器路径。

## 改动位置与交付

源码：`~/workspace/node3-browser-poc/muse-chat-mcp-test/source/muse-driver.mjs`。

| 行号（本地最终版） | 内容 |
| --- | --- |
| 45 | 原栈选择器保留 |
| 92 | detector 独立词汇，不改变点击契约 |
| 262 | 状态读取通过串行队列 |
| 286 | detector 专用日志 |
| 298 | 多信号、可见区域、栈外/暂停兜底 |
| 383 | 快照 diff、连续一致与短超时 |
| 404 | reload 一次、自愈留痕及防循环 |
| 955 | chat 等待过程中的定期检测与提前返回 |
| 992 | chat 收尾 needsApproval 复用判定 |

源码副本没有 Git 元数据，因此附 [muse-driver.patch](muse-driver.patch) 和 [verification.json](verification.json) 供复核。补丁已在临时目录对本次修改前副本重放，结果与当前源码逐字节一致。

- 修改前 SHA-256：`3e01abac2d53d3edd4b3d1e361d2af214c2b0fe9f28a898d09d88a1487eba448`
- 修改后 SHA-256：`741782a88f2821f9fdf6c95075a49133d1f9f8ebb280308ef6476c51281ce66c`
- 补丁 SHA-256：`89e335deb7e52d230c654f5ca179385abe4761d57e17ea5c6d7636145124c25a`

本次完成本地实现与模拟验收，尚未证明真实页面布局及暂停文案匹配，也未完成在线回声；由 Antigravity 复核后，总控协调部署与真实 DOM 验证。分享卡可识别不等于其详情已能被现有 reader 提取：本任务保留读卡结构与审批授权逻辑，没有扩大自动点击范围。
