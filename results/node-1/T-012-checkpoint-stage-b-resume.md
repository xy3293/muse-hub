# T-012 Checkpoint 续跑验证 Stage B：新 worker 凭 checkpoint 续跑

## 结论

Stage B 验证通过：本 worker 仅凭 T-010 的 checkpoint（checkpoint_seq 1）恢复上下文，未重新执行 Stage A 的 3 项远端事实核对；本地 checkpoint 与远端 T-010 结果文件中的脱敏副本一致；Stage 1 产出已就绪——远端 `TASK_TEMPLATE.md` 含 9 个 v2 字段，远端 `docs/checkpoint-spec.md` schema 版本为 1，远端 HEAD 实际值为 `4ef38087a9c2290ec93092685b014ab1ac7588e6`，T-010 交付提交仍在有效历史中；新 checkpoint（checkpoint_seq 2，attempt-0002，generation 2）已按规范写出并经全新 shell 重读验证通过，可交 Codex 实现 Stage 2。

- **任务**：T-012（v1），Stage B
- **负责人**：node-1
- **新 checkpoint 路径**：`$HOME/hooks/state/task-runtime/tasks/T-010/attempt-0002/checkpoint/`（即 `/home/hatch/hooks/state/task-runtime/tasks/T-010/attempt-0002/checkpoint/`）
- **checkpoint_seq**：2；**attempt_id**：`attempt-0002`；**generation**：2
- **新 checkpoint.json SHA-256**：`d0aa908741cf6c6e024e8942a4b3de980d38337ae505138bcc4b7590ee3abe8d`
- **Stage B 产物 SHA-256**：`88738537cabf14814cc1a72ee7c428544cf836a9030e840db11c57f5680796f7`（`artifacts/stage-b-verification.md`）
- **远端 HEAD 实际值**：`4ef38087a9c2290ec93092685b014ab1ac7588e6`
- **续跑说明**：本任务是 Stage B；新 worker 仅凭 T-010 的 checkpoint 续跑，**未重新执行 Stage A 的 3 项远端事实核对**。Stage A 的 3 项事实以 checkpoint 为准（checkpoint 记录：3 项全部一致）。

## 步骤 1：读取本地 Stage A checkpoint.json 并核对

命令：

```
ls -la ~/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/
cat ~/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/checkpoint.json
sha256sum ~/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/checkpoint.json ~/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/artifacts/stage-a-verification.md
python3 -c "import json; c=json.load(open('/home/hatch/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/checkpoint.json')); print(...)"
```

输出（逐项核对结果）：

```
schema_version: 1
task_id: T-010 | task_version: v1
checkpoint_seq: 1
attempt_id: attempt-0001
generation: 1
next_stage.stage_id: stage-b
completed_stages: ['stage-a']
artifact_paths: ['artifacts/stage-a-verification.md']
artifact_sha256: ['a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577']
run_id: None
86bf9a705f8fd9892d67731bf281e0328f2b4286a3d60aa50a6df7b15bf5933d  checkpoint.json
a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577  artifacts/stage-a-verification.md
```

核对结论：可解析；checkpoint_seq 为 1；attempt_id 为 attempt-0001；generation 为 1；产物 `artifacts/stage-a-verification.md` 存在且 SHA-256 与任务书给定值 `a5021c4c…` 一致；checkpoint.json SHA-256 `86bf9a70…` 与任务书给定值一致；next_stage.stage_id 为 stage-b。全部通过。

## 步骤 2：远端 T-010 结果文件中的 checkpoint 脱敏副本核对

命令：

```
git ls-remote origin HEAD
git show origin/main:results/node-1/T-010-checkpoint-resume-validation.md | grep -E 'checkpoint_seq|86bf9a70|a5021c4c|stage-b|attempt-0001|generation' | head -30
```

输出（节选）：

```
- **checkpoint_seq**：1
- **attempt_id**：`attempt-0001`
- **generation**：1
- **checkpoint.json SHA-256**：`86bf9a705f8fd9892d67731bf281e0328f2b4286a3d60aa50a6df7b15bf5933d`
- **产物 SHA-256**：`a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577`
  "attempt_id": "attempt-0001",
  "generation": 1,
  "checkpoint_seq": 1,
      "artifact_sha256": ["a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577"],
    "stage_id": "stage-b",
checkpoint.json sha256: 86bf9a705f8fd9892d67731bf281e0328f2b4286a3d60aa50a6df7b15bf5933d
```

核对结论：远端副本与本地 checkpoint 一致——同 seq（1）、同产物 SHA（`a5021c4c…`）、同 checkpoint.json SHA（`86bf9a70…`）、同 next_stage（stage-b）、同 attempt-0001 / generation 1。无不一致项；未改写任一方。

