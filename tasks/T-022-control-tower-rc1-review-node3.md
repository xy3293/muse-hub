# T-022：Control Tower Stage 1 合同 1.1.0-rc.1 独立审查（node-3）

## 任务

你是 node-3，独立核验节点。审查 Muse Control Tower Stage 1 修订候选合同（OpenAPI 1.1.0-rc.1 + 架构决策书 v1.1-rc.1），给出独立结论。这是 CH-17 冻结门槛的三方核查之一（另两方：Codex 复核 Pydantic 类型与真实源解析；Antigravity 生成 TS 类型并核查页面消费）。

## 背景

- 1.0.1 合同未通过冻结复核（审计：12 项实质冲突 C01–C12、20 组新增 N01–N20、33 项遗漏 O01–O33、T-006 十项未验证 D1–D10、17 项变更 CH-01–CH-17）。审计记录在总控侧，不附在此；本任务书后附修订版两文件全文作为审查对象。
- 修订要点：17 操作 / 13 路径（与 v1.1 §10 逐条一致）；七维任务状态并列；收据一对多（T-004 两份收据均保留）；鉴权改单租户 Tower API Key（`X-CT-Access-Key`）；事件/健康字段未知值保留 null；双侧巡逻分别采集（节点侧 300 秒 / 总控侧 60 秒）。

## 审查范围

1. **状态模型**：七维状态是否自洽、能否表达 BOARD 滞后 / Issue OPEN / 远端未交付 / 收据 REJECT / 证据冲突等真实场景；归一化优先顺序有无漏洞或循环。
2. **权限与安全边界**：Tower API Key 方案是否完整可用（签发、轮换、失效、Origin 校验）；文件白名单、SQLite 边界、备份责任是否可执行；有无敏感信息透传到浏览器的口子。
3. **过度设计**：对照 CH-01–CH-17，指出哪些设计超出冻结所需、可以砍掉或延后；哪些“新增”被冒充成原文要求。
4. **可实现性抽查**：挑 3–5 个最复杂的 schema（Task、Event、ReceiptEvidence、Runtime、RefreshResult），判断后端能否按合同实现、前端能否按合同消费；发现字段缺失、类型歧义、枚举不全要逐条列出（文件 + schema 名 + 行号）。
5. **审计闭环**：逐项核对 C01–C12 是否都已修复（只核你能从本文本判断的；需外部事实的标“需总控核实”，不猜）。

## 交付

写到 `results/node-3/T-022-control-tower-rc1-review.md`，包含：结论（PASS / FAIL）、逐项审查表、阻塞问题清单（带合同位置和修正建议）、非阻塞建议。只写你自己的专属目录，不动其他文件，不发 Issue 评论（R8 缺口或失败除外）。

## 规则

- 合同全文附在本任务书后（YAML + 决策书），以此为准审查；不要假设你能访问私有仓库。
- 不写任何密钥、token、真实隐私信息；合同本身不含密钥。
- 交付声称不是证据：总控按远端 HEAD 与文件验收。

---

## 附件一：OpenAPI 1.1.0-rc.1 全文（审查对象）

