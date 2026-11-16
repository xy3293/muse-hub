# T-046 独立复核意见（总控独立复核方）

- 复核方：Antigravity（Gemini 3.8 Flash）
- 身份：总控派出的独立复核方
- 复核任务：[T-046-bridge-robustness.md](file:///home/hatch/workspace/muse-hub-git/tasks/T-046-bridge-robustness.md)
- 交付提交：`b725725cb1b1021eb940892cd7748c2f7aea36c7`
- 交付报告：[evidence/T-046-bridge-robustness/REPORT.md](file:///home/hatch/workspace/muse-hub-git/evidence/T-046-bridge-robustness/REPORT.md)
- 复核结论：**PASS**

---

## 一、复核对象与核验方式

1. **桥源码改动核验**：
   - 目标文件：`~/workspace/node3-browser-poc/muse-chat-mcp-test/source/muse-driver.mjs`
   - 补丁重放验证：提交内附带的 `evidence/T-046-bridge-robustness/muse-driver.patch`。经独立沙盒执行 `patch -R` 与正向 `patch` 验证，补丁反向还原后 SHA-256 为 `3e01abac2d53d3edd4b3d1e361d2af214c2b0fe9f28a898d09d88a1487eba448`（修改前基线），再次重放后为 `741782a88f2821f9fdf6c95075a49133d1f9f8ebb280308ef6476c51281ce66c`，与本地文件逐字节完全一致，重放干净无冲突。
   - 语法检查：`node --check muse-driver.mjs` 退出码 0，无语法错误。

2. **证据复跑与验证**：
   - 验收测试：`node --test evidence/T-046-bridge-robustness/acceptance.mjs` 独立复跑，**22/22 测试全部 PASS**（耗时约 25 秒，运行于真实本地 Chromium 159.0.8154.6）。
   - 离线驱动与审批回归测试：`node --test test_approval_patch.js test_director_snapshot.mjs` 独立复跑，**193/193 测试全部 PASS**。
   - Shim 回归测试：`node --test --test-skip-pattern='driver.status computes approval from DOM count=' test_needsApproval_patch.js` 独立复跑，**19/19 测试全部 PASS**。

---

## 二、逐项复核结果

### 1. 四条鲁棒性做法实现核验：PASS

| 模式 | 实现方式与逻辑判定 | 代码行号（muse-driver.mjs） | 判定 |
| --- | --- | --- | --- |
| **多信号判定** | 1. 信号 A：`sels.approvalStack` 容器节点存在（保留原有选择器）；<br>2. 信号 B：容器内匹配识别词汇（`DETECTOR_APPROVE`）的审批按钮存在；<br>3. 信号 C：同一个按钮可见（非零几何尺寸、非 `display:none`、非 `visibility:hidden/collapse`、非 `opacity:0`、非 `hidden/aria-hidden`）且与视口（viewport）和所有祖先滚动/裁剪区域求交后与 `composerRoot` 可视区域相交；<br>4. 判定分支：A+B+C 全真为真审批卡（`approval_card`，`needsApproval=true`）；仅 A 为真为空容器（`empty_container`，`needsApproval=false`）；B 为真但 C 为假记为不可用卡（`unavailable_card`，`needsApproval=false`）；独立处理栈外分享卡（`external_approval`，`needsApproval=true`）。 | `muse-driver.mjs#L298-L381` | **PASS** |
| **状态轮询 + 变化检测** | 定时快照比对（每 150ms 采样一次），连续两次序列化快照完全一致才采信为稳定状态；设有约 2500ms 短超时保护，超时则按最后快照并记录 `stable:false, reason:unstable_timeout`。每个样本记 `sample` 序号与 `changed` 状态。 | `muse-driver.mjs#L383-L402` | **PASS** |
| **矛盾态自愈** | 检测到“发送暂停但无可见审批卡”（`sendPaused && !stackCard && !externalCard`）的矛盾态时：<br>1. 记录自愈事件 `event: recovery, outcome: started, reason: send_paused_without_visible_card`；<br>2. 执行 `page.reload({ waitUntil: 'domcontentloaded', timeout: 10000 })` 并等待输入框渲染可见（上限 3000ms）；<br>3. 重新执行一轮快照轮询并记录结果（`recovered` 或 `unresolved`）；<br>4. 防死循环保护：记录 `_approvalRecovery = { page, url }`，同一页面连续矛盾只 reload 一次，后续直接标记 `already_retried` 并保留 `needsApproval=true`。重试仅重查 DOM，绝不重复提交 prompt，不越权点击。 | `muse-driver.mjs#L404-L429` | **PASS** |
| **误判留痕** | 独立写入专用 `detector-log.jsonl`（默认在源码目录下，可通过 `MUSE_DETECTOR_LOG` 环境变量指定，权限 0600，目录 0700）；记录 ISO 时间戳、事件类型（snapshot/decision/recovery）、上下文、样本数、稳定标记、A/B/C 各信号布尔值、按钮几何可见性明细、暂停证据、矛盾态标记及最终结论。写文件异常降级到 stderr，避免破坏 MCP stdout 或静默丢日志。 | `muse-driver.mjs#L286-L296` | **PASS** |

### 2. 三种验收场景与证据核验：PASS

| 场景 | 对应 Fixture | 判定依据（Signals / 补充） | needsApproval | 结论 | 独立复跑 |
| --- | --- | --- | --- | --- | --- |
| **真审批卡** | `fixtures/approval-card.html` | A: true, B: true, C: true（`允许` 按钮在审批栈内，尺寸可见且与 composer 可视区域相交） | `true` | `approval_card` | PASS |
| **空容器** | `fixtures/empty-container.html` | A: true, B: false, C: false（栈容器存在但内部无审批按钮，无暂停信号） | `false` | `empty_container` | PASS |
| **分享卡（栈外）** | `fixtures/share-card.html` | A: false, B: false, C: false（栈外独立区域检测到 `允许一次` 按钮可见且处于 composer 区域，暂停提示生效） | `true` | `external_approval` | PASS |

- **模拟 DOM vs 真实环境说明核验**：
  - `REPORT.md` 在“DOM 证据与适用范围”章节已明确标注：**“本次三种场景全部是模拟 DOM，使用真实本地 Chromium 渲染；没有当前生产页面实测”**，完全如实披露，没有虚构线上实测。
  - **模拟 DOM 的充分性评估**：测试直接拉起真实本地 Chromium（版本 159.0.8154.6），通过 Playwright route 本地回包，渲染完整 HTML 树并进行真实的 CSS 计算、视口裁剪、滚动溢出计算和 CDP 通信。这不仅验证了三场景的逻辑分支，更深度覆盖了 22 项边界用例（`display:none`、`visibility:hidden`、零宽高、屏外、隐藏祖先、裁剪溢出、非同一按钮拼凑、草稿文本防误判等），足以证明探测算法本身的鲁棒性。

### 3. 限制说明与交付边界合理性：PASS

- **未部署**：报告明确指出三台 live 桥运行在 Chen 的 PC 上，本次仅交付本地源码副本与补丁，未尝试连接或部署远程主机，符合任务书第 59 行要求。
- **真实页面 DOM 与在线回声未验**：报告客观陈述了未验原因（本地环境无 `/opt/google/chrome/chrome`，未启动 8787 shim 端口），并如实附上退出码为 1 的 `selftest.log` 与 `cli.log` 作为负向证据，未作隐瞒。
- **Shim 回归测试显式排除 2 条旧 locator-count 用例**：
  - 经查阅 `test_needsApproval_patch.js:169-188` 源码，被排除的两条用例断言内容为 `assert.equal(needsApproval, count > 0)`，其 fake page mock 仅提供了 `locator.count()` 方法，完全不支持新的 `page.evaluate()` 多信号判定。
  - 任务书明确指出：“踩过两次假阳性坑……现有代码是单信号：只判容器存在……不做单信号数量判定”。因此旧的“容器数量 > 0 即为 true”的用例属于被修复的缺陷行为，在回归测试中显式排除是完全必要且合理的，且 `acceptance.mjs` 中的 `status-serial` 用例已完整覆盖了 `status()` 接口的字段契约和串行队列等待。
- **结论**：上述限制均如实陈述，边界清晰，不影响“本地交付 PASS”的判定。

### 4. 接口与审批授权逻辑不变性核验：PASS

- **接口结构不变**：`status()` 返回结构 `browserRunning, url, loggedIn, viewerId, composerReady, needsApproval, profileDir, headless` 保持 100% 一致。
- **授权词汇隔离**：用于点击授权的决策词汇 `APPROVE_BUTTON = /^(Approve|允许)$/i` 完全未动；探测识别用的 `DETECTOR_APPROVE` 独立定义并加有安全隔离注释，禁止越权触发点击。
- **审批读取逻辑不变**：`_readApprovals()`、`_clickApproval()` 等核心读取与点击方法未作任何修改；`test_approval_patch.js` 193 项审批协议回归测试全部通过。
- **Chat 等待提前返回**：在 `_run()` 消息等待循环中每 1000ms 调用一次探测器，发现审批提前结束等待，避免长达数十秒的无谓挂起，同时保证 prompt 发送、单调输出及收尾判定一致。

### 5. 边界合规性核验：PASS

- **未引入新依赖**：未安装任何外部 package，依赖项沿用现有 `playwright-core`。
- **未改 RULES.md**：提交记录中无任何 RULES 修改。
- **未碰 Chen 的 PC**：未触及 Tailscale、ACL、远程登录或网络代理。
- **未重构服务器架构**：仅改动 `muse-driver.mjs` 中的 detector 判定与状态串行调用。

---

## 三、复核结论

**PASS**

本地交付完全符合 [T-046-bridge-robustness.md](file:///home/hatch/workspace/muse-hub-git/tasks/T-046-bridge-robustness.md) 的各项验收标准，代码修改精准，测试用例详实，限制陈述坦诚，补丁重放逐字节一致。同意由总控统筹安排后续向 Chen 的 PC 部署及生产页面 DOM 核验。
