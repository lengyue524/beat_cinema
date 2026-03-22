# Story 10.5: 大规模列表与 Playlist 匹配性能护栏（3000+ 数据量验证）

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 性能关注用户，
I want 在超大数据量下（关卡列表 + Playlist 匹配）建立可执行、可回归的性能护栏，
so that 版本演进时能持续满足加载与交互体验目标，避免性能退化。

## Acceptance Criteria

1. 定义 3000+ 关卡场景下的性能验证基线（加载、筛选、排序）与 Playlist 匹配验证基线（首次进入、重进、下载后刷新）。  
2. 明确可接受阈值与退化告警条件（与 PRD NFR1/NFR2 对齐，首次加载 < 3s、缓存命中 < 1s）。  
3. 输出针对列表渲染、匹配索引构建、下载完成后状态刷新链路的优化优先级建议。  
4. 验证项覆盖缓存命中与非命中两类路径，并覆盖单曲下载与批量下载完成后的列表一致性。  

## Tasks / Subtasks

- [x] Task 1: 建立 3000+ 性能基线与测量方法（AC: 1,2）
  - [x] 定义测量对象：首次加载、缓存加载、筛选、排序、Playlist 首次进入/重进、下载后刷新
  - [x] 统一测量方式（时间窗口、采样次数、通过判定）
  - [x] 固化阈值：首次 < 3s、缓存命中 < 1s，并定义退化告警线
- [x] Task 2: 覆盖缓存命中/非命中与下载场景（AC: 1,4）
  - [x] 设计缓存命中路径验证（已有解析缓存）
  - [x] 设计缓存非命中路径验证（首次解析/路径切换）
  - [x] 设计单曲下载与批量下载完成后的一致性验证（未安装计数与条目状态）
- [x] Task 3: 输出性能优化优先级建议（AC: 3）
  - [x] 评估列表渲染成本（构建、重建、长列表策略）
  - [x] 评估匹配索引构建与重建成本（key/hash/songName）
  - [x] 评估下载完成后的状态回流链路成本（全量/增量刷新）
- [x] Task 4: 形成可执行性能护栏文档并对齐既有规则（AC: 2,4）
  - [x] 输出性能护栏清单（smoke/full 两层）
  - [x] 与 `project-context.md` 规则、PRD/UX 语义对齐
  - [x] 给出与 S10.6 的协同执行建议（先一致性修复，再基线固化）

## Dev Notes

### Epic 上下文与依赖约束

- 本故事承接 S10.4（核心流程回归护栏），目标是把“功能可回归”进一步提升为“性能可回归”。  
- 依赖标注（沿用 S10.3 标准）：
  - 依赖 Story：`10-4-core-flow-regression-guardrails`
  - 阻塞 Story：无
  - 解锁条件：回归护栏基线已固化，可在 3000+ 数据量场景复用
  - 依赖类型：mandatory
  - 风险等级：medium

### 与 PRD/NFR 对齐（必须守住）

- PRD NFR1：500 首首次加载 < 3s（本故事扩展到 3000+ 护栏场景）
- PRD NFR2：缓存命中后续加载 < 1s
- PRD NFR19：Playlist 映射策略可追踪（hash 优先、名称兜底）
- FR26/FR38/FR39：Playlist 映射与下载状态回流必须保持用户可见一致性

### 前一故事情报（S10.4）

- 已有“核心流程回归清单”可复用：下载链路、配置写入、面板流转。  
- 本故事要在 S10.4 的功能护栏上增加“量化门槛 + 告警规则 + 数据规模压力场景”。  
- 若发现“下载完成后状态不回流”问题，优先由 S10.6 实施修复，再回到本故事做性能复测。

### 代码观察重点（性能视角）

- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
  - `_onLoad`、`_onDownloadTasksUpdated` 是否存在重复全量解析/重建
  - `_buildPlaylists` 与索引构建（key/hash/songName）的重建频率
- `lib/Services/services/level_parse_service.dart`
  - 3000+ 目录扫描与 hash 计算成本
  - 缓存命中场景是否可避免重复重算
- `lib/Modules/CustomLevels` 与 `playlist_page.dart`
  - 长列表渲染策略（懒加载、重建范围控制）
  - 状态变更触发的 UI 重建粒度

### 实施边界

