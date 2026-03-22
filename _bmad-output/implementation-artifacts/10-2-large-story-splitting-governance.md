# Story 10.2: large-story-splitting-governance

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 产品与开发协作方，
I want 将过大的 Story 按统一规则拆分为可并行、可验证、可追踪的子 Story，
so that 降低单点风险并提升迭代可预测性与交付质量。

## Acceptance Criteria

1. 定义 Story 拆分规则（触发条件、拆分粒度、验收边界）。  
2. 产出 1 个模板示例：将“搜索 + 下载 + 进程管理”拆分为独立子能力。  
3. 明确每个子 Story 的输入/输出、依赖、完成定义（DoD）。  
4. 新增 Story 不与既有已完成 Story 冲突或重复。  

## Tasks / Subtasks

- [x] Task 1: 建立可执行的 Story 拆分规则文档（AC: 1）
  - [x] 定义“大 Story 触发条件”（如 SP 阈值、跨模块耦合、跨 sprint 风险、单 Story 多目标）
  - [x] 定义拆分粒度标准（单 Story 单目标、可在一个生命周期内完成、可独立验证）
  - [x] 定义验收边界模板（行为边界、数据边界、错误边界、性能边界）
- [x] Task 2: 产出 S3.2 拆分模板（AC: 2）
  - [x] 基于 `S3.2: YtDlpService 实现（搜索 + 下载 + 进程管理）` 形成拆分前后对照
  - [x] 输出至少 3 个子 Story（建议：搜索能力、下载能力、进程生命周期治理）
  - [x] 为每个子 Story 提供 Given/When/Then 示例验收场景
- [x] Task 3: 补齐子 Story 的 I/O、依赖与 DoD（AC: 3）
  - [x] 明确输入（输入源/触发事件/前置状态）与输出（状态变化/可观察结果）
  - [x] 标注依赖链（前置 Story、阻塞条件、解锁条件）
  - [x] 给出统一 DoD 清单（实现、测试、文档、状态流转）
- [x] Task 4: 冲突与重复校验（AC: 4）
  - [x] 逐项比对 E1-E9 done Story，确保无功能重复和状态冲突
  - [x] 记录“复用既有能力”而非“重造轮子”的策略
  - [x] 将新增拆分建议保持在规划工件，不修改已完成历史项

## Dev Notes

### Epic 上下文与业务意图

- 本 Story 属于 E10（Post-MVP Hardening），目标是“治理实施质量与可维护性”，不引入新业务功能范围。  
- `S10.1` 已完成 BDD 验收规范统一；`S10.2` 进一步将“大 Story 拆分规则化”，为后续 `S10.3` 依赖治理打基础。  
- 关键结果：形成“可复用拆分标准 + 可直接执行模板”，而不是一次性文档说明。  

### 目标对象与拆分样本

- 重点样本：`S3.2: YtDlpService 实现（搜索 + 下载 + 进程管理）`（8 SP，高复杂、跨能力聚合，来自 `epics.md`）。  
- 预期拆分方向（示例）：
  - 子 Story A：搜索命令与结果解析
  - 子 Story B：下载链路与进度输出
  - 子 Story C：进程生命周期、超时与取消治理
- 每个子 Story 必须具备可独立验收的业务结果，避免按技术层硬切导致“不可验证”。  

### 架构与流程护栏（必须遵守）

- 继续遵循项目既有状态机：`backlog -> ready-for-dev -> in-progress -> review -> done`。  
- Story 拆分仅落在规划工件（`_bmad-output/planning-artifacts/`）与实施工件文档，不改动已完成代码的行为边界。  
- 避免与 E3/E4/E5 已完成能力冲突，优先“复用和显式引用”而非“重述和重造”。  
- 依赖表达为“Story 级可追踪关系”，后续可被 `sprint-status.yaml` 同步消费。  

### 技术与规范参考（提炼给 dev-story）

- INVEST 质量门槛用于检验拆分结果：Independent / Negotiable / Valuable / Estimable / Small / Testable。  
- 拆分后的每个 Story 需包含：
  - 明确用户价值（Valuable）
  - 单 sprint 可完成规模（Small）
  - 可判定通过条件（Testable，优先 Given/When/Then）
- 与现有项目规范一致：
  - 用户可见文案保持 L10n 约束
  - 文档不嵌入实现细节（控件 ID、内部类名、命令调用步骤）  

### 文件结构要求

- 主要编辑目标：
  - `_bmad-output/planning-artifacts/epics.md`（新增拆分规则与样本拆分结果）
  - 必要时补充同目录下治理说明文档（若拆分模板过长）
