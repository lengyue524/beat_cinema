# Sprint Change Proposal

Date: 2026-03-22  
Project: beat_cinema  
Mode: Incremental

## 1. Issue Summary

触发类型：**新增需求（无现有 Story 直接覆盖）**  
触发上下文：实现期（BMM 4-implementation），用户提出 Playlist 与歌曲管理的操作增强。

新增需求原文（归并）：
1. 歌曲列表支持多选；多选时右键显示“添加到歌单、删除”
2. 普通右键支持“添加、删除”；删除需要删除歌曲目录
3. Playlist 详情支持：删除（可选是否删除歌曲目录）、添加到歌单、移动到其他歌单
4. 添加/移动到歌单时弹出歌单选择列表，支持歌单搜索

问题陈述：
- 当前系统以单条目操作为主，缺少批量选择与跨歌单管理闭环。
- Playlist 详情中缺少“移动/添加/删除并可选删除文件目录”的一致入口。
- 缺少统一“歌单选择器（可搜索）”组件，导致后续扩展成本高。

证据来源：
- 用户明确提出 4 条新增需求，且与现有 FR26/FR27/FR28（Playlist 管理）方向一致，但超出当前实现范围。

## 2. Impact Analysis

### Epic Impact
- 不需要回滚已完成 Epic。
- 主要影响 **E8（Playlist Management）** 的能力边界，建议在 **E10（Hardening）** 增加增量故事，降低对已完成故事的回归风险。

### Story Impact
- 现有 `S8.2/S8.3` 需要扩展“条目操作能力”说明（文档层）。
- 建议新增 E10 增量故事：
  - `S10.9`: 歌曲列表多选与批量右键操作（添加到歌单/删除目录）
  - `S10.10`: Playlist 详情高级管理（删除含可选删目录、添加到歌单、移动到歌单）
  - `S10.11`: 通用歌单选择弹窗（搜索 + 单/多目标选择）

### Artifact Conflicts
- **PRD**：现有 FR 已覆盖“播放列表浏览/导出/状态”，但未明确“多选 + 跨歌单移动 + 可选删目录”。
- **Architecture**：需补充“批量选择状态、文件删除安全策略、歌单写入一致性”设计约束。
- **UX**：需补充多选交互、右键菜单在“单选/多选”两种上下文的差异化规则，以及歌单搜索选择器交互。

### Technical Impact
- 需要新增或扩展 Playlist 领域服务：歌单条目增删改、跨歌单移动、批量写入。
- 需要目录删除安全机制：确认弹窗、失败回滚/提示、任务中资源占用处理。
- 需要统一歌单选择弹窗，避免在多个页面重复实现。

## 3. Recommended Approach

Selected Path: **Option 1 - Direct Adjustment（推荐）**

Rationale:
- 属于功能增强，不改变产品主线与技术栈。
- 可通过新增增量 Story 交付，避免改动已完成故事定义。
- 风险可控：把“批量操作”和“歌单选择器”拆分，便于分阶段回归。

Effort Estimate: **Medium**  
Risk Level: **Medium**  
Timeline Impact: **中等（建议插入 E10 当前冲刺）**

## 4. Detailed Change Proposals

### Proposal A — `epics.md` 增量故事补充

Artifact: `_bmad-output/planning-artifacts/epics.md`  
Section: `E10` 故事列表与详细 Story 段落

OLD:
- E10 目前到 `S10.8`，缺少“多选/跨歌单操作/歌单搜索选择器”专属故事

NEW:
- 新增 `S10.9: 歌曲列表多选与批量右键操作`
- 新增 `S10.10: Playlist 详情高级管理操作（删歌/移动/添加）`
- 新增 `S10.11: 通用歌单选择弹窗（支持搜索）`

Rationale:
- 把用户需求拆为可独立开发与验收的 3 个 Story，降低单点复杂度。

---

### Proposal B — `prd.md` 功能需求补充

Artifact: `_bmad-output/planning-artifacts/prd.md`  
Section: Functional Requirements（E8 相关）

OLD:
- FR26/FR27/FR28 聚焦播放列表浏览、状态与导出

