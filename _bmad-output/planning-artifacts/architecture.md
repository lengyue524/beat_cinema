---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
status: complete
lastStep: 8
completedAt: '2026-03-21'
inputDocuments: ['_bmad-output/planning-artifacts/prd.md', '_bmad-output/project-context.md']
workflowType: 'architecture'
project_name: 'beat_cinema'
user_name: 'Lihang'
date: '2026-03-10'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
37 条 FR 分布在 7 个能力领域。架构影响最大的领域：
- **关卡资源浏览 (FR1-FR7):** 文件系统批量扫描 + Isolate 后台解析 + 内存缓存 + 响应式列表渲染
- **视频搜索与下载 (FR8-FR13):** 外部进程（yt-dlp）封装 + 并发下载队列 + 进度流（Stream）
- **布局与导航 (FR17-FR20):** ShellRoute 重构为 IndexedStack + 右侧面板系统 + 右键菜单
- **媒体播放 (FR21-FR24, Growth):** media_kit 集成 + 左右声道分离音频路由
- **错误处理 (FR34-FR37):** 全链路防御式解析，外部数据不可信

**Non-Functional Requirements:**
15 条 NFR 驱动关键架构决策：
- NFR1-2: 500 首 < 3s / 缓存 < 1s → Isolate 解析 + 内存缓存层
- NFR5: UI 60fps → 重计算隔离到 Isolate
- NFR7: 不因外部数据崩溃 → 全链路容错
- NFR9: 原子性写入 → 临时文件 + 重命名策略
- NFR12: yt-dlp 可替换 → 服务层抽象接口

**Scale & Complexity:**
- Primary domain: Flutter Desktop（重文件 I/O + 外部进程集成）
- Complexity level: Medium-High
- Estimated architectural components: ~12-15 个核心组件

### Technical Constraints & Dependencies

**已确立约束（来自现有代码库）:**
- BLoC + GoRouter 架构已定型，v2 在此基础上扩展
- sealed class events/states + part/part of 文件组织
- 手写 fromMap/toMap 序列化
- 仅 Windows 平台，但需跨平台抽象（path 包）
- 已知拼写错误必须保持一致

**新增依赖（v2 引入）:**
- media_kit（Growth 阶段）
- window_manager 或类似包
- GitHub Releases API（http 包）

### Cross-Cutting Concerns Identified

1. **错误处理链:** 外部数据 → 防御式解析 → 错误 State → UI 提示。贯穿所有 7 个能力领域。
2. **文件系统抽象:** 路径验证、文件锁定检测、编码处理（GBK/UTF-8）、原子写入。
3. **外部进程管理:** yt-dlp 进程生命周期（启动/监控/终止/超时）。
4. **缓存策略:** info.dat 解析结果的内存缓存 + 失效策略。
5. **布局状态管理:** IndexedStack 页面保持、面板展开/收起、右键菜单上下文。
6. **L10n 双语:** 所有用户可见文本需同步更新 en/zh ARB。

## Starter Template Evaluation

### Primary Technology Domain

Flutter Desktop (Windows) — Brownfield 项目，基于现有 v0.0.3 代码库迭代。

### Starter Template: Not Applicable (Brownfield)

本项目无需 starter 模板。所有基础架构决策已由现有代码库确立：

**已确立决策：**
- 语言 & Runtime: Dart (Flutter SDK >=3.0.6 <4.0.0)
- 状态管理: BLoC ^9.1.0 + Cubit (sealed class events/states, part/part of)
- 路由: GoRouter ^15.1.2 + ShellRoute
- 项目结构: Modules/PascalCase + models/snake_case
- 序列化: 手写 fromMap/toMap（带默认值容错）
- 国际化: flutter_gen + ARB (en/zh)
- 代码风格: flutter_lints ^4.0.0 默认规则
- 持久化: shared_preferences ^2.2.3

**v2 需要新增的架构决策：**
- 媒体播放包选型与集成方案
- info.dat 解析缓存策略
- yt-dlp 可替换服务层接口设计
- IndexedStack + 面板系统 UI 架构
- 原子写入 + 跨平台路径抽象
- 窗口管理包集成
- GitHub API 更新检测网络层

**第一个实现 Story:** ShellRoute + IndexedStack 重构（Sprint 0），非项目初始化。

## Core Architectural Decisions

### Decision Priority Analysis