```yaml
openapi: 3.0.3
info: {title: Muse Control Tower Stage 1 API, version: 1.1.0-rc.1, description: 'Contract candidate; 17 operations on 13 paths. Sources: v1.1 §10, T-006, T-007, Stage 0 corrected 2026-11-15 and user-confirmed 1:N receipt baseline. Do not treat rc as production-signed frozen contract.'}
servers:
- {url: 'http://127.0.0.1:8000'}
x-change-register:
  CH-01: C01 C02; V §10; exact 17 operations and parameter names
  CH-02: C03 C04 O01 O02 O03 O04 O14; orthogonal status and provenance
  CH-03: C05 C06 O05 O06 O13; delivery/ACK and 1:N receipts
  CH-04: C07 O07 O08 O09 O10 O11 O12; events and unknown values
  CH-05: O15 O16 O17 O18 O19 O20; VM adapter and health
  CH-06: O21; source and freshness
  CH-07: O22 O23; cache/quota/failure
  CH-08: N05 O28; single-tenant access key
  CH-09: C10 C11 O31; errors and write semantics
  CH-10: N07 N08 O32; query/filter/pagination
  CH-11: C08 N16; two-sided patrol and no realtime guarantee
  CH-12: C09 O24 O25; SQLite boundary, WAL, backup (in architecture document)
  CH-13: O26; explicit allowlist/path defenses (in architecture document)
  CH-14: O27; Worktree governance (in architecture document)
  CH-15: O28 O29; single tenant and prototype check (in architecture document)
  CH-16: O31 D1-D10; samples and fixtures (in architecture document)
  CH-17: C12 O33; review and freeze gate (in architecture document)
x-new-design-origins:
  N05: T-007 risk 5; API-key choice is new
  N06-N09: v1.1 Stage 1 requires OpenAPI/errors; exact envelopes, filters, numbers and code list are NEW
  N10-N12: T-007 risks 2/10 and T-006 dictionaries; derived enums are NEW
  N13-N14: Stage 0 §4 checkpoint, postdates T-006
  N15: T-006 §8 severity is NEW
  N16: User correction verified Stage 0 §3
  N17-N18: v1.1 §6/§10 general notes/todos/health, specific DTO NEW
x-response-policy: 200 partial only with explicit stale/unavailable source_meta; 503 if no usable authoritative data or snapshot. Caches in memory only; no second GitHub task database. Get 404 for unknown ids. Mutation 403 for disallowed Origin; no CORS allowlist. All timestamps UTC/RFC3339; unknown nullable, never invented.
paths:
  /api/v1/overview:
    get:
      operationId: getOverview
      summary: Read overall snapshot
      x-audit: [CH-06, O21, CH-07, O23]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/OverviewHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
  /api/v1/nodes:
    get:
      operationId: listNodes
      summary: List the three real nodes
      x-audit: [CH-01, CH-06, O14, O21]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/NodeListHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
  /api/v1/nodes/{node_id}:
    get:
      operationId: getNode
      summary: Read one real node
      x-audit: [CH-01, C02, O14]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/NodeHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '404': {$ref: '#/components/responses/Http404'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
      parameters:
      - name: node_id
        in: path
        required: true
        schema: {type: string}
  /api/v1/tasks:
    get:
      operationId: listTasks
      summary: Filter and paginate normalized tasks
      x-audit: [CH-01, CH-02, CH-06, CH-10, O01, O21, O32]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/TaskListHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
      parameters:
      - name: q
        in: query
        required: false
        description: Case-insensitive substring over task id/title; applied before pagination
        schema: {type: string}
      - name: status
        in: query
        required: false
        description: Exact derived_status
        schema: {type: string}
      - name: assignee
        in: query
        required: false
        description: Exact node assignee
        schema:
          type: string
          enum: [node-1, node-2, node-3]
      - name: limit
        in: query
        required: false
        description: Page length
        schema: {type: integer, minimum: 1, maximum: 100, default: 50}
      - name: offset
        in: query
        required: false
        description: Zero-based offset
        schema: {type: integer, minimum: 0, default: 0}
      description: Sort by task id ascending before limit/offset; total counts filtered matches. Excludes node-4.
  /api/v1/tasks/{task_id}:
    get:
      operationId: getTask
      summary: Read one task and all associated receipts
      x-audit: [CH-01, C02, CH-02, CH-03, O01, O13]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/TaskHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '404': {$ref: '#/components/responses/Http404'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
      parameters:
      - name: task_id
        in: path
        required: true
        schema: {type: string}
  /api/v1/events:
    get:
      operationId: listEvents
      summary: Filter and paginate events
      x-audit: [CH-04, CH-06, O07, O09, O21]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/EventListHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
      parameters:
      - name: node_id
        in: query
        required: false
        description: Exact source node
        schema:
          type: string
          enum: [node-1, node-2, node-3]
      - name: task_id
        in: query
        required: false
        description: Exact task id
        schema: {type: string}
      - name: limit
        in: query
        required: false
        description: Page length
        schema: {type: integer, minimum: 1, maximum: 100, default: 50}
      - name: offset
        in: query
        required: false
        description: Zero-based offset
        schema: {type: integer, minimum: 0, default: 0}
      description: Sort by detected_at descending, unknown timestamps last; tie-break by id ascending.
  /api/v1/runtime:
    get:
      operationId: getRuntime
      summary: Read director and node runtime separately
      x-audit: [CH-05, CH-06, CH-11, O15, O19, N16]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/RuntimeHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}}
  /api/v1/notes:
    get:
      operationId: listNotes
      summary: List private notes
      x-audit: [CH-01, N06, N17]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/NoteListHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}}
    post:
      operationId: createNote
      summary: Create private note
      x-audit: [CH-08, CH-09, N05, N17]
      security:
      - towerKey: []
      responses: {'201': {$ref: '#/components/responses/NoteHttp201'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '422': {$ref: '#/components/responses/Http422'}, '500': {$ref: '#/components/responses/Http500'}}
      requestBody:
        required: true
        content:
          application/json: {schema: {$ref: '#/components/schemas/NoteCreate'}}
      description: Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
  /api/v1/notes/{id}:
    patch:
      operationId: patchNote
      summary: Patch private note (last-write-wins)
      x-audit: [CH-01, C01, CH-09, C10]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/NoteHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '404': {$ref: '#/components/responses/Http404'}, '422': {$ref: '#/components/responses/Http422'}, '500': {$ref: '#/components/responses/Http500'}}
      parameters:
      - name: id
        in: path
        required: true
        schema: {type: string}
      requestBody:
        required: true
        content:
          application/json: {schema: {$ref: '#/components/schemas/NotePatch'}}
      description: Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
    delete:
      operationId: deleteNote
      summary: Delete private note
      x-audit: [CH-01, CH-08, N05]
      security:
      - towerKey: []
      responses:
        '204': {description: Deleted}
        '401': {$ref: '#/components/responses/Http401'}
        '403': {$ref: '#/components/responses/Http403'}
        '404': {$ref: '#/components/responses/Http404'}
        '500': {$ref: '#/components/responses/Http500'}
      parameters:
      - name: id
        in: path
        required: true
        schema: {type: string}
      description: Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
  /api/v1/todos:
    get:
      operationId: listTodos
      summary: List private todos
      x-audit: [CH-01, N06, N17]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/TodoListHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}}
    post:
      operationId: createTodo
      summary: Create private todo
      x-audit: [CH-08, CH-09, N05, N17]
      security:
      - towerKey: []
      responses: {'201': {$ref: '#/components/responses/TodoHttp201'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '422': {$ref: '#/components/responses/Http422'}, '500': {$ref: '#/components/responses/Http500'}}
      requestBody:
        required: true
        content:
          application/json: {schema: {$ref: '#/components/schemas/TodoCreate'}}
      description: Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
  /api/v1/todos/{id}:
    patch:
      operationId: patchTodo
      summary: Patch private todo (last-write-wins)
      x-audit: [CH-01, C01, CH-09, C10]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/TodoHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '404': {$ref: '#/components/responses/Http404'}, '422': {$ref: '#/components/responses/Http422'}, '500': {$ref: '#/components/responses/Http500'}}
      parameters:
      - name: id
        in: path
        required: true
        schema: {type: string}
      requestBody:
        required: true
        content:
          application/json: {schema: {$ref: '#/components/schemas/TodoPatch'}}
      description: Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
    delete:
      operationId: deleteTodo
      summary: Delete private todo
      x-audit: [CH-01, CH-08, N05]
      security:
      - towerKey: []
      responses:
        '204': {description: Deleted}
        '401': {$ref: '#/components/responses/Http401'}
        '403': {$ref: '#/components/responses/Http403'}
        '404': {$ref: '#/components/responses/Http404'}
        '500': {$ref: '#/components/responses/Http500'}
      parameters:
      - name: id
        in: path
        required: true
        schema: {type: string}
      description: Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
  /api/v1/refresh:
    post:
      operationId: refreshReadModels
      summary: Synchronously refresh read-only source projections
      x-audit: [CH-07, CH-08, CH-09, C11, O22, O23]
      security:
      - towerKey: []
      responses: {'200': {$ref: '#/components/responses/RefreshResultHttp200'}, '401': {$ref: '#/components/responses/Http401'}, '403': {$ref: '#/components/responses/Http403'}, '500': {$ref: '#/components/responses/Http500'}, '503': {$ref: '#/components/responses/Http503'}, '409': {$ref: '#/components/responses/Http409'}}
      description: 200 completed/degraded; 409 REFRESH_IN_PROGRESS; 503 no usable sources/snapshot; no GitHub writes or node wake. Mutation requires validated Origin matching the configured exact allowed origin; missing Origin is rejected. No CORS and no cookie sessions.
  /healthz:
    get:
      operationId: healthz
      summary: Liveness only; no source or credential details
      security: []
      x-audit: [CH-01, N18]
      responses: {'200': {$ref: '#/components/responses/HealthHttp200'}}
components:
  responses:
    Http401:
      description: Missing or invalid Control Tower access key
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    Http403:
      description: Forbidden origin or scope
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    Http404:
      description: Resource not found
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    Http422:
      description: Invalid input
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    Http500:
      description: Unexpected server failure; sensitive details redacted
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    Http503:
      description: No usable authoritative source or snapshot
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    Http409:
      description: Refresh already in progress
      content:
        application/json: {schema: {$ref: '#/components/schemas/Error'}}
    OverviewHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Overview'}}
    NodeListHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/NodeList'}}
    NodeHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Node'}}
    TaskListHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/TaskList'}}
    TaskHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Task'}}
    EventListHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/EventList'}}
    RuntimeHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Runtime'}}
    NoteListHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/NoteList'}}
    NoteHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Note'}}
    TodoListHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/TodoList'}}
    TodoHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Todo'}}
    RefreshResultHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/RefreshResult'}}
    HealthHttp200:
      description: OK
      content:
        application/json: {schema: {$ref: '#/components/schemas/Health'}}
    NoteHttp201:
      description: Created
      content:
        application/json: {schema: {$ref: '#/components/schemas/Note'}}
    TodoHttp201:
      description: Created
      content:
        application/json: {schema: {$ref: '#/components/schemas/Todo'}}
  securitySchemes:
    towerKey: {type: apiKey, in: header, name: X-CT-Access-Key, description: 'NEW N05: unique high-entropy local app credential held only in browser memory for one session; distinct from GitHub PAT and VM secrets. Set via operator UI; never persist/log. All API operations except /healthz require it; no cookie session, so no CSRF cookie flow. Reject cross-origin requests, do not enable CORS. Server secret supplied as protected systemd credential.'}
  schemas:
    SourceMeta:
      type: object
      additionalProperties: false
      properties:
        source:
          type: string
          enum: [github, vm_local, sqlite, derived]
        source_ref: {type: string, nullable: true}
        observed_at: {type: string, nullable: true, format: date-time}
        last_success_at: {type: string, nullable: true, format: date-time}
        fetched_at: {type: string, nullable: true, format: date-time}
        freshness:
          type: string
          enum: [fresh, stale, unavailable, unknown]
        stale: {type: boolean}
        current_error_code: {type: string, nullable: true}
      required: [source, source_ref, observed_at, last_success_at, fetched_at, freshness, stale, current_error_code]
      description: Current computed condition, not raw historical last_error. Missing timestamps => unknown, never fresh.
      x-audit: [CH-05, CH-06, O16, O20, O21]
    SourceSnapshot:
      type: object
      additionalProperties: false
      properties:
        sources:
          type: array
          items: {$ref: '#/components/schemas/SourceMeta'}
        generated_at: {type: string, format: date-time}
        partial: {type: boolean}
      required: [sources, generated_at, partial]
      description: For mixed sources, a fresh GitHub fetch does not make stale VM records fresh.
      x-audit: [CH-06, O21]
    SourceConflict:
      type: object
      additionalProperties: false
      properties:
        dimension: {type: string}
        sources:
          type: array
          items: {type: string}
        reason: {type: string}
        evidence_refs:
          type: array
          items: {type: string}
      required: [dimension, sources, reason, evidence_refs]
      x-audit: [CH-02, O01]
    Checkpoint:
      type: object
      additionalProperties: false
      properties:
        run_id: {type: string, nullable: true}
        contract_revision: {type: string, nullable: true}
        last_progress_at: {type: string, nullable: true, format: date-time}
        checkpoint_at: {type: string, nullable: true, format: date-time}
        resume_available: {type: boolean}
        resume_count: {type: integer, nullable: true, minimum: 0}
      required: [run_id, contract_revision, last_progress_at, checkpoint_at, resume_available, resume_count]
      description: From Stage-0 post-Nov12 checkpoint facts, not T-006. Unknown is null; never infer resume from an old commit.
      x-audit: [CH-02, N13, N14]
    DeliveryEvidence:
      type: object
      additionalProperties: false
      properties:
        version_sha: {type: string, nullable: true}
        source_paths:
          type: array
          items: {type: string}
        remote_verified: {type: boolean}
        verified_at: {type: string, nullable: true, format: date-time}
      required: [version_sha, source_paths, remote_verified, verified_at]
      description: Only verified remote commit + readable remote files count as delivered.
      x-audit: [CH-03, O05]
    ReceiptCheck:
      type: object
      additionalProperties: false
      properties:
        name: {type: string, nullable: true}
        status:
          type: string
          nullable: true
          enum: [PASS, FAIL]
        evidence: {type: string, nullable: true}
      required: [name, status, evidence]
      description: Sanitized; no secrets, absolute paths or stack traces.
      x-audit: [CH-03, O13]
    ReceiptEvidence:
      type: object
      additionalProperties: false
      properties:
        receipt_ref: {type: string}
        schema_version: {type: integer, nullable: true}
        event_id: {type: string, nullable: true}
        task_id: {type: string}
        node_id: {type: string, nullable: true}
        version_sha: {type: string, nullable: true}
        status:
          type: string
          nullable: true
          enum: [REVIEWED]
        verdict:
          type: string
          nullable: true
          enum: [PASS, REJECT]
        summary: {type: string, nullable: true}
        reviewed_at: {type: string, nullable: true, format: date-time}
        source_paths:
          type: array
          items: {type: string}
        checks:
          type: array
          items: {$ref: '#/components/schemas/ReceiptCheck'}
        superseded: {type: boolean, nullable: true}
      required: [receipt_ref, schema_version, event_id, task_id, node_id, version_sha, status, verdict, summary, reviewed_at, source_paths, checks, superseded]
      description: Task to receipt is 1:N. Keep EVERY historical receipt including both T-004 5d71eee6 and fa4cee5; superseded only with explicit evidence, never by array order.
      x-audit: [CH-03, C05, C06, O13]
    AckEvidence:
      type: object
      additionalProperties: false
      properties:
        acked: {type: boolean, nullable: true}
        ack_commit_sha: {type: string, nullable: true}
        ack_method: {type: string, nullable: true}
        acked_at: {type: string, nullable: true, format: date-time}
      required: [acked, ack_commit_sha, ack_method, acked_at]
      description: ack_method enum unverified.
      x-audit: [CH-03, CH-04, O06, O11]
    Node:
      type: object
      additionalProperties: false
      properties:
        id:
          type: string
          enum: [node-1, node-2, node-3]
        status:
          type: string
          enum: [idle, assigned, running, checkpointed, resuming, blocked, unknown]
        current_task_id: {type: string, nullable: true}
        last_seen_at: {type: string, nullable: true, format: date-time}
        last_progress_at: {type: string, nullable: true, format: date-time}
        source_meta: {$ref: '#/components/schemas/SourceMeta'}
      required: [id, status, current_task_id, last_seen_at, last_progress_at, source_meta]
      description: Recent git commit alone is NOT an online heartbeat.
      x-audit: [CH-02, O14, N11]
    Task:
      type: object
      additionalProperties: false
      properties:
        id: {type: string}
        title: {type: string}
        assignee:
          type: string
          nullable: true
          enum: [node-1, node-2, node-3]
        task_book_path: {type: string, nullable: true}
        task_version: {type: string, nullable: true}
        issue_number: {type: integer, nullable: true}
        issue_url: {type: string, nullable: true}
        board_status:
          type: string
          nullable: true
          enum: [待领, 进行中, 待验收, 完成, 失败, 拒收]
        issue_state:
          type: string
          nullable: true
          enum: [OPEN, CLOSED]
        delivery_status:
          type: string
          enum: [delivered, not_delivered, unverified]
        acceptance_status:
          type: string
          enum: [accepted, rejected, pending, unverified]
        event_status: {type: string, nullable: true}
        derived_status:
          type: string
          enum: [pending, in_progress, pending_review, delivered, accepted, rejected, failed, checkpointed, resuming, parked, needs_attention, unverified, unknown]
        source_conflicts:
          type: array
          items: {$ref: '#/components/schemas/SourceConflict'}
        delivery: {$ref: '#/components/schemas/DeliveryEvidence'}
        receipts:
          type: array
          items: {$ref: '#/components/schemas/ReceiptEvidence'}
        main_ack: {$ref: '#/components/schemas/AckEvidence'}
        run_id: {type: string, nullable: true}
        contract_revision: {type: string, nullable: true}
        last_progress_at: {type: string, nullable: true, format: date-time}
        checkpoint: {$ref: '#/components/schemas/Checkpoint'}
        parked_reason: {type: string, nullable: true}
        parked_until: {type: string, nullable: true, format: date-time}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [id, title, assignee, task_book_path, task_version, issue_number, issue_url, board_status, issue_state, delivery_status, acceptance_status, event_status, derived_status, source_conflicts, delivery, receipts, main_ack, run_id, contract_revision, last_progress_at, checkpoint, parked_reason, parked_until, source_meta]
      description: Seven orthogonal dimensions are board_status/issue_state/delivery_status/acceptance_status/event_status/derived_status/source_conflicts. accepted requires matching remote revision, PASS receipt, ACKED event and main_ack.acked=true. Issue state never determines completion. No pass-through historical errors.
      x-audit: [CH-02, CH-03, C03, C04, C05, C06, O01, O02, O03, O04, O05, O06, O13]
    EventReview:
      type: object
      additionalProperties: false
      properties:
        verdict:
          type: string
          nullable: true
          enum: [PASS, REJECT]
        receipt_path: {type: string, nullable: true}
        reviewed_at: {type: string, nullable: true, format: date-time}
      required: [verdict, receipt_path, reviewed_at]
      x-audit: [CH-04, O10]
    EventDelivery:
      type: object
      additionalProperties: false
      properties:
        status: {type: string, nullable: true}
        attempt_count: {type: integer, nullable: true, minimum: 0}
      required: [status, attempt_count]
      description: status values unverified.
      x-audit: [CH-04, O10]
    EventApproval:
      type: object
      additionalProperties: false
      properties:
        status: {type: string, nullable: true}
        operation_id: {type: string, nullable: true}
      required: [status, operation_id]
      description: status values unverified.
      x-audit: [CH-04, O10]
    EventRetry:
      type: object
      additionalProperties: false
      properties:
        attempt_count: {type: integer, nullable: true, minimum: 0}
        wakes: {type: integer, nullable: true, minimum: 0}
        last_wake_at: {type: string, nullable: true, format: date-time}
      required: [attempt_count, wakes, last_wake_at]
      x-audit: [CH-04, O11]
    EventSignal:
      type: object
      additionalProperties: false
      properties:
        comment_id: {type: integer, nullable: true}
        issue: {type: integer, nullable: true}
        updated_at: {type: string, nullable: true, format: date-time}
      required: [comment_id, issue, updated_at]
      x-audit: [CH-04, O12]
    EventTimes:
      type: object
      additionalProperties: false
      properties:
        detected_at: {type: string, nullable: true, format: date-time}
        receipt_saved_at: {type: string, nullable: true, format: date-time}
        main_acked_at: {type: string, nullable: true, format: date-time}
      required: [detected_at, receipt_saved_at, main_acked_at]
      x-audit: [CH-04, O12]
    Event:
      type: object
      additionalProperties: false
      properties:
        id: {type: string}
        schema_version: {type: integer, nullable: true}
        kind: {type: string, nullable: true}
        task_id: {type: string, nullable: true}
        node_id: {type: string, nullable: true}
        state:
          type: string
          nullable: true
          enum: [ACKED, NEEDS_ATTENTION, REJECTED, SUPERSEDED, CLOSED_INTERNAL]
        source_commit_sha: {type: string, nullable: true}
        source_paths:
          type: array
          items: {type: string}
        review: {$ref: '#/components/schemas/EventReview'}
        delivery: {$ref: '#/components/schemas/EventDelivery'}
        approval: {$ref: '#/components/schemas/EventApproval'}
        main_ack: {$ref: '#/components/schemas/AckEvidence'}
        retry: {$ref: '#/components/schemas/EventRetry'}
        signals:
          type: array
          items: {$ref: '#/components/schemas/EventSignal'}
        timestamps: {$ref: '#/components/schemas/EventTimes'}
        last_error_historical: {type: string, nullable: true}
        severity:
          type: string
          enum: [info, warning, critical, unknown]
        summary: {type: string, nullable: true}
        source_meta: {$ref: '#/components/schemas/SourceMeta'}
      required: [id, schema_version, kind, task_id, node_id, state, source_commit_sha, source_paths, review, delivery, approval, main_ack, retry, signals, timestamps, last_error_historical, severity, summary, source_meta]
      description: kind and several subfield enums not verified; retain nulls. NEEDS_ATTENTION is NOT failure/terminal. 48h/7d escalation not implemented; no Tower timers. last_error_historical is history, not a current incident.
      x-audit: [CH-04, C07, O07, O08, O09, O10, O11, O12, N15]
    PatrolSide:
      type: object
      additionalProperties: false
      properties:
        interval_seconds: {type: integer, nullable: true, minimum: 1}
        source: {type: string, nullable: true}
        observed_at: {type: string, nullable: true, format: date-time}
        status:
          type: string
          enum: [verified, unknown, error]
      required: [interval_seconds, source, observed_at, status]
      description: Observed current configuration per side, never hard-coded or inferred from historical values.
      x-audit: [CH-11, N16]
    HealthSummary:
      type: object
      additionalProperties: false
      properties:
        last_success_at: {type: string, nullable: true, format: date-time}
        last_attempt_at: {type: string, nullable: true, format: date-time}
        consecutive_api_failures: {type: integer, nullable: true, minimum: 0}
        consecutive_script_failures: {type: integer, nullable: true, minimum: 0}
        rate_remaining: {type: integer, nullable: true, minimum: 0}
        rate_checked_at: {type: string, nullable: true, format: date-time}
        ledger_available: {type: boolean, nullable: true}
        current_status:
          type: string
          enum: [healthy, abnormal, unknown]
        source_meta: {$ref: '#/components/schemas/SourceMeta'}
      required: [last_success_at, last_attempt_at, consecutive_api_failures, consecutive_script_failures, rate_remaining, rate_checked_at, ledger_available, current_status, source_meta]
      description: Health >15m since reliable last_success => abnormal; no reliable record => unknown. Historical last_error not exposed as current.
      x-audit: [CH-05, O15, O16, O19]
    ScanSummary:
      type: object
      additionalProperties: false
      properties:
        scan_cursor: {type: string, nullable: true}
        scan_cursor_updated_at: {type: string, nullable: true, format: date-time}
        source_meta: {$ref: '#/components/schemas/SourceMeta'}
      required: [scan_cursor, scan_cursor_updated_at, source_meta]
      description: Full comment and s3 ledger structures retained only in internal adapter.
      x-audit: [CH-05, O17]
    Runtime:
      type: object
      additionalProperties: false
      properties:
        node_patrol: {$ref: '#/components/schemas/PatrolSide'}
        director_patrol: {$ref: '#/components/schemas/PatrolSide'}
        health: {$ref: '#/components/schemas/HealthSummary'}
        scan: {$ref: '#/components/schemas/ScanSummary'}
        hook_wake_guaranteed_realtime:
          type: boolean
          enum: [false]
        data_last_refreshed_at: {type: string, nullable: true, format: date-time}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [node_patrol, director_patrol, health, scan, hook_wake_guaranteed_realtime, data_last_refreshed_at, source_meta]
      description: Node observed 300s patrol.sh v2026-11-11.3; director observed 60s Hook poll_interval_secs on 2026-11-15. Historical director 300/180 MUST NOT be shown as current. No guaranteed real-time wake.
      x-audit: [CH-05, CH-06, CH-11, C08, O15, O17, O19]
    Overview:
      type: object
      additionalProperties: false
      properties:
        nodes:
          type: array
          items: {$ref: '#/components/schemas/Node'}
        task_counts:
          type: object
          additionalProperties: {type: integer, minimum: 0}
        recent_events:
          type: array
          items: {$ref: '#/components/schemas/Event'}
        runtime: {$ref: '#/components/schemas/Runtime'}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [nodes, task_counts, recent_events, runtime, source_meta]
      x-audit: [CH-06, O21]
    NodeList:
      type: object
      additionalProperties: false
      properties:
        items:
          type: array
          items: {$ref: '#/components/schemas/Node'}
        total: {type: integer, minimum: 0}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [items, total, source_meta]
      x-audit: [CH-06, O21, N06]
    TaskList:
      type: object
      additionalProperties: false
      properties:
        items:
          type: array
          items: {$ref: '#/components/schemas/Task'}
        total: {type: integer, minimum: 0}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [items, total, source_meta]
      x-audit: [CH-06, O21, N06]
    EventList:
      type: object
      additionalProperties: false
      properties:
        items:
          type: array
          items: {$ref: '#/components/schemas/Event'}
        total: {type: integer, minimum: 0}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [items, total, source_meta]
      x-audit: [CH-06, O21, N06]
    Note:
      type: object
      additionalProperties: false
      properties:
        id: {type: string}
        title: {type: string}
        body: {type: string}
        created_at: {type: string, format: date-time}
        updated_at: {type: string, format: date-time}
      required: [id, title, body, created_at, updated_at]
      x-audit: [N17]
    NoteCreate:
      type: object
      additionalProperties: false
      properties:
        title: {type: string}
        body: {type: string}
      required: [title, body]
      x-audit: [N17]
    NotePatch:
      type: object
      additionalProperties: false
      properties:
        title: {type: string}
        body: {type: string}
      description: At least one field; last write wins; no 409 concurrency guarantee.
      x-audit: [CH-09, C10]
      minProperties: 1
    Todo:
      type: object
      additionalProperties: false
      properties:
        id: {type: string}
        text: {type: string}
        done: {type: boolean}
        created_at: {type: string, format: date-time}
        updated_at: {type: string, format: date-time}
      required: [id, text, done, created_at, updated_at]
      x-audit: [N17]
    TodoCreate:
      type: object
      additionalProperties: false
      properties:
        text: {type: string}
      required: [text]
      x-audit: [N17]
    TodoPatch:
      type: object
      additionalProperties: false
      properties:
        text: {type: string}
        done: {type: boolean}
      description: At least one field; last write wins; no 409 concurrency guarantee.
      x-audit: [CH-09, C10]
      minProperties: 1
    NoteList:
      type: object
      additionalProperties: false
      properties:
        items:
          type: array
          items: {$ref: '#/components/schemas/Note'}
        total: {type: integer, minimum: 0}
      required: [items, total]
      x-audit: [N06]
    TodoList:
      type: object
      additionalProperties: false
      properties:
        items:
          type: array
          items: {$ref: '#/components/schemas/Todo'}
        total: {type: integer, minimum: 0}
      required: [items, total]
      x-audit: [N06]
    RefreshResult:
      type: object
      additionalProperties: false
      properties:
        status:
          type: string
          enum: [completed, degraded]
        refreshed_at: {type: string, nullable: true, format: date-time}
        source_meta: {$ref: '#/components/schemas/SourceSnapshot'}
      required: [status, refreshed_at, source_meta]
      description: 200 only. 409 REFRESH_IN_PROGRESS. 503 SOURCE_UNAVAILABLE or GITHUB_RATE_LIMITED when no usable snapshot.
      x-audit: [CH-07, CH-09, C11, O22, O23]
    Health:
      type: object
      additionalProperties: false
      properties:
        status:
          type: string
          enum: [ok]
      required: [status]
      x-audit: [CH-01, N18]
    Error:
      type: object
      additionalProperties: false
      properties:
        code:
          type: string
          enum: [AUTH_REQUIRED, FORBIDDEN_ORIGIN, NOT_FOUND, VALIDATION_ERROR, REFRESH_IN_PROGRESS, SOURCE_UNAVAILABLE, GITHUB_RATE_LIMITED, INTERNAL_ERROR]
        message: {type: string}
        request_id: {type: string, nullable: true}
      required: [code, message, request_id]
      description: No absolute paths, credentials, local sensitive evidence, or stack traces.
      x-audit: [CH-09, O31]

```

