# Sprint Change Proposal

Date: 2026-03-21
Project: beat_cinema
Mode: Incremental

## 1. Issue Summary

当前冲刺阶段暴露出 Playlist 相关的连续性问题：
- Playlist 页面加载时间显著偏长（尤其在大规模关卡库与批量下载后）
- Playlist 歌曲下载完成后，列表状态与“未安装”计数未及时更新

触发来源：
- E8 Playlist 管理能力进入高频使用后，用户在真实数据规模下反馈“加载慢 + 状态不变”

证据与现象：
- 下载任务已完成、文件已存在，但 Playlist 未安装计数不变化
- 进入 Playlist 的首屏等待时间明显偏长
- 现象在单曲下载与批量下载场景均可观察

## 2. Impact Analysis

### Epic Impact
- 不需要回滚 E8 已交付能力
- 主要影响 E10（质量与可维护性强化），建议在 E10 增加“Playlist 增量刷新一致性”故事并扩展性能护栏范围

### Story Impact
- 调整 `S10.5`：从“纯列表性能”扩展为“列表 + Playlist 匹配刷新性能”
- 新增 `S10.6`：针对“下载完成后 Playlist 状态不同步”进行专项修复

### Artifact Conflicts
- PRD：目标不变，仅当前实现偏离既定 NFR（首次/缓存加载阈值）
- UX：目标不变（实时反馈、状态可感知），当前行为未达标
- Architecture：不需要重定义架构方向，属于链路实现与刷新策略层面的偏差

### Technical Impact
- 需要明确下载状态到 Playlist 视图状态的端到端一致性链路
- 需要降低“下载完成后全量重解析”路径频率，优先增量更新策略
- 需要建立可回归的性能基线与告警阈值，防止后续退化

## 3. Recommended Approach

Selected Path: Direct Adjustment (Option 1, Hybrid)

Rationale:
- 风险最低：不推翻现有 E8 交付与匹配策略主线
- 响应最快：通过新增/细化 E10 故事可立即进入实现闭环
- 可持续：将“问题修复”与“性能护栏”一起固化为后续迭代标准

Effort:
- Medium

Risk:
- Medium（涉及状态链路与刷新策略，若缺少护栏可能反复回归）

Timeline Impact:
- 小幅增加 E10 实施工作量，但可显著降低后续反复修补成本

## 4. Detailed Change Proposals

### 4.1 `epics.md` - 更新 S10.5 范围（已确认 Approve）

Story: `S10.5`
Section: 标题、用户故事、验收标准

OLD:
- `S10.5: 大规模列表性能护栏（3000+ 数据量验证）`
- 重点仅覆盖列表加载/筛选/排序

NEW:
- `S10.5: 大规模列表与 Playlist 匹配性能护栏（3000+ 数据量验证）`
- 验收标准扩展到 Playlist 首次进入、重进、下载后刷新
- 阈值明确对齐 PRD NFR1/NFR2（首次 < 3s，缓存 < 1s）

Rationale:
- 现网痛点不只在列表渲染，也在 Playlist 匹配与刷新链路
- 护栏必须覆盖真实用户路径，避免“指标看起来达标但体验仍失败”

### 4.2 `epics.md` - 新增 S10.6（已确认 Approve）

Story: `S10.6`
Section: 新增故事（用户故事、验收标准、依赖、估算）

OLD:
- E10 仅到 S10.5，无专门条目约束“下载完成后 Playlist 一致性”

NEW:
- 新增 `S10.6: Playlist 下载后增量刷新与匹配一致性修复`
- 明确单曲/批量下载后 1 秒内状态可观察变化
- 明确“增量优先、避免重复全量重解析”的实现方向

Rationale:
- 将当前用户痛点从“临时修补”升级为“明确交付目标”
- 便于代码评审与回归测试针对性验收

### 4.3 `sprint-status.yaml` - 增加新故事状态（已确认 Approve）

Artifact: `sprint-status.yaml`
Section: `epic-10` stories

OLD:
- `10-4-core-flow-regression-guardrails: backlog`
- `10-5-large-scale-list-performance-guardrails: backlog`

NEW:
- 保留原条目
- 新增 `10-6-playlist-incremental-refresh-consistency: backlog`

