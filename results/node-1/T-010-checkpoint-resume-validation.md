# T-010 Checkpoint 续跑验证 Stage A：写 checkpoint（小型）

- **编号**：T-010（v1）
- **负责人**：node-1
- **Issue**：https://github.com/xy3293/muse-hub/issues/10
- **任务书**：`tasks/T-010-checkpoint-resume-validation.md`
- **规范**：`docs/checkpoint-spec.md`（v1）
- **结果文件**：`results/node-1/T-010-checkpoint-resume-validation.md`
- **执行时间**：2026-11-12T10:04:14Z（核对）至 2026-11-12T10:05:00Z（checkpoint 写入）

## 结论

Stage A 完成。3 项远端事实逐项实测，全部与期望值一致，无不一致项。已按 `docs/checkpoint-spec.md` 第 2–4 节写出 checkpoint（`checkpoint_seq` 1），产物先写临时文件、校验、原子 rename；并用全新 shell／进程重读验证：checkpoint 可解析，引用产物存在且 SHA-256 匹配。只做 Stage A，未做 Stage B。

## 1. 远端事实核对（逐项实测）

核对前先执行 `git pull --ff-only`，本地 HEAD 与远端一致：

```text
c2eba3e8400c66d61f045e044254369196ec8851
```

`git ls-remote origin HEAD` 同为 `c2eba3e8400c66d61f045e044254369196ec8851`。

### 1.1 BOARD.md 远端 T-009 行状态

期望：完成

命令：

```sh
git show origin/main:BOARD.md | grep -E 'T-009'
```

输出：

```text
| T-009 | 工人丢失修复 v2 Stage 0：DB 关联与巡逻可见性探测 | node-1 | 完成 | tasks/T-009-v2-stage0-db-patrol-probe.md | [#9](https://github.com/xy3293/muse-hub/issues/9) |
```

结论：一致。T-009 行状态为“完成”。

### 1.2 hooks/patrol.sh 远端 SHA-256

期望：`f5795685b88e44f06fe806e94c0192a2598b978830ec8052d78edc8cfb2245a3`

命令：

```sh
git show origin/main:hooks/patrol.sh | sha256sum
```

输出：

```text
f5795685b88e44f06fe806e94c0192a2598b978830ec8052d78edc8cfb2245a3  -
```

结论：一致。

### 1.3 results/node-1/T-009-v2-stage0-db-patrol-probe.md 远端 blob SHA

期望：`40bfd7b607b8795b08f921788d26e19677bc53b9`

命令：

```sh
git ls-tree origin/main results/node-1/T-009-v2-stage0-db-patrol-probe.md
git cat-file -s origin/main:results/node-1/T-009-v2-stage0-db-patrol-probe.md
```

输出：

```text
100644 blob 40bfd7b607b8795b08f921788d26e19677bc53b9	results/node-1/T-009-v2-stage0-db-patrol-probe.md
14366
```

结论：一致。blob 大小 14,366 字节，与 T-009 交付报告一致。

## 2. Checkpoint

- **checkpoint 路径**：`$HOME/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/`（即 `/home/hatch/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/`）
- **checkpoint 文件**：`checkpoint.json`
- **checkpoint_seq**：1
- **attempt_id**：`attempt-0001`
- **generation**：1
- **checkpoint.json SHA-256**：`86bf9a705f8fd9892d67731bf281e0328f2b4286a3d60aa50a6df7b15bf5933d`
- **产物**：`artifacts/stage-a-verification.md`（Stage A 核对记录，含 3 项核对的命令与输出）
- **产物 SHA-256**：`a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577`
- **写入方式**：产物与 checkpoint.json 均先写临时文件（`.tmp`），校验通过后原子 rename；checkpoint.json 写入后执行 fsync。
- **未推送说明**：按规范，checkpoint、heartbeat、状态文件不得推送到公开 GitHub 仓库；本 checkpoint 仅存在于节点本地共享持久化目录，供 Stage B 新 worker 读取。

### 2.1 Checkpoint 完整内容（脱敏副本）

本 checkpoint 不含任何 token、密钥、电话、地址等秘密。`run_id` 为 `null`：规范要求“仅在可靠获取时填写”，本 worker 回合内无可靠可得的 worker run ID，故留空，未编造。