---

## 附件二：架构决策书 v1.1-rc.1 全文（审查对象）

# Muse Control Tower — Stage 1 架构决策书 v1.1-rc.1

- **配套合同**：`muse-control-tower-stage1-openapi-1.1.0-rc.1.yaml`（OpenAPI 3.0.3；`info.version=1.1.0-rc.1`；13 路径、17 操作）。本文件决定数据权威、内部适配器、部署与验收；具体 HTTP Schema 以 YAML 为准。
- **状态**：待三方核查与总控签收的修订候选，不冒充已经部署或已生产冻结。修订依据：项目 v1.1 §5–§12、T-006 §1–§11/附表 A–D、T-007 风险 1–10、2026-11-15 Stage 0 修正版、用户本轮明确确认的收据归属。YAML 中 `x-audit` / `x-change-register` 与本文件 CH 表互为追溯索引。
- **证据优先级**：用户后续核实事实 > Stage 0 更正 > 较早文档在同一时间点的观察。节点侧 300 秒、总控侧 60 秒是不同数据源；旧文档把总控也写成 300 秒不能用于覆盖更新事实。[CH-11/C08/N16]

## 1. 部署、安全与容量裁决 [CH-08/CH-12/CH-13/CH-15；N01–N05、O24–O30]

**继续选第三方案**：由 systemd **系统级** unit 托管，但 Uvicorn 进程以专用非 root 系统用户 `controltower` 运行，不依赖 `systemctl --user`、linger、用户 DBus；默认单 worker、监听 `127.0.0.1:8000`，前端构建后同源静态提供，通过 SSH 隧道私有访问。`systemctl --system` 是否有效仍需实测，不能将用户 bus 失败当作系统 bus 也失败，也不能以 `nohup` 代替生产守护。建议 `NoNewPrivileges=true`、`ProtectSystem=strict`、`PrivateTmp=true`、仅数据库目录可写；`ProtectHome` 及只读 bind/ACL 须按真实 VM 路径验证，不可盲启导致读不到数据。密钥用 systemd credentials 或受限外部配置，绝不入库。[N01–N04；出处：v1.1 §4/§11、Stage 0 §2、T-007 风险 3/6]