Rationale:
- 让冲刺状态与故事清单保持一致
- 为后续 `create-story` / `dev-story` 提供可执行入口

## 5. Implementation Handoff

Scope Classification:
- Moderate（现有计划内增量调整 + Backlog 重组）

Handoff Recipients:
- Scrum Master / PO：维护故事顺序与优先级
- Developer：实现 S10.6 并配合 S10.5 护栏验证
- Reviewer：聚焦“状态一致性 + 性能退化”双维度验收

Responsibilities:
- SM/PO：确认 S10.6 排期（建议高优先）并维持 E10 交付节奏
- Dev：完成下载完成后的 Playlist 增量刷新链路修复
- QA/Review：覆盖单曲、批量、失败重试、重进页面四类路径

Success Criteria:
- 下载完成后 Playlist 计数与条目状态自动更新
- Playlist 加载体验达到 PRD/NFR 目标区间
- 新增护栏可稳定发现并阻止后续性能回归

## Checklist Status Snapshot

- 1.1 Trigger Story Identification: [x] Done
- 1.2 Core Problem Definition: [x] Done
- 1.3 Evidence Collection: [x] Done
- 2.1~2.5 Epic Impact Assessment: [x] Done
- 3.1~3.4 Artifact Conflict Analysis: [x] Done
- 4.1~4.4 Path Forward Selection: [x] Done
- 5.1~5.5 Proposal Components: [x] Done
- 6.1 Proposal Self-Review: [x] Done
- 6.2 Proposal Accuracy Check: [x] Done
- 6.3 User Approval: [x] Done（用户指令“继续”，视为批准）
- 6.4 sprint-status 同步: [x] Done
- 6.5 Handoff Confirmation: [x] Done（执行顺序：S10.6 -> S10.5）

## Approval and Handoff Log

- Approval: 已批准（2026-03-21）
- Scope Classification: Moderate
- Routed To:
  - Scrum Master / PO：组织故事顺序与节奏
  - Developer：优先实施 S10.6（下载后增量刷新一致性）
  - Reviewer / QA：执行状态一致性与性能回归验证

---

## Sprint Change Proposal Addendum (Mini Player UX)

Date: 2026-03-21  
Mode: Incremental

### 1. Issue Summary

当前实现中，歌曲播放后缺少固定可见的就近控制入口。用户滚动列表后需要回到原位置才能停止播放，影响连续操作体验。

触发来源：
- 用户新增需求：播放时在底部增加迷你播放器浮窗，便于滚动后停止播放

### 2. Impact Analysis

- Epic Impact：不影响既有 E1-E9 完成状态；在 E10 新增 UX 强化 Story 即可
- Story Impact：新增 `S10.7`，与 `S10.6` 并行管理，避免混入下载一致性故事
- Artifact Impact：需要更新 `epics.md` 与 `sprint-status.yaml`
- Technical Impact：复用现有 `audio preview` 与 `player lifecycle` 能力，不引入新技术栈

### 3. Recommended Approach

Selected Path: Option 1 (Direct Adjustment)

Rationale:
- 属于明确新增需求，直接增补 Story 成本最低、边界最清晰
- 复用已有播放器能力，风险可控

Effort: Low  
Risk: Medium

### 4. Detailed Change Proposals (Approved)

1) `epics.md` 新增 `S10.7: 音频播放浮动控制条（Mini Player）`  
2) `sprint-status.yaml` 新增 `10-7-floating-audio-mini-player: backlog`  
3) `10-6` 保持 `ready-for-dev`，不改变当前主线修复优先级

### 5. Implementation Handoff

Scope Classification: Minor  
Handoff Recipients:
- Scrum Master / PO：维护故事顺序与状态
- Developer：实现 `S10.7` 浮动迷你播放器
- Reviewer：验证显示/隐藏、停止控制、封面旋转、资源回收

Success Criteria:
- 播放开始显示浮动条，停止后自动隐藏
- 浮动条仅停止按钮，行为与需求一致
- 封面圆形旋转与播放状态同步

### Addendum Approval Log

- Incremental Proposal 1 (新增 S10.7): Approved (`a`)
- Incremental Proposal 2 (sprint-status 同步): Approved (`a`)
- Incremental Proposal 3 (epics 详细落文): Approved (`a`)
- Pending: Final proposal approval (yes/no/revise)