**关键决策（阻塞实施）：**
- 数据缓存策略 — 内存 + 文件持久化（Sprint 1 依赖）
- UI 架构 — StatefulShellRoute + Row 面板系统（Sprint 0 依赖）
- 服务层 — Repository + Service + Manager 三层分离（Sprint 2 依赖）

**重要决策（塑造架构）：**
- 窗口管理 — window_manager（Sprint 0 可引入）
- 更新检测 — http + GitHub Releases API（Sprint 4）

**延迟决策（Growth PoC 后确认）：**
- media_kit 双 Player 声道分离方案（Sprint 3 前做 PoC）

### 数据与缓存架构

**info.dat 缓存策略：内存 + 文件持久化**
- 首次启动：Isolate 批量解析 CustomLevels 目录下所有 info.dat → 结果存入内存 Map + 序列化到本地 JSON 缓存文件
- 后续启动：读缓存文件到内存 → 比对文件修改时间戳 → 仅增量解析变更项
- 缓存失效：文件夹修改时间戳变更触发重解析
- 满足：NFR1 (< 3s 首次) / NFR2 (< 1s 缓存)

**cinema-video.json 原子写入：**
- 写入临时文件 (.tmp) → File.rename() 替换原文件
- Windows 同卷内 rename 为原子操作
- 满足：NFR9（写入失败不损坏已有文件）

### 服务层架构

**三层分离设计：**
- `VideoRepository`（抽象层）：定义 search/download 接口，不依赖具体实现
- `YtDlpService`（实现层）：封装 yt-dlp 进程管理、输出解析、编码处理（GBK/UTF-8）
- `DownloadManager`（协调层）：并发队列（最大 3 并发）、进度流、任务状态管理

**进程生命周期管理：**
- YtDlpService 统一管理 yt-dlp 进程启动/监控/终止
- 搜索超时：30 秒 / 下载超时：10 分钟（NFR14）
- 非零退出码 → 解析错误信息 → 传播到 BLoC 错误 State
- 应用关闭 → DownloadManager.dispose() 终止所有活跃进程（NFR10）

### UI 架构

**页面保持 — StatefulShellRoute：**
- GoRouter 原生 StatefulShellRoute，多分支独立 Navigator 栈
- 每个 Rail tab 对应一个分支，切换时页面状态保持
- URL 与页面状态自动同步，深链接和导航正确工作

**右侧面板 — Row 布局 + AnimatedContainer：**
- 主布局：`Row [ NavigationRail | Expanded(内容区) | AnimatedContainer(面板) ]`
- 面板宽度在 0 和目标宽度（~350px）之间动画切换
- 面板内容由 `PanelCubit` 管理（当前面板类型 + 上下文数据）
- 面板关闭时宽度归零，内容区自动扩展

**右键菜单：**
- `GestureDetector.onSecondaryTapUp` 捕获右键事件
- `showMenu()` 显示上下文菜单，菜单项根据当前选中项动态生成

**BLoC Provider 层级：**
- `AppBloc` → 根级（main.dart），管理全局配置 + 更新检测状态
- 各页面 BLoC → StatefulShellRoute 分支级，随分支生命周期
- `PanelCubit` → 面板级，独立于页面状态

### 媒体集成（Growth — Sprint 3 PoC 验证后）

**media_kit 双 Player 方案：**
- 包选型：media_kit（基于 libmpv/FFmpeg，唯一支持声道分离的 Flutter Desktop 方案）
- 音乐 Player：`af=pan=stereo|c0=c0|c1=0`（仅输出左声道）
- 视频 Player：`af=pan=stereo|c0=0|c1=c1`（仅输出右声道）
- `SyncCalibrationCubit` 统一协调两个 Player，偏移通过 seek() 调整
- **PoC 验证点：** audio filter 声道分离在 Windows 上的稳定性和延迟

### 分发与系统

**窗口管理 — window_manager：**
- 最小尺寸约束（确保 Rail + 内容 + 面板布局）
- 窗口位置/尺寸持久化到 SharedPreferences
- `onWindowClose` 拦截：检查活跃下载 → 确认弹窗 → dispose 资源 → 关闭

**更新检测 — UpdateService：**
- `http` 包调用 GitHub Releases API (`/repos/{owner}/{repo}/releases/latest`)
- 解析 `tag_name` + 手写 SemVer 比较
- AppBloc 启动时触发 + 24 小时周期检查
- 网络不可用时静默跳过

**应用关闭流程：**
onWindowClose → 检查活跃下载 → 有则弹窗确认 → DownloadManager.dispose() → Player.dispose() → 窗口关闭

