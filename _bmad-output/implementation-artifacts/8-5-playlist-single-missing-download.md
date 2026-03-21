# Story 8.5: playlist-single-missing-download

Status: done

## Story

As a 播放列表用户，
I want 在 Playlist 详情里对“未下载”歌曲直接点击下载并进入下载管理，
so that 我可以不离开当前上下文快速补齐缺失歌曲。

## Acceptance Criteria

1. Playlist 详情中，处于“待处理-未下载”的歌曲显示“下载”操作入口。  
2. 点击“下载”后，下载任务在 1 秒内进入下载管理列表，并可见状态流转（pending/downloading/completed/failed）。  
3. 下载失败时，用户可看到可理解错误信息并支持重试。  
4. 下载完成后，Playlist 状态可刷新，歌曲从“未下载”转换为“已就绪”或“待处理-未配置”。  

## Tasks / Subtasks

- [x] Task 1: 扩展 Playlist 状态模型以区分“未下载 / 未配置”（AC: 1,4）
  - [x] 在 `PlaylistSongWithStatus` 中补充下载态字段（`downloading` / `downloadError`）
  - [x] 保持与现有 `LevelMetadata` 匹配逻辑兼容（hash 优先、名称兜底）
- [x] Task 2: 在 Playlist 详情页增加单曲下载入口（AC: 1,2）
  - [x] 对未匹配（未下载）项渲染下载按钮与进行中状态
  - [x] 点击后派发下载事件并阻止重复点击导致重复任务
- [x] Task 3: 接入下载管理能力（AC: 2,3）
  - [x] 扩展下载管理器支持自定义任务（Playlist 下载任务入统一下载队列）
  - [x] 失败信息在 Playlist 列表可见，并可在下载管理页进行重试
- [x] Task 4: 完成下载后刷新 Playlist 视图（AC: 4）
  - [x] 下载状态变化通过事件回流到 PlaylistBloc 并驱动重载
  - [x] 校验头部统计与过滤结果同步更新

## Dev Notes

### Scope & Boundaries

- 本 Story 仅覆盖“单曲下载（未下载）”，不包含“下载全部缺失”（S8.6）和“增强导出/失败重试”（S8.7）。
- 目标是先打通最小闭环：列表可点下载 -> 下载管理可观测 -> 状态回流 Playlist。

### Existing Implementation Context

- 现有 Playlist 页面与 BLoC：
  - `lib/Modules/Playlists/playlist_page.dart`
  - `lib/Modules/Playlists/bloc/playlist_bloc.dart`
- 现有下载管理页面与任务模型：
  - `lib/Modules/Downloads/downloads_page.dart`
  - `lib/Services/managers/download_manager.dart`

### Architecture/Quality Notes

- 状态语义对齐 PRD/UX：`已就绪 / 待处理(未下载/未配置)`。
- 下载任务创建后 1 秒内可见是硬约束（NFR16）。
- 失败项必须提供“可理解错误”而非仅技术异常栈。

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S8.5`]
- [Source: `_bmad-output/planning-artifacts/prd.md` - `FR38`, `NFR16`]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` - `Journey 4`]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- create-story continuation
- implementation-readiness follow-up

### Completion Notes List

- 已实现 Playlist 未下载歌曲单曲下载入口，并接入统一下载管理队列。
- 新增 BeatSaver 下载服务（按 hash 查询并下载/解压到 CustomLevels）。
- 下载任务状态（进行中/失败）已回流到 Playlist 列表；完成后触发重载匹配。
- 路由层已将全局下载管理器注入 Playlist/Downloads 页面。
- 已通过验证：`flutter analyze`（相关模块）与 `flutter test test/widget_test.dart`。

### File List

- `_bmad-output/implementation-artifacts/8-5-playlist-single-missing-download.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `lib/Services/managers/download_manager.dart`
- `lib/Services/services/beatsaver_download_service.dart`
- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
- `lib/Modules/Playlists/bloc/playlist_event.dart`
- `lib/Modules/Playlists/bloc/playlist_state.dart`
- `lib/Modules/Playlists/playlist_page.dart`
- `lib/App/bloc/app_bloc.dart`
- `lib/App/Route/app_route.dart`
- `pubspec.yaml`

## Change Log

- 2026-03-21: 创建 Story 8.5 并设置为 ready-for-dev。
- 2026-03-21: 完成 Story 8.5 开发实现，状态推进到 review。
- 2026-03-21: 完成回归验证与修复后收口，状态更新为 done。