**内存边界**：已知 7.7Gi 是可见总量，非已证实配额；可用内存曾不足 1Gi，swap 在用，hello RSS 约 43.5Mi，`memory.max` 未可读。先核真实 cgroup/宿主边界，再用真实读取、SQLite CRUD、静态前端、连续刷新、重启恢复的峰值 RSS/Swap/OOM 证据确定 `MemoryHigh/MemoryMax`；不编数值。容量未验时只能受控测试，不能宣布生产容量或无人值守部署验收。[N04；出处：Stage 0 §2]

**首版认证改选单租户专用 API Key**：不是旧 1.0.1 的 cookie/session/CSRF 方案。管理员经 SSH 隧道访问浏览器时临时输入独立的高熵 **Tower 访问密钥**；前端只存会话内内存，不写 localStorage、URL 或日志，刷新页面需重输。浏览器**绝不可获得 GitHub PAT/App Token 或 VM 运行凭据**；Tower 密钥仅用于调用自身 API。后端从受限 systemd credential 加载并常数时间比较 `X-CT-Access-Key`；除 `/healthz` 外每个接口均验。关闭 CORS 凭据跨域访问，POST/PATCH/DELETE 校验 `Origin` 与部署时配置的精确允许源；不接受任意外部源。401=缺失/错误密钥，403=来源不允许；无 cookie，故不创建无发行流程的 CSRF token。密钥轮换需重启/热加载后使旧密钥失效；首次配置与轮换由总控负责。**此认证选型是新增决策而非原文**。[CH-08/N05/O28；出处：v1.1 §11、T-007 风险 5（原文提出 Bearer/回环限制候选，未指定本机制）]

