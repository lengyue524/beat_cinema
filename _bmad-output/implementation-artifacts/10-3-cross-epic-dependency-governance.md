# Story 10.3: cross-epic-dependency-governance

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 迭代规划者与实施协同方，
I want 为跨 Epic 前向依赖建立统一、可追踪、可同步的标注与顺序规则，
so that 避免执行顺序误判并降低跨模块联动带来的回归风险。

## Acceptance Criteria

1. 在受影响 Story 中显式标注“依赖 Story / 阻塞 Story / 解锁条件”。  
2. 输出统一依赖标注格式并应用到后续新增 Story。  
3. 对已识别前向依赖（如 E3↔E5、E4↔E5）给出执行顺序建议。  
4. 依赖变更同步到 sprint tracking（避免状态与依赖不一致）。  

## Tasks / Subtasks

- [x] Task 1: 建立统一依赖标注规范并落地（AC: 1,2）
  - [x] 定义统一模板：`依赖 Story / 阻塞 Story / 解锁条件 / 依赖类型 / 风险等级`
  - [x] 明确依赖类型分类：mandatory / discretionary / internal / external
  - [x] 在 E10 后续 Story（至少 S10.3/S10.4/S10.5）中应用该格式
- [x] Task 2: 输出跨 Epic 依赖地图与建议顺序（AC: 3）
  - [x] 对 E3↔E5、E4↔E5 建立依赖对照表（上游能力、下游消费点、风险说明）
  - [x] 给出可执行顺序建议（先解锁上游，再推进下游）
  - [x] 为关键路径增加“阻塞解除标准”（unblock criteria）
- [x] Task 3: 覆盖用户补充场景（playlist 元信息复用）（AC: 1,3）
  - [x] 将“playlist 根据歌曲信息获取对应元信息并复用全量歌曲列表界面”纳入依赖案例
  - [x] 显式标注该场景的跨 Epic 依赖链（E8 -> E2 -> 组件复用）
  - [x] 给出执行顺序与验收边界，避免重复实现列表展示逻辑
- [x] Task 4: 同步 sprint tracking 一致性规则（AC: 4）
  - [x] 定义依赖变更触发 sprint-status 更新的规则（何时更新、更新哪些字段）
  - [x] 校验依赖标注与状态流转不冲突（blocked 不应标记 done）
  - [x] 输出最小检查清单，供 create-story/dev-story/code-review 复用

## Dev Notes

### Epic 上下文与目标

- 本 Story 继承 `S10.2` 的拆分治理成果，目标从“拆分规则”推进到“跨 Epic 依赖显式治理”。  
- 重点是让依赖关系可读、可查、可执行，并与 sprint tracking 状态流转保持一致。  

### 前一故事学习（来自 S10.2）

- 已具备的资产：
  - 可执行拆分规则（触发条件/粒度/边界/INVEST）
  - `S3.2` 拆分模板（A/B/C）及统一依赖字段雏形
  - 冲突与重复校验方法（复用优先）
- 本 Story 应在此基础上做“跨 Epic 级”扩展，而不是重新定义一套新规范。  

### 关键依赖案例（必须覆盖）

1) E3 ↔ E5（搜索下载能力与面板承载）
- 上游：E3 的搜索/下载能力  
- 下游：E5 的 Panel/ContextMenu 路由承载  
- 风险：先后顺序错误会导致“功能存在但入口不可用”  

2) E4 ↔ E5（配置编辑能力与面板交互）
- 上游：E4 的配置读写与原子写入  
- 下游：E5 的面板编辑交互  
- 风险：UI 可编辑但后端能力或错误处理不完整  

3) 用户补充需求：Playlist 元信息复用链
- 需求：playlist 需要根据 playlist 内歌曲信息映射对应歌曲元信息，并显示与“全部歌曲列表”一致的界面  
- 建议依赖链：`E8 Playlist` 依赖 `E2 LevelMetadata/列表组件能力`  
- 治理原则：优先复用既有列表展示能力，不新增重复渲染逻辑与状态模型  

### 统一依赖标注格式（本 Story 输出标准）

- `依赖 Story`：当前 Story 依赖哪些上游 Story
- `阻塞 Story`：当前 Story 阻塞哪些下游 Story
- `解锁条件`：满足什么证据后可推进下游
- `依赖类型`：mandatory / discretionary / internal / external
- `风险等级`：high / medium / low

