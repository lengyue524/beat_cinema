# Story 10.12: 通用歌单选择弹窗（支持搜索）

Status: done

## Story

As a 需要跨歌单整理歌曲的用户，
I want 使用统一且可搜索的歌单选择弹窗来选择目标歌单，
so that 我可以在“添加到歌单”和“移动到歌单”两类场景下快速、稳定地完成目标选择。

## Acceptance Criteria

1. 提供统一歌单选择弹窗，支持搜索过滤。
2. 搜索支持大小写不敏感匹配，关键词高亮为可选能力（可不阻塞主流程）。
3. 在“移动到歌单”场景下可禁用当前歌单作为目标。
4. 当可选目标为空时提供明确空状态提示。
5. 弹窗可复用于“添加到歌单”“移动到歌单”两类入口，且交互一致。

## Tasks / Subtasks

- [x] Task 1: 抽离通用歌单选择器组件（AC: 1, 5）
  - [x] 在 Playlist 模块新增可复用弹窗组件（`PlaylistPickerDialog`）
  - [x] 输入参数包含：歌单列表、当前歌单路径（可选）、模式（add/move）、初始查询词（可选）
  - [x] 输出统一为目标歌单路径（确认）或 `null`（取消）
- [x] Task 2: 搜索与列表交互（AC: 1, 2, 4）
  - [x] 实现大小写不敏感搜索过滤（标题维度）
  - [x] 空结果时展示统一空状态文案（与当前 i18n 风格一致）
  - [x] 支持关键词高亮（首个命中片段加粗）
- [x] Task 3: 业务场景约束（AC: 3, 5）
  - [x] move 场景禁用当前歌单目标并给出不可选语义
  - [x] add 场景允许当前歌单（由上层 mutation 逻辑处理幂等/去重）
  - [x] 在 Playlist 详情页“添加/移动”入口统一接入该组件，移除重复弹窗逻辑
- [x] Task 4: 状态与可访问性（AC: 1-5）
  - [x] 键盘操作可达：搜索框聚焦、上下选择、回车确认、Esc 取消
  - [x] 文案与语义标签可本地化，不引入硬编码回退冲突
  - [x] 保持与既有暗色主题、间距规范一致
- [x] Task 5: 测试与回归（AC: 1-5）
  - [x] Widget 测试覆盖：搜索过滤、空状态、move 禁用当前歌单、选择返回值
  - [x] 回归验证：Playlist 详情“添加/移动”动作路径仍可用
  - [x] 回归验证：现有 mutation 反馈（SnackBar/action notice）不受影响

## Dev Notes

- `10-11` 已在页面内完成可搜索选择弹窗的原型逻辑；本 Story 目标是沉淀为通用组件，避免重复实现和后续扩展成本。
- 该 Story 不改动核心 mutation 语义，只聚焦“选择目标歌单”交互层的复用与一致性。
- 需保持与现有 `PlaylistMutationMode`、`MutatePlaylistSongsEvent` 对接方式兼容，避免扩大回归面。

### Architecture Compliance

- 落实 `Reusable Playlist Picker`：组件化、可复用、可配置（add/move 场景差异由参数驱动）。
- 与 `Playlist Mutation Service Boundary` 解耦：选择器只负责“选谁”，不负责“怎么改”。
- 保持现有 BLoC 事件流稳定，不在选择器内部直接做文件系统操作。

### Library / Framework Requirements

- 继续使用 Flutter + `flutter_bloc` 现有栈，不新增依赖。
- 复用现有 Material 组件能力（`AlertDialog`/`TextField`/`ListView`）。
- 导入保持 `package:beat_cinema/...` 风格，禁止相对导入。

### File Structure Requirements

- 主要改动目标（建议）：
  - `lib/Modules/Playlists/widgets/playlist_picker_dialog.dart`（新增）
  - `lib/Modules/Playlists/playlist_page.dart`（接入通用选择器）
  - `lib/l10n/intl_zh.arb`
  - `lib/l10n/intl_en.arb`
- 测试建议：
  - `test/modules/playlists/widgets/playlist_picker_dialog_test.dart`（新增）
  - `test/modules/playlists/playlist_page_rebuild_index_test.dart`（必要回归补充）

### Testing Requirements

- 至少覆盖：
  - 搜索过滤（大小写不敏感）
  - 空状态提示
  - move 禁用当前歌单
  - 点击候选后返回目标路径
- 回归：
  - Playlist 详情“添加到歌单”“移动到歌单”两条路径
  - 现有删除流程与 mutation 反馈流程

### Previous Story Intelligence

- 来自 `10-11`：
  - 选择器逻辑已具备可用原型，但位于页面内部，复用成本高。
  - 删除/添加/移动反馈已统一到 `PlaylistActionNotice`，本 Story 不应破坏该反馈链路。
  - 未匹配条目删除、move 回滚等稳定性修复已完成，应维持不回退。

### Git Intelligence Summary

- 当前 Playlist 模块在持续强化“交互复用 + 行为一致性”；本 Story 推荐最小侵入式重构：先抽组件，再替换调用点。
- 优先控制改动面在 Playlist 模块与 l10n，避免牵动 CustomLevels 核心逻辑。

### Latest Tech Information

- 当前 Flutter 桌面能力可满足弹窗、搜索输入、键盘导航与列表选择，不需要新增三方 UI 库。
- 保持现有 i18n 生成流程（更新 ARB 后执行 `flutter gen-l10n`）。

### Project Structure Notes

- 本 Story 是 `10-11` 的收口项：把“可搜索目标歌单选择”从页面逻辑提升为可复用组件。
- 后续若扩展到更多入口（例如主列表批量“添加到歌单”），可直接复用该组件。

### References

- [Source: _bmad-output/planning-artifacts/epics.md#S10.12]
- [Source: _bmad-output/planning-artifacts/architecture.md#Addendum-2026-03-22-Playlist-批量操作与歌单选择器]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Design-System-Foundation]
- [Source: _bmad-output/planning-artifacts/sprint-change-proposal-2026-03-22.md]
- [Source: _bmad-output/implementation-artifacts/10-11-playlist-detail-cross-playlist-operations.md]
- [Source: _bmad-output/project-context.md]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- N/A（create-story 阶段）

### Completion Notes List

- 新增 `PlaylistPickerDialog` 组件，统一承载“添加到歌单/移动到歌单”的目标选择交互。
- 在 `PlaylistPage` 中移除内联弹窗实现，改为调用通用组件，降低重复代码与维护成本。
- 选择器支持大小写不敏感搜索、空状态提示、move 场景禁用当前歌单、关键词高亮。
- 新增键盘可达能力：方向键切换候选，Enter 确认，Esc 取消。
- 新增并通过 widget 测试覆盖搜索过滤、空状态、禁用语义、返回值与键盘确认路径。
- 执行 `flutter gen-l10n` 与 playlist 模块相关测试，均通过。

### File List

- `lib/Modules/Playlists/widgets/playlist_picker_dialog.dart`
- `lib/Modules/Playlists/playlist_page.dart`
- `lib/l10n/intl_zh.arb`
- `lib/l10n/intl_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_zh.dart`
- `lib/l10n/app_localizations_en.dart`
- `test/modules/playlists/widgets/playlist_picker_dialog_test.dart`
- `_bmad-output/implementation-artifacts/10-12-playlist-picker-dialog-with-search.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-03-27: 创建 S10.12 Story 文档并置为 ready-for-dev。
- 2026-03-27: 完成 S10.12 开发实现（通用歌单选择器抽离、PlaylistPage 接入、键盘可达、测试覆盖）并置为 review。
- 2026-03-27: code-review 通过，推进为 done。
