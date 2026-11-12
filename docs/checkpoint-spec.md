# Checkpoint 规范（v1）

**版本：** v1（2026-11-12，工人丢失修复 v2 Stage 1）
**依据：** v2 §3、§5、§6，T-008、T-009 探测结论
**状态：** 总控冻结；改动须总控批准并更新 release-manifest

## 1. 目的

单个 worker execute 回合有约 600 秒超时边界。checkpoint 让任何一个 worker
即使在 600 秒被终止，也不会带走唯一一份工作成果：超时后新 worker 从最新
有效 checkpoint 续跑，已完成阶段不丢失、不重复执行，外部副作用不重复发生。

## 2. 目录结构

checkpoint 位于已验证的共享持久化目录 `/home/hatch/hooks/state/` 下，与
`seen`、HEAD、`pending` 等巡逻状态隔离。worker 环境没有
`HATCH_HOOK_STATE_DIR`、`HATCH_HOOK_ID`，实现不得假设这两个变量存在，
必须使用原始文件系统路径，并在启动时验证目录存在、可写、可读。

``` text
/home/hatch/hooks/state/
  task-runtime/
    tasks/
      <T-xxx>/
        task-state.json
        events.jsonl
        attempts/
          attempt-0001/
            checkpoint/
              checkpoint.json
              artifacts/
                <阶段产物>
            result/
              result.md
          attempt-0002/
            checkpoint/
              checkpoint.json
              artifacts/
            result/
    locks/
      <T-xxx>.claim.lock
    heartbeat/
      <T-xxx>/
        attempt-0002.json
        worker-parent.json
    alerts/
      <T-xxx>.json
  patrol-cache/
    board/
    task-books/
    rate-limit.json
```

不得将 checkpoint、heartbeat、状态文件、缓存或任何秘密推送到公开 GitHub
仓库。结果文件（`results/<负责人>/T-xxx-....md`）可以引用 checkpoint 的
路径、序号和校验和，但不得把 token、密钥等秘密写进去。

## 3. checkpoint 内容格式（schema_version 1）

``` json
{
  "schema_version": 1,
  "task_id": "T-xxx",
  "task_version": "v1",
  "attempt_id": "attempt-0001",
  "generation": 1,
  "checkpoint_seq": 1,
  "created_at": "ISO-8601",
  "run_id": "仅在可靠获取时填写",
  "completed_stages": [
    {
      "stage_id": "stage-01",
      "summary": "本阶段已完成的可验证工作",
      "artifact_paths": ["artifacts/phase-01-notes.md"],
      "artifact_sha256": ["sha256..."],
      "completed_at": "ISO-8601"
    }
  ],
  "next_stage": {
    "stage_id": "stage-02",
    "objective": "下一回合要完成的具体工作",
    "inputs": ["artifacts/phase-01-notes.md"],
    "acceptance": ["可核验的阶段验收条件"]
  },
  "side_effects": [
    {
      "effect_id": "effect-001",
      "type": "github_publish",
      "status": "not_started|intent_recorded|confirmed|unknown",
      "target": "任务结果目标路径",
      "evidence": null
    }
  ],
  "result_status": "in_progress",
  "notes": "续跑所需的最小上下文"
}
```

模板中的 run ID、文件名和时间均为结构示例，不是已存在的生产值。

## 4. 写入规则

1. 每完成一个可独立验证的阶段，写一次 checkpoint；不要等到整个任务结束才写。
2. checkpoint 必须保存已完成阶段、可验证产物路径及 SHA-256、下一阶段目标／输入／验收条件、重要决策及依据、外部副作用状态、task version／attempt ID／generation。
3. 先把产物写入临时文件或临时目录，完成写入后校验，再原子 rename。
4. checkpoint JSON 也采用临时文件写入、校验、原子 rename；必要时执行 fsync，避免进程中断后只留下半截文件。
5. `checkpoint_seq` 单调递增；旧 checkpoint 不覆盖，便于审计和回滚。
6. 每个 checkpoint 引用的 artifact 必须存在且 SHA-256 匹配，否则不能用于自动续跑。
7. checkpoint 不能只写“我做到这里了”；必须让新 worker 不依赖旧 worker 的隐式上下文即可继续。
8. 研究任务应保存来源、关键事实、待核对项和引用位置；代码任务应保存已改文件、测试结果、未完成项和当前分支／提交信息（如适用）。

## 5. 损坏、缺失和版本不兼容

- **有效 checkpoint：** schema 可解析、任务版本匹配、generation／attempt 合法、引用产物存在且校验和正确，可自动续跑。
- **checkpoint JSON 损坏：** 不猜测或修复内容；检查上一序号 checkpoint 是否完整，若完整则退回上一份并记录事件。
- **artifact 缺失／哈希不匹配：** 当前 checkpoint 无效；检查上一份 checkpoint。
- **所有 checkpoint 均无效：** 先核验远端是否已有最终结果，以及副作用账本是否存在未决动作；无法证明安全则 `NEEDS_HUMAN`。
- **没有 checkpoint：** 只有在确认没有已发布结果、没有正在进行或状态未知的外部副作用、旧 worker 已终结时，才允许从头重做；必须记录“无 checkpoint 重做”及重复成本。
- **schema 不兼容：** 不自动迁移未知字段；由总控安排显式迁移或人工处理。