NEW:
- 增补 FR（建议编号 FR42-FR45）：
  - FR42: 歌曲列表支持多选和批量右键操作（添加到歌单、删除歌曲目录）
  - FR43: Playlist 详情支持单/多条目删除，且可选“同步删除歌曲文件目录”
  - FR44: Playlist 详情支持将歌曲添加到其他歌单、移动到其他歌单
  - FR45: 添加/移动时提供歌单选择弹窗，并支持歌单搜索

Rationale:
- 让新增需求进入正式需求基线，便于后续验收与回归。

---

### Proposal C — `architecture.md` 与 `ux-design-specification.md` 同步补充

Artifacts:
- `_bmad-output/planning-artifacts/architecture.md`
- `_bmad-output/planning-artifacts/ux-design-specification.md`

OLD:
- 有右键菜单与 Playlist 模块说明，但缺少批量选择与跨歌单操作的约束细节

NEW:
- Architecture 增补：
  - 多选状态模型（selection set + scope）
  - 批量文件删除安全策略（确认、失败提示、部分成功处理）
  - Playlist 写入策略（原子写入与并发冲突处理）
- UX 增补：
  - 单选 vs 多选右键菜单差异
  - 删除操作二次确认（含“是否删除目录”开关）
  - 歌单选择器交互（搜索、空状态、禁用当前歌单）

Rationale:
- 避免实现期理解偏差，减少“做出来能用但体验不一致”的返工。

---

### Proposal D — `sprint-status.yaml` 同步

Artifact: `_bmad-output/implementation-artifacts/sprint-status.yaml`  
Section: `epic-10` stories

OLD:
- E10 仅到 `10-9`（backlog）或与 epics 文档存在不一致

NEW:
- 新增：
  - `10-10-playlist-multi-select-and-batch-context-actions: backlog`
  - `10-11-playlist-detail-cross-playlist-operations: backlog`
  - `10-12-playlist-picker-dialog-with-search: backlog`

Rationale:
- 保持 sprint 跟踪与故事清单一致，确保后续 `create-story` 可执行。

## 5. Implementation Handoff

Scope Classification: **Moderate**

Handoff Recipients:
- **SM / PO**：确认故事编号与优先级，安排进入当前 E10 实施序列
- **Dev**：按 `10-10 -> 10-11 -> 10-12` 顺序实现
- **QA / Reviewer**：重点验证批量删除、跨歌单移动、目录删除开关、搜索选择器可用性

Success Criteria:
- 歌曲列表可多选并批量右键操作；
- Playlist 详情支持删除/添加/移动全链路；
- 歌单选择弹窗可搜索、可选择、交互一致；
- 删除目录行为可控且有清晰确认与错误反馈。

## Checklist Status Snapshot

- 1.1 Trigger Story Identification: [x] Done（新增需求，无现有 Story 直接承载）
- 1.2 Core Problem Definition: [x] Done
- 1.3 Evidence Collection: [x] Done
- 2.1~2.5 Epic Impact Assessment: [x] Done
- 3.1~3.4 Artifact Conflict Analysis: [x] Done
- 4.1~4.4 Path Forward Selection: [x] Done
- 5.1~5.5 Proposal Components: [x] Done
- 6.1 Proposal Self-Review: [x] Done
- 6.2 Proposal Accuracy Check: [x] Done
- 6.3 User Approval: [x] Done（用户选择 yes）
- 6.4 sprint-status 同步: [x] Done（已新增 10-10/10-11/10-12）
- 6.5 Handoff Confirmation: [x] Done（执行顺序：10-10 -> 10-11 -> 10-12）

## Approval and Handoff Log

- Proposal A: Approved (`a`)
- Proposal B: Approved (`a`)
- Proposal C: Approved (`a`)
- Proposal D: Approved (`a`)
- Final Approval: Approved (`yes`)
- Scope Classification: Moderate
- Routed To:
  - Scrum Master / PO：创建并排序 10-10/10-11/10-12
  - Developer：按依赖顺序实现多选与跨歌单操作
  - QA / Reviewer：重点验证批量删除、目录删除开关、歌单搜索选择器
