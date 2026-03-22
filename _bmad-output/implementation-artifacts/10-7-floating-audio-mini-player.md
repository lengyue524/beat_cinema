# Story 10.7: 音频播放浮动控制条（Mini Player）

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 播放列表与关卡列表用户，
I want 在歌曲播放时看到一个底部浮动迷你播放器，并可随时一键停止，
so that 我在滚动长列表时无需回到原行也能控制播放，且停止后界面自动回收不干扰浏览。

## Acceptance Criteria

1. 音频开始播放后显示底部浮动控制条；音频停止/结束后自动隐藏。  
2. 浮动条仅提供“停止”控制，不包含上一首、下一首、暂停按钮。  
3. 浮动条左侧显示当前歌曲圆形封面，播放中持续旋转。  
4. 在用户滚动列表或切换同页内容时，浮动条保持可见并可点击停止。  
5. 实现遵循现有播放器生命周期管理，不引入资源泄漏或残留播放。  

## Tasks / Subtasks

- [x] Task 1: 建立迷你播放器状态来源与显示条件（AC: 1,4,5）
  - [x] 在现有音频预览状态基础上提取最小可用播放状态（当前歌曲、是否播放、封面来源、可停止回调）
  - [x] 明确“显示/隐藏”判定：`playing == true` 显示；停止、完成、销毁时隐藏
  - [x] 避免新增并行播放器实例，继续复用 `playerService.createAudioPlayer()` 现有链路
- [x] Task 2: 实现底部浮动 Mini Player 组件（AC: 1,2,3,4）
  - [x] 新增可复用组件（建议在 `lib/Modules/CustomLevels/widgets/`）承载封面、歌曲名、停止按钮
  - [x] 封面使用圆形裁切，播放中做连续旋转动画；停止/隐藏时动画安全回收
  - [x] 控件仅保留“停止”动作（语义和图标清晰），不引入暂停/上一首/下一首
- [x] Task 3: 接入现有列表页面并保证同页滚动可用（AC: 1,4）
  - [x] 在 `LevelListView` 所在页面层级叠加浮动条（建议 `Stack + Positioned`）
  - [x] 确保 `ListView` 滚动、筛选、搜索、详情切换时浮动条状态不抖动
  - [x] 若播放源切换到另一首，浮动条信息应同步替换且不中断控制能力
- [x] Task 4: 生命周期与回归验证（AC: 5）
  - [x] 校验 `dispose`、页面切换、播放完成、手动停止后的资源释放
  - [x] 跑最小回归：开始播放、滚动后停止、自动结束隐藏、重复切歌
  - [x] 执行 `flutter analyze`，必要时补充组件级测试或最小交互测试

## Dev Notes

### Epic 上下文与依赖约束

- 本故事来自 `epics.md` 中 S10.7，属于 E10（Post-MVP Hardening）新增体验增强项。  
- 依赖标注（沿用 S10.3 标准）：
  - 依赖 Story：`7-2-audio-preview`, `7-6-player-resource-lifecycle`
  - 阻塞 Story：无
  - 解锁条件：浮动条显示/隐藏、停止控制、封面旋转与资源回收可端到端验证
  - 依赖类型：mandatory
  - 风险等级：medium

### 重点代码区域（优先复用，避免重造）

- `lib/Modules/CustomLevels/widgets/level_list_view.dart`
  - 现有 `_previewPlayer`、`_playingLevelPath`、`_previewPlaying` 已具备状态基础
  - `_toggleAudioPreview` 已覆盖播放/暂停切换与 `stream.completed` 收敛
- `lib/Modules/CustomLevels/widgets/level_list_tile.dart`
  - 封面读取逻辑已存在（`coverImageFilename` + 默认封面），可抽取复用
- `lib/Services/services/player_service.dart`
  - `createAudioPlayer` / `disposePlayer` / `disposeAll` 为生命周期唯一可信入口

### 实施边界（防回归）

- 不改动下载、视频搜索、播放列表匹配等与本故事无关流程。  
- 不新增第二条音频播放主链路（禁止“一个列表内多个独立 Player”并行播放）。  
- 浮动条只处理“播放中可停止”的场景；暂停态不作为本故事目标能力。  

### 交互与样式约束