**内部文件白名单**：VM 管理员在仓库外配置实际绝对路径，精确限定 `health.json`、`scan.json`、`events/` 中已枚举的受控 JSON 文件、`receipts/` 中已枚举的受控 JSON 文件、`logs/health-exceptions.jsonl`、实际 Hook 定义；没有实测绝对路径之前保持部署子门禁阻断。目录只用于受控遍历，不能开放用户提供的路径参数；解析 symlink/`..`、规范化后用文件描述符打开并验证目标仍处于授权目录，禁止未知 symlink；按任务 ID 校验字符和授权归属。只读 OS 权限；不提供远程 Shell、任意文件读写、GitHub 推送。原始 VM 数据不进公开 `muse-hub`。[CH-13/O26；出处：v1.1 §6/§11、T-007 风险 6]

**数据保存与备份**：SQLite 仅持久化 notes/todos、自有刷新元信息；不保存第二套 GitHub 任务权威库。GitHub、VM 只读投影只在进程内短期缓存，重启后丢失可以重新加载；数据库启 WAL，单应用实例内串行短事务，写冲突依 SQLite 可靠重试/失败处理，不承诺乐观并发 409（本版 PATCH 为 last-write-wins）。总控制定并验收 VM **外**状态文件与 SQLite 一致性备份/恢复步骤，频率及保留期待总控定，不造数字。[CH-12/C09/C10/O24/O25；出处：v1.1 §5、T-007 风险 2/4]

## 2. 权威数据、七维状态及一对多收据 [CH-02/CH-03；C03–C06、O01–O14]

### 2.1 原始源、内部模型与公开 DTO