## 6. 外部副作用账本

所有可能产生重复影响的外部动作都要先记账，再执行，再记录结果，例如
GitHub commit／push、Issue 评论、远端任务状态更新及其他不可逆操作。

状态至少分为：`not_started`（尚未执行）、`intent_recorded`（已经持久化
执行意图，但结果未知）、`confirmed`（已核验成功，并保存证据）、
`unknown`（执行结果无法确认）。

如果状态为 `intent_recorded` 或 `unknown`，恢复时先查询远端事实，不得
直接重复执行。GitHub push 超时尤其如此：先核验远端 commit／blob，确认
未成功后再继续。

## 7. 续跑规则

1. 确认旧 run 已终结（见第 8 节）。
2. 检查最新 checkpoint，校验 schema、任务版本、artifact SHA-256。
3. 核对外部副作用账本。
4. 核对是否已有最终结果、远端 commit／blob 或 Issue 更新。
5. 递增 generation，创建新的 resume attempt。
6. 把 checkpoint 中的 `next_stage` 和已完成产物交给新 worker。
7. 新 worker 先 claim，再按 checkpoint 续跑。
8. 不重新执行 checkpoint 已标记完成的阶段。
9. 续跑完成后按正常流程落盘、handoff、发布和核验。

## 8. 超时判定（只读，worker 内执行）

- 关联键：`metadata_json.wake_payload.event_id`（`T-xxx@vN@<head_sha>`，任务＋版本＋HEAD 三合一）；次选 `metadata_json.wake_payload.tasks` 数组，**须兼容对象数组与字符串数组两种格式**（T-009 已验证并存）。
- 启动证据：`worker_started_at` 非空。
- 超时终结：`status='failed'` 且 `last_error_stage='worker_timeout'`（另有 `worker_phase='execute'`、`created_at`→`updated_at` 约 +600 秒作佐证）。
- **lane 差异（Codex 适配器注意）：** 总控侧 `wake_payload` 是 `events[]`（每项含 `task_id`）；节点侧是 `tasks`＋`event_id`。适配器必须先对齐目标 lane 的实际结构，不得假设只有一种格式。
- **巡逻查不到库（T-009 已验证）：** `muse.db` 只能由 worker 内的 agent 经 `muse.db` 工具只读查询；巡逻进程（bash＋curl＋jq＋git）没有任何 DB 访问途径。不得把 DB 查询写进 `patrol.sh`；巡逻降级方案沿用 seen 文件＋`git ls-remote` HEAD 门控。
- 心跳过期、wake 返回成功、`outcome: wake` 均不得单独作为超时或启动证据；无法可靠关联 run 行时转 `NEEDS_HUMAN`。

## 9. 心跳（独立后台进程）

worker 主循环在模型／工具调用阻塞期间无法自行写心跳，心跳必须由 worker
启动时派生的独立后台进程写入（T-008 部分验证、T-009 已验证父进程识别）：

- 父进程识别用 PID＋`/proc/<pid>/stat` 第 22 字段 starttime，防 PID 复用；
- 父进程消失后 helper 自行退出（实测约 2 秒内；starttime 错配 5ms 内退出）；
- 心跳间隔建议 60 秒，超过 180 秒未更新标记 `HEARTBEAT_STALE`（只作告警和诊断，不得单独触发自动重唤）；
- 正常退出时 worker 须停止 helper 并清理临时文件，不删除事件历史；
- 只允许清理已证明属于旧 attempt 的 helper，不得仅按 PID 杀进程。

## 10. 600 秒预算（收紧版）

v2 §5.1 原表各阶段极值合计 630 秒，超 600 秒上限。本规范收紧主体工作为
420–450 秒，收尾至少 90 秒，各阶段极值合计恰为 600 秒：

| 阶段 | 预算 |
|---|---|
| 启动、读取状态、claim | 15–30 秒 |
| 主体工作 | 420–450 秒 |
| checkpoint、结果落盘、校验 | 30–45 秒 |
| GitHub 推送／交接／通知 | 45–75 秒 |
| **合计** | **510–600 秒** |

到达约 450 秒时停止新增工作，进入 checkpoint 和交付收尾。任务书模板
（`TASK_TEMPLATE.md`）已同步此表。

## 11. 版本与生效

- 本规范为 v1；Codex 实现、Antigravity 审查、总控验收、node-1 canary 均以本文件为准。
- 改动本规范须总控批准，并同步更新 release-manifest；不得把未验证的能力标记为已验证。
- 待验证（Stage 0／canary 给出证据前不得声称具备）：600 秒是否为平台可配置时限；checkpoint 在真实 worker timeout 后是否保留并可被新 worker 读取；长任务全程 heartbeat 的稳定性；GitHub 条件请求（ETag）是否可用；节点凭据能否安全注入巡逻 API 请求。