### sprint tracking 同步规则（实施护栏）

- 依赖变更时应同步检查 `sprint-status.yaml`，避免“状态显示可推进但依赖未满足”。  
- 对显式 blocked 项，禁止直接流转到 done；应先满足解锁条件。  
- 建议在故事文档中保留“依赖变更记录”简表，便于 code-review 快速核验。  

### 文件结构要求

- 主要编辑目标：
  - `_bmad-output/planning-artifacts/epics.md`（依赖标注规范与案例）
  - `_bmad-output/implementation-artifacts/sprint-status.yaml`（状态同步）
- 当前 Story 文件：
  - `_bmad-output/implementation-artifacts/10-3-cross-epic-dependency-governance.md`

### 测试与验证要求

- 本 Story 以文档验证和一致性审计为主：
  - 依赖标注是否结构化、可追踪、可判定
  - 跨 Epic 顺序建议是否可执行
  - 依赖与 sprint-status 状态是否一致
- 若做脚本化检查，优先：
  - 检查“依赖 Story/阻塞 Story/解锁条件”字段完整性
  - 检查 blocked/done 等状态冲突

### 最新实践参考（Web Research 摘要）

- 依赖治理建议采用“消除 -> 缓解 -> 管理”三步法，减少不可控阻塞。  
- 建议将 blocker 标记与解锁条件标准化，保留时间戳与责任人信息便于回顾。  
- 对本项目落地：优先清除不必要耦合，保留必要依赖并可视化追踪。  

## Project Structure Notes

- 保持在规划与实施工件范围内完成治理，不改动现有运行时代码行为。  
- 与项目既有规则一致：术语统一、L10n 约束、状态机一致。  

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `E10 / S10.3`]
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml` - `10-3-cross-epic-dependency-governance: done`]
- [Source: `_bmad-output/implementation-artifacts/10-2-large-story-splitting-governance.md` - 拆分规则与依赖模板]
- [Source: `_bmad-output/planning-artifacts/architecture.md` - E3/E4/E5 模块边界与交互关系]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` - 面板交互与列表一致性原则]
- [Source: `_bmad-output/project-context.md` - 规则与状态流转约束]
- [Source: User requirement - playlist songs map to level metadata and reuse full list UI]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- create-story workflow
- sprint-status auto-discovery (`10-3-cross-epic-dependency-governance`)
- artifact analysis: epics / architecture / ux / project-context
- previous story intelligence: `10-2-large-story-splitting-governance.md`
- web research: dependency mapping best practices
- user additional requirement: playlist metadata mapping and shared list UI
- dev-story workflow
- `flutter test`
- `flutter analyze`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- 已在 `epics.md` 的 S10.3 条目中落地统一依赖标注格式（依赖/阻塞/解锁条件/类型/风险）。
- 已输出跨 Epic 依赖地图（E3->E5、E4->E5、E8->E2）与执行顺序建议。
- 已覆盖用户补充需求：playlist 根据歌曲信息映射元信息并复用全量歌曲列表界面。
- 已补充 unblock criteria 与 sprint tracking 同步检查清单，保证依赖与状态一致。
- 已完成回归验证：`flutter test` 与 `flutter analyze` 均通过。
- code-review 修复已完成：补齐 S10.4/S10.5 依赖标注字段并修正 blocked 状态表达与状态机一致性。

### File List

- `_bmad-output/planning-artifacts/epics.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/10-3-cross-epic-dependency-governance.md`

## Change Log

- 2026-03-21: 完成 S10.3 依赖治理文档落地，故事状态流转到 review。
- 2026-03-21: 完成 S10.3 code-review 修复并关闭中优先级问题，故事状态更新为 done。

## Senior Developer Review (AI)

### Review Date

2026-03-21

### Reviewer

AI Code Reviewer

### Outcome

Approve

### Findings

- [x] [Medium] AC2 要求“应用到后续新增 Story”，但 S10.4/S10.5 缺少完整依赖字段（已补齐依赖/阻塞/解锁条件/类型/风险）。
- [x] [Medium] sprint 同步规则引用 blocked 状态，与现有 `sprint-status.yaml` 状态集合不一致（已改为“依赖未满足不得 done”的兼容表达）。