- 视觉风格遵循现有暗色主题与品牌紫（`AppColors`），不引入新的主题分支。  
- 浮动条应覆盖在内容层上方但不阻塞主列表滚动交互。  
- 需要补充无障碍语义（停止按钮 tooltip/semanticLabel、封面语义描述）。  

### 建议实现顺序

1. 先在 `LevelListView` 内确认状态机（显示/隐藏/切歌/停止）。  
2. 再落地 `MiniPlayer` 组件与封面旋转动画。  
3. 最后做样式收口与生命周期回归验证。  

### 验证要求

- 必测场景：
  - 点击歌曲封面开始播放后，底部浮动条立即出现
  - 列表滚动到任意位置时，浮动条仍可见且“停止”可用
  - 音频自然播放结束后，浮动条自动隐藏
  - 连续切换不同歌曲，浮动条信息与封面同步更新
  - 页面销毁或切换后无残留音频与资源泄漏
- 必跑命令：
  - `flutter analyze`

## Project Structure Notes

- 保持分层：UI 组件在 `Modules/*/widgets`，播放资源管理仍归 `Services/services/player_service.dart`。  
- 浮动条组件尽量无业务副作用，通过参数驱动，便于后续复用到 Playlist 详情页。  

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` - `S10.7`]
- [Source: `_bmad-output/planning-artifacts/architecture.md` - `UI 架构 / 媒体集成 / 生命周期管理`]
- [Source: `lib/Modules/CustomLevels/widgets/level_list_view.dart`]
- [Source: `lib/Modules/CustomLevels/widgets/level_list_tile.dart`]
- [Source: `lib/Services/services/player_service.dart`]

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- sprint-status route: `10-7-floating-audio-mini-player`
- create-story artifact generation from S10.7 acceptance criteria

### Completion Notes List

- TDD: 先新增 `mini_audio_player_bar_test.dart` 并确认在组件缺失时失败，再实现后转绿
- 新增 `MiniAudioPlayerBar`，支持底部浮动、圆形封面旋转、单一“停止播放”控制
- 在 `LevelListView` 中接入 Mini Player，播放时显示、停止/结束后自动隐藏，且滚动中持续可操作
- 新增 mini player 本地化键并重新生成 l10n 代码
- 已执行 `flutter test` 与 `flutter analyze`，结果均通过
- Code review 修复：播放中筛选后浮动条仍可见可停止、停止时释放播放器、列表底部防遮挡
- 新增 `resolveMiniPlayerDisplayData` 的测试，覆盖“列表过滤后使用缓存显示”关键场景

### File List

- `lib/Modules/CustomLevels/widgets/mini_audio_player_bar.dart`
- `lib/Modules/CustomLevels/widgets/level_list_view.dart`
- `lib/l10n/intl_zh.arb`
- `lib/l10n/intl_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_zh.dart`
- `test/modules/custom_levels/widgets/mini_audio_player_bar_test.dart`
- `test/modules/custom_levels/widgets/level_list_view_mini_player_state_test.dart`
- `_bmad-output/implementation-artifacts/10-7-floating-audio-mini-player.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Senior Developer Review (AI)

- Reviewer: Codex AI
- Date: 2026-03-21
- Outcome: Approve

### Summary

- 已完成对高/中优先级问题的自动修复并复验通过。
- AC2/AC3 保持不变；AC1/AC4/AC5 的边界场景已补强。

### Action Items (Resolved)

- [x] [HIGH] 解决“播放中筛选后浮动条消失，无法停止”问题（`LevelListView` 新增缓存回退显示逻辑）。
- [x] [HIGH] 解决“停止播放后未及时释放播放器实例”问题（停止时显式释放并清空引用）。
- [x] [MEDIUM] 解决“浮动条遮挡列表底部条目”问题（列表底部动态 padding）。
- [x] [MEDIUM] 补充针对筛选回退显示逻辑的自动化测试。

## Change Log

- 2026-03-21: `create-story` 执行，新增 `10-7` 故事文档并进入 ready-for-dev。
- 2026-03-21: `dev-story` 完成 Mini Player 实现与验证，故事状态更新为 review。
- 2026-03-21: `code-review` 修复高/中优先级问题并复验通过，故事状态更新为 done。