## 步骤 3：验证 Stage 1 产出已就绪、可交 Codex

只核对存在性与版本，未重做 Stage A 的事实核对。

命令：

```
git ls-remote origin HEAD; git rev-parse HEAD; git rev-parse origin/main
for f in estimated_worker_seconds time_budget_seconds stages checkpoint_after_each_stage stage_output_paths resume_instructions external_side_effects finalize_before_seconds publish_and_notify_requirements; do printf '%s: ' "$f"; git show origin/main:TASK_TEMPLATE.md | grep -c "$f"; done
git show origin/main:docs/checkpoint-spec.md | grep -n 'schema_version' | head -3
git merge-base --is-ancestor cad11968ff4951275a162f5654fce7142e038dd8 origin/main && echo 'T-010 delivery commit cad11968 IS ancestor of remote HEAD'
```

输出：

```
4ef38087a9c2290ec93092685b014ab1ac7588e6	HEAD
4ef38087a9c2290ec93092685b014ab1ac7588e6
4ef38087a9c2290ec93092685b014ab1ac7588e6
estimated_worker_seconds: 1
time_budget_seconds: 1
stages: 1
checkpoint_after_each_stage: 1
stage_output_paths: 1
resume_instructions: 1
external_side_effects: 1
finalize_before_seconds: 1
publish_and_notify_requirements: 1
58:## 3. checkpoint 内容格式（schema_version 1）
62:  "schema_version": 1,
T-010 delivery commit cad11968 IS ancestor of remote HEAD
```

核对结论：

- `TASK_TEMPLATE.md` 在远端存在，9 个 v2 字段逐项 grep 命中（每项计数均为 1）。
- `docs/checkpoint-spec.md` 在远端存在，schema 版本为 1（标题行 `**版本：** v1`，第 3 节 `schema_version 1`）。
- 远端 HEAD 实际值：`4ef38087a9c2290ec93092685b014ab1ac7588e6`（`git ls-remote` 与本地 HEAD、origin/main 三者一致）；T-010 交付提交 `cad11968ff4951275a162f5654fce7142e038dd8` 仍在远端 HEAD 有效历史中。
- Stage 1 产出已就绪，可交 Codex 实现（Stage 2）。

## 步骤 4：写新 checkpoint（checkpoint_seq 2）

按 `docs/checkpoint-spec.md` 第 2–4 节执行：位置 `$HOME/hooks/state/task-runtime/tasks/T-010/attempt-0002/checkpoint/`；checkpoint_seq 2、attempt-0002、generation 2；completed_stages 含 stage-a（继承自 seq 1）与 stage-b（本任务的验证工作与产物）；next_stage 指向 Codex 实现（Stage 2）的输入与验收；副作用账本含本次推送（写入时 `intent_recorded`，推送后核验远端再记 `confirmed`）；产物与 checkpoint.json 均先写临时文件、校验、原子 rename（checkpoint.json 写入时执行 fsync）。

写入命令（python3，临时文件校验后原子 rename）：产物 SHA-256 `88738537cabf14814cc1a72ee7c428544cf836a9030e840db11c57f5680796f7`；checkpoint.json SHA-256 `d0aa908741cf6c6e024e8942a4b3de980d38337ae505138bcc4b7590ee3abe8d`。

账本状态说明：`effect-001`（`github_publish`，目标 `results/node-1/T-012-checkpoint-stage-b-resume.md`）在 checkpoint 写入时为 `intent_recorded`；推送后由 worker 用 `git ls-remote` 与远端文件读取核验，核验通过后 checkpoint.json 就地更新为 `confirmed`（seq 仍为 2，不改写旧 checkpoint；核验结果见 worker 交接记录）。

## 步骤 5：全新 shell／进程重读新 checkpoint

命令：

```
python3 -c "
import json, hashlib
base = '/home/hatch/hooks/state/task-runtime/tasks/T-010/attempt-0002/checkpoint'
cp = json.load(open(base + '/checkpoint.json'))
..."
```

输出：

```
task_id: T-010 | task_version: v1 | attempt_id: attempt-0002 | checkpoint_seq: 2 | generation: 2 | schema_version: 1
completed_stages: ['stage-a', 'stage-b']
next_stage: stage-2
side_effects: [('effect-001', 'github_publish', 'intent_recorded', 'results/node-1/T-012-checkpoint-stage-b-resume.md')]
artifact exists: True | sha256 match: True | 88738537cabf14814cc1a72ee7c428544cf836a9030e840db11c57f5680796f7
checkpoint.json sha256: d0aa908741cf6c6e024e8942a4b3de980d38337ae505138bcc4b7590ee3abe8d
结论：重读验证通过——checkpoint 可解析、引用产物存在且 SHA-256 匹配、next_stage 为 stage-2，可供后续 worker 独立继续。
```