```json
{
  "schema_version": 1,
  "task_id": "T-010",
  "task_version": "v1",
  "attempt_id": "attempt-0001",
  "generation": 1,
  "checkpoint_seq": 1,
  "created_at": "2026-11-12T10:05:00Z",
  "run_id": null,
  "completed_stages": [
    {
      "stage_id": "stage-a",
      "summary": "核对 3 项远端事实并写 checkpoint：BOARD.md 远端 T-009 行状态为完成；hooks/patrol.sh 远端 SHA-256 与期望一致；results/node-1/T-009-v2-stage0-db-patrol-probe.md 远端 blob SHA 与期望一致。3 项全部一致，无不一致项。",
      "artifact_paths": ["artifacts/stage-a-verification.md"],
      "artifact_sha256": ["a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577"],
      "completed_at": "2026-11-12T10:05:00Z"
    }
  ],
  "next_stage": {
    "stage_id": "stage-b",
    "objective": "Stage B（由总控以 v2 派发）：新 worker 仅凭本 checkpoint 续跑，读取 artifacts/stage-a-verification.md 的 3 项已核对远端事实，不重新执行 Stage A 的核对，完成 v2 任务书规定的剩余工作并交付结果文件。",
    "inputs": ["artifacts/stage-a-verification.md", "tasks/T-010-checkpoint-resume-validation.md（v2 版任务书）", "docs/checkpoint-spec.md"],
    "acceptance": ["不重新执行 Stage A 已标记完成的 3 项远端事实核对", "Stage B 产物按 checkpoint 规范写入新 checkpoint（checkpoint_seq 递增，generation 递增，attempt-0002）", "结果文件推送至 results/node-1/，一次 shell 推送，成功不发 Issue 评论"]
  },
  "side_effects": [
    {
      "effect_id": "effect-001",
      "type": "github_publish",
      "status": "not_started",
      "target": "results/node-1/T-010-checkpoint-resume-validation.md",
      "evidence": null
    }
  ],
  "result_status": "in_progress",
  "notes": "远端基准 HEAD c2eba3e8400c66d61f045e044254369196ec8851（git ls-remote 与本地 HEAD 一致）。Stage A 只做事实核对与 checkpoint 写入，未做 Stage B。checkpoint 路径：$HOME/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint/。结果文件推送前须把本 effect 先记为 intent_recorded，推送后核验远端再记为 confirmed。"
}
```

### 2.2 副作用账本说明

`effect-001`（`github_publish`，目标 `results/node-1/T-010-checkpoint-resume-validation.md`）在 checkpoint 写入时状态为 `not_started`，因为推送动作发生在 checkpoint 写入之后。本结果文件经一次 shell 推送交付；推送后由 worker 用 `git ls-remote` 与远端文件读取核验，核验证据见 worker 交接记录，不改写本 checkpoint（`checkpoint_seq` 单调递增，旧 checkpoint 不覆盖；推送确认如需记账，应由后续 checkpoint 以新序号记录）。

## 3. Checkpoint 重读验证（全新 shell／进程）

checkpoint 写入后，用全新 shell 进程重新读取 `checkpoint.json` 并校验，命令与输出如下。

命令：

```sh
python3 -c "
import json, hashlib, os
base = os.path.expanduser('~/hooks/state/task-runtime/tasks/T-010/attempt-0001/checkpoint')
cp = json.load(open(base + '/checkpoint.json'))
print('parse: OK')
print('task_id:', cp['task_id'], '| task_version:', cp['task_version'], '| attempt_id:', cp['attempt_id'], '| checkpoint_seq:', cp['checkpoint_seq'], '| schema_version:', cp['schema_version'])
for p, s in zip(cp['completed_stages'][0]['artifact_paths'], cp['completed_stages'][0]['artifact_sha256']):
    fp = base + '/' + p
    print('artifact exists:', os.path.exists(fp), '| path:', p)
    h = hashlib.sha256(open(fp,'rb').read()).hexdigest()
    print('sha256 match:', h == s, '|', h)
print('next_stage:', cp['next_stage']['stage_id'])
print('side_effects:', [(e['effect_id'], e['status']) for e in cp['side_effects']])
print('checkpoint.json sha256:', hashlib.sha256(open(base + '/checkpoint.json','rb').read()).hexdigest())
"
```

输出：

```text
parse: OK
task_id: T-010 | task_version: v1 | attempt_id: attempt-0001 | checkpoint_seq: 1 | schema_version: 1
artifact exists: True | path: artifacts/stage-a-verification.md
sha256 match: True | a5021c4c1685e261312bfeaf21e6aec5798d8d0c2fe0b721066377448fbf4577
next_stage: stage-b
side_effects: [('effect-001', 'not_started')]
checkpoint.json sha256: 86bf9a705f8fd9892d67731bf281e0328f2b4286a3d60aa50a6df7b15bf5933d
```

结论：重读验证通过——checkpoint 可解析、任务版本匹配（T-010/v1）、引用产物存在且 SHA-256 匹配、`next_stage` 为 stage-b，可供 Stage B 新 worker 独立续跑。

## 4. 未验证／推断

- 无。3 项事实均已实测，无不一致，无未验证项。
- `run_id` 留空是事实（本回合无可靠可得值），不是推断。

## 5. 交付

- 本文件一次 shell 推送至 `results/node-1/`；成功不发 Issue 评论，交付靠推送。
- 未修改 BOARD.md；结果文件与 checkpoint 均不含秘密。