- 当前 Story 文件：
  - `_bmad-output/implementation-artifacts/10-2-large-story-splitting-governance.md`

### 测试与验证要求

- 本 Story 验证以“文档可执行性”与“冲突审计”为主：
  - 规则是否可操作（触发条件、粒度、边界可判定）
  - 样本拆分是否满足独立可验收（每个子 Story 都有 I/O、依赖、DoD）
  - 是否与已完成 Story 重复或冲突（E1-E9 done 对照）
- 若引入脚本化检查，优先做“重复标题/重复能力关键词”扫描与依赖链完整性检查。  

### 前一故事学习（S10.1 继承）

- 已沉淀实践：
  - 验收标准优先行为化（Given/When/Then）
  - 每条关键项都要覆盖成功路径 + 失败/边界路径
  - 术语保持与 PRD/Architecture/UX 一致，避免实现细节污染
- 本 Story 应复用以上写作与验收范式，形成可复制模板。  

### Git 与近期实现模式（用于一致性）

- 最近提交风格显示：以 `feat/fix` 小步迭代为主，强调 bug 修复与依赖升级。  
- 本 Story 输出应支持这种“小步可落地”节奏：拆分后子 Story 尽量可单独推进与审查。  

### 最新实践参考（Web Research 摘要）

- INVEST 框架用于 Story 质量校验的行业共识仍稳定有效，尤其适合控制“过大 Story”风险。  
- 强调 Story 的 Independent/Small/Testable，可显著降低串行阻塞并提升 sprint 预测性。  
- 对本项目的直接应用：拆分后子 Story 必须具备可独立交付价值与清晰验收边界，而非仅按代码模块切块。  

## Project Structure Notes

- 与统一项目结构保持一致：
  - 规划与治理文档放在 `_bmad-output/planning-artifacts/`
  - 实施状态与上下文放在 `_bmad-output/implementation-artifacts/`
- 不触碰 `_bmad/` 工作流引擎文件与已有 done Story 历史状态。  

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `E10 / S10.2`]
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml` - `10-2-large-story-splitting-governance: done`]
- [Source: `_bmad-output/implementation-artifacts/10-1-bdd-acceptance-criteria-hardening.md` - 前序学习与约束]
- [Source: `_bmad-output/planning-artifacts/prd.md` - FR/NFR 与阶段范围]
- [Source: `_bmad-output/planning-artifacts/architecture.md` - 服务层与状态流转约束]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` - 错误分级与交互一致性]
- [Source: `_bmad-output/project-context.md` - 项目级编码与文档规则]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- create-story workflow
- sprint-status auto-discovery (`10-2-large-story-splitting-governance`)
- artifact analysis: epics / PRD / architecture / UX / project-context
- previous story intelligence: `10-1-bdd-acceptance-criteria-hardening.md`
- git intelligence: recent 5 commits
- web research: INVEST story splitting best practices
- dev-story workflow
- `flutter test`
- `flutter analyze`
- `rg` 关键字段检查（子 Story A、输入/输出、DoD、冲突校验）

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- 已在 `epics.md` 为 S10.2 落地可执行拆分规则（触发条件、粒度、边界、INVEST 门槛）。
- 已产出 S3.2 拆分模板（A/B/C 三个子 Story），并补齐每条的 I/O、依赖、DoD 与 BDD 示例。
- 已完成与 E1-E9 done 条目的冲突与重复校验，明确“复用与引用”策略。
- 已通过回归验证：`flutter test` 与 `flutter analyze` 全通过。
- code-review 修复已完成：移除误导性未勾选项、补充拆分前后对照矩阵、统一依赖标注格式。

### File List

- `_bmad-output/planning-artifacts/epics.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/10-2-large-story-splitting-governance.md`

## Change Log

- 2026-03-21: 完成 S10.2 拆分治理文档与模板落地，故事状态流转到 review。
- 2026-03-21: 完成 S10.2 code-review 修复并关闭中低风险项，故事状态更新为 done。

## Senior Developer Review (AI)

### Review Date

2026-03-21

### Reviewer

AI Code Reviewer

### Outcome

Approve

### Findings

- [x] [Medium] S10.2 核心规则段落使用大量未勾选项，语义易被误解为未完成（已改为说明性条目）。
- [x] [Medium] 缺少结构化“拆分前后对照”证据（已新增对照矩阵）。
- [x] [Low] 依赖描述未统一格式，不利于后续 S10.3 消费（已统一为依赖/阻塞/解锁条件格式）。
