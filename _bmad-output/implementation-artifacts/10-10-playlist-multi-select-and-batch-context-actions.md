# Story 10.10: 歌曲列表多选与批量右键操作

Status: done

## Story

As a 歌曲列表用户，
I want 在歌曲列表中使用 Ctrl/Shift 进行多选，并通过右键菜单执行“添加到歌单/删除歌曲目录”等批量操作，
so that 我可以在大量歌曲管理场景下减少重复点击并保持操作效率。

## Acceptance Criteria

1. 歌曲列表支持多选（Ctrl 追加、Shift 区间）与清空选择；列表刷新后不出现错选、串选。
2. 多选状态下右键菜单展示批量动作（添加到歌单、删除歌曲目录），并显示“已选择 N 项”。
3. 单选状态右键菜单保留现有主流程能力（搜索视频、配置相关）且不回归。
4. 批量删除前必须二次确认，确认框明确显示待删除数量，并区分“歌曲目录删除”语义。
5. 执行后列表与统计即时更新；部分失败需反馈“成功 X / 失败 Y”并给出失败原因摘要。

## Tasks / Subtasks

- [x] Task 1: 建立列表层多选状态模型与交互入口（AC: 1）
  - [x] 在 `LevelListView` 的状态层新增 `selectedLevelPaths: Set<String>`，与现有 `_selectedLevelPath` 单选态共存
  - [x] 处理桌面键盘修饰键（Ctrl/Shift）与点击行为，支持追加选择、区间选择、空白区清空
  - [x] 保证排序/筛选变更后选择集合按 `levelPath` 稳定映射，不依赖索引位置
- [x] Task 2: 右键菜单分支与批量动作入口（AC: 2, 3）
  - [x] 复用 `ContextMenuRegion`，按“单选/多选”动态构建菜单项，保持交互一致性
  - [x] 多选菜单首行显示已选数量（禁用项，仅信息展示）
  - [x] 单选菜单保持现有条目顺序与能力，不改变既有快捷操作路径
- [x] Task 3: 批量删除歌曲目录流程（AC: 4, 5）
  - [x] 新增批量删除确认弹窗，展示数量与风险提示
  - [x] 文件系统删除按条目逐一执行，捕获 `FileSystemException` 并汇总部分失败
  - [x] 删除完成后触发增量刷新（优先单项刷新事件，避免全量重载）
- [x] Task 4: 批量“添加到歌单”动作对接（AC: 2, 5）
  - [x] 在动作层预留与歌单选择器的调用接口（Story `10-12` 落地后复用）
  - [x] 先完成批量数据打包与事件分发边界（输入：选中 levelPaths，输出：playlist mutation 请求）
  - [x] 结果统一反馈成功/失败统计，避免静默失败
- [x] Task 5: 回归与验证（AC: 1-5）
  - [x] Widget 测试覆盖 Ctrl/Shift 多选、清空、菜单切换
  - [x] 行为测试覆盖批量删除确认、部分失败反馈、列表统计刷新
  - [x] 手工回归单选右键主链路（搜索视频、配置、下载）确保零回归

## Dev Notes

- 复用优先：列表展示与交互主干继续基于 `LevelListView`，避免复制新列表组件。
- 上下文菜单继续复用 `ContextMenuRegion`，仅扩展菜单数据构建逻辑，不改其通用弹出机制。
- 选择状态必须用 `levelPath` 作为稳定主键，不能依赖当前可见索引。
- 批量删除是“数据 + 文件系统”双层动作，执行顺序应保证“文件失败不破坏列表数据一致性”。
- 结果反馈必须可观测：成功数、失败数、失败摘要至少展示一次（SnackBar/Dialog 均可）。

### Architecture Compliance

- 遵循 Addendum 2026-03-22 的 Selection State Model：`selectedLevelPaths: Set<String>`。
- 遵循 Delete Safety Strategy：部分失败可接受，但不可导致状态错乱或数据损坏。
- 变更范围限定在 `CustomLevels` 列表交互层与必要的服务边界；避免将 Playlist 详情逻辑混入本 Story。
- 保持现有 BLoC 架构与事件驱动方式，不引入新的状态管理框架。

### Library / Framework Requirements

- Flutter Material 3 + `flutter_bloc` 既有栈，不新增第三方依赖。
- 使用 `dart:io` 删除目录时必须 catch `FileSystemException`。
- 保持 `package:beat_cinema/...` 导入风格，禁止相对导入与内联 import。

### File Structure Requirements

- 主要改动目标：
  - `lib/Modules/CustomLevels/widgets/level_list_view.dart`
  - `lib/Modules/CustomLevels/widgets/level_list_tile.dart`（如需增加选中态表现）
  - `lib/Modules/Panel/context_menu_region.dart`（仅在确有必要时做兼容增强）
  - `lib/Modules/CustomLevels/bloc/custom_levels_bloc.dart` 与 `custom_levels_event.dart`（若新增增量刷新事件）
- 测试建议位置：
  - `test/modules/custom_levels/widgets/` 下新增多选与批量菜单测试

### Testing Requirements