### Decision Impact — 实施顺序

1. window_manager + StatefulShellRoute 重构（Sprint 0）
2. 缓存架构 + Isolate 解析 + 增强列表（Sprint 1）
3. 三层服务层 + 面板系统 + 搜索/下载（Sprint 2）
4. media_kit PoC → 双 Player 校准工作台（Sprint 3）
5. Playlist 管理 + UpdateService（Sprint 4）

### Cross-Component Dependencies

- 面板系统依赖 StatefulShellRoute 先完成
- 搜索/下载面板依赖三层服务层 + 面板系统
- 同步校准依赖 media_kit + 面板系统
- 关闭流程依赖 window_manager + DownloadManager + media_kit Player

## Implementation Patterns & Consistency Rules

### 已由 Project Context 覆盖（不重复）

文件/目录命名、BLoC/Cubit 文件组织、导入顺序、错误处理（try/catch → emit State）、模型序列化（fromMap/toMap + 默认值）、已知拼写错误一致性——均已在 project-context.md 68 条规则中定义。

### v2 新增模式

#### 服务层命名与组织

```
lib/Services/
  video_repository.dart       # 抽象接口
  ytdlp_service.dart          # yt-dlp 实现
  download_manager.dart        # 并发队列管理
  update_service.dart          # GitHub 更新检测
  cache_service.dart           # info.dat 缓存管理
```

- Services 目录使用 PascalCase（与 Modules 一致）
- 抽象类以功能命名（`VideoRepository`），实现类以技术前缀命名（`YtDlpService`）
- Manager 类延续现有 `static final` 实例模式

#### 面板系统状态模式

```dart
sealed class PanelState {}
final class PanelClosed extends PanelState {}
final class PanelOpen extends PanelState {
  final PanelContent content;  // 枚举：search, detail, preview
  final dynamic context;       // 面板上下文数据
}
```

- 面板状态由独立 `PanelCubit` 管理，不混入页面 BLoC
- 面板操作：`PanelCubit.open(PanelContent, context)` / `PanelCubit.close()`
- 右键菜单触发面板时传递选中项作为 context

#### 缓存数据模式

```dart
class CachedLevel {
  final String hash;            // 关卡目录名作为 key
  final DateTime lastModified;  // 文件修改时间戳
  final LevelInfo info;         // 解析后的 info.dat
  final CinemaStatus status;    // 视频配置状态
}
```

- 缓存文件：应用数据目录 `cache/levels_cache.json`
- 序列化使用 `fromMap`/`toMap`（与现有模型一致）
- 缓存失效：文件夹修改时间戳比对

#### 进度流模式

```dart
Stream<DownloadProgress> get progressStream;  // broadcast stream

// BLoC 订阅
_subscription = downloadManager.progressStream.listen((progress) {
  add(DownloadProgressUpdated(progress));
});
// BLoC close() 中取消 subscription
```

- 所有异步进度使用 `StreamController<T>.broadcast()`
- BLoC 在 `close()` 中取消 subscription
- 进度数据类使用不可变类（final 字段）

#### 统一错误模型

```dart
class AppError {
  final ErrorType type;     // parse, download, fileSystem, network
  final String userMessage; // L10n 用户友好消息
  final String? detail;     // 技术细节（仅 Logger）
  final bool retryable;     // 是否可重试
}
```

- 用户可见消息必须走 L10n（en/zh ARB）
- 技术细节仅写 Logger，不展示给用户
- 可重试错误提供重试回调

#### 右键菜单注册模式

```dart
ContextMenuRegion(
  menuItems: (item) => [
    ContextMenuItem(label: l10n.searchVideo, onTap: () => ...),
    ContextMenuItem(label: l10n.openFolder, onTap: () => ...),
    if (item.hasVideo) ContextMenuItem(label: l10n.preview, onTap: () => ...),
  ],
  child: LevelListTile(item),
)
```

- `ContextMenuRegion` 封装在 `lib/Common/`
- 菜单项文本走 L10n，根据项状态动态生成

### Enforcement Rules

**所有 AI 代理必须：**
1. 新建 Service/Repository 放在 `lib/Services/`
2. 面板状态通过 `PanelCubit` 管理，不在页面 BLoC 中混合面板逻辑
3. 异步进度使用 Stream broadcast + BLoC subscription
4. 用户可见错误走 L10n，技术详情仅写 Logger
5. 缓存数据使用 fromMap/toMap 序列化
6. 右键菜单项文本走 L10n，根据项状态动态生成

