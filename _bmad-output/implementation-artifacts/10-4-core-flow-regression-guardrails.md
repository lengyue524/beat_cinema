# Story 10.4: 核心流程回归护栏（下载/写入配置/面板流转）

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 维护者，
I want 为“搜索下载、配置写入、面板流转”三条核心链路建立最小可执行回归护栏，
so that 后续改动不会在不易察觉的地方引入回归并影响 Playlist/配置主流程稳定性。

## Acceptance Criteria

1. 定义 3 条关键回归链路：搜索下载、配置写入、面板开关与切换。  
2. 每条链路包含“预期状态变化”与“失败时用户反馈”。  
3. 回归检查清单可在开发完成后快速人工执行。  
4. 护栏内容与现有 Project Context 规则一致（不引入冲突）。  

## Tasks / Subtasks

- [x] Task 1: 固化三条核心回归链路（AC: 1）
  - [x] 梳理链路 A：搜索 -> 下载任务入队 -> 任务状态推进 -> 列表状态反馈
  - [x] 梳理链路 B：下载完成 -> `cinema-video.json` 写入 -> 状态图标/摘要更新
  - [x] 梳理链路 C：右键入口 -> 面板打开/切换上下文 -> 关闭与恢复
- [x] Task 2: 为每条链路定义“预期状态变化 + 失败反馈”（AC: 2）
  - [x] 明确状态节点（pending/downloading/completed/failed 与已就绪/待处理语义）
  - [x] 明确失败反馈最小要求（错误文案、重试入口、不中断其它操作）
  - [x] 明确关键时限（任务可观察、状态回流、UI 反馈）
- [x] Task 3: 输出可快速执行的回归清单（AC: 3）
  - [x] 形成“前置条件 -> 操作步骤 -> 预期结果 -> 失败判定”的清单结构
  - [x] 覆盖单曲下载、批量下载、失败重试、页面重进场景
  - [x] 标注 smoke 与 full 两种执行粒度
- [x] Task 4: 与项目规则对齐并完成可交付收口（AC: 4）
  - [x] 校验与 `project-context.md` 中 BLoC/路由/L10n/错误处理规则一致
  - [x] 校验与 PRD FR26/FR38/FR39/NFR16/NFR17/NFR19 语义一致
  - [x] 在故事记录中提供实施产物清单与后续 S10.5 复用入口

## Dev Notes

### Epic 上下文与依赖约束

- 本故事来自 E10 质量强化阶段，直接依赖 `S10.3` 的“依赖标注 + 同步规则”。  
- 依赖标注沿用 S10.3 标准：
  - 依赖 Story：`10-3-cross-epic-dependency-governance`
  - 阻塞 Story：`10-5-large-scale-list-performance-guardrails`
  - 解锁条件：产出 3 条核心回归链路且具备可执行检查清单
  - 依赖类型：mandatory
  - 风险等级：medium

### 实施边界（避免偏题）

- 本故事重点是“回归护栏定义与可执行检查清单”，不是一次性重构所有 Playlist 逻辑。  
- 若在执行中发现“下载完成后状态不回流”实装问题，记录为 S10.6 的优先实现输入，避免在本故事里做大规模逻辑变更。  

### 与现有需求映射（必须保持一致）

- PRD 相关要求：
  - FR26：Playlist 映射本地元信息并复用全量列表体验
  - FR38/FR39：单曲/批量下载任务入队与状态可观测
  - NFR16/NFR17：任务创建与队列稳定性
  - NFR19：Playlist 映射策略可追踪（hash 优先、名称兜底）
- UX 相关要求（Journey 4）：
  - 下载任务在 1 秒内进入下载管理
  - 下载结果应状态回流到列表
  - 失败项可重试且不阻断整体流程

### 代码与文件触达建议

- 主要代码观察点（用于定义护栏，不要求本故事全部改动）：
  - `lib/Modules/Playlists/bloc/playlist_bloc.dart`
  - `lib/Modules/Playlists/playlist_page.dart`
  - `lib/Services/managers/download_manager.dart`
  - `lib/Services/services/level_parse_service.dart`
  - `lib/Services/services/playlist_parse_service.dart`
- 主要文档与追踪工件：
  - `_bmad-output/planning-artifacts/epics.md`
  - `_bmad-output/implementation-artifacts/sprint-status.yaml`
  - 本故事文件（作为 dev-story 执行主输入）

### 测试与验证要求

- 采用“最小可执行回归”优先，先保证手工检查可复用，再视情况追加自动化。
- 推荐验证矩阵：
  - 单曲下载成功 -> Playlist 计数收敛
  - 批量下载（含失败）-> 未安装计数自动收敛 + 失败项可解释
  - 页面切换/重进 -> 状态一致性不丢失
  - 配置写入成功/失败 -> 状态图标与错误提示符合预期
