# Story 10.11: Playlist 详情高级管理操作（删除/添加/移动）

Status: done

## Story

As a Playlist 详情页用户，
I want 在歌曲明细里执行删除、添加到其他歌单、移动到其他歌单，并可选择是否同步删除歌曲目录，
so that 我可以在不离开当前上下文的情况下完成歌单治理与跨歌单整理。

## Acceptance Criteria

1. Playlist 详情支持单项/多项删除。
2. 删除时提供开关：仅移除歌单项 / 同步删除歌曲目录。
3. 支持“添加到歌单”与“移动到其他歌单”。
4. 移动完成后，源歌单与目标歌单的条目数量和状态保持一致。
5. 删除歌曲目录失败时不得破坏歌单数据，需给出明确失败提示。

## Tasks / Subtasks

- [x] Task 1: Playlist 详情选择与批量动作入口（AC: 1）
  - [x] 在 `PlaylistPage` 详情列表复用现有 `LevelListView` 多选能力，保持与歌曲总表交互一致
  - [x] 将当前选中条目映射为 playlist song 实体（避免仅按 UI 索引操作）
  - [x] 支持单项与多项删除入口，菜单语义按 UX 规范区分
- [x] Task 2: 删除流程与安全策略（AC: 2, 5）
  - [x] 增加删除确认弹窗与“同步删除歌曲目录”开关
  - [x] 先执行歌单数据变更，再执行可选文件删除（失败时回报部分失败，不回滚已成功歌单变更）
  - [x] 对文件删除失败输出“成功 X / 失败 Y”及失败摘要
- [x] Task 3: 添加/移动到歌单业务流程（AC: 3, 4）
  - [x] 增加 playlist mutation 边界方法：add/remove/move（保持原子写入）
  - [x] “移动”语义 = 从源歌单移除 + 追加到目标歌单，且统计与状态即时收敛
  - [x] 目标歌单选择入口通过可注入选择器接口接入（由 `10-12` 完成实际搜索弹窗）
- [x] Task 4: 状态一致性与刷新（AC: 4, 5）
  - [x] 完成后刷新源/目标歌单视图统计（已配置/未安装/总数）
  - [x] 失败路径不破坏 playlist 数据文件；必要时输出失败清单
  - [x] 保持与 `PlaylistBloc` 现有下载状态流、匹配状态流兼容
- [x] Task 5: 回归与测试（AC: 1-5）
  - [x] BLoC/服务测试覆盖删/加/移三类操作（含部分失败）
  - [x] Widget 测试覆盖删除确认开关与结果反馈文案
  - [x] 回归验证 Playlist 详情现有导出、筛选、下载入口不受影响

## Dev Notes

- 该 Story 聚焦 Playlist 详情操作闭环；通用可搜索歌单选择弹窗由 `10-12` 承接。
- 必须遵循 Delete Safety Strategy：文件删除失败不能导致 `.bplist` 数据损坏。
- Playlist 变更写入沿用原子写入原则（参考 `S4.4` 相关能力）。
- 与 `10-10` 已实现的“批量动作结果统计反馈”保持一致（成功/失败计数 + 摘要）。

### Architecture Compliance

- 落实 `Playlist Mutation Service Boundary`：删/加/移统一在服务边界实现，页面只负责触发与展示。
- 落实 `Delete Safety Strategy`：区分“仅删除歌单项”和“同步删除目录”，并支持部分失败。
- 与 `Reusable Playlist Picker` 对接方式保持可替换，不在本 Story 内硬编码弹窗实现。

### Library / Framework Requirements

- 继续使用 Flutter + `flutter_bloc` 现有栈，不新增依赖。
- 文件删除统一 `dart:io` + `FileSystemException` 捕获。
- 导入保持 `package:beat_cinema/...` 风格，禁止相对导入。

### File Structure Requirements

- 主要改动目标：
  - `lib/Modules/Playlists/playlist_page.dart`
  - `lib/Modules/Playlists/bloc/playlist_bloc.dart`
  - `lib/Modules/Playlists/bloc/playlist_event.dart`
  - `lib/Modules/CustomLevels/widgets/level_list_view.dart`（仅必要适配）
  - `lib/l10n/intl_zh.arb`
  - `lib/l10n/intl_en.arb`
- 测试建议：
  - `test/modules/playlists/` 下新增删/加/移与失败路径测试