## Project Structure & Boundaries

### Complete Project Directory Structure

```
beat_cinema/
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml
├── lib/
│   ├── main.dart                          # 根 BlocProvider<AppBloc>
│   ├── App/
│   │   ├── app_bloc/
│   │   │   ├── app_bloc.dart
│   │   │   ├── app_event.dart
│   │   │   └── app_state.dart
│   │   ├── Route/
│   │   │   └── app_route.dart             # StatefulShellRoute 配置
│   │   └── root_page.dart                 # Row布局(Rail+内容+面板)
│   ├── Common/
│   │   ├── constants.dart
│   │   ├── context_menu_region.dart       # v2 新增
│   │   └── app_error.dart                 # v2 新增
│   ├── Services/                          # v2 新增
│   │   ├── video_repository.dart
│   │   ├── ytdlp_service.dart
│   │   ├── download_manager.dart
│   │   ├── cache_service.dart
│   │   └── update_service.dart
│   ├── l10n/
│   │   ├── intl_en.arb
│   │   └── intl_zh.arb
│   ├── models/
│   │   ├── custom_level/
│   │   ├── cinema_config/
│   │   ├── cached_level/                  # v2 新增
│   │   ├── download_progress/             # v2 新增
│   │   ├── level_info/                    # v2 新增
│   │   └── playlist/                      # Growth 新增
│   └── Modules/
│       ├── CustomLevels/                  # 改造 - 增强列表
│       │   ├── custom_levels_page.dart
│       │   └── bloc/
│       ├── CinemaSearch/                  # 改造 - 面板化
│       │   ├── cinema_search_panel.dart
│       │   └── bloc/
│       ├── Panel/                         # v2 新增
│       │   ├── panel_host.dart
│       │   └── cubit/
│       ├── Settings/
│       │   ├── settings_page.dart
│       │   └── cubit/
│       ├── MediaPlayer/                   # Growth 新增
│       │   ├── audio_preview_panel.dart
│       │   ├── video_preview_panel.dart
│       │   ├── sync_calibration_panel.dart
│       │   └── cubit/
│       ├── Playlist/                      # Growth 新增
│       │   ├── playlist_page.dart
│       │   └── bloc/
│       └── Manager/                       # 遗留, 逐步迁移到 Services
├── test/
├── windows/
└── assets/
```

### Architectural Boundaries

**状态管理层级：**
- AppBloc（根级）→ 全局配置 + 更新检测，所有页面可访问
- 页面 BLoC（StatefulShellRoute 分支级）→ CustomLevelsBloc, PlaylistBloc，随分支生命周期
- PanelCubit（root_page 级）→ 面板状态，所有分支共享
- 面板内部 BLoC → CinemaSearchBloc, SyncCalibrationCubit，面板打开时创建

**服务层边界：**
- VideoRepository（抽象）→ BLoC 依赖抽象接口
- YtDlpService（实现）→ 仅被 Repository 实现引用
- DownloadManager → BLoC 通过 Stream 订阅，不直接操作进程
- CacheService → CustomLevelsBloc 调用获取/刷新缓存

**数据流：**
用户操作 → BLoC Event → BLoC 调用 Service → Service 操作文件/进程 → 结果 Stream → BLoC emit State → UI 更新

### Requirements to Structure Mapping

| FR 范围 | 目录位置 |
|---------|---------|
| FR1-FR7 关卡浏览 | Modules/CustomLevels/ + Services/cache_service.dart + models/level_info/ |
| FR8-FR13 搜索下载 | Modules/CinemaSearch/ + Services/video_repository.dart + Services/ytdlp_service.dart + Services/download_manager.dart |
| FR14-FR16 配置管理 | models/cinema_config/ + Modules/CinemaSearch/ |
| FR17-FR20 布局导航 | App/Route/ + App/root_page.dart + Modules/Panel/ + Common/context_menu_region.dart |
| FR21-FR24 媒体播放 | Modules/MediaPlayer/ |
| FR25-FR28 Playlist | Modules/Playlist/ + models/playlist/ |
| FR29-FR33 系统设置 | Modules/Settings/ + Services/update_service.dart |
| FR34-FR37 错误处理 | Common/app_error.dart（跨所有模块） |

### External Integration Points