- 单测/组件测试至少覆盖：
  - Ctrl 追加选择、Shift 区间选择、清空选择
  - 单选/多选右键菜单项分支正确性
  - 删除确认弹窗出现与数量文案
  - 批量删除部分失败时的统计反馈
- 回归检查：
  - 现有单选右键链路不回归
  - 列表筛选/排序后选择状态不串行

### Previous Story Intelligence

- 来自 `10-8` 的经验应复用：
  - 优先走增量刷新与局部状态收敛，避免不必要全量刷新
  - 对“快速重复触发”要有防重入机制
  - 下载/文件动作后的 UI 反馈要即时且可理解

### Git Intelligence Summary

- 最近提交集中在“搜索稳定性、BBDown 集成、列表体验优化”，说明当前分支对列表与下载链路已有较多改动。
- 本 Story 应尽量在既有组件上做增量扩展，减少对下载/搜索链路的耦合改动，降低回归风险。

### Latest Tech Information

- 当前项目 Flutter 版本范围 `>=3.0.6 <4.0.0`，可直接使用桌面端鼠标与键盘事件组合实现多选交互，无需引入新库。
- 对桌面端右键交互保持 `GestureDetector.onSecondaryTapUp + showMenu` 模式，与现有实现一致可降低学习和维护成本。

### Project Structure Notes

- 与现有“ShellRoute + 路由级 BlocProvider”结构一致，本 Story 不新增路由页面。
- 该 Story 只处理“歌曲全量列表”的多选与批量入口；Playlist 详情“删/加/移”由后续 Story `10-11` 承接。
- “添加到歌单”建议通过接口边界与 `10-12` 的通用歌单选择器对接，避免重复实现弹窗。

### References

- [Source: _bmad-output/planning-artifacts/epics.md#S10.10]
- [Source: _bmad-output/planning-artifacts/prd.md#FR42-FR45]
- [Source: _bmad-output/planning-artifacts/architecture.md#Addendum-2026-03-22-Playlist-批量操作与歌单选择器]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Addendum-2026-03-22-多选与跨歌单操作-UX-规范]
- [Source: _bmad-output/implementation-artifacts/10-8-configured-video-missing-direct-download.md]
- [Source: _bmad-output/project-context.md]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- N/A（create-story 阶段）

### Completion Notes List

- 在 `LevelListView` 实现 `selectedLevelPaths` 多选模型，支持 Ctrl 追加、Shift 区间、多选保留与空白区清空。
- 右键菜单改为单选/多选动态分支：多选模式展示“已选择 N 项 + 添加到歌单 + 删除歌曲目录 + 清空选择”。
- 单选右键保留既有主流程（搜索视频/配置链路）并补充“添加到歌单、删除歌曲目录”入口。
- 批量删除新增二次确认，删除失败时汇总失败摘要；完成后触发列表刷新并收敛选中态。
- 预留批量“添加到歌单”与批量删除的可注入处理器边界，便于后续 Story `10-11`/`10-12` 对接。
- 新增多选交互 widget 测试（Ctrl/Shift、菜单切换、空白区清空），并通过现有 custom-levels widget 回归套件。
- 已执行 `flutter analyze` 与 `flutter test test/modules/custom_levels/widgets`，结果均通过。

### File List

- `lib/Modules/CustomLevels/widgets/level_list_view.dart`
- `lib/Modules/CustomLevels/widgets/level_list_tile.dart`
- `lib/Modules/CustomLevels/custom_levels_page.dart`
- `lib/Modules/CustomLevels/bloc/custom_levels_event.dart`
- `lib/Modules/CustomLevels/bloc/custom_levels_bloc.dart`
- `lib/Modules/Panel/context_menu_region.dart`
- `lib/l10n/intl_zh.arb`
- `lib/l10n/intl_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_zh.dart`
- `lib/l10n/app_localizations_en.dart`
- `test/modules/custom_levels/widgets/level_list_view_multi_select_test.dart`
- `test/modules/custom_levels/widgets/level_list_view_delete_behavior_test.dart`
- `_bmad-output/implementation-artifacts/10-10-playlist-multi-select-and-batch-context-actions.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-03-27: 完成 S10.10 实现（列表多选、批量右键、批量删除确认与反馈、动作边界预留）并补充回归测试。
- 2026-03-27: 代码评审后修复增量刷新链路（移除全量重载）、补充删除行为单测并完成复审通过。

## Senior Developer Review (AI)

### Review Date

2026-03-27

### Reviewer

AI Reviewer

### Outcome

Approve

### Summary

- 已修复“批量删除后触发全量重载”的实现偏差，改为按删除路径增量移除列表与缓存。
- 已补充删除确认文案与部分失败统计的可测试逻辑，并新增对应测试。
- `analyze` 与 custom-levels 相关测试套件均通过，Story 与实现一致性满足通过条件。

### Findings Closed

- [x] 批量删除后由 `ReloadCustomLevelsEvent` 全量刷新改为增量移除事件。
- [x] 删除确认与部分失败反馈补充可执行测试覆盖。
- [x] “添加到歌单”无处理器时的反馈路径改为统一结果统计输出（非静默失败）。