- **GitHub**：BOARD 六列（编号、任务、负责人、状态、任务书、Issue）；负责人仅 node-1/2/3；BOARD 原始状态六值为「待领、进行中、待验收、完成、失败、拒收」。任务书 `版本：vN` 必须与 `contract_revision` 分开。Issue 编号、Issue OPEN/CLOSED 仅展示关联事实，不参与完成计算。版本键供历史关联，不改变现有巡逻脚本。[O02–O04；出处：T-006 §1–§5]
- **交付**：只有远端提交 SHA 和对应远端文件确实可读取，才确认 `delivery_status=delivered`。本地未推送提交不算交付；无证据为 `unverified`，已经确认远端不存在则 `not_delivered`。[O05；出处：T-006 附表 B3]
- **事件与收据**：按 `event_id`、`task_id`、`version_sha`、`source_paths` 做证据关联；`Task.receipts[]` **一对多**，包含历史版本、拒收、修正收据，不用最新一条覆盖历史。基线期五份收据归属：T-002 一份、T-003 一份、T-004 两份（`5d71eee6`、`fa4cee5`，后者修正）、T-005 一份；该归属由总控 VM 核实，本文件不虚构收据完整 SHA、时间、结论。接口 `ReceiptEvidence.receipt_ref` 是非敏感且稳定的来源引用，不是本地绝对路径。[O06/O13；出处：T-006 §9、用户本轮核实]
- **完整验收**：仅当当前可核实的远端交付版本与 PASS 收据 `version_sha` 一致，关联事件 `state=ACKED`，且 `main_ack.acked=true` 时 `acceptance_status=accepted`、`derived_status=accepted`。收据 `REJECT` 保留拒收，且绝不等价于 `FAIL`；不同版本或没有可靠关联时只能 `pending/unverified`。同一版本存在冲突收据或 ACK 证据不一致时 `source_conflicts[]` 记明冲突，`acceptance_status=unverified`，不采用“时间最近的 PASS 自动覆盖”规则。显式证据确认 superseded 后仍保留历史记录。[C05/C06/O06/O13；出处：v1.1 §7、T-006 §8–§9]
- **归一化优先顺序（新增确定性规则）**：先核同一交付修订 `version_sha` 对应的收据与事件 ACK；有冲突或证据不完整时不宣布 accepted。优先级为：验收证据冲突→`unverified`；完整验收→`accepted`；当前修订明确 REJECT→`rejected`；BOARD 完成但验收证据不足→`unverified`；有确切当前 NEEDS_ATTENTION→`needs_attention`；其余按已证实 parked/resuming/checkpointed、远端 delivered、BOARD 待验收/进行中/待领/失败依次推导；缺失/互相矛盾则 `unknown` 并给出 `source_conflicts`。`event_status` 取与任务当前修订有关、可按 `timestamps.detected_at` 排序的最后可靠事件状态；无法确定事件顺序则置 null 并列冲突。BOARD「拒收」必须可见，但没有匹配拒收证据不能直接推定验收 REJECT。[CH-02/CH-03/C04/C05/O01/O07；依据：v1.1 §7、T-006 附表 A/B；优先级细节为新增]
- **七维并列**：`board_status`（原文）、`issue_state`（事实）、`delivery_status`（远端）、`acceptance_status`（证据）、`event_status`（事件）、`derived_status`（综合）、`source_conflicts`（冲突数组）。不能把七维压缩成一个 Task.status。若 BOARD「完成」但完整证据不足，则 `derived_status=unverified`；Issue OPEN 不影响上述任何结论；`NEEDS_ATTENTION` 为待人工归类，不是失败终态。[C04/O01；出处：v1.1 §7、T-006 §1/§2]
- **长任务**：`run_id`、`contract_revision`、`last_progress_at`、`checkpoint`、`parked_reason/parked_until` 与任务书版本分别保存；`checkpointed/resuming/parked` 仅在实际证据存在时出现，不以最近提交或过时 checkpoint 推断当前运行。[N13/N14；出处：Stage 0 §4 的 T-009/T-010 后续事实，非 T-006 原文]

### 2.2 事件与健康语义

`Event` 必须保留 `state`、`kind`、`review`、`delivery`、`approval`、`main_ack`、`retry`、`signals`、`timestamps` 及来源标识。已观测事件状态仅 ACKED/NEEDS_ATTENTION；REJECTED/SUPERSEDED/CLOSED_INTERNAL 允许接收但标记未经独立验证，不写自动状态转换；`kind`、`delivery.status`、`approval.status`、`ack_method` 枚举未证实时为 null/保留原值。`NEEDS_ATTENTION` 的 12 次重唤条件来自旧规则；48 小时归类、7 天升级**尚未在代码中实现**，Tower 本轮不增加定时器。[CH-04/O07–O12；出处：T-006 §2、§8、附表 D]

`health.json` 内部模型完整识别 `schema_version,last_success_at,last_attempt_at,consecutive_api_failures,consecutive_script_failures,note,rate.{remaining,reset,checked_at},last_error,s3.{ledger_available,error}`；`scan.json` 内部识别 `schema_version,scan_cursor,scan_cursor_updated_at,comments[issue][].{id,updated_at,processed},migrated_from,migrated_at,s3_ledger.{ledger_id,prefix_bytes,prefix_sha256,seq}`。公开 `/runtime` 只返回经过核实且脱敏的 HealthSummary/ScanSummary。`last_error` 是历史错误，不能直接变成当前 `current_error_code`。可靠 `last_success_at` 超过 **15 分钟**标 abnormal，无可靠记录标 unknown；其他来源新鲜度独立判断。[CH-05/O15–O20；出处：v1.1 §9、T-006 §6–§7]

`logs/health-exceptions.jsonl` 的结构仍未验证：**不按行向前端透传原文**；取得脱敏样本、审过字段之后才允许接入公开事件。该限制优先于 T-006 曾提出的“按行透传”候选，以满足 v1.1 §11 的敏感信息边界。[O18；出处：T-006 §10/附表 D1]

## 3. API、安全错误及降级合同 [CH-01/CH-06–CH-11/CH-16]

**严格保留 v1.1 §10 的 17 个操作、13 路径：** `/overview`、`/nodes`、`/nodes/{node_id}`、`/tasks`、`/tasks/{task_id}`、`/events`、`/runtime` 各 GET；`/notes` 与 `/todos` 各 GET/POST、`/{id}` 各 PATCH/DELETE；`POST /refresh`；`GET /healthz`。不得新增 `GET /notes/{id}` 或 `GET /todos/{id}`。[CH-01/C01/C02；出处：v1.1 §10]

**列表与搜索（新增）**：NodeList、TaskList、EventList 使用 `items,total,source_meta`；NoteList、TodoList 用 `items,total`。`GET /tasks` 支持 `q`（任务编号或标题大小写不敏感子串）、`status`（derived_status）、`assignee`，过滤后按任务 ID 升序，再 `limit`/`offset` 分页，默认 50、最大 100；`GET /events` 按检测时间降序、无时间置后、同时间 ID 升序；同样分页。`total` 指过滤后总数。精确语义均为**新增**，不冒充 v1.1 原数值。[CH-10/N06–N08/O32；出处：v1.1 Stage 2 搜索筛选需求、T-007 风险 10]

**数据新鲜度（新增）**：聚合 `source_meta.sources[]` 每来源含 `observed_at,last_success_at,fetched_at,freshness,stale,current_error_code`，并有 `generated_at,partial`；单一来源失败只标其自身，不能因其他源新鲜便整页标新鲜。成功且可用则 200；部分失败且有**可辨识的旧快照**返回 200 + `partial=true` 和 stale/unavailable 标签；所有所需源均无可用数据则 503 `SOURCE_UNAVAILABLE`（GitHub 因限额且无缓存则 `GITHUB_RATE_LIMITED`）；不得假装快照是实时数据。[CH-06/CH-07/O21–O23；出处：T-007 风险 2/8/10]

**只读 GitHub 限额**：后端使用经 Chen 授权的最低权限只读凭据（与 Tower Key 分离），优先缓存复用、按 GitHub 返回的 remaining/reset 与响应时间退避；刷新失败时保留进程内既有快照，不能每次前端渲染都全量请求 GitHub。具体 TTL、限流阈值与重试次数待实际 API/内存测试决定，不填虚构数字；未认证每小时 60 的旧观测不代表当前带凭据额度。[CH-07/O22/O23；出处：T-007 风险 8]

**刷新**：`POST /api/v1/refresh` 是同步、只读重采集；成功 200 `status=completed`，部分源失败但有可用数据 200 `status=degraded`；已有刷新在进行则**只用 409** `REFRESH_IN_PROGRESS`；无可用数据则 503。刷新不得提交 Git、调用节点或改变现有 Hook。[CH-09/C11；出处：v1.1 §10、T-007 风险 8；具体 HTTP 语义为新增]