- **Beat Saber 文件系统：** CacheService → CustomLevels 目录扫描/info.dat 解析/cinema-video.json 读写
- **yt-dlp 外部进程：** YtDlpService → Process.run 调用，编码处理，超时控制
- **media_kit (Growth)：** MediaPlayer 模块 → libmpv 音视频播放，audio filter 声道路由
- **GitHub API (Growth)：** UpdateService → HTTP GET releases/latest，SemVer 比较
- **SharedPreferences：** AppBloc/Settings → 路径、窗口状态、更新检查时间持久化

## Architecture Validation

### PRD Coverage

| 维度 | 结果 |
|------|------|
| 37 个 FR 全覆盖 | ✅ 通过 — 所有 FR 在项目结构映射表中有明确目录对应 |
| 15 个 NFR 全覆盖 | ✅ 通过 — NFR 在核心架构决策和实现模式中已体现 |
| 4 个用户旅程路径 | ✅ 通过 — 每个旅程涉及的模块和数据流已在架构中定义 |
| MVP / Growth 阶段划分 | ✅ 通过 — 目录注释明确标注阶段归属 |

### Technical Consistency

| 维度 | 结果 |
|------|------|
| Project Context 68 条规则兼容性 | ✅ 通过 — sealed class、part/part of、命名规范等均遵循 |
| BLoC 生命周期一致性 | ✅ 通过 — 根级/分支级/面板级层次清晰，无循环依赖 |
| 数据流单向性 | ✅ 通过 — Event → BLoC → Service → Stream → State → UI |
| 文件操作安全性 | ✅ 通过 — 原子写入 + 异常回滚在 Service 层统一处理 |
| L10n 一致性 | ✅ 通过 — 所有用户可见文本（含错误消息、菜单项）走 ARB |

### Risk Mitigation

| 风险项 | 缓解策略 | 状态 |
|--------|---------|------|
| yt-dlp 进程僵死 | 超时 kill + 重试，Isolate.run 隔离 | ✅ 已覆盖 |
| info.dat 解析异常 | 防御性 fromMap + 缓存验证 + 优雅降级 | ✅ 已覆盖 |
| 大量关卡内存压力 | 分级缓存（内存上限 + 文件持久化 + 时间戳淘汰） | ✅ 已覆盖 |
| 窗口关闭数据丢失 | window_manager 拦截 + 优雅关闭流程 | ✅ 已覆盖 |
| media_kit 声道路由兼容性 | Growth 阶段验证，降级为普通播放 | ✅ 已覆盖 |

### Open Items

| 编号 | 说明 | 建议解决阶段 |
|------|------|------------|
| ARCH-OPEN-1 | Manager/ 遗留代码迁移至 Services/ 的详细计划 | Epic 规划阶段 |
| ARCH-OPEN-2 | media_kit 双播放器实例资源管理细节 | Growth 阶段设计 |
| ARCH-OPEN-3 | yt-dlp 版本兼容性测试矩阵 | 开发阶段 Sprint 1 |

### Validation Conclusion

**整体评估：✅ 架构通过验证**

架构文档完整覆盖了 PRD 的所有需求，与现有代码库约束兼容，关键风险点均有缓解策略。3 个遗留问题不阻塞 Epic 规划和开发启动。

---

## Addendum 2026-03-22: Playlist 批量操作与歌单选择器

### Scope

- 歌曲列表新增多选与批量右键能力
- Playlist 详情新增删除/添加/移动跨歌单操作
- 新增可搜索的通用歌单选择弹窗

### Architecture Adjustments

1. **Selection State Model**
   - 在列表层引入 `selectedLevelPaths: Set<String>`，支持单选与多选共存策略
   - 多选状态与当前过滤/排序状态解耦，避免列表重排导致选择错乱

2. **Playlist Mutation Service Boundary**
   - 新增或扩展 Playlist 领域服务，统一处理：
     - 添加到歌单
     - 从歌单删除
     - 在歌单间移动
   - 写入策略沿用原子写入原则，防止 .bplist 半写入损坏

3. **Delete Safety Strategy**
   - 删除操作区分两层：
     - 仅删除歌单条目
     - 同步删除歌曲目录
   - 文件删除失败时不得破坏歌单数据一致性，需返回部分成功结果并反馈失败清单

4. **Reusable Playlist Picker**
   - 歌单选择器作为可复用组件，服务于“添加到歌单”和“移动到歌单”
   - 支持搜索过滤、禁用当前歌单目标、空状态提示
