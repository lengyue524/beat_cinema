# Story 10.6: Playlist 下载后增量刷新与匹配一致性修复

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Playlist 用户，
I want 歌曲下载完成后列表状态立即更新、未安装计数同步收敛，且在批量场景下保持界面流畅，
so that 我无需重启或重复进入页面即可得到一致且可信的匹配结果。

## Acceptance Criteria

1. 单曲下载完成后 1 秒内，Playlist 对应条目从“未安装”切换为“已匹配/已就绪”。  
2. 批量下载完成后，Playlist 未安装计数在任务稳定后自动收敛，无需手动刷新页面。  
3. 下载状态更新链路避免重复全量重解析（以增量更新为主），并保持 UI 可响应。  
4. 匹配策略保持 `key -> hash -> songName` 顺序，且与当前 PRD/UX 状态语义一致。  
5. 覆盖异常场景：下载失败、任务取消、任务完成但输出目录已存在。  

## Tasks / Subtasks

- [x] Task 1: 梳理并固化下载状态回流链路（AC: 1,2,5）
  - [x] 明确任务状态到 Playlist 行状态的映射（pending/downloading/completed/failed/cancelled）
  - [x] 对失败/取消场景提供可见且可恢复的状态反馈
  - [x] 验证“输出目录已存在”分支下的状态收敛逻辑
- [x] Task 2: 实施增量刷新策略（AC: 1,2,3）
  - [x] 避免每次状态变化触发全量 `parseAll + buildPlaylists`
  - [x] 保证单曲完成时目标条目可快速收敛
  - [x] 保证批量完成后统一收敛并减少抖动
- [x] Task 3: 保持匹配语义与回归一致性（AC: 4）
  - [x] 维持 `key -> hash -> songName` 顺序与既有实现一致
  - [x] 回归验证 Playlist 未安装统计与已匹配统计
  - [x] 校验与 PRD/UX 状态语义不冲突
- [x] Task 4: 验证与证据留存（AC: 1~5）
  - [x] 执行最小回归：单曲下载、批量下载、失败重试、取消
  - [x] 记录前后对比证据（状态变化、计数收敛、关键日志）
  - [x] 产出可复用的检查清单条目

## Dev Notes

### Epic 上下文与依赖约束

- 本故事来自 `epics.md` 中 S10.6，属于 E10（Post-MVP Hardening）一致性修复项。  
- 依赖标注（沿用 S10.3 标准）：
  - 依赖 Story：`10-3-cross-epic-dependency-governance`
  - 阻塞 Story：无
  - 解锁条件：完成下载任务状态到 Playlist 视图状态端到端一致性校验
  - 依赖类型：mandatory
  - 风险等级：high

### 重点代码区域

- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
  - `_onDownloadTasksUpdated`
  - `_buildPlaylists`
  - 下载任务与状态映射（`_taskIdToSongHash` / `_downloadingHashes` / `_downloadErrors`）
- `lib/Services/services/level_parse_service.dart`
  - 下载后关卡重新识别与 hash 计算链路
- `lib/Modules/Playlists/playlist_page.dart`
  - 未安装列表、下载中状态展示、计数显示与交互反馈

### 实施边界

- 本故事优先保证“状态一致性 + 增量刷新”，不做无关 UI 重构。  
- 如需新增依赖或跨模块行为变更，先在故事内标注并与现有规范对齐。  

### 验证要求

- 必测场景：
  - 单曲下载完成后状态收敛
  - 批量下载完成后计数收敛
  - 下载失败与取消后的状态可见性
  - 任务完成但目录已存在时的状态判定
- 必跑命令：
  - `flutter analyze`
  - 必要时补充最小可复现用例验证关键回归点

## Project Structure Notes

- 保持分层边界：UI -> BLoC -> Services。  
- 仅在 BLoC 与 Service 层实现状态与数据回流，不把业务判断下沉到 UI。  

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S10.6`]
- [Source: `_bmad-output/planning-artifacts/prd.md`]
- [Source: `_bmad-output/implementation-artifacts/10-3-cross-epic-dependency-governance.md`]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- sprint-status route: `10-6-playlist-incremental-refresh-consistency`
- create-story artifact generation from S10.6 acceptance criteria

### Completion Notes List

- 已根据 S10.6 生成 ready-for-dev 故事文档
- 已拆分任务为“状态回流、增量刷新、匹配语义、验证证据”四类
- 新增 `LevelParseService.parseSingleLevel` 以支持下载完成后的按目录增量解析
- `PlaylistBloc` 增加 `_rawPlaylists/_levels` 缓存，完成态优先走增量刷新，失败时自动回退全量解析
- 取消任务新增可见错误文案（`下载已取消`），并保持可重试入口
- 已执行 `flutter analyze`、`flutter test`、`flutter test test/services/level_parse_service_test.dart` 全部通过

### File List

- `lib/Services/services/level_parse_service.dart`
- `lib/Modules/Playlists/bloc/playlist_bloc.dart`
- `test/services/level_parse_service_test.dart`
- `_bmad-output/implementation-artifacts/10-6-playlist-incremental-refresh-consistency.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Senior Developer Review (AI)

- Reviewer: Codex AI
- Date: 2026-03-21
- Outcome: Approve

### Summary

- AC1/AC2/AC3：下载状态变化不再触发频繁全量链路，完成态在任务稳定后优先增量收敛。
- AC4：匹配顺序保持 `key -> hash -> songName`，未改动语义优先级。
- AC5：失败与取消均有可见反馈，`outputDir 已存在` 的完成态会进入收敛刷新。

## Change Log

- 2026-03-21: `create-story` 执行，新增 `10-6` 故事文档并进入 ready-for-dev。
- 2026-03-21: `dev-story + code-review` 完成，增量刷新与状态一致性修复交付，故事状态更新为 done。