**错误与写入**：错误体 `{code,message,request_id}`；枚举 `AUTH_REQUIRED,FORBIDDEN_ORIGIN,NOT_FOUND,VALIDATION_ERROR,REFRESH_IN_PROGRESS,SOURCE_UNAVAILABLE,GITHUB_RATE_LIMITED,INTERNAL_ERROR`。401、403、404、422、409（仅 refresh 冲突）、503、500 根据 YAML 列出；不会在错误体回显 Token、OS 绝对路径、堆栈。Note/Todo PATCH 为**最后写入覆盖**（单租户首版新增约定），不返回无法检测的并发 409；DELETE 成功 204；POST 创建 201。若未来引入 ETag/If-Match，须升版合同。[CH-09/C10/O31/N09；出处：v1.1 Stage 1 错误码交付要求、T-007 风险 4/5]

**双侧巡逻**：`Runtime.node_patrol` 独立读取 `patrol.sh` 实际配置（本次确认 300 秒，注册建议 300–600），`director_patrol` 独立读取 Hook 定义（2026-11-15 确认 `poll_interval_secs:60`）；各自标来源和观测时间。总控历史 300/180 不作当前默认值。未知用 null+unknown；`hook_wake_guaranteed_realtime=false` 代表**不保证实时**，不是断言每次送达均慢。[CH-11/C08/N16；出处：Stage 0 §3–§4 修正]

### 合同测试用 JSON 示例（新增；示意值并非实时生产记录）

```json
{"code":"GITHUB_RATE_LIMITED","message":"GitHub source unavailable and no usable snapshot","request_id":null}
```

```json
{"status":"degraded","refreshed_at":null,"source_meta":{"sources":[{"source":"github","source_ref":null,"observed_at":null,"last_success_at":null,"fetched_at":null,"freshness":"unavailable","stale":true,"current_error_code":"GITHUB_RATE_LIMITED"}],"generated_at":"2026-11-15T00:00:00Z","partial":true}}
```

上述第二例仅验证 schema/部分失败的表达形式；`generated_at` 是**示例生成时刻**，不是任何 GitHub 数据的采集时间。T-004 一对多验收测试应以两份不同 `version_sha` 的收据条目构造，**但不得把缩写 SHA 当作真实完整版本哈希**。[CH-03/CH-16/O13/O31]

## 4. T-006 缺失项 O01–O33 处置登记 [CH-02–CH-17]

处置枚举：`已纳入公开合同` 表示 YAML 有明确字段/规则；`纳入内部适配器模型` 表示保留在内部模型或运维实施约束，不直接透传浏览器；`等待源数据核实` 表示必须由总控取证，不得编值；本次**没有**未获用户明确批准而擅自标为「经批准延后」的项目。一个 O 项可有主处置及限定说明。

| O 编号 | 处置 | 位置或待办 |
|---|---|---|
| O01 | 已纳入公开合同 | Task 七维、SourceConflict；Y `Task` [CH-02] |
| O02 | 已纳入公开合同 | 原始六态 `board_status`；Y `Task` [CH-02] |
| O03 | 已纳入公开合同 | `task_version/task_book_path` 与独立 `contract_revision`；Y `Task` [CH-02] |
| O04 | 已纳入公开合同 | `issue_number/issue_state/issue_url`；Y `Task` [CH-02] |
| O05 | 已纳入公开合同 | `DeliveryEvidence.remote_verified/version_sha/source_paths`；Y [CH-03] |
| O06 | 已纳入公开合同 | `acceptance_status/receipts/main_ack` 与验收规则；Y [CH-03] |
| O07 | 已纳入公开合同 | `Event.state`、NEEDS_ATTENTION 非终态；Y [CH-04] |
| O08 | 已纳入公开合同 | `Event.retry`；不自动执行 48h/7d 机制；Y/A [CH-04] |
| O09 | 已纳入公开合同 | `Event.id/schema_version/source_commit_sha/source_paths`；Y [CH-04] |
| O10 | 已纳入公开合同 | `Event.review/delivery/approval`，未知枚举可 null；Y [CH-04] |
| O11 | 已纳入公开合同 | `Event.main_ack/retry`；Y [CH-04] |
| O12 | 已纳入公开合同 | `Event.signals/timestamps/last_error_historical`（脱敏）；Y [CH-04] |
| O13 | 已纳入公开合同 | `Task.receipts[]` 一对多、`ReceiptEvidence/ReceiptCheck`；Y [CH-03] |
| O14 | 已纳入公开合同 | `Node` 证据规则，未知心跳不判在线；Y/A [CH-02] |
| O15 | 纳入内部适配器模型 | HealthSource 全字段内部保存；公开 HealthSummary 为脱敏子集；A §2.2 [CH-05] |
| O16 | 已纳入公开合同 | historical `last_error` 不等于当前故障；Y `SourceMeta/HealthSummary` [CH-05] |
| O17 | 纳入内部适配器模型 | ScanSource comments/s3 ledger 全字段保留；公开 ScanSummary；A §2.2 [CH-05] |
| O18 | 等待源数据核实 | `health-exceptions.jsonl` 无字段样本；不得原文透传；A §2.2 [CH-05] |
| O19 | 已纳入公开合同 | 15 分钟健康阈值、无记录 unknown；Y `HealthSummary` [CH-05] |
| O20 | 纳入内部适配器模型 | 历史错误与当前派生健康分层，公开 `current_error_code`；A §2.2 [CH-05] |
| O21 | 已纳入公开合同 | 聚合 `SourceSnapshot/SourceMeta`；Y [CH-06] |
| O22 | 纳入内部适配器模型 | 进程缓存、限额、退避；公开刷新结果及时间；A §3 [CH-07] |
| O23 | 已纳入公开合同 | 200 部分可用/503 无数据、错误码；Y/A [CH-07] |
| O24 | 纳入内部适配器模型 | VM 外备份/恢复纳入运维验收；**具体频率/留存等待总控定**；A §1 [CH-12] |
| O25 | 纳入内部适配器模型 | SQLite WAL/短事务、仓库外数据库；A §1 [CH-12] |
| O26 | 等待源数据核实 | 白名单算法已定，**精确绝对路径尚待 VM 核实**；A §1 [CH-13] |
| O27 | 纳入内部适配器模型 | Worktree 访问约定+集成审查属于内部工作区治理；A §5 [CH-14] |
| O28 | 已纳入公开合同 | 单租户 Tower API Key；Y securitySchemes，A §1 [CH-08/15] |
| O29 | 等待源数据核实 | 静态 Space 原型可见性与快照内容由总控核验；A §5 [CH-15] |
| O30 | 纳入内部适配器模型 | Python venv、锁定版本与部署复核；A §5 [CH-15] |
| O31 | 已纳入公开合同 | Error.code 枚举与两个示例；Y/A [CH-09/16] |
| O32 | 已纳入公开合同 | 服务端 `q`、先过滤再排序分页；Y `/tasks` [CH-10] |
| O33 | 纳入内部适配器模型 | 合同评审签收流程与版本锁定；A §5 [CH-17] |

**D6 附表 D1–D10 仍受证据约束**：D1/D2/D3/D6/D7/D8 等字段和枚举仍未验证；D4 Issue #6 评论不得猜；D5 T-007 收据在当前时点需重查（不把调查时未知当永久未知）；D9 T-002 SHA 不猜；D10 自动升级尚未实现。**唯一新增确认**是基线五份收据的确切任务归属，不代表所有收据字段/当前状态已验证。[CH-16；出处：T-006 附表 D、用户本轮核实]

## 5. CH-01～CH-17 变更追溯及新增设计出处

