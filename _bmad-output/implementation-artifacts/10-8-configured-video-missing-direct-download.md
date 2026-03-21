# Story 10.8: 配置视频缺失时的列表直达下载与工具分流

Status: done

## Story

As a 关卡列表用户，
I want 当歌曲存在 `cinema-video.json` 但缺少本地视频文件时，直接在列表项点击下载并自动选择合适下载工具，
so that 我可以在当前列表视图内快速补齐视频文件并收敛状态，无需切换面板或手动判断下载方式。

## Acceptance Criteria

1. `configuredMissingFile` 状态歌曲在列表项提供直接下载入口。  
2. 点击后 1 秒内任务进入下载管理，列表项进入“下载中”并防重复触发。  
3. URL 为视频直链（`.mp4/.mkv/.webm/.mov/.avi/.m4v`）时走 HTTP 直连下载。  
4. URL 为页面链接或非直链时走既有下载队列（yt-dlp）。  
5. 下载完成后自动回写 `cinema-video.json.videoFile` 并刷新状态；失败/取消有可见反馈。  

## Tasks / Subtasks

- [x] Task 1: 列表直达入口与状态交互（AC: 1,2）
  - [x] 在 `LevelListTile` 为 `configuredMissingFile` 提供可点击下载图标
  - [x] 下载中切换为进度指示并禁用重复触发
  - [x] 沿用现有 tooltip/semantic 语义，保持一致性
- [x] Task 2: URL 下载工具分流（AC: 3,4）
  - [x] 增加按 URL 判定规则（直链扩展名 -> HTTP，其他 -> yt-dlp）
  - [x] 直链接入 `DownloadManager.enqueueCustom` 运行器并支持取消
  - [x] 站点链接复用 `DownloadManager.enqueue` 既有队列
- [x] Task 3: 下载完成回写与状态收敛（AC: 5）
  - [x] 复用现有下载任务监听 `_onDownloadTasks`
  - [x] 成功后回写 `cinema-video.json.videoFile` 并触发列表刷新
  - [x] 失败/取消显示 SnackBar 并清理 pending 状态

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Completion Notes List

- `LevelListTile` 增加 `configuredMissingFile` 的点击下载态与下载中态展示。
- `LevelListView` 增加 URL 分流策略：直链视频走 HTTP 直连下载，非直链继续走 yt-dlp 队列。
- 直链下载使用 `DownloadManager.enqueueCustom`，具备取消、进度回流与任务状态同步能力。
- 新增 pending key 防重入逻辑，避免同一歌曲同一 URL 重复排队。
- 成功后继续复用既有“识别新视频文件 + 回写 config + reload”流程，不破坏原有状态链路。
- 新增 `LevelListTile` 组件测试，覆盖缺失视频下载按钮点击与下载中状态展示。
- 新增 `LevelListView` 交互测试，覆盖 URL 分流选择（直链 `enqueueCustom` / 非直链 `enqueue`）与 pending 态切换。
- 新增“快速连点防重入”测试，验证同一配置视频下载在短时间重复点击仅入队一次。
- 补充“非直链（yt-dlp）分支快速连点防重入”测试，确保两类下载工具分支行为一致。
- 补充“任务完成后 pending 清理”测试，验证下载按钮可恢复并确保任务流监听闭环。

### File List

- `lib/Modules/CustomLevels/widgets/level_list_tile.dart`
- `lib/Modules/CustomLevels/widgets/level_list_view.dart`
- `test/modules/custom_levels/widgets/level_list_tile_configured_missing_test.dart`
- `test/modules/custom_levels/widgets/level_list_view_config_download_test.dart`
- `_bmad-output/planning-artifacts/epics.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/10-8-configured-video-missing-direct-download.md`

## Change Log

- 2026-03-21: 新增 S10.8 故事并完成实现与状态回填。
