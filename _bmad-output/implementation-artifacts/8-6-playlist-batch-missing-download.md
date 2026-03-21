# Story 8.6: playlist-batch-missing-download

Status: done

## Story

As a 播放列表用户，
I want 一键下载播放列表中全部缺失歌曲，并可选择是否更新已存在歌曲，
so that 我可以快速完成歌单补齐而无需逐条手动处理。

## Acceptance Criteria

1. Playlist 详情提供“下载全部缺失歌曲”入口。  
2. 支持两种模式：仅下载缺失 / 缺失 + 更新已存在。  
3. 更新判定规则可见且可追踪：文件缺失、版本不一致、用户强制更新。  
4. 批量任务创建后 1 秒内进入下载管理并可观测任务状态。  
5. 在 100 首缺失场景下，单任务失败不导致队列整体中断。  

## Tasks / Subtasks

- [x] Task 1: 批量入口与模式选择（AC: 1,2）
  - [x] 在 Playlist 头部增加“下载全部缺失歌曲”按钮
  - [x] 增加模式选择（仅缺失 / 缺失+更新 + 可选强制更新）
- [x] Task 2: 更新判定与任务构建（AC: 3）
  - [x] 为每首歌输出判定原因（缺失/版本不一致/强制）
  - [x] 任务元数据包含 songName/hash/判定原因
- [x] Task 3: 批量入队与稳定性保障（AC: 4,5）
  - [x] 批量任务按 20 条分段入队，避免瞬时拥塞
  - [x] 单任务失败后继续处理后续任务（队列不中断）
- [x] Task 4: 可观测性与回流（AC: 4,5）
  - [x] 下载管理可见完整任务集合及状态
  - [x] Playlist 列表状态按任务结果增量刷新

## Dev Notes

### Scope & Boundaries

- 本 Story 关注“批量下载与更新判定”，不处理导出失败清单与重试（S8.7）。
- 默认依赖 S8.5 的单曲下载链路已打通。

### Key Quality Constraints

- 批量创建任务可观测时效：1 秒（NFR17 相关时效要求）。
- 失败隔离：单任务失败不影响剩余队列推进。

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S8.6`]
- [Source: `_bmad-output/planning-artifacts/prd.md` - `FR39`, `NFR17`]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` - `Journey 4`]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Completion Notes List

- 已实现“下载全部缺失歌曲”入口，支持两种模式：仅缺失 / 缺失+更新。
- 已实现更新判定规则：文件缺失、版本不一致、用户强制更新。
- 批量任务写入统一下载队列，并透出 metadata（songName/hash/reason）便于追踪。
- 批量入队采用分段节流（每 20 条让出事件循环），满足大批量稳定性要求。
- 已通过验证：`flutter analyze`（相关模块）与 `flutter test test/widget_test.dart`。

### File List

- `_bmad-output/implementation-artifacts/8-6-playlist-batch-missing-download.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `lib/Modules/Playlists/playlist_page.dart`
- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
- `lib/Modules/Playlists/bloc/playlist_event.dart`
- `lib/Services/managers/download_manager.dart`

## Change Log

- 2026-03-21: 创建 Story 8.6 并设置为 ready-for-dev。
- 2026-03-21: 完成 Story 8.6 实现并推进到 review。
- 2026-03-21: 完成回归验证并收口，状态更新为 done。
