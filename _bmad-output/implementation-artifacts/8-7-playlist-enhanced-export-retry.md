# Story 8.7: playlist-enhanced-export-retry

Status: done

## Story

As a 播放列表用户，
I want 导出时同时包含 `.bplist` 与已下载歌曲目录，并在部分失败时获得清单与重试入口，
so that 导出过程具备容错能力且可恢复。

## Acceptance Criteria

1. 导出内容包含 `.bplist` 文件与已下载歌曲目录。  
2. 部分歌曲缺失或复制失败时，导出不中断，可用内容仍完成输出。  
3. 导出结束后 3 秒内生成失败清单（至少含 songName/hash/失败原因/时间戳）。  
4. 提供“仅重试失败项”入口，触发后 1 秒内创建对应重试任务。  
5. 结果反馈包含成功数、失败数与可执行下一步操作。  

## Tasks / Subtasks

- [x] Task 1: 导出范围增强（AC: 1）
  - [x] 在导出流程中复制源 `.bplist` 文件到目标目录
  - [x] 复制已下载歌曲目录并保留目录结构
- [x] Task 2: 部分成功策略（AC: 2,5）
  - [x] 采用“可用先行”策略，不因单项失败终止全量导出
  - [x] 导出结果在 Playlist 页展示成功/失败统计
- [x] Task 3: 失败清单生成（AC: 3）
  - [x] 导出结束后生成结构化失败清单 JSON 文件
  - [x] 清单字段包含 songName/hash/失败原因/时间戳（及可选 levelPath）
- [x] Task 4: 失败项重试（AC: 4）
  - [x] 提供“仅重试失败项”入口（导出结果横幅按钮）
  - [x] 触发后立即创建重试导出流程并更新结果状态

## Dev Notes

### Scope & Boundaries

- 本 Story 仅覆盖“增强导出与失败重试”，不再重复实现下载判定逻辑（S8.6）。
- 导出流程目标是“强韧性 + 可恢复”，优先保障可用内容交付。

### Key Quality Constraints

- 导出部分成功是必须行为，不允许“全有或全无”策略。
- 失败清单是后续恢复入口，不应作为可选项。

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S8.7`]
- [Source: `_bmad-output/planning-artifacts/prd.md` - `FR40`, `FR41`, `NFR18`]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` - `Journey 4`]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Completion Notes List

- 已实现导出范围增强：复制 `.bplist` + 已下载歌曲目录。
- 已实现部分成功导出：未下载项记为失败但不中断整体导出。
- 已实现失败清单文件生成：`playlist_export_failures_<timestamp>.json`。
- 已实现“仅重试失败项”事件链路与 UI 入口。
- 已修复失败项重试键匹配边界：songName 为空时使用 hash 回退，避免漏重试。
- 已通过验证：`flutter analyze`（相关模块）与 `flutter test test/widget_test.dart`。

### File List

- `_bmad-output/implementation-artifacts/8-7-playlist-enhanced-export-retry.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `lib/Modules/Playlists/bloc/playlist_state.dart`
- `lib/Modules/Playlists/bloc/playlist_event.dart`
- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
- `lib/Modules/Playlists/playlist_page.dart`

## Change Log

- 2026-03-21: 创建 Story 8.7 并设置为 ready-for-dev。
- 2026-03-21: 完成 Story 8.7 实现并推进到 review。
- 2026-03-21: 修复失败项重试匹配边界后收口，状态更新为 done。
- 2026-03-21: 修复“songName 为空时仅重试失败项匹配不到”的键规范问题。