- 验证输出要可直接被 S10.5 复用为性能护栏输入。

### 前一故事情报（S10.3）

- 已统一依赖标注格式，后续故事必须延续，不可引入第二套模板。  
- 已明确“依赖未满足不得 done”的 sprint-status 一致性规则；本故事结论与状态更新必须遵守。  

### Git 情报摘要（最近提交风格）

- 最近提交以 `feat:` / `fix:` 简短前缀为主。  
- Playlist 相关改动频繁，建议本故事输出的回归清单优先覆盖 Playlist 链路，减少反复修补。  

### 最新技术信息（用于护栏设计）

- Flutter 官方建议测试分层：单元/Widget/集成组合，而非单一端到端覆盖。  
- 本项目当前依赖仅含 `flutter_test`，未引入 `integration_test`、`bloc_test`；本故事应先设计“可快速执行的手工+轻量自动化护栏”，避免引入额外依赖导致范围膨胀。  

## Project Structure Notes

- 保持现有分层：UI (`Modules`) -> BLoC -> Service -> 文件系统/外部工具。  
- 回归护栏要覆盖“状态流”而不是只覆盖页面渲染，确保跨层问题可被发现。  
- 避免新增与现有模块平行的重复实现（尤其是 Playlist 列表渲染与状态计算）。  

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S10.4` / `S10.5` / `S10.6`]
- [Source: `_bmad-output/planning-artifacts/prd.md` - `FR26, FR38, FR39, NFR16, NFR17, NFR19`]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` - `Journey 4`]
- [Source: `_bmad-output/project-context.md` - `Critical Implementation Rules`]
- [Source: `_bmad-output/implementation-artifacts/10-3-cross-epic-dependency-governance.md`]
- [Source: [Flutter Testing Overview](https://docs.flutter.dev/testing/overview)]
- [Source: [Flutter Widget Testing Introduction](https://docs.flutter.dev/cookbook/testing/widget/introduction)]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- create-story workflow auto-discovery (`10-4-core-flow-regression-guardrails`)
- artifact analysis: epics / prd / architecture / ux / project-context
- previous story intelligence: `10-3-cross-epic-dependency-governance.md`
- git log pattern sampling (last 5 commits)
- web research: Flutter official testing guidance
- implementation artifact: `10-4-core-flow-regression-checklist.md`
- validation run: `flutter analyze lib/Modules/Playlists lib/Services`
- validation run: `flutter test test/widget_test.dart`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- 已将回归护栏目标拆分为可执行任务与可判定验收边界
- 已补充与 S10.3 依赖治理规则的连续性约束
- 已将 S10.5/S10.6 作为下游衔接明确标注
- 已新增可执行回归清单，覆盖 3 条核心链路与 smoke/full 两种执行粒度
- 已纳入单曲/批量/失败重试/页面重进场景，并定义统一失败判定规则
- 已对齐 PRD FR26/FR38/FR39 与 NFR16/NFR17/NFR19 语义
- 已完成最小回归验证（analyze + widget smoke test）
- code-review 自动修复：补齐 AC2 可判定锚点与 AC→证据映射，提升审查可重复性
- code-review 自动修复：补充执行证据采集字段，降低“通过判定主观化”风险

### File List

- `_bmad-output/implementation-artifacts/10-4-core-flow-regression-guardrails.md`
- `_bmad-output/implementation-artifacts/10-4-core-flow-regression-checklist.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `lib/Modules/Playlists/bloc/playlist_bloc.dart` (review anchor)
- `lib/Modules/Playlists/playlist_page.dart` (review anchor)
- `lib/Services/managers/download_manager.dart` (review anchor)

## Change Log

- 2026-03-21: `dev-story` 完成，输出核心流程回归护栏清单并将故事状态置为 review。
- 2026-03-21: `code-review` 自动修复高/中问题，补强可审计锚点与 AC 证据映射，故事状态更新为 done。

## Senior Developer Review (AI)

### Review Date

2026-03-21

### Reviewer

AI Code Reviewer

### Outcome

Approve

### Findings

- [x] [High] AC2 缺少可判定锚点，导致“失败反馈”难以客观验收（已在回归清单补齐锚点）。
- [x] [High] 故事缺少 AC->证据映射，审查可追溯性不足（已新增映射章节）。
- [x] [Medium] 结果记录模板缺少执行证据字段，难以复盘（已新增证据采集字段）。
- [x] [Medium] Story File List 对审查锚点覆盖不足（已补充关键代码观察锚点路径）。