| 变更 | 审计项 | 落点 |
|---|---|---|
| CH-01 | C01/C02 | 17 操作、13 路径，恢复两项 path 参数名；Y paths |
| CH-02 | C03/C04/O01–O04/O14 | 七维状态、原始 BOARD、节点/任务规则；Y Task/Node |
| CH-03 | C05/C06/O05/O06/O13 | 远端证据、ACK、收据 1:N；Y DeliveryEvidence/ReceiptEvidence/Task |
| CH-04 | C07/O07–O12 | Event 原始子结构及未知值；Y Event 系列 |
| CH-05 | O15–O20 | HealthSource/ScanSource 内部 + 公开摘要；Y Runtime/A §2 |
| CH-06 | O21 | SourceMeta/SourceSnapshot；Y 列表与聚合 |
| CH-07 | O22/O23 | 缓存、限额、503/部分可用；Y/A §3 |
| CH-08 | N05/O28 | 单租户 API Key，删除旧 cookie/CSRF 设定；Y/A §1 |
| CH-09 | C10/C11/O31 | last-write-wins、refresh 409、错误枚举；Y/A §3 |
| CH-10 | N07/N08/O32 | 查询、过滤、排序、分页；Y/A §3 |
| CH-11 | C08/N16 | 两侧 PatrolSide，实时保证语义；Y/A §3 |
| CH-12 | C09/O24/O25 | SQLite/备份边界；A §1 |
| CH-13 | O26 | VM 路径白名单及校验；A §1 |
| CH-14 | O27 | 三 worktree 权责隔离；A §6 |
| CH-15 | O28/O29 | 单租户、Space 核查；A §1/§6 |
| CH-16 | O31/D1–D10 | 示例 JSON、异常与未验证测试；A §3/§4/§6 |
| CH-17 | C12/O33 | rc 签收门槛及正式冻结流程；A §6 |

**新增设计逐项溯源（N01–N20，不伪称原文继承）：**

| N | 新增设计与依据 |
|---|---|
| N01 | systemd 系统级 unit + 非 root 账号；Stage 0 §2 阻断后的裁决，v1.1 §4 只要求 systemd。 |
| N02 | 回环 8000、单 worker、前端同源静态；Stage 0 预检 + v1.1 §4–§5 的部署目标，具体细节由架构新增。 |
| N03 | systemd 安全 sandbox；T-007 风险 6 的最小权限目标，unit 参数为新增建议。 |
| N04 | cgroup/峰值内存验收；Stage 0 §2 未验证容量，限额方法为新增。 |
| N05 | Tower API Key + Origin 校验；T-007 风险 5 仅要求最小鉴权，此方案为新增替换旧 cookie 草案。 |
| N06 | `{items,total}` 列表包装；v1.1 §10 未规定形状，新增。 |
| N07 | q/status/assignee/node_id/task_id 过滤；v1.1 Stage 2 搜索筛选目标，参数新增。 |
| N08 | limit=50、max=100、offset=0 和排序；v1.1 无数值，新增。 |
| N09 | 401/403/404/409/422/500/503、错误体/码；v1.1 Stage 1 需要错误码规范，但具体值新增。 |
| N10 | SourceMeta/SourceSnapshot；T-007 风险 2/8/10 要求时效标注，具体 Schema 新增。 |
| N11 | 节点派生状态枚举；v1.1 §8 要求未知/真实心跳，枚举新增。 |
| N12 | Task 派生状态枚举；v1.1 §7 七维是原要求，具体英文 enum 新增且按本轮修订。 |
| N13 | run_id、contract_revision、last_progress_at、PARKED；Stage 0 §4 后续 checkpoint 事实。 |
| N14 | Checkpoint.resume_available/resume_count；Stage 0 §4 续跑目标，字段为新增。 |
| N15 | Event.severity/summary；T-006 §8 只有原始状态，严重级别为新增展示维度。 |
| N16 | node_patrol/director_patrol；用户后续纠正并由 Stage 0 §3 更新，非旧版统一 300 秒。 |
| N17 | Note.title/body、Todo.text/done 等 CRUD DTO；v1.1 §6/§10 只给总体要求，具体字段新增。 |
| N18 | RefreshResult 与 liveness Health 的响应体；v1.1 §10 仅给操作用途，具体字段新增。 |
| N19 | 初始提交、Muse App 实际身份读回、A/B 资源门槛；v1.1 §12 + Stage 0 §4/§5 后续事实，细节新增。 |
| N20 | 合同 diff、类型生成、签收纪律；v1.1 Stage 1 冻结目标，执行流程新增。 |

## 6. Stage 2 开工、测试和冻结签收 [CH-14–CH-17；C12/O27–O33]

1. **冻结前**：Codex 复核 Pydantic 类型与真实源解析，Antigravity 用 YAML 生成 TS 类型并核查页面消费，node-3 独立检查状态/权限/过度设计；三方提交差异与证据后由架构负责人确认，Muse 总控记录固定版本与 commit。未签收前 `rc.1` 不能称 `1.1.0` 正式版。[CH-17/O33；出处：v1.1 Stage 1、T-007 风险 10]
2. **工作区**：私有 `xy3293/muse-control-tower` 先建初始 commit（含两合同和最小 README），再由同一基线建 backend/Codex、frontend/Antigravity、integration/总控三个 worktree。**接受轻量“工作目录约定＋总控逐提交评审”模式，不宣称 worktree 提供 OS 权限隔离**；总控负责调用/授权 Codex 与 Antigravity 工具会话，node-1 研究、node-2 浏览器测试、node-3 独立审查，不替代开发者直接改对应业务代码。需要真实硬隔离时另行升版。[CH-14/O27；出处：v1.1 §3/§12、T-007 风险 7]
3. **仓库与权限**：初始提交后用**Muse GitHub App 身份**读回已存在 README/合同，不能拿当前 `gh xy3293` 成功代替 App 访问。403 交 Chen 更新 App 所选私库，404 先辨别路径与权限。不得在空库时用未认证 404 证明不存在。[N19；出处：Stage 0 §4/§5、T-007 风险 8]
4. **资源/部署门禁**：Stage 2 代码开发须等 A/B 包关键资源阶段释放且由总控确认；systemd 系统 manager 及非 root 读权限未通过时，可在受控环境做代码开发，但部署子阶段阻断，不能称生产通过。内存边界、备份频率、白名单实际路径、Space 原型核查分别留证，不捏造完成状态。[CH-12/13/15；O24/O26/O29；出处：Stage 0 §2/§4]
5. **合同验收用例**：方法/路径 17/13 校验；401/403、Origin、无 cookie/no CORS；列表全局搜索先过滤再分页；三节点/no node-4；BOARD 完成但无收据→unverified；Issue OPEN 但 ACK/收据齐→accepted；T-003 本地 SHA 不算交付；T-004 双收据不覆盖；同修订相反 verdict→冲突不自动接受；REJECT 不作 FAIL；NEEDS_ATTENTION 不触发 48h/7d 计时器；无健康记录 unknown，历史 last_error 不误报；两侧 300/60 独立读取；GitHub 不可用时 200 partial/503；refresh 并行 409；不写 GitHub；note/todo WAL/重启可读；无凭据/绝对路径/日志泄露。[CH-01–CH-16；出处：v1.1 §7–§11、T-006 附表 A–D、T-007 风险 2/4/5/6/8/10]
6. **正式版本门槛**：修订 `rc.1` 的任何字段变更均先提交合同 diff 与对应 C/O/N/CH 理由；核对兼容性、生成的后端/前端类型和示例，再由架构负责人批准，发布 `1.1.0` 并记录 SHA。不得让任何开发方静默改字段；仍未证实的来源数据只能按上文等待核实，不得用猜测封闭漏洞。[CH-17/C12；出处：v1.1 Stage 1]

**结论：** 当前交付为可评审的两文件修订候选；除已核实的 T-004 一对多收据和双侧巡逻事实外，其余未知项仍明确为未知。完成上列签收后才正式冻结，并按 Stage 2 资源与环境门槛派工。

---
来源：ChatGPT（项目策划架构师）2026-11-15 05:30 +08 回复全文转录；总控本地落盘，未改动正文。ChatGPT 对话：https://chatgpt.com/c/6af8c577-aac4-83ee-b4e8-8775ca7d9924