- 本故事以“性能护栏定义与验证”为主，不要求一次性重构全部性能热点。  
- 可输出优化优先级与建议，但不要越界改动无关功能语义。  
- 仅在必要时提出依赖变更；新增依赖需用户明确批准。  

### 测试与验证要求

- 必须提供可重复测量方法，避免“体感快/慢”结论。  
- 验证最少覆盖：
  - 缓存命中 vs 非命中
  - 单曲下载完成后状态收敛
  - 批量下载完成后状态收敛
  - 页面重进后状态一致
- 若添加自动化，保持与现有项目测试栈一致（当前以 `flutter_test` 为主）。

### 最新技术信息（官方参考）

- Flutter 官方性能建议：
  - 大列表应优先使用惰性构建（`ListView.builder`）
  - 避免不必要重建与高成本布局/绘制
  - 为列表提供 extent 信息（`itemExtent` / `prototypeItem` / `itemExtentBuilder`）可降低滚动成本
- 对本项目的直接启示：
  - 减少下载状态变化导致的全量重建
  - 对 Playlist 匹配链路优先做增量刷新策略
  - 将性能门槛写入可执行清单并持续复核

## Project Structure Notes

- 保持分层边界：UI -> BLoC -> Services，不把性能采样逻辑散落到 UI 事件中。  
- 性能护栏产物优先放在实施工件目录，供后续 `dev-story` / `code-review` 复用。  
- 复用 S10.4 已产出的回归清单结构（smoke/full + 判定锚点），避免重复模板。  

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S10.5`]
- [Source: `_bmad-output/planning-artifacts/prd.md` - `NFR1, NFR2, NFR19, FR26, FR38, FR39`]
- [Source: `_bmad-output/implementation-artifacts/10-4-core-flow-regression-guardrails.md`]
- [Source: `_bmad-output/project-context.md` - `Critical Implementation Rules`]
- [Source: [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)]
- [Source: [Flutter Cookbook: Work with long lists](https://docs.flutter.dev/cookbook/lists/long-lists)]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- create-story workflow auto-discovery (`10-5-large-scale-list-performance-guardrails`)
- artifact analysis: epics / prd / project-context / previous story
- previous story intelligence: `10-4-core-flow-regression-guardrails.md`
- web research: Flutter 官方性能文档（列表与构建成本）
- implementation artifact: `10-5-large-scale-performance-guardrails-checklist.md`
- validation run: `flutter analyze lib/Modules/Playlists lib/Modules/CustomLevels lib/Services`
- validation run: `flutter test test/widget_test.dart`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- 已将性能护栏拆解为“测量基线、阈值告警、缓存路径、下载一致性”四类任务
- 已明确与 S10.6 的执行衔接：先修一致性，再固化大规模性能护栏
- 已补充官方性能实践引用，避免过时实现策略
- 已产出 3000+ 场景性能护栏清单，覆盖缓存命中/非命中与下载后一致性验证
- 已固化阈值、告警级别与采样规范（P50/P95/Max）
- 已输出优化优先级（P0/P1/P2）用于后续实施排期
- 已完成最小回归验证（analyze + widget smoke test）
- code-review 自动修复：新增可执行采样脚本模板，支持 P50/P95/Max 计算与阻断判定
- code-review 自动修复：补齐采集锚点（代码路径）与 AC→证据映射，提升审查可重复性

### File List

- `_bmad-output/implementation-artifacts/10-5-large-scale-list-performance-guardrails.md`
- `_bmad-output/implementation-artifacts/10-5-large-scale-performance-guardrails-checklist.md`
- `_bmad-output/implementation-artifacts/10-5-performance-sampling-template.ps1`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-03-21: `dev-story` 完成，产出 3000+ 性能护栏清单并将故事状态置为 review。
- 2026-03-21: `code-review` 自动修复高/中问题，补齐可执行采样入口与 AC 证据映射，故事状态更新为 done。

## Senior Developer Review (AI)

### Review Date

2026-03-21

### Reviewer

AI Code Reviewer

### Outcome

Approve

### Findings

- [x] [High] 缺少可执行采样入口，3000+ 基线难以复现（已新增 `10-5-performance-sampling-template.ps1`）。
- [x] [High] 阈值存在但缺少代码采集锚点，验收主观性高（已补充采集锚点路径）。
- [x] [Medium] 缺少 AC->证据映射，审查追溯性不足（已新增映射章节）。
- [x] [Medium] File List 未覆盖新增实施产物（已补齐脚本文件与说明）。