### Testing Requirements

- 至少覆盖：
  - 单项/多项删除 + 开关语义
  - 添加到其他歌单与移动到其他歌单
  - 移动后源/目标统计一致性
  - 目录删除部分失败提示与数据不损坏
- 回归：
  - Playlist 详情导出能力
  - 下载任务状态同步
  - “仅未配置”筛选语义

### Previous Story Intelligence

- 来自 `10-10`：
  - 多选状态要用稳定主键（path/hash）而非索引
  - 批量动作必须给出可观测结果统计
  - 优先增量刷新，避免不必要全量重载

### Git Intelligence Summary

- 最近提交集中在搜索稳定性与列表交互增强；本 Story 应最小化对搜索/下载链路的影响。
- 推荐将 Playlist 详情变更限制在 Playlist 模块与可复用列表适配层，降低回归面。

### Latest Tech Information

- 当前 Flutter 版本范围可直接支持桌面右键和键盘修饰键交互，无需额外 UI 依赖。
- 继续沿用现有 `ContextMenuRegion` 与 BLoC 事件驱动模式，减少认知成本。

### Project Structure Notes

- 本 Story 为 `10-12` 的前置实现：先打通数据与动作边界，再接入“可搜索歌单选择器”。
- 若 `10-12` 未完成，本 Story 内“目标歌单选择”可先使用占位入口/回调注入，不阻塞核心删/移逻辑。

### References

- [Source: _bmad-output/planning-artifacts/epics.md#S10.11]
- [Source: _bmad-output/planning-artifacts/prd.md#FR43-FR45]
- [Source: _bmad-output/planning-artifacts/architecture.md#Addendum-2026-03-22-Playlist-批量操作与歌单选择器]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Addendum-2026-03-22-多选与跨歌单操作-UX-规范]
- [Source: _bmad-output/implementation-artifacts/10-10-playlist-multi-select-and-batch-context-actions.md]
- [Source: _bmad-output/project-context.md]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- N/A（create-story 阶段）

### Completion Notes List

- Playlist 详情接入多选状态回传，新增批量“删除/添加/移动”入口，并在标题区展示已选数量。
- 新增 `DeletePlaylistSongsEvent` 与 `MutatePlaylistSongsEvent`，实现删/加/移 mutation 边界（含 move=add+remove）。
- 删除流程支持“同步删除歌曲目录”开关；先写 playlist 再删目录，目录失败仅计入失败统计，不破坏 playlist 数据。
- 新增 `PlaylistActionNotice` 统一动作反馈，页面以 Snackbar 呈现“成功 X / 失败 Y + 摘要”。
- Playlist 目标选择弹窗提供搜索过滤能力，并在 move 模式禁用当前歌单目标。
- 为避免 Playlist 详情误用全局删目录逻辑，`LevelListView` 增加 `enablePlaylistBatchActions` 与 `onSelectionChanged` 适配。
- 已执行 `flutter analyze`、`flutter test test/modules/playlists`、`flutter test test/modules/custom_levels/widgets`，全部通过。

### File List

- `lib/Modules/Playlists/bloc/playlist_event.dart`
- `lib/Modules/Playlists/bloc/playlist_state.dart`
- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
- `lib/Modules/Playlists/playlist_page.dart`
- `lib/Modules/CustomLevels/widgets/level_list_view.dart`
- `lib/Modules/CustomLevels/bloc/custom_levels_event.dart`
- `lib/Modules/CustomLevels/bloc/custom_levels_bloc.dart`
- `lib/l10n/intl_zh.arb`
- `lib/l10n/intl_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_zh.dart`
- `lib/l10n/app_localizations_en.dart`
- `test/modules/playlists/bloc/playlist_bloc_mutation_test.dart`
- `test/modules/playlists/playlist_page_rebuild_index_test.dart`
- `_bmad-output/implementation-artifacts/10-11-playlist-detail-cross-playlist-operations.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-03-27: 完成 S10.11（Playlist 详情删/加/移、删除目录开关、目标歌单选择与搜索、动作反馈）并补齐回归测试。
- 2026-03-27: 根据 code-review 自动修复 4 项问题：move 失败回滚保障、未匹配条目删除能力、JSON 解析异常反馈、补齐删除确认/结果反馈测试覆盖。