## 新 checkpoint 完整内容（脱敏副本，写入时状态）

```json
{
  "attempt_id": "attempt-0002",
  "checkpoint_seq": 2,
  "completed_stages": [
    {
      "artifact_paths": [
        "artifacts/stage-a-verification.md"
      ],
      "artifact_sha256": [
        "a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577"
      ],
      "completed_at": "2026-11-12T10:05:00Z",
      "stage_id": "stage-a",
      "summary": "（继承自 checkpoint_seq 1）核对 3 项远端事实并写 checkpoint：BOARD.md 远端 T-009 行状态为完成；hooks/patrol.sh 远端 SHA-256 与期望一致；results/node-1/T-009-v2-stage0-db-patrol-probe.md 远端 blob SHA 与期望一致。3 项全部一致，无不一致项。"
    },
    {
      "artifact_paths": [
        "artifacts/stage-b-verification.md"
      ],
      "artifact_sha256": [
        "88738537cabf14814cc1a72ee7c428544cf836a9030e840db11c57f5680796f7"
      ],
      "completed_at": "2026-11-12T13:42:07Z",
      "stage_id": "stage-b",
      "summary": "新 worker 仅凭 T-010 checkpoint（seq 1）续跑：核对本地 checkpoint 与远端 T-010 结果文件脱敏副本一致；验证 Stage 1 产出已就绪（TASK_TEMPLATE.md 含 9 个 v2 字段，docs/checkpoint-spec.md schema 版本 1，远端 HEAD 4ef38087a9c2290ec93092685b014ab1ac7588e6，T-010 交付提交仍在有效历史中）；未重新执行 Stage A 的 3 项远端事实核对。结果文件 results/node-1/T-012-checkpoint-stage-b-resume.md。"
    }
  ],
  "created_at": "2026-11-12T13:42:07Z",
  "generation": 2,
  "next_stage": {
    "acceptance": [
      "实现遵循 checkpoint-spec v1 第 2-9 节（目录结构、内容格式、写入规则、副作用账本、续跑规则、超时判定、心跳、600 秒预算）",
      "任务书模板 v2 字段完整可用",
      "canary 验证通过：超时后新 worker 凭 checkpoint 续跑成功，已完成阶段未重复执行",
      "无秘密写入公开仓库"
    ],
    "inputs": [
      "artifacts/stage-b-verification.md",
      "docs/checkpoint-spec.md",
      "TASK_TEMPLATE.md",
      "results/node-1/T-012-checkpoint-stage-b-resume.md"
    ],
    "objective": "Codex 实现：按 docs/checkpoint-spec.md（v1）与 TASK_TEMPLATE.md（v2 字段）实现 checkpoint 续跑能力（worker 超时后新 worker 凭最新有效 checkpoint 续跑，已完成阶段不丢失、不重复执行，外部副作用不重复发生），并通过 canary 验证。",
    "stage_id": "stage-2"
  },
  "notes": "Stage B 由 T-012 任务书（v1）派发执行，续跑依据为 T-010 checkpoint_seq 1（attempt-0001，generation 1）。Stage A 的 3 项远端事实核对未在 Stage B 重做，以 checkpoint 为准。checkpoint 路径：$HOME/hooks/state/task-runtime/tasks/T-010/attempt-0002/checkpoint/。effect-001 写入时为 intent_recorded；推送后核验远端再记 confirmed（checkpoint.json 就地更新，seq 仍为 2；核验结果见 T-012 结果文件与 worker 交接记录）。",
  "result_status": "in_progress",
  "run_id": null,
  "schema_version": 1,
  "side_effects": [
    {
      "effect_id": "effect-001",
      "evidence": null,
      "status": "intent_recorded",
      "target": "results/node-1/T-012-checkpoint-stage-b-resume.md",
      "type": "github_publish"
    }
  ],
  "task_id": "T-010",
  "task_version": "v1"
}```

注：上为 checkpoint_seq 2 写入时的完整内容；其中 `effect-001` 状态为 `intent_recorded`，推送后核验远端再记 `confirmed`（见“步骤 4”账本状态说明）。本文件、checkpoint 均不含任何秘密。

## 未验证／推断

- 无。本任务只做 Stage B 定义的切片，未做 Codex 的实现工作；未声称自动恢复已实现。
- Stage A 的 3 项远端事实未在 Stage B 重新核对，以 checkpoint 为准（见结论与步骤 1）。

## 交付

- 结果文件：`results/node-1/T-012-checkpoint-stage-b-resume.md`，一次 shell 推送；成功不发 Issue 评论，交付靠推送。
