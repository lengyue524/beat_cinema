---
stepsCompleted: [1, 2, 3, 4]
status: Complete
inputDocuments: ['_bmad-output/planning-artifacts/prd.md', '_bmad-output/planning-artifacts/architecture.md', '_bmad-output/planning-artifacts/ux-design-specification.md']
---

# Beat Cinema v2 - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Beat Cinema v2, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: 用户可以浏览 Beat Saber CustomLevels 目录下的所有自定义关卡列表
FR2: 用户可以查看每首关卡的元数据（歌名、作者、BPM、时长、难度及对应颜色标识）
FR3: 用户可以查看每首关卡的 Cinema 视频配置状态（无视频 / 已配置 / 下载中）
FR4: 用户可以按关键词搜索关卡列表
FR5: 用户可以按难度、视频状态、修改时间等条件筛选关卡列表
FR6: 用户可以按歌名、作者、BPM、修改时间等字段排序关卡列表
FR7: 系统可以在后台解析 info.dat 并缓存解析结果，列表加载不阻塞 UI
FR8: 用户可以为选定关卡搜索匹配的视频（YouTube / Bilibili）
FR9: 用户可以通过粘贴视频 URL 直接触发下载
FR10: 用户可以从搜索结果中选择视频并一键下载
FR11: 用户可以查看当前所有下载任务的进度状态
FR12: 用户可以在下载失败时查看错误原因并重试
FR13: 系统可以管理并发下载队列（限流、排队、超时控制）
FR14: 用户可以为关卡创建 cinema-video.json 配置（关联已下载视频）
FR15: 用户可以编辑已有的 cinema-video.json 配置参数
FR16: 用户可以查看关卡目录中已存在的视频文件信息
FR17: 用户可以通过 NavigationRail 在主要功能页面间切换，且页面状态保持不丢失
FR18: 用户可以通过右键菜单快速访问关卡的常用操作
FR19: 用户可以通过按需展开的右侧面板查看详情、搜索结果等上下文信息
FR20: 用户可以调整窗口大小，且布局自适应（有最小尺寸约束）
FR21: 用户可以试听关卡的音乐文件（Growth）
FR22: 用户可以预览关卡已下载的视频文件（Growth）
FR23: 用户可以通过左右声道分离同时播放音乐和视频音轨，并调整偏移量进行同步校准（Growth）
FR24: 用户可以保存校准后的偏移值到 cinema-video.json（Growth）
FR25: 用户可以浏览本地 .bplist 播放列表文件（Growth）
FR26: 用户可以查看播放列表歌曲，并基于 playlist 歌曲信息映射对应本地关卡元信息；已下载条目复用“全部歌曲列表”一致的列表界面与交互（Growth）
FR27: 用户可以查看播放列表歌曲状态（已就绪 / 待处理），并可在详情中查看待处理拆分（未配置、未下载）（Growth）
FR28: 用户可以将播放列表涉及的内容导出到指定文件夹（Growth）
FR38: 用户可以对未下载歌曲执行单曲下载（来源为 BeatSaver），下载任务进度同步到下载管理（Growth）
FR39: 用户可以执行“下载全部缺失歌曲”，并可选择是否对已存在歌曲执行更新；系统应提供明确更新判定（文件缺失/版本不一致/用户强制更新），并在任务创建后 1 秒内将全部任务加入下载管理且可观测状态（Growth）
FR40: 导出时系统应复制 playlist 文件（.bplist）与已下载歌曲目录到目标文件夹（Growth）
FR41: 导出遇到部分缺失歌曲时，系统应继续导出可用内容并给出缺失项提示，不因部分失败中断整体导出；导出完成后必须生成缺失清单并提供“仅重试失败项”入口（Growth）
FR29: 用户可以设置 Beat Saber 安装路径
FR30: 系统可以自动检测 Beat Saber 安装路径（Growth）
FR31: 系统可以在启动时检查应用更新并通知用户（Growth）
FR32: 用户可以在首次使用时通过引导流程完成基础配置（Growth）
FR33: 系统可以持久化用户偏好设置（路径、窗口状态）
FR34: 系统可以在 info.dat 格式异常时降级显示（仅歌名），不影响其他功能
FR35: 系统可以在文件被占用时提示用户并提供重试选项
FR36: 系统可以在 yt-dlp 进程异常时捕获错误并向用户展示可理解的错误信息
FR37: 系统可以在网络不可用时正常运行所有离线功能

### NonFunctional Requirements

NFR1: 500 首关卡的列表首次加载（含 info.dat 解析）在 3 秒内完成
NFR2: 缓存生效时后续加载在 1 秒内完成
NFR3: 列表筛选和排序操作响应时间 < 100ms
NFR4: 页面切换（NavigationRail）无可感知延迟（< 16ms，单帧渲染）
NFR5: info.dat 解析在后台 Isolate 中执行，UI 线程帧率保持 60fps
NFR6: 应用内存占用在 800 首关卡场景下不超过 500MB
NFR7: 应用运行期间不因外部数据格式异常（info.dat / yt-dlp JSON）崩溃
NFR8: yt-dlp 下载任务成功率 > 95%（排除网络/资源不可用因素）
NFR9: 文件写入操作（cinema-video.json）具有原子性——写入失败不损坏已有文件
NFR10: 应用关闭时在 3 秒内优雅终止所有子进程（yt-dlp）
NFR11: 网络不可用时，所有离线功能正常运行，不产生未处理异常
NFR12: yt-dlp 调用封装为可替换服务层，便于适配版本升级或替换工具
NFR13: Beat Saber 文件路径操作使用 path 包抽象，不硬编码平台分隔符
NFR14: 外部进程（yt-dlp）调用设置 30 秒搜索超时、10 分钟下载超时
NFR15: media_kit 播放器资源在页面离开或应用关闭时正确释放，无内存泄漏
NFR16: 单曲下载触发后，任务应在 1 秒内出现在下载管理并可观察到状态变化
NFR17: “下载全部缺失歌曲”在 100 首缺失场景下应保持队列稳定；单任务失败不得导致全队列中断
NFR18: 导出流程需支持部分成功；失败项记录文件应在导出完成后 3 秒内可见，且至少包含 songName/hash/失败原因/时间戳；用户触发“仅重试失败项”后 1 秒内应创建对应导出重试任务
NFR19: Playlist 映射策略需可追踪（hash 优先、名称兜底），冲突与未命中场景应有可解释结果

### Additional Requirements

**来自 Architecture：**
- ARCH-1: ShellRoute 重构为 StatefulShellRoute + IndexedStack 实现页面状态保持
- ARCH-2: 新增 Services/ 目录，建立 Repository + Service + Manager 三层服务架构
- ARCH-3: VideoRepository 抽象接口 + YtDlpService 实现层 + DownloadManager 协调层
- ARCH-4: CacheService 管理 info.dat 解析缓存（内存 + 文件持久化 + 时间戳失效）
- ARCH-5: cinema-video.json 原子写入（临时文件 + File.rename）
- ARCH-6: PanelCubit 独立管理面板状态，不混入页面 BLoC
- ARCH-7: 统一 AppError 错误模型（type, userMessage, detail, retryable）
- ARCH-8: window_manager 集成（最小尺寸、窗口持久化、关闭拦截）
- ARCH-9: UpdateService 通过 GitHub Releases API 检测更新
- ARCH-10: 应用关闭流程：onWindowClose → 检查活跃下载 → 确认弹窗 → dispose 资源
- ARCH-11: Manager/ 遗留代码逐步迁移到 Services/（ARCH-OPEN-1）

**来自 UX Design：**
- UX-1: 主布局 Row [ NavigationRail(72px) | Expanded(内容) | AnimatedContainer(面板 350px) ]
- UX-2: 5 个自定义组件：LevelListTile, DifficultyBadge, StatusIndicator, PanelHost, ContextMenuRegion
- UX-3: 暗色主题（Surface 5 层色阶）+ Beat Saber 难度色静态常量 + 成功紫 #9B59FF
- UX-4: 沉浸霓虹设计方向：选中行紫色左条、面板紫色左边线、进度条紫色填充
- UX-5: 列表行高 48px，8px 网格间距系统
- UX-6: 页面级摘要栏（总数/已配/下载中）
- UX-7: 搜索面板平台切换器（YouTube/Bilibili 图标按钮）
- UX-8: 错误四级呈现（静默降级/内联提示/SnackBar/模态确认）
- UX-9: 筛选列表中配完的歌延迟消失（保留 3-5s → 淡出）
- UX-10: 所有自定义组件定义 normal/hover/pressed/disabled 四态
- UX-11: 键盘导航（Tab/Enter/Esc/Shift+F10/Arrow/Ctrl+F）
- UX-12: 屏幕阅读器 semanticLabel 支持
- UX-13: 空状态设计（6 种场景各有引导文案）
- UX-14: 微交互原则：每个操作 100ms 内视觉反馈
- UX-15: 骨架屏加载模式（列表首次加载、搜索结果加载）

### Requirements Coverage Map

| 需求 ID | Epic | 阶段 |
|---------|------|------|
| FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR34 | E2 关卡列表引擎 | MVP |
| FR8, FR9, FR10, FR11, FR12, FR13, FR36 | E3 视频搜索与下载 | MVP |
| FR14, FR15, FR16, FR35 | E4 视频配置管理 | MVP |
| FR17, FR20, FR29, FR33 | E1 项目基础架构 | MVP |
| FR18, FR19 | E5 面板与上下文菜单 | MVP |
| FR37 | E6 用户体验与反馈 | MVP |
| FR21, FR22, FR23, FR24 | E7 媒体播放与同步校准 | Growth |
| FR25, FR26, FR27, FR28, FR38, FR39, FR40, FR41 | E8 播放列表管理 | Growth |
| FR30, FR31, FR32 | E9 系统增强与引导 | Growth |
| NFR1, NFR2, NFR3, NFR5, NFR6, NFR7 | E2 关卡列表引擎 | MVP |
| NFR4, NFR10, NFR13 | E1 项目基础架构 | MVP |
| NFR8, NFR12, NFR14 | E3 视频搜索与下载 | MVP |
| NFR9 | E4 视频配置管理 | MVP |
| NFR7, NFR11 | E6 用户体验与反馈 | MVP |
| NFR15 | E7 媒体播放与同步校准 | Growth |
| NFR16, NFR17, NFR18, NFR19 | E8 播放列表管理 | Growth |
| ARCH-1, ARCH-2, ARCH-7, ARCH-8, ARCH-10 | E1 项目基础架构 | MVP |
| ARCH-4 | E2 关卡列表引擎 | MVP |
| ARCH-3, ARCH-11 | E3 视频搜索与下载 | MVP |
| ARCH-5 | E4 视频配置管理 | MVP |
| ARCH-6 | E5 面板与上下文菜单 | MVP |
| ARCH-9 | E9 系统增强与引导 | Growth |
| UX-1, UX-3, UX-5 | E1 项目基础架构 | MVP |
| UX-2(LevelListTile, DifficultyBadge, StatusIndicator), UX-6, UX-10, UX-15 | E2 关卡列表引擎 | MVP |
| UX-7 | E3 视频搜索与下载 | MVP |
| UX-4, UX-9 | E5 面板与上下文菜单 | MVP |
| UX-2(PanelHost, ContextMenuRegion) | E5 面板与上下文菜单 | MVP |
| UX-8, UX-13, UX-14 | E6 用户体验与反馈 | MVP |
| UX-11, UX-12 | E6 用户体验与反馈 | MVP |

**覆盖率**：86/86 需求已分配（100%）

---

## Epic List

### E1: 项目基础架构 (Foundation & Architecture)

**目标**：搭建 v2 应用骨架，包括路由、布局、主题、窗口管理和基础服务层，为所有功能页面提供可靠基座。

**覆盖需求**：FR17, FR20, FR29, FR33 | NFR4, NFR10, NFR13 | ARCH-1, ARCH-2, ARCH-7, ARCH-8, ARCH-10 | UX-1, UX-3, UX-5

**验收标准**：
- StatefulShellRoute + IndexedStack 实现多页面切换，页面状态不丢失
- Row 布局骨架（Rail 72px + 内容区 + 面板占位）渲染正确
- 暗色主题 5 层 Surface 色阶 + 语义色 + 难度色静态常量可用
- window_manager 最小 1024x600，窗口状态持久化，关闭拦截流程完整
- Services/ 目录结构建立，AppError 模型可用
- Beat Saber 路径设置 + shared_preferences 持久化工作正常
- path 包抽象文件路径，无硬编码分隔符

**Story 候选**：
- S1.1: StatefulShellRoute + NavigationRail 路由重构
- S1.2: Row 主布局骨架（Rail + 内容区 + 面板占位）
- S1.3: 暗色主题系统（Surface 色阶 + 语义色 + 难度色 + 8px 网格）
- S1.4: window_manager 集成（最小尺寸、状态持久化、关闭拦截）
- S1.5: Services 层基础设施（目录结构 + AppError 模型）
- S1.6: 设置页 - Beat Saber 路径配置与持久化
- S1.7: 应用关闭优雅终止流程（检查下载 → 确认 → dispose）

---

### E2: 关卡列表引擎 (Level List Engine)

**目标**：构建高性能关卡列表，支持 info.dat 后台解析与缓存、元数据展示、搜索/筛选/排序，是用户最核心的交互界面。

**覆盖需求**：FR1-FR7, FR34 | NFR1-NFR3, NFR5-NFR7 | ARCH-4 | UX-2(LevelListTile, DifficultyBadge, StatusIndicator), UX-6, UX-10, UX-15

**验收标准**：
- 500 首关卡首次加载 < 3s，缓存后 < 1s
- info.dat 解析在 Isolate 中执行，UI 保持 60fps
- 缓存支持内存 + 文件持久化 + 时间戳失效
- LevelListTile 48px 行高，展示歌名、作者、BPM、时长、难度色点、状态图标
- 搜索/筛选/排序响应 < 100ms
- 格式异常 info.dat 降级显示（仅歌名），不崩溃
- 骨架屏加载动画、摘要栏（总数/已配/下载中）

**Story 候选**：
- S2.1: info.dat 解析服务（Isolate + 防御性解析 + 降级）
- S2.2: CacheService（内存缓存 + JSON 文件持久化 + 时间戳失效）
- S2.3: CustomLevels BLoC 重构（集成缓存、流式加载）
- S2.4: LevelListTile 自定义组件（48px 行高、四态交互）
- S2.5: DifficultyBadge 组件（Beat Saber 难度色点 8-10px）
- S2.6: StatusIndicator 组件（🎬/⬇️/─/⚠️ 状态图标）
- S2.7: 列表搜索功能（关键词匹配、Ctrl+F 快捷键）
- S2.8: 列表筛选功能（难度、视频状态、修改时间）
- S2.9: 列表排序功能（歌名、作者、BPM、修改时间）
- S2.10: 摘要栏组件（总数/已配视频/下载中统计）
- S2.11: 骨架屏加载动画

---

### E3: 视频搜索与下载 (Video Search & Download)

**目标**：构建 yt-dlp 服务层，实现视频搜索、URL 粘贴下载、一键下载、并发队列管理和错误重试。

**覆盖需求**：FR8-FR13, FR36 | NFR8, NFR12, NFR14 | ARCH-3, ARCH-11 | UX-7

**验收标准**：
- VideoRepository 抽象接口 + YtDlpService 实现，可替换
- 搜索 YouTube/Bilibili，30s 超时，结果在面板展示
- 粘贴 URL 和搜索结果一键下载均可触发
- DownloadManager 限 3 并发，排队，10 分钟超时
- 下载进度实时展示（StreamController）
- 失败可查看错误原因并重试
- yt-dlp 异常转换为可理解的用户错误信息（L10n）
- Manager/ 遗留下载代码迁移到 Services/

**Story 候选**：
- S3.1: VideoRepository 抽象接口定义
- S3.2: YtDlpService 实现（搜索 + 下载 + 进程管理）
- S3.3: DownloadManager 并发队列（3 并发、排队、超时）
- S3.4: 搜索面板 UI（平台切换 YouTube/Bilibili、结果列表）
- S3.5: URL 粘贴下载功能
- S3.6: 下载进度实时展示（StreamController → UI）
- S3.7: 下载失败错误展示与重试机制
- S3.8: yt-dlp 错误映射（进程异常 → AppError → L10n 消息）
- S3.9: Manager/ 遗留代码迁移到 Services/

---

### E4: 视频配置管理 (Video Configuration)

**目标**：实现 cinema-video.json 的创建、编辑和关卡视频文件信息查看，确保文件操作的原子性和安全性。

**覆盖需求**：FR14-FR16, FR35 | NFR9 | ARCH-5

**验收标准**：
- 可为关卡创建 cinema-video.json（关联已下载视频）
- 可编辑已有配置参数
- 可查看关卡目录中的视频文件信息（文件名、大小、格式）
- 写入使用原子操作（临时文件 + File.rename）
- 文件被占用时提示用户并提供重试选项

**Story 候选**：
- S4.1: cinema-video.json 数据模型（fromMap/toMap + 防御性默认值）
- S4.2: 配置创建流程（关联视频 → 生成 JSON）
- S4.3: 配置编辑 UI（参数调整表单）
- S4.4: 原子文件写入服务（临时文件 + rename）
- S4.5: 关卡目录视频文件信息查看
- S4.6: 文件占用检测与重试提示

---

### E5: 面板与上下文菜单 (Panel & Context Menu)

**目标**：实现右侧面板系统和右键菜单，为关卡操作提供高效的上下文交互。

**覆盖需求**：FR18, FR19 | ARCH-6 | UX-2(PanelHost, ContextMenuRegion), UX-4, UX-9

**验收标准**：
- PanelHost 350px AnimatedContainer，展开/收起动画流畅
- PanelCubit 独立管理面板状态（内容类型、开关）
- 面板紫色左边线，选中行紫色左条（霓虹风格）
- ContextMenuRegion 封装右键菜单（GestureDetector.onSecondaryTapUp）
- 右键菜单提供：搜索视频、编辑配置、打开目录等常用操作
- 筛选列表中已配置歌曲延迟消失（3-5s → 淡出）

**Story 候选**：
- S5.1: PanelHost 组件（AnimatedContainer 350px + 展开/收起）
- S5.2: PanelCubit 面板状态管理
- S5.3: ContextMenuRegion 组件（右键菜单封装）
- S5.4: 关卡右键菜单项定义与路由
- S5.5: 面板霓虹视觉效果（紫色边线、选中高亮）
- S5.6: 筛选列表已配置项延迟淡出

---

### E6: 用户体验与反馈 (UX & Feedback)

**目标**：构建统一的错误处理、空状态、微交互和无障碍体系，确保应用在各种场景下提供一致且友好的用户体验。

**覆盖需求**：FR37 | NFR7, NFR11 | UX-8, UX-11, UX-12, UX-13, UX-14

**验收标准**：
- 错误四级呈现（静默降级/内联提示/SnackBar/模态确认）全覆盖
- 6 种空状态场景各有专属引导文案（L10n）
- 每个操作 100ms 内提供视觉反馈
- 网络不可用时离线功能正常，不产生未处理异常
- 键盘导航（Tab/Enter/Esc/Shift+F10/Arrow/Ctrl+F）
- 所有非文本元素有 semanticLabel

**Story 候选**：
- S6.1: 错误呈现框架（4 级路由：AppError.type → 呈现方式）
- S6.2: 空状态组件（6 种场景模板 + L10n 文案）
- S6.3: 微交互系统（按钮反馈、列表项悬停、面板过渡）
- S6.4: 离线模式保障（网络检测 + 功能降级）
- S6.5: 键盘导航支持（焦点管理、快捷键绑定）
- S6.6: 无障碍标注（semanticLabel + 屏幕阅读器兼容）

---

### E7: 媒体播放与同步校准 (Media Playback & Sync) — Growth

**目标**：集成 media_kit 实现音频/视频预览和分声道同步校准，让用户精确调整视频与谱面的时间偏移。

**覆盖需求**：FR21-FR24 | NFR15

**验收标准**：
- 可试听关卡音频文件（play/pause/seek）
- 可预览已下载视频文件
- 双播放器分声道方案：左声道音乐、右声道视频音轨
- 偏移量调整 UI（滑块 + 精确输入 + 实时预览）
- 校准值可保存到 cinema-video.json
- 页面离开或应用关闭时播放器资源正确释放

**Story 候选**：
- S7.1: media_kit 集成与播放器服务封装
- S7.2: 音频预览功能（play/pause/seek）
- S7.3: 视频预览功能（play/pause/seek）
- S7.4: 分声道同步校准 UI（双播放器 + 偏移滑块）
- S7.5: 偏移值保存到 cinema-video.json
- S7.6: 播放器资源生命周期管理

---

### E8: 播放列表管理 (Playlist Management) — Growth

**目标**：支持 .bplist 文件浏览、歌曲元信息映射与状态治理、缺失歌曲下载补全和增强导出，帮助用户高效闭环管理播放列表。

**覆盖需求**：FR25-FR28, FR38-FR41 | NFR16-NFR19

**验收标准**：
- 可浏览本地 .bplist 文件列表
- 可查看播放列表歌曲，并复用“全部歌曲列表”一致的列表界面
- 可展示并筛选歌曲状态（已就绪 / 待处理：未配置、未下载）
- 可执行单曲下载与“下载全部缺失歌曲”
- 可将 playlist 文件与已下载歌曲目录导出到指定文件夹
- 导出部分失败时可继续完成、生成缺失清单并支持仅重试失败项

**Story 候选**：
- S8.1: .bplist 文件解析服务
- S8.2: 播放列表浏览页面（列表 + 详情）
- S8.3: 播放列表歌曲视频状态展示
- S8.4: 关卡目录批量导出功能
- S8.5: 播放列表未下载歌曲单曲下载（BeatSaver）
- S8.6: 下载全部缺失歌曲与更新判定
- S8.7: 增强导出（.bplist + 已下载歌曲目录 + 部分成功与重试）

---

### E9: 系统增强与引导 (System Enhancements) — Growth

**目标**：提供自动路径检测、应用更新检查和首次使用引导，降低用户上手门槛。

**覆盖需求**：FR30-FR32 | ARCH-9

**验收标准**：
- 自动检测 Beat Saber 安装路径（Steam/Oculus 常见位置）
- 启动时通过 GitHub Releases API 检查更新，有新版本时通知
- 首次使用引导流程（路径设置 → 功能介绍 → 完成）

**Story 候选**：
- S9.1: Beat Saber 路径自动检测
- S9.2: UpdateService（GitHub Releases API + SemVer 比较）
- S9.3: 更新通知 UI
- S9.4: 首次使用引导流程（3 步向导）

---

## Epic Dependency Graph

```
E1 基础架构 ──┬──→ E2 列表引擎 ──→ E3 搜索下载 ──→ E4 配置管理
              │                                        │
              ├──→ E5 面板菜单 ←─────────────────────────┘
              │
              └──→ E6 体验反馈 (横切，贯穿所有 Epic)
              
MVP 完成后：
E2 + E7 媒体播放（依赖列表 + media_kit）
E2 + E8 播放列表（依赖列表解析基础）
E1 + E9 系统增强（依赖基础架构）
```

## 实施顺序建议

| Sprint | Epic | 原因 |
|--------|------|------|
| Sprint 1 | E1 基础架构 | 所有功能的前置依赖 |
| Sprint 2 | E2 关卡列表引擎 | 核心交互界面，用户价值最高 |
| Sprint 3 | E3 搜索下载 + E4 配置管理 | 核心工作流闭环 |
| Sprint 4 | E5 面板菜单 + E6 体验反馈 | 交互增强，MVP 收尾 |
| Sprint 5 | E7 媒体播放 | Growth 高价值功能 |
| Sprint 6 | E8 播放列表 + E9 系统增强 | Growth 收尾 |

---

# Story Details

## E1: 项目基础架构 (Foundation & Architecture)

### S1.1: StatefulShellRoute + NavigationRail 路由重构

**用户故事**：作为用户，我希望通过侧边导航在功能页面间切换时，之前页面的滚动位置和输入状态保持不变，这样我不会因为切换页面而丢失工作上下文。

**验收标准**：
- [ ] ShellRoute 替换为 StatefulShellRoute，每个 tab 对应独立 Navigator
- [ ] IndexedStack 保持所有页面的 widget 状态
- [ ] NavigationRail 固定 72px 宽，仅图标模式，悬停显示 Tooltip
- [ ] 至少 3 个 tab：关卡列表、下载管理、设置
- [ ] 页面切换无可感知延迟（< 16ms，NFR4）
- [ ] 所有用户可见文案使用 L10n ARB key

**技术要点**：
- `StatefulShellRoute.indexedStack` 构造函数
- 每个 branch 定义 `navigatorKey` 和 `rootRoute`
- NavigationRail `selectedIndex` 绑定 `StatefulShellRoute` 的 `currentIndex`
- L10n: tab 标签和 tooltip 文案

**依赖**：无（E1 起点）
**估算**：5 SP

---

### S1.2: Row 主布局骨架（Rail + 内容区 + 面板占位）

**用户故事**：作为用户，我希望应用界面有清晰的三栏布局：左侧固定导航、中间内容区、右侧可展开的详情面板，这样我能高效地在不同功能和上下文信息间切换。

**验收标准**：
- [ ] root_page.dart 重构为 `Row [ NavigationRail(72px) | VerticalDivider | Expanded(内容) | AnimatedContainer(面板占位) ]`
- [ ] 面板占位区初始宽度 0，展开时 350px，AnimatedContainer 动画时长 200ms
- [ ] VerticalDivider 使用 Surface-2 颜色
- [ ] 内容区响应窗口宽度变化（最小内容区 = 1024 - 72 - 350 = 602px）
- [ ] 布局在最小窗口尺寸 1024x600 下正确渲染

**技术要点**：
- `root_page.dart` 是 StatefulShellRoute 的 `builder`
- 面板占位由 E5 的 PanelHost 填充，此处仅预留 `AnimatedContainer`
- 使用 `LayoutBuilder` 或 `MediaQuery` 检测可用宽度

**依赖**：S1.1（路由骨架）
**估算**：3 SP

---

### S1.3: 暗色主题系统（Surface 色阶 + 语义色 + 难度色 + 8px 网格）

**用户故事**：作为用户，我希望应用有统一的暗色游戏风格主题，颜色层次清晰且视觉舒适，这样长时间使用不会视觉疲劳。

**验收标准**：
- [ ] ThemeData 配置 Material 3 暗色主题，colorSchemeSeed 使用品牌紫
- [ ] 5 层 Surface 色阶：Surface-0 `#141422`、Surface-1 `#1A1A2E`、Surface-2 `#1E1E35`、Surface-3 `#24243B`、Surface-4 `#2A2A42`
- [ ] 语义色常量：成功紫 `#9B59FF`、警告琥珀 `#FFA000`、错误红 `#CF6679`、信息青 `#80CBC4`
- [ ] Beat Saber 难度色静态常量（Easy 绿 → Expert+ 紫红，Expert+ 带 1px 白色边框）
- [ ] 前景文字色定义（主文字、次文字、禁用文字）并满足 WCAG AA 对比度
- [ ] 8px 基础网格间距系统（padding/margin 为 8 的倍数）
- [ ] 主题通过 `AppTheme` 类统一提供，避免硬编码颜色值

**技术要点**：
- 创建 `lib/App/theme/app_theme.dart` 和 `app_colors.dart`
- Surface 色阶作为 `ColorScheme` extension 或静态常量
- 难度色放入 `BeatSaberColors` 静态类
- 所有颜色引用通过 `AppColors` / `Theme.of(context)` 访问

**依赖**：无
**估算**：3 SP

---

### S1.4: window_manager 集成（最小尺寸、状态持久化、关闭拦截）

**用户故事**：作为用户，我希望应用记住我调整的窗口大小和位置，下次启动时恢复；关闭时如果有下载任务进行中，能给我提示而不是直接丢失进度。

**验收标准**：
- [ ] window_manager 初始化：最小尺寸 1024x600，默认居中
- [ ] 窗口大小和位置通过 shared_preferences 持久化
- [ ] 启动时恢复上次窗口状态（位置、大小），校验不超出屏幕范围
- [ ] `onWindowClose` 拦截：检查是否有活跃下载任务
- [ ] 有活跃下载时显示确认弹窗（L10n 文案）
- [ ] 确认关闭后执行资源 dispose 流程

**技术要点**：
- `main.dart` 中 `windowManager.ensureInitialized()` + 配置
- `WindowListener` mixin 实现 `onWindowClose`
- 窗口状态存储 key: `window_x`, `window_y`, `window_width`, `window_height`
- 关闭确认弹窗复用 UX-8 模态确认模式

**依赖**：S1.6（shared_preferences 已可用）
**估算**：5 SP

---

### S1.5: Services 层基础设施（目录结构 + AppError 模型）

**用户故事**：作为开发者，我希望项目有清晰的服务层目录结构和统一的错误模型，这样新增功能时知道代码放在哪里，错误处理有一致的模式。

**验收标准**：
- [ ] 创建 `lib/Services/` 目录，包含子目录：`repositories/`, `services/`, `managers/`
- [ ] 创建 `lib/Core/errors/app_error.dart`：`AppError` sealed class / enum type
- [ ] AppError 包含字段：`type`（枚举）、`userMessage`（L10n key）、`detail`（技术详情）、`retryable`（bool）
- [ ] AppError.type 枚举值：`fileSystem`, `network`, `process`, `parse`, `unknown`
- [ ] 提供 `AppError.fromException(Object e)` 工厂方法，将常见异常映射到对应类型
- [ ] 编写单元测试验证 AppError 工厂方法

**技术要点**：
- `AppError` 使用 `sealed class` + `part`/`part of` 文件组织（项目惯例）
- `userMessage` 存储 ARB key 而非硬编码字符串
- 每种 type 有默认的错误呈现级别建议（映射到 UX-8 四级）

**依赖**：无
**估算**：3 SP

---

### S1.6: 设置页 - Beat Saber 路径配置与持久化

**用户故事**：作为用户，我希望在设置中指定 Beat Saber 的安装路径，并且下次启动时自动记住这个设置，这样我不需要每次都重新配置。

**验收标准**：
- [ ] 设置页面包含 Beat Saber 路径输入（文本框 + 文件夹选择按钮）
- [ ] 路径选择使用系统文件夹选择对话框
- [ ] 验证路径下是否存在 `Beat Saber_Data/CustomLevels` 目录
- [ ] 路径无效时内联错误提示（UX-8 内联级别）
- [ ] 路径通过 shared_preferences 持久化
- [ ] 路径使用 `path` 包处理，不硬编码分隔符（NFR13）
- [ ] 所有文案使用 L10n

**技术要点**：
- 使用 `file_picker` 或系统原生对话框选择文件夹
- 路径存储 key: `beat_saber_path`
- 验证逻辑：`Directory(path/Beat Saber_Data/CustomLevels).existsSync()`

**依赖**：无
**估算**：3 SP

---

### S1.7: 应用关闭优雅终止流程

**用户故事**：作为用户，我希望关闭应用时所有后台下载任务和子进程被正确终止，不留下僵尸进程或损坏的文件。

**验收标准**：
- [ ] `onWindowClose` → 检查 DownloadManager 活跃任务数
- [ ] 有活跃任务时：显示模态确认弹窗，告知用户有 N 个下载进行中
- [ ] 用户确认后：取消所有下载、终止 yt-dlp 子进程、dispose BLoC/Cubit
- [ ] 整个关闭流程在 3 秒内完成（NFR10）
- [ ] 无活跃任务时直接关闭，不弹窗

**技术要点**：
- `WindowListener.onWindowClose` → `windowManager.setPreventClose(true)` 拦截
- 关闭序列：`DownloadManager.cancelAll()` → `Process.kill()` 所有子进程 → `dispose()`
- 设置 3 秒超时保护，超时后强制关闭
- 此 Story 与 E3 的 DownloadManager 有运行时依赖，但接口在此定义

**依赖**：S1.4（window_manager 关闭拦截）、S1.5（Services 层）
**估算**：3 SP

---

## E2: 关卡列表引擎 (Level List Engine)

### S2.1: info.dat 解析服务（Isolate + 防御性解析 + 降级）

**用户故事**：作为用户，我希望应用能快速读取所有关卡的元数据，即使某些关卡的数据文件有问题也不影响整体列表加载。

**验收标准**：
- [ ] 在后台 Isolate 中批量解析 `info.dat` 文件（NFR5）
- [ ] 解析提取：歌名、副标题、作者、BPM、时长、难度列表（含类型和标签）
- [ ] 防御性解析：缺失字段使用默认值，不抛异常
- [ ] 格式异常时降级：仅从目录名提取歌名（FR34）
- [ ] 解析错误记录到日志，不展示给用户（UX-8 静默级别）
- [ ] 500 首关卡解析 + 缓存写入总计 < 3s（NFR1）

**技术要点**：
- `Isolate.run()` 传入文件路径列表，返回解析结果列表
- 使用 `try-catch` 包裹每个文件的解析，单个失败不影响批量
- 返回类型：`List<LevelMetadata>` 其中 `LevelMetadata` 包含 `parseStatus` 字段
- 解析结果的 `fromMap` 使用 `??` 为每个字段提供默认值

**依赖**：S1.5（Services 层目录）
**估算**：5 SP

---

### S2.2: CacheService（内存缓存 + JSON 文件持久化 + 时间戳失效）

**用户故事**：作为用户，我希望第二次打开应用时关卡列表几乎瞬间加载，因为之前解析过的数据已被缓存。

**验收标准**：
- [ ] 内存层：`Map<String, LevelMetadata>` 按目录路径索引
- [ ] 文件层：解析结果序列化为 JSON 存储到本地文件
- [ ] 时间戳失效：记录每个目录的 `lastModified`，目录更新时重新解析
- [ ] 缓存命中时后续加载 < 1s（NFR2）
- [ ] 缓存文件损坏时静默重建，不影响功能
- [ ] 提供 `invalidate(path)` 和 `invalidateAll()` 方法

**技术要点**：
- 缓存文件路径：`%APPDATA%/beat_cinema/level_cache.json` 或应用数据目录
- 失效策略：比较 `Directory.statSync().modified` 与缓存时间戳
- 启动流程：加载文件缓存 → 比对时间戳 → 仅重新解析变更的目录
- 内存层在 BLoC 生命周期内有效

**依赖**：S2.1（解析服务提供数据）
**估算**：5 SP

---

### S2.3: CustomLevels BLoC 重构（集成缓存、流式加载）

**用户故事**：作为用户，我希望关卡列表随着解析进度逐步显示，而不是等全部解析完才一次性出现。

**验收标准**：
- [ ] 重构现有 `CustomLevelsBloc`，事件/状态使用 `sealed class`
- [ ] 状态包含：`initial`, `loading`, `loaded`, `error`
- [ ] `loading` 状态携带已解析数量和总数（用于进度指示）
- [ ] 集成 CacheService：优先从缓存加载，后台增量更新变更部分
- [ ] 列表数据流式更新（先展示缓存数据，新解析的数据追加更新）
- [ ] 800 首关卡场景内存不超过 500MB（NFR6）

**技术要点**：
- 加载流程：`emit(Loading)` → 读缓存 → `emit(Loaded(cached))` → Isolate 解析变更 → `emit(Loaded(merged))`
- `part`/`part of` 文件组织：`custom_levels_event.dart`, `custom_levels_state.dart`
- 保持现有 `AppLaunchComplated` 事件命名（已知拼写，不可改）

**依赖**：S2.1, S2.2
**估算**：5 SP

---

### S2.4: LevelListTile 自定义组件（48px 行高、四态交互）

**用户故事**：作为用户，我希望关卡列表中的每一行紧凑地展示关键信息（歌名、作者、难度、状态），且鼠标悬停/点击时有清晰的视觉反馈。

**验收标准**：
- [ ] 固定行高 48px，8px 内边距
- [ ] 布局：`Row [ StatusIcon(24px) | 歌名+作者(Expanded) | 难度色点组(Row) | BPM(固定宽) ]`
- [ ] 四态交互：normal / hover(Surface-3 背景) / pressed(Surface-4) / disabled(0.38 透明度)
- [ ] 选中态：左侧 3px 紫色竖条（UX-4 霓虹风格）
- [ ] 歌名主文字色，作者次文字色，文字溢出省略
- [ ] 组件接受 `LevelMetadata` 数据对象
- [ ] semanticLabel 包含歌名和作者（UX-12）

**技术要点**：
- 继承 `StatelessWidget`，内部使用 `Material` + `InkWell` 实现交互态
- 选中态通过外部 `selectedId` 参数控制
- 难度色点区域使用 `DifficultyBadge` 子组件（S2.5）
- 状态图标区域使用 `StatusIndicator` 子组件（S2.6）

**依赖**：S1.3（主题色可用）、S2.5、S2.6
**估算**：5 SP

---

### S2.5: DifficultyBadge 组件（Beat Saber 难度色点 8-10px）

**用户故事**：作为用户，我希望一眼就能看到每首关卡支持哪些难度，通过熟悉的 Beat Saber 难度颜色快速识别。

**验收标准**：
- [ ] 圆形色点，直径 8px（普通难度）或 10px（Expert+）
- [ ] Expert+ 额外 1px 白色边框以示区分
- [ ] 色值使用 `BeatSaberColors` 静态常量（S1.3 中定义）
- [ ] 多难度横向排列，间距 4px
- [ ] Tooltip 显示难度名称
- [ ] semanticLabel 列出所有难度名称

**技术要点**：
- `Container` + `BoxDecoration(shape: BoxShape.circle)`
- Expert+ 边框通过 `border: Border.all(color: white, width: 1)`
- 难度顺序：Easy → Normal → Hard → Expert → Expert+

**依赖**：S1.3（难度色常量）
**估算**：2 SP

---

### S2.6: StatusIndicator 组件（状态图标）

**用户故事**：作为用户，我希望关卡的视频配置状态通过直观的图标一目了然：没有视频、已配置、正在下载或有问题。

**验收标准**：
- [ ] 4 种状态图标：无视频(─)、已配置(🎬)、下载中(⬇️ 带进度)、异常(⚠️)
- [ ] 图标尺寸 20px，居中于 24px 容器
- [ ] 下载中状态可显示百分比文字或进度圆环
- [ ] 异常状态使用错误红色（`#CF6679`）
- [ ] 已配置状态使用成功紫色（`#9B59FF`）
- [ ] semanticLabel 描述当前状态

**技术要点**：
- 接受 `VideoConfigStatus` 枚举参数
- 下载中状态接受 `double progress` (0.0-1.0)
- 使用 `Icon` 或自定义 `CustomPaint` 渲染

**依赖**：S1.3（语义色）
**估算**：2 SP

---

### S2.7: 列表搜索功能（关键词匹配、Ctrl+F）

**用户故事**：作为用户，我希望按 Ctrl+F 或点击搜索图标就能快速搜索关卡，输入关键词后列表实时过滤。

**验收标准**：
- [ ] 搜索框位于列表上方，支持 Ctrl+F 快捷键激活
- [ ] 实时过滤：输入时即刻筛选（debounce 200ms）
- [ ] 匹配范围：歌名、作者、mapper 名称
- [ ] 不区分大小写
- [ ] 搜索响应 < 100ms（NFR3）
- [ ] 清空搜索框恢复完整列表
- [ ] Esc 键关闭搜索框

**BDD Scenarios (Given/When/Then):**
- Given 关卡列表已完成加载且用户位于列表页  
  When 用户按下 Ctrl+F 并输入关键词  
  Then 搜索框应获得焦点，列表应在 100ms 内显示匹配结果
- Given 搜索功能可用且用户已输入关键词  
  When 用户将关键词清空或按下 Esc，或部分元数据为空  
  Then 系统应恢复完整列表并进行降级展示而不报错，交互状态保持可继续操作

**技术要点**：
- `TextField` + `FocusNode` + 键盘快捷键绑定（`Shortcuts` / `CallbackShortcuts`）
- BLoC event: `SearchQueryChanged(String query)`
- 过滤在 BLoC 中使用 `where()` 对内存列表操作（NFR3 < 100ms）

**依赖**：S2.3（BLoC 提供列表数据）
**估算**：3 SP

---

### S2.8: 列表筛选功能（难度、视频状态、修改时间）

**用户故事**：作为用户，我希望能筛选出只有特定难度或缺少视频配置的关卡，这样我能专注处理需要配置视频的歌曲。

**验收标准**：
- [ ] 筛选条件：难度（多选）、视频状态（无视频/已配置/下载中）、修改时间范围
- [ ] 筛选 UI：列表上方的 FilterChip 组或下拉选择
- [ ] 多条件组合为 AND 逻辑
- [ ] 筛选结果实时更新，响应 < 100ms（NFR3）
- [ ] 已激活的筛选条件有视觉标识
- [ ] 一键清除所有筛选

**技术要点**：
- BLoC event: `FilterChanged(FilterCriteria criteria)`
- `FilterCriteria` 数据类包含各筛选维度
- 筛选和搜索可叠加使用

**依赖**：S2.3, S2.7
**估算**：3 SP

---

### S2.9: 列表排序功能（歌名、作者、BPM、修改时间）

**用户故事**：作为用户，我希望能按歌名、作者、BPM 或修改时间排序关卡列表，快速找到最新添加或特定 BPM 范围的歌曲。

**验收标准**：
- [ ] 排序字段：歌名（默认）、作者、BPM、修改时间
- [ ] 每个字段支持升序/降序切换
- [ ] 排序 UI：列表上方的排序按钮或下拉
- [ ] 排序响应 < 100ms（NFR3）
- [ ] 当前排序字段和方向有视觉指示

**技术要点**：
- BLoC event: `SortChanged(SortField field, SortDirection direction)`
- 排序在内存中执行（`list.sort()`）
- 与搜索/筛选联合作用

**依赖**：S2.3
**估算**：2 SP

---

### S2.10: 摘要栏组件（总数/已配视频/下载中统计）

**用户故事**：作为用户，我希望在列表顶部看到总关卡数、已配置视频数和下载中数量的统计，快速了解整体进度。

**验收标准**：
- [ ] 摘要栏位于搜索/筛选区域与列表之间
- [ ] 显示：总数 / 已配置 / 下载中（实时更新）
- [ ] 数字使用强调色（已配置用成功紫，下载中用信息青）
- [ ] 筛选后摘要反映筛选后的统计
- [ ] L10n 支持中英文

**技术要点**：
- 从 BLoC state 的 `filteredLevels` 计算统计
- `BlocBuilder` 局部重建
- 布局：`Row` 居左排列 3 个 `Text.rich` 统计项

**依赖**：S2.3
**估算**：2 SP

---

### S2.11: 骨架屏加载动画

**用户故事**：作为用户，我希望列表加载时看到骨架占位动画而非空白屏幕，让我知道数据正在加载。

**验收标准**：
- [ ] 首次加载（无缓存）时显示 10-15 行骨架占位
- [ ] 骨架行模拟 LevelListTile 的布局结构（色块占位）
- [ ] shimmer 闪烁动画效果
- [ ] 缓存加载时不显示骨架（直接展示数据）
- [ ] 骨架 → 实际数据过渡自然（fade-in）

**技术要点**：
- 使用 `shimmer` 包或手写 `AnimatedBuilder` + `LinearGradient`
- BLoC `Loading(hasCache: false)` 时展示骨架，`Loading(hasCache: true)` 时跳过
- 与 S2.3 的状态流配合

**依赖**：S2.4（知道 LevelListTile 布局以模拟）
**估算**：2 SP

---

## E3: 视频搜索与下载 (Video Search & Download)

### S3.1: VideoRepository 抽象接口定义

**用户故事**：作为开发者，我希望视频搜索和下载功能通过抽象接口定义，这样未来可以替换底层工具（如从 yt-dlp 切换到其他方案）而不影响上层逻辑。

**验收标准**：
- [ ] `lib/Services/repositories/video_repository.dart` 定义抽象接口
- [ ] 方法：`search(query, platform)` → `Future<List<VideoSearchResult>>`
- [ ] 方法：`download(url, outputDir, {onProgress})` → `Future<DownloadResult>`
- [ ] 方法：`cancelDownload(taskId)` → `Future<void>`
- [ ] 方法：`getVideoInfo(url)` → `Future<VideoInfo>`
- [ ] 定义关联数据模型：`VideoSearchResult`, `DownloadResult`, `VideoInfo`, `DownloadProgress`
- [ ] 所有模型使用 `fromMap`/`toMap` + 防御性默认值

**技术要点**：
- 纯 Dart 抽象类，不引入 yt-dlp 依赖
- `platform` 参数为枚举：`youtube`, `bilibili`
- `onProgress` 回调类型：`void Function(DownloadProgress)`

**依赖**：S1.5（Services 目录结构）
**估算**：3 SP

---

### S3.2: YtDlpService 实现（搜索 + 下载 + 进程管理）

**用户故事**：作为系统，我需要通过 yt-dlp 进程实现视频搜索和下载，确保进程生命周期被正确管理，不会产生僵尸进程。

**验收标准**：
- [ ] 实现 `VideoRepository` 接口，封装 yt-dlp 命令行调用
- [ ] 搜索：`yt-dlp --dump-json "ytsearch5:{query}"` + JSON 解析
- [ ] 下载：`yt-dlp -o {outputPath} --progress {url}` + stdout 进度解析
- [ ] 所有 Process 调用使用 `Isolate.run()` 防止阻塞 UI
- [ ] 搜索超时 30s，下载超时 10min（NFR14）
- [ ] 进程跟踪：维护 `Map<String, Process>` 用于取消
- [ ] yt-dlp 不存在或版本不兼容时返回明确错误

**BDD Scenarios (Given/When/Then):**
- Given 用户在搜索面板输入关键词并触发搜索  
  When yt-dlp 在超时时间内返回有效结果  
  Then 系统应解析并返回结构化列表数据，且主线程保持可响应
- Given 系统已发起 yt-dlp 搜索或下载任务  
  When 任务超过超时阈值或可执行文件不可用  
  Then 系统应返回可理解错误信息并标记为可重试，不产生僵尸进程

**技术要点**：
- `Process.start()` 启动，`process.stdout` 流式解析进度
- 进度解析正则：匹配 `[download] xx.x%`
- 搜索结果从 yt-dlp JSON 输出中提取：title, url, duration, thumbnail
- Bilibili 搜索可能需要不同参数

**依赖**：S3.1（接口定义）
**估算**：8 SP

---

### S3.3: DownloadManager 并发队列（3 并发、排队、超时）

**用户故事**：作为用户，我希望同时下载多个视频时系统自动管理队列，不会因为太多并发导致下载变慢或失败。

**验收标准**：
- [ ] 最大 3 个并发下载任务
- [ ] 超出并发的任务自动排队（FIFO）
- [ ] 单任务超时 10 分钟，超时自动取消并标记失败
- [ ] 提供任务状态查询：`pending`, `downloading`, `completed`, `failed`, `cancelled`
- [ ] 提供全局进度流：`Stream<List<DownloadTask>>`
- [ ] `cancelAll()` 方法用于应用关闭时批量取消
- [ ] 下载成功率 > 95%（NFR8，排除外部因素）

**技术要点**：
- `StreamController<List<DownloadTask>>` 广播任务状态变化
- 使用 `Completer` 管理每个任务的完成
- 队列管理：`Queue<DownloadTask>` + 信号量控制并发
- `cancelAll()` 遍历活跃进程调用 `process.kill()`

**依赖**：S3.2（YtDlpService 提供下载能力）
**估算**：5 SP

---

### S3.4: 搜索面板 UI（平台切换 YouTube/Bilibili、结果列表）

**用户故事**：作为用户，我希望在右侧面板中搜索视频，能切换 YouTube 和 Bilibili 平台，从结果列表中选择并一键下载。

**验收标准**：
- [ ] 搜索面板在右侧 PanelHost 中展示
- [ ] 顶部：平台切换器（YouTube/Bilibili 图标按钮，UX-7）
- [ ] 搜索框输入关键词（默认预填关卡歌名）
- [ ] 结果列表：缩略图（如可用）、标题、时长、来源
- [ ] 每个结果有"下载"按钮
- [ ] 搜索中显示加载动画，无结果显示空状态（UX-13）
- [ ] 搜索失败显示错误信息 + 重试按钮

**技术要点**：
- 面板通过 PanelCubit 打开（E5 提供）
- 搜索 BLoC: `SearchVideoBloc`（event/state sealed class）
- 结果列表使用 `ListView.builder`
- 缩略图使用 `Image.network` + placeholder

**依赖**：S3.2, S3.3, E5（面板系统）
**估算**：5 SP

---

### S3.5: URL 粘贴下载功能

**用户故事**：作为用户，我希望直接粘贴视频链接就能触发下载，不需要先搜索再选择。

**验收标准**：
- [ ] 面板顶部提供 URL 输入框或粘贴按钮
- [ ] 自动识别 YouTube / Bilibili URL 格式
- [ ] 粘贴有效 URL 后自动获取视频信息（标题、时长）并显示确认
- [ ] 用户确认后加入下载队列
- [ ] 无效 URL 显示内联错误提示

**技术要点**：
- URL 正则验证：`youtube.com/watch`, `youtu.be/`, `bilibili.com/video`
- 调用 `VideoRepository.getVideoInfo(url)` 获取元数据
- 复用 DownloadManager 入队逻辑

**依赖**：S3.2, S3.3
**估算**：3 SP

---

### S3.6: 下载进度实时展示（StreamController → UI）

**用户故事**：作为用户，我希望看到每个下载任务的实时进度百分比和速度，了解还需等待多久。

**验收标准**：
- [ ] 下载管理页面展示所有任务列表
- [ ] 每个任务显示：视频标题、进度条、百分比、下载速度、状态
- [ ] 进度条使用品牌紫色填充（UX-4）
- [ ] 状态变化实时更新（< 1s 延迟）
- [ ] 已完成任务移至底部或单独分组

**技术要点**：
- `StreamBuilder` 监听 `DownloadManager.taskStream`
- 进度条：`LinearProgressIndicator` + 自定义颜色
- 下载速度从 yt-dlp stdout 解析

**依赖**：S3.3
**估算**：3 SP

---

### S3.7: 下载失败错误展示与重试机制

**用户故事**：作为用户，我希望下载失败时能看到可理解的错误原因，并能一键重试。

**验收标准**：
- [ ] 失败任务显示错误图标 + 简明错误描述（L10n）
- [ ] 常见错误分类：网络超时、视频不可用、地区限制、yt-dlp 错误
- [ ] 每个失败任务提供"重试"按钮
- [ ] 重试使用相同参数重新入队
- [ ] 可选：展开查看技术详情（面向高级用户）

**技术要点**：
- `AppError` 映射 yt-dlp 退出码和 stderr 到用户友好消息
- 重试：`DownloadManager.retry(taskId)` 克隆参数重新入队
- 技术详情使用 `ExpansionTile` 折叠显示

**依赖**：S3.3, S1.5（AppError）
**估算**：3 SP

---

### S3.8: yt-dlp 错误映射（进程异常 → AppError → L10n 消息）

**用户故事**：作为系统，我需要将 yt-dlp 的各种异常情况（进程崩溃、超时、网络错误、格式不支持）转换为用户可理解的本地化错误信息。

**验收标准**：
- [ ] 映射 yt-dlp 常见退出码到 AppError.type
- [ ] 解析 stderr 关键词（"HTTP Error", "Video unavailable", "age-restricted" 等）
- [ ] 进程超时（30s 搜索 / 10min 下载）映射为 `network` 类型错误
- [ ] 每种映射有对应 L10n ARB key
- [ ] yt-dlp 不存在时映射为 `process` 类型 + 安装引导消息
- [ ] 未知错误有兜底消息

**技术要点**：
- 创建 `YtDlpErrorMapper` 类
- 映射表：`Map<Pattern, AppError Function(String stderr)>`
- ARB key 规范：`error_ytdlp_network_timeout`, `error_ytdlp_video_unavailable` 等

**依赖**：S1.5（AppError）、S3.2（YtDlpService）
**估算**：3 SP

---

### S3.9: Manager/ 遗留代码迁移到 Services/

**用户故事**：作为开发者，我希望将旧的 `Manager/cinema_download_manager.dart` 代码迁移到新的 Services 层架构中，消除代码重复和混乱的职责边界。

**验收标准**：
- [ ] `cinema_download_manager.dart` 的功能完全由 `YtDlpService` + `DownloadManager` 覆盖
- [ ] 旧的 Manager/ 模块中对 yt-dlp 的直接调用全部移除
- [ ] 所有引用旧 Manager 的代码更新为使用新 Services
- [ ] 迁移后运行所有现有功能确认无回归
- [ ] 旧文件标记为 deprecated 或删除（根据团队策略）

**技术要点**：
- 逐步迁移：先建新实现 → 更新引用 → 删除旧代码
- 保持 `AppLaunchComplated` 拼写不变
- 注意 `part`/`part of` 文件组织可能需要更新

**依赖**：S3.2, S3.3（新服务已就绪）
**估算**：5 SP

---

## E4: 视频配置管理 (Video Configuration)

### S4.1: cinema-video.json 数据模型（fromMap/toMap + 防御性默认值）

**用户故事**：作为开发者，我需要一个健壮的数据模型来表示 cinema-video.json 的内容，能安全地解析各种版本的配置文件。

**验收标准**：
- [ ] `CinemaVideoConfig` 数据类，包含所有 Cinema 插件支持的字段
- [ ] `fromMap(Map<String, dynamic>)` 构造：每个字段有防御性默认值
- [ ] `toMap()` 序列化：仅输出非默认值字段（减少文件大小）
- [ ] `copyWith()` 方法用于不可变更新
- [ ] 支持 Cinema 插件的核心字段：videoID, title, author, videoFile, duration, offset 等
- [ ] 单元测试覆盖：正常解析、缺失字段、类型错误、空 Map

**技术要点**：
- 手动 `fromMap`/`toMap`（项目惯例，不使用代码生成）
- 所有数字字段默认 0，字符串默认空字符串
- `offset` 字段为 `int`（毫秒），与 E7 同步校准功能关联

**依赖**：无
**估算**：3 SP

---

### S4.2: 配置创建流程（关联视频 → 生成 JSON）

**用户故事**：作为用户，我希望下载视频后能自动或一键创建 cinema-video.json，将视频与关卡关联起来。

**验收标准**：
- [ ] 下载完成后自动弹出创建配置的提示（面板内）
- [ ] 自动填充已知字段：videoFile（文件名）、title、author、duration
- [ ] 用户可修改自动填充的值
- [ ] 确认后生成 cinema-video.json 写入关卡目录
- [ ] 写入成功后更新关卡列表中对应项的状态图标
- [ ] 所有文案 L10n

**技术要点**：
- 从 `DownloadResult` 和 `VideoSearchResult` 提取元数据
- 调用 S4.4 的原子写入服务
- 触发 BLoC 事件更新列表项状态

**依赖**：S4.1, S4.4, S3.3（下载完成触发）
**估算**：3 SP

---

### S4.3: 配置编辑 UI（参数调整表单）

**用户故事**：作为用户，我希望能编辑已有的 cinema-video.json 中的参数（如偏移量、视频文件名），修改后保存。

**验收标准**：
- [ ] 编辑 UI 在右侧面板中展示
- [ ] 显示当前配置的所有可编辑字段
- [ ] 表单验证：必填字段、数值范围、文件名有效性
- [ ] 保存按钮触发原子写入
- [ ] 保存成功显示 SnackBar 确认
- [ ] 未保存修改时离开面板有确认提示

**技术要点**：
- `Form` + `TextFormField` 组合
- 使用 `CinemaVideoConfig.copyWith()` 生成更新后的对象
- 面板关闭前检查 `FormState.isDirty`

**依赖**：S4.1, S4.4, E5（面板）
**估算**：3 SP

---

### S4.4: 原子文件写入服务（临时文件 + rename）

**用户故事**：作为用户，我希望配置文件的保存操作是安全的——即使写入过程中断电或崩溃，也不会损坏我已有的配置。

**验收标准**：
- [ ] 写入流程：数据 → 临时文件（.tmp 后缀）→ `File.rename()` 覆盖目标文件
- [ ] rename 是原子操作（同一文件系统内），确保不会出现半写状态
- [ ] 临时文件写入失败时不影响原文件
- [ ] 写入失败返回 `AppError(type: fileSystem, retryable: true)`
- [ ] rename 失败（如跨卷）时回退到 copy + delete

**BDD Scenarios (Given/When/Then):**
- Given 目标目录可写且存在有效配置数据  
  When 系统执行原子写入流程  
  Then 应生成临时文件并成功替换目标文件，且目标文件内容完整可读
- Given 目标配置文件正被其他进程占用或文件系统异常  
  When 系统尝试执行写入或重命名  
  Then 原文件应保持不损坏，系统应返回 fileSystem 类型错误并提供重试路径

**技术要点**：
- `File.writeAsString()` 写入 `.tmp` → `File.rename()` 覆盖
- Windows 上 `rename` 在同一分区是原子的
- 需处理 `FileSystemException`（权限、磁盘满、路径不存在）

**依赖**：S1.5（AppError）
**估算**：3 SP

---

### S4.5: 关卡目录视频文件信息查看

**用户故事**：作为用户，我希望能查看关卡目录中已有的视频文件信息（文件名、大小、格式），确认下载的视频是否正确。

**验收标准**：
- [ ] 面板中显示关卡目录内的视频文件列表
- [ ] 每个文件显示：文件名、大小（MB 格式化）、扩展名
- [ ] 标识当前 cinema-video.json 中引用的文件
- [ ] 无视频文件时显示空状态提示

**技术要点**：
- 扫描目录：`Directory.listSync()` 过滤视频扩展名（.mp4, .mkv, .webm）
- 文件大小：`File.lengthSync()` → 格式化为 MB

**依赖**：E5（面板展示）
**估算**：2 SP

---

### S4.6: 文件占用检测与重试提示

**用户故事**：作为用户，当我试图编辑一个被其他程序占用的配置文件时，希望得到清晰提示而不是看到报错，并能在文件释放后重试。

**验收标准**：
- [ ] 写入时捕获 `FileSystemException`（ERROR_SHARING_VIOLATION）
- [ ] 显示用户友好的错误提示：文件被占用，建议关闭相关程序
- [ ] 提供"重试"按钮
- [ ] 错误提示使用 SnackBar 级别（UX-8）
- [ ] L10n 文案

**技术要点**：
- Windows 文件锁错误码：`ERROR_SHARING_VIOLATION (32)`
- 捕获 `FileSystemException` 检查 `osError.errorCode`
- 重试使用指数退避（1s → 2s → 4s），最多 3 次自动重试后提示用户

**依赖**：S4.4（写入服务）
**估算**：2 SP

---

## E5: 面板与上下文菜单 (Panel & Context Menu)

### S5.1: PanelHost 组件（AnimatedContainer 350px + 展开/收起）

**用户故事**：作为用户，我希望右侧面板能流畅地展开和收起，显示不同类型的上下文信息（搜索结果、配置编辑、文件详情）。

**验收标准**：
- [ ] PanelHost 使用 `AnimatedContainer`：收起 0px → 展开 350px
- [ ] 动画时长 200ms，曲线 `Curves.easeInOut`
- [ ] 面板左侧 1px 紫色边线（UX-4 霓虹风格）
- [ ] 面板头部：标题 + 关闭按钮
- [ ] 面板内容区支持动态切换（搜索结果 / 配置编辑 / 文件详情等）
- [ ] 面板展开时内容区 Expanded 自动压缩
- [ ] Esc 键关闭面板

**BDD Scenarios (Given/When/Then):**
- Given 用户在内容区选择“搜索视频”操作  
  When PanelHost 打开  
  Then 面板应从 0px 平滑过渡到 350px，并显示对应标题与内容区域
- Given 面板已打开且当前展示一种内容类型  
  When 用户切换到另一种面板内容或按 Esc  
  Then 面板应正确切换内容上下文或关闭，且内容区布局无错位与残影

**技术要点**：
- `AnimatedContainer` width + `ClipRect` 避免内容溢出
- 内容区使用 `IndexedStack` 或 `AnimatedSwitcher` 切换
- 面板关闭动画完成后才销毁内容（避免闪烁）

**依赖**：S1.2（布局骨架预留面板位）
**估算**：5 SP

---

### S5.2: PanelCubit 面板状态管理

**用户故事**：作为开发者，我需要一个独立的 Cubit 管理面板的开关状态和内容类型，不与页面 BLoC 混合。

**验收标准**：
- [ ] `PanelCubit` 管理状态：`closed`, `open(PanelContent content)`
- [ ] `PanelContent` 枚举或 sealed class：`search`, `configEdit`, `fileInfo`, `downloadDetail`
- [ ] 提供方法：`openPanel(content)`, `closePanel()`, `togglePanel(content)`
- [ ] 同一内容类型 toggle：打开 → 关闭；不同内容类型 toggle：切换内容
- [ ] PanelCubit 作为 S1.2 布局中的 `BlocProvider`，全页面可访问

**技术要点**：
- `PanelState` sealed class + `part`/`part of` 文件组织
- Cubit 而非 Bloc（状态变化简单，不需要事件流）
- 提供在 E1 的 provider 层级中

**依赖**：S1.5（项目结构）
**估算**：2 SP

---

### S5.3: ContextMenuRegion 组件（右键菜单封装）

**用户故事**：作为用户，我希望在关卡列表中右键点击就能看到操作菜单，快速执行搜索视频、编辑配置等操作。

**验收标准**：
- [ ] ContextMenuRegion 封装 `GestureDetector.onSecondaryTapUp`
- [ ] 接受 `List<ContextMenuItem>` 定义菜单项
- [ ] 菜单使用 `showMenu()` 在点击位置弹出
- [ ] 菜单样式符合暗色主题（Surface-3 背景、Surface-4 悬停）
- [ ] 支持分隔线和禁用状态菜单项
- [ ] 点击菜单项后自动关闭菜单
- [ ] 组件可复用于列表项、面板内容等场景

**技术要点**：
- `GestureDetector.onSecondaryTapUp` 获取 `TapUpDetails.globalPosition`
- `showMenu(context, position, items)` 弹出 `PopupMenuEntry`
- `ContextMenuItem` 数据类：`label`, `icon`, `onTap`, `enabled`, `isDivider`
- 菜单主题通过 `PopupMenuThemeData` 在 ThemeData 中配置

**依赖**：S1.3（主题色）
**估算**：3 SP

---

### S5.4: 关卡右键菜单项定义与路由

**用户故事**：作为用户，我希望右键菜单提供我最常用的操作：搜索视频、编辑配置、打开关卡目录、复制歌名。

**验收标准**：
- [ ] 菜单项列表（根据关卡状态动态调整）：
  - 搜索视频（始终可用）→ 打开搜索面板
  - 粘贴 URL 下载（始终可用）→ 打开 URL 输入
  - 编辑配置（有 cinema-video.json 时可用）→ 打开编辑面板
  - 打开关卡目录（始终可用）→ `Process.run('explorer', [path])`
  - 复制歌名（始终可用）→ 复制到剪贴板
  - ---分隔线---
  - 删除视频配置（有配置时可用）→ 确认弹窗后删除
- [ ] 各操作正确路由到对应面板或功能
- [ ] 所有菜单文案 L10n

**技术要点**：
- 菜单项列表根据 `LevelMetadata.videoConfigStatus` 动态生成
- 打开目录：`Process.run('explorer', [levelDirPath])`
- 复制：`Clipboard.setData(ClipboardData(text: songName))`
- 删除配置：`showDialog` 确认 → `File.delete()`

**依赖**：S5.3, S5.2（路由到面板）
**估算**：3 SP

---

### S5.5: 面板霓虹视觉效果（紫色边线、选中高亮）

**用户故事**：作为用户，我希望面板和选中状态有游戏风格的霓虹紫色视觉效果，营造沉浸感。

**验收标准**：
- [ ] 面板左边线 1px 品牌紫 `#9B59FF`
- [ ] 列表选中行左侧 3px 紫色竖条
- [ ] 进度条使用紫色填充 + 深紫色轨道
- [ ] 紫色元素适度使用，不过度刺眼
- [ ] 所有紫色使用 `AppColors.brandPurple` 常量引用

**技术要点**：
- 面板边线：`Border(left: BorderSide(color: brandPurple, width: 1))`
- 选中竖条：`Container(width: 3, color: brandPurple)` 在 LevelListTile 左侧
- 进度条：`LinearProgressIndicator` + `valueColor` / `backgroundColor`

**依赖**：S1.3（颜色常量）、S5.1、S2.4
**估算**：2 SP

---

### S5.6: 筛选列表已配置项延迟淡出

**用户故事**：作为用户，当我筛选"未配置视频"的关卡并为其中一首配好视频后，希望它不要立即从列表消失，让我能确认配置成功后再自然淡出。

**验收标准**：
- [ ] 列表处于"未配置"筛选模式时，新配置完成的项保留 3-5 秒
- [ ] 保留期间显示配置成功的视觉反馈（StatusIndicator 变为成功态）
- [ ] 3-5 秒后该项 fade-out 淡出（300ms 动画）
- [ ] 淡出完成后从列表移除
- [ ] 摘要栏统计实时更新（已配数 +1）

**技术要点**：
- 使用 `AnimatedList` 或手动管理 `AnimatedOpacity`
- BLoC 状态中标记"pendingRemoval"项及其倒计时
- `Timer` 控制延迟，到期后 emit 新状态移除该项

**依赖**：S2.3, S2.8（筛选功能）
**估算**：3 SP

---

## E6: 用户体验与反馈 (UX & Feedback)

### S6.1: 错误呈现框架（4 级路由：AppError.type → 呈现方式）

**用户故事**：作为用户，我希望不同严重程度的错误以不同方式呈现——轻微的不打扰我，严重的明确告知我需要怎么做。

**验收标准**：
- [ ] 4 级呈现路由已实现：
  - Level 0 静默降级：记录日志，功能降级（如 info.dat 解析失败显示目录名）
  - Level 1 内联提示：错误信息嵌入当前 UI 区域（如表单字段下方红色文字）
  - Level 2 SnackBar：底部弹出 3-5 秒，可操作（如"重试"按钮）
  - Level 3 模态确认：全屏遮罩弹窗，需要用户明确操作（如关闭确认）
- [ ] `AppError.type` → 呈现级别的默认映射表
- [ ] 提供 `ErrorPresenter` 工具类或 extension，一行代码触发呈现
- [ ] SnackBar 样式符合暗色主题，错误红色边框
- [ ] 所有错误文案使用 L10n

**技术要点**：
- `ErrorPresenter.show(context, AppError error, {int? overrideLevel})`
- 默认映射：`parse` → L0, `fileSystem` → L2, `network` → L2, `process` → L3
- SnackBar 使用 `ScaffoldMessenger`
- 模态使用 `showDialog`

**依赖**：S1.5（AppError 模型）
**估算**：5 SP

---

### S6.2: 空状态组件（6 种场景模板 + L10n 文案）

**用户故事**：作为用户，当列表为空或无搜索结果时，我希望看到友好的提示和引导，而不是一片空白。

**验收标准**：
- [ ] 6 种空状态场景覆盖：
  1. 关卡目录为空（未设置路径或路径下无关卡）
  2. 搜索无匹配结果
  3. 筛选后无结果
  4. 视频搜索无结果
  5. 下载列表为空
  6. 播放列表为空（Growth）
- [ ] 每种场景有：图标/插画 + 标题 + 描述文字 + 可选操作按钮
- [ ] 空状态组件居中显示，视觉舒适
- [ ] 所有文案中英双语 L10n
- [ ] 操作按钮引导用户解决问题（如"设置路径"、"清除筛选"）

**技术要点**：
- 通用 `EmptyStateWidget(icon, title, description, actionLabel, onAction)`
- 各场景预设工厂方法：`EmptyStateWidget.noLevels()`, `.noSearchResults()` 等
- 图标使用 Material Icons，不引入额外资源

**依赖**：S1.3（主题）
**估算**：3 SP

---

### S6.3: 微交互系统（按钮反馈、列表项悬停、面板过渡）

**用户故事**：作为用户，我希望每个操作都有即时的视觉反馈，让我确信操作已被识别。

**验收标准**：
- [ ] 按钮点击：ink splash 效果 + 按下态色变（100ms 内响应）
- [ ] 列表项悬停：背景色变为 Surface-3（UX-14）
- [ ] 面板展开/收起：200ms 宽度动画
- [ ] 下载开始：状态图标立即变为下载中态
- [ ] 配置保存成功：短暂绿色闪烁或 check 图标动画
- [ ] 所有过渡动画使用一致的时长和曲线

**技术要点**：
- 全局动画常量：`AppAnimations.fast = 100ms`, `medium = 200ms`, `slow = 300ms`
- 曲线统一使用 `Curves.easeInOut`
- Material `InkWell` / `InkResponse` 自带 splash
- 自定义动画使用 `AnimatedContainer` / `AnimatedOpacity`

**依赖**：S1.3
**估算**：3 SP

---

### S6.4: 离线模式保障（网络检测 + 功能降级）

**用户故事**：作为用户，我希望没有网络时仍能浏览关卡列表、查看和编辑配置，只有搜索和下载功能不可用。

**验收标准**：
- [ ] 检测网络可用性（定期 ping 或 connectivity 检查）
- [ ] 离线时所有本地功能正常：浏览列表、查看配置、编辑配置、打开目录
- [ ] 离线时搜索/下载按钮置灰 + tooltip 提示"需要网络连接"
- [ ] 网络恢复时自动解除限制（无需重启）
- [ ] 不产生未处理异常（NFR11）

**技术要点**：
- 轻量网络检测：尝试 DNS 解析或 HEAD 请求（非实时，每 30 秒一次）
- 网络状态通过 `ValueNotifier<bool>` 或 `Cubit<bool>` 全局广播
- 所有网络请求包裹 try-catch，`SocketException` → `AppError(type: network)`

**依赖**：S1.5（AppError）
**估算**：3 SP

---

### S6.5: 键盘导航支持（焦点管理、快捷键绑定）

**用户故事**：作为用户，我希望可以完全通过键盘操作应用——Tab 切换焦点、Enter 确认、Esc 返回，提高工作效率。

**验收标准**：
- [ ] Tab / Shift+Tab 在列表项、按钮、输入框间顺序切换焦点
- [ ] 焦点项有清晰的视觉高亮（紫色描边或背景色变化）
- [ ] Enter 激活当前焦点项（等同点击）
- [ ] Esc 关闭面板 / 清空搜索 / 取消弹窗
- [ ] Shift+F10 在焦点列表项上打开右键菜单
- [ ] Arrow Up/Down 在列表中移动焦点
- [ ] Ctrl+F 激活搜索框

**技术要点**：
- `FocusNode` 管理、`FocusTraversalGroup` 定义焦点顺序
- `Shortcuts` + `Actions` widget 绑定快捷键
- 面板打开时焦点陷入面板（focus trap），关闭后焦点返回触发元素

**依赖**：S2.7（搜索快捷键）、S5.1（面板 Esc 关闭）
**估算**：5 SP

---

### S6.6: 无障碍标注（semanticLabel + 屏幕阅读器兼容）

**用户故事**：作为使用屏幕阅读器的用户，我希望应用中的图标、状态指示和操作按钮都有语义标注，让我能理解界面内容。

**验收标准**：
- [ ] 所有 Icon 组件有 `semanticLabel`
- [ ] DifficultyBadge 的 semanticLabel 列出所有难度名称
- [ ] StatusIndicator 的 semanticLabel 描述当前状态
- [ ] LevelListTile 的 `Semantics` 包裹完整信息
- [ ] 操作按钮的 `tooltip` 即是无障碍标签
- [ ] 测试：启用 Windows 讲述人可导航和操作

**技术要点**：
- `Semantics` widget 包裹自定义组件
- `semanticLabel` 使用 L10n 文案（支持中英文）
- `ExcludeSemantics` 排除装饰性元素
- Material 组件自带基础无障碍支持，仅需补充自定义组件

**依赖**：S2.4, S2.5, S2.6（自定义组件）
**估算**：3 SP

---

## E7: 媒体播放与同步校准 (Media Playback & Sync) — Growth

### S7.1: media_kit 集成与播放器服务封装

**用户故事**：作为开发者，我需要将 media_kit 集成到项目中，并提供一个服务封装层管理播放器实例的创建、配置和释放。

**验收标准**：
- [ ] `media_kit` + `media_kit_video` + `media_kit_libs_windows_video` 依赖添加
- [ ] `PlayerService` 类封装 `Player` 和 `VideoController` 的生命周期
- [ ] 提供方法：`createAudioPlayer()`, `createVideoPlayer()`, `dispose()`
- [ ] 播放器配置：缓冲策略、音量、播放速率
- [ ] 确保 dispose 后无内存泄漏（NFR15）
- [ ] Windows 平台编译和运行验证

**技术要点**：
- `MediaKit.ensureInitialized()` 在 `main.dart`
- 播放器实例池管理，避免重复创建
- dispose 时确保底层 native 资源释放

**依赖**：S1.5（Services 层）
**估算**：5 SP

---

### S7.2: 音频预览功能（play/pause/seek）

**用户故事**：作为用户，我希望在选中关卡时能直接试听其音乐，确认是否是我要配置视频的歌曲。

**验收标准**：
- [ ] 面板中提供音频播放器控件（play/pause 按钮、进度条、时间显示）
- [ ] 播放关卡目录下的音频文件（.ogg / .egg）
- [ ] 支持 seek（点击进度条跳转）
- [ ] 切换关卡时自动停止当前播放
- [ ] 离开页面时自动停止播放并释放资源
- [ ] 播放器 UI 简洁，不占用过多面板空间

**技术要点**：
- 使用 `PlayerService.createAudioPlayer()`
- `Player.open(Media(filePath))` 打开本地文件
- `Player.stream.position` / `Player.stream.duration` 绑定进度条
- `Player.seek(position)` 实现跳转

**依赖**：S7.1, E5（面板展示）
**估算**：3 SP

---

### S7.3: 视频预览功能（play/pause/seek）

**用户故事**：作为用户，我希望能预览已下载的视频，确认内容和画质是否满意。

**验收标准**：
- [ ] 面板中提供视频播放区域 + 控件
- [ ] 播放关卡目录下的视频文件（.mp4 / .mkv / .webm）
- [ ] 视频区域响应面板宽度（350px 内自适应）
- [ ] 支持 play/pause/seek
- [ ] 离开面板时停止播放并释放资源

**技术要点**：
- `Video` widget 嵌入面板
- `VideoController` 绑定 `Player`
- 面板宽度约束下的视频 aspect ratio 处理

**依赖**：S7.1, E5
**估算**：3 SP

---

### S7.4: 分声道同步校准 UI（双播放器 + 偏移滑块）

**用户故事**：作为用户，我希望能同时听到关卡音乐和视频音轨，通过调整偏移量让它们完美同步。

**验收标准**：
- [ ] 双播放器方案：音频播放器（左声道）+ 视频播放器（右声道）
- [ ] 偏移量调整 UI：滑块（粗调 ±5s）+ 精确输入框（±1ms）
- [ ] 调整偏移量时实时应用（一个播放器 seek 偏移）
- [ ] 显示当前偏移值（正值 = 视频提前，负值 = 视频延后）
- [ ] 播放/暂停/重置按钮
- [ ] 操作指引文案（L10n）

**技术要点**：
- 分声道：`Player.setAudioDevice()` 或 audio filter 路由到左/右声道
- 偏移实现：`Player.seek(position + offset)` 同步两个播放器
- `Slider` + `TextFormField` 双输入控件

**依赖**：S7.2, S7.3
**估算**：8 SP

---

### S7.5: 偏移值保存到 cinema-video.json

**用户故事**：作为用户，我希望校准好的偏移值能保存到配置文件，这样 Beat Saber 的 Cinema 插件能正确使用。

**验收标准**：
- [ ] "保存偏移"按钮将当前偏移值写入 cinema-video.json 的 `offset` 字段
- [ ] 使用原子写入（S4.4）
- [ ] 保存成功后 SnackBar 确认
- [ ] 已有 offset 值时显示"覆盖"确认
- [ ] 偏移值单位为毫秒（整数）

**技术要点**：
- 读取现有 config → `copyWith(offset: newOffset)` → 原子写入
- 与 S4.1 的 `CinemaVideoConfig` 模型配合

**依赖**：S7.4, S4.1, S4.4
**估算**：2 SP

---

### S7.6: 播放器资源生命周期管理

**用户故事**：作为用户，我希望在离开校准页面或关闭应用时，播放器资源被正确释放，不会导致内存泄漏或音频残留。

**验收标准**：
- [ ] 离开校准面板时自动停止播放并 dispose 两个播放器
- [ ] 应用关闭时 dispose 所有活跃播放器（NFR15）
- [ ] dispose 后 native 库资源释放（无内存泄漏）
- [ ] 重新打开校准面板时创建新播放器实例
- [ ] 异常中断（如崩溃）后下次启动无残留进程

**技术要点**：
- `PlayerService` 维护活跃播放器列表
- 注册到应用关闭流程（S1.7）
- `Player.dispose()` 在 `PanelCubit` 关闭时调用

**依赖**：S7.1, S1.7（关闭流程）
**估算**：2 SP

---

## E8: 播放列表管理 (Playlist Management) — Growth

### S8.1: .bplist 文件解析服务

**用户故事**：作为开发者，我需要能解析 Beat Saber 的 .bplist 播放列表格式，提取歌曲列表和难度信息。

**验收标准**：
- [ ] 解析 .bplist JSON 格式（Base64 编码的封面 + 歌曲列表）
- [ ] 提取：播放列表名称、封面（可选）、歌曲列表（hash + 难度）
- [ ] 通过 hash 关联本地 CustomLevels 目录
- [ ] 防御性解析：格式异常降级处理
- [ ] 支持批量解析多个 .bplist 文件

**技术要点**：
- .bplist 是 JSON 格式：`{ playlistTitle, songs: [{ hash, difficulties: [{characteristic, name}] }] }`
- hash 匹配：遍历 CustomLevels 目录的 info.dat 中的 hash 字段
- 使用 CacheService 缓存 hash 索引

**依赖**：S2.2（CacheService 提供 hash 索引）
**估算**：3 SP

---

### S8.2: 播放列表浏览页面（列表 + 详情）

**用户故事**：作为用户，我希望能浏览所有本地播放列表，点击查看其中包含的歌曲。

**验收标准**：
- [ ] NavigationRail 新增"播放列表"tab
- [ ] 播放列表页面：左侧列表展示所有 .bplist 文件
- [ ] 每个播放列表显示：名称、歌曲数量、封面缩略图（如有）
- [ ] 点击播放列表在面板中显示歌曲详情列表
- [ ] 歌曲列表复用 LevelListTile 组件

**技术要点**：
- 新建 `PlaylistBloc`（event/state sealed class）
- .bplist 文件扫描：`Directory(playlistsPath).listSync()` 过滤 `.bplist`
- 播放列表路径：`{beatSaberPath}/Playlists/`

**依赖**：S8.1, S1.1（NavigationRail 新 tab）
**估算**：5 SP

---

### S8.3: 播放列表歌曲视频状态展示

**用户故事**：作为用户，我希望在播放列表详情中看到每首歌的就绪状态和待处理原因，快速定位并处理未配置或未下载的歌曲。

**验收标准**：
- [ ] 播放列表歌曲列表中复用与“全部歌曲列表”一致的列表组件和交互
- [ ] 播放列表级别统计：已就绪 / 待处理 / 总数
- [ ] 待处理状态可细分并展示原因：未配置、未下载
- [ ] 可一键筛选待处理歌曲与仅未配置歌曲
- [ ] 映射结果具备可解释性：hash 优先、名称兜底、冲突不误判（NFR19）

**技术要点**：
- 通过 hash 匹配查询本地关卡，名称兜底作为二级匹配策略
- 冲突（同名多关卡）场景输出“需人工确认”，不自动错误绑定

**依赖**：S8.2, S2.6（StatusIndicator）
**估算**：3 SP

---

### S8.4: 关卡目录批量导出功能

**用户故事**：作为用户，我希望将播放列表中所有歌曲的完整关卡目录（含视频配置）导出到指定文件夹，方便备份或分享。

**验收标准**：
- [ ] "导出"按钮触发文件夹选择对话框
- [ ] 复制播放列表涉及的所有关卡目录到目标文件夹
- [ ] 包含 info.dat、音频文件、cinema-video.json、视频文件（可选）
- [ ] 进度展示：N/总数
- [ ] 大文件（视频）提供跳过选项
- [ ] 导出完成后 SnackBar 确认

**技术要点**：
- `Directory.listSync()` + `File.copy()` 批量复制
- 使用 Isolate 防止阻塞 UI（大量文件时）
- 目标文件夹冲突处理：跳过 / 覆盖 / 重命名

**依赖**：S8.2
**估算**：5 SP

---

### S8.5: 播放列表未下载歌曲单曲下载（BeatSaver）

**用户故事**：作为用户，我希望对播放列表中的未下载歌曲直接执行下载，以便快速补齐缺失内容而不离开当前页面。

**验收标准**：
- [ ] 待处理（未下载）歌曲项提供“下载”按钮
- [ ] 点击后创建下载任务并在 1 秒内出现在下载管理（NFR16）
- [ ] 下载来源为 BeatSaver，失败时展示可理解错误并支持重试
- [ ] 下载中/完成/失败状态在列表中可见并与下载管理同步

**技术要点**：
- 复用现有下载管理能力，新增 playlist 场景任务来源标记
- 下载任务与歌曲条目建立可追踪关联（songName/hash）

**依赖**：S8.3, S3.3（DownloadManager）
**估算**：3 SP

---

### S8.6: 下载全部缺失歌曲与更新判定

**用户故事**：作为用户，我希望一键下载播放列表中全部缺失歌曲，并可选择是否更新已存在歌曲，以减少逐条操作成本。

**验收标准**：
- [ ] 页面提供“下载全部缺失歌曲”入口
- [ ] 支持“仅下载缺失”与“缺失+更新”两种模式
- [ ] 更新判定明确：文件缺失 / 版本不一致 / 用户强制更新
- [ ] 100 首缺失场景下队列稳定，单任务失败不影响全队列（NFR17）
- [ ] 任务创建后 1 秒内可在下载管理观察到完整任务集合

**技术要点**：
- 批量任务采用分批入队策略，防止瞬时队列抖动
- 在任务元数据中持久化判定原因，便于 UI 与日志追溯

**依赖**：S8.5
**估算**：5 SP

---

### S8.7: 增强导出（.bplist + 已下载歌曲目录 + 部分成功与重试）

**用户故事**：作为用户，我希望导出时同时携带 playlist 文件和可用歌曲目录，并在部分失败时拿到清单和重试入口，保证导出流程可恢复。

**验收标准**：
- [ ] 导出内容至少包含 `.bplist` 与已下载歌曲目录（FR40）
- [ ] 遇到部分缺失歌曲时不中断整体导出（FR41）
- [ ] 导出完成后 3 秒内生成失败清单（songName/hash/失败原因/时间戳）（NFR18）
- [ ] 提供“仅重试失败项”入口，触发后 1 秒内创建重试任务（NFR18）
- [ ] 导出结果反馈包含成功数、失败数和可操作下一步

**技术要点**：
- 导出流程采用“可用先行”策略：先复制可用内容，再汇总失败项
- 失败清单文件使用结构化格式，便于后续自动重试

**依赖**：S8.4, S8.5
**估算**：5 SP

---

## E9: 系统增强与引导 (System Enhancements) — Growth

### S9.1: Beat Saber 路径自动检测

**用户故事**：作为用户，我希望应用能自动找到我的 Beat Saber 安装位置，不需要手动设置路径。

**验收标准**：
- [ ] 检测 Steam 默认安装路径：`C:\Program Files (x86)\Steam\steamapps\common\Beat Saber`
- [ ] 检测 Steam 自定义库路径：读取 `steamapps/libraryfolders.vdf`
- [ ] 检测 Oculus 默认路径（如适用）
- [ ] 检测到多个安装时让用户选择
- [ ] 未检测到时回退到手动设置（S1.6）
- [ ] 检测结果可在设置页覆盖

**技术要点**：
- 解析 `libraryfolders.vdf`（Valve 的 KeyValues 格式）
- 检测顺序：Steam 默认 → Steam 自定义库 → Oculus → 放弃
- 所有路径使用 `path` 包拼接

**依赖**：S1.6（路径设置基础）
**估算**：3 SP

---

### S9.2: UpdateService（GitHub Releases API + SemVer 比较）

**用户故事**：作为系统，我需要在启动时检查 GitHub 上是否有新版本发布，并通知用户。

**验收标准**：
- [ ] 启动后延迟 5 秒检查更新（不影响启动速度）
- [ ] 调用 GitHub Releases API：`GET /repos/{owner}/{repo}/releases/latest`
- [ ] 解析返回的 tag_name 与当前版本进行 SemVer 比较
- [ ] 有新版本时发出通知（不自动更新）
- [ ] 检查间隔：每 24 小时最多一次（通过 shared_preferences 记录上次检查时间）
- [ ] 网络不可用时静默跳过

**技术要点**：
- 使用 `http` 包发送 GET 请求
- SemVer 比较：分割 major.minor.patch 逐段比较
- 当前版本从 `pubspec.yaml` 或编译时注入

**依赖**：S1.5（Services 层）
**估算**：3 SP

---

### S9.3: 更新通知 UI

**用户故事**：作为用户，我希望在有新版本可用时看到非侵入的通知，能查看更新内容并选择下载。

**验收标准**：
- [ ] 通知形式：NavigationRail 底部小徽标 + 设置页横幅
- [ ] 点击徽标或横幅显示更新详情（版本号、更新说明、下载链接）
- [ ] "查看详情"按钮打开 GitHub Releases 页面
- [ ] 可选"忽略此版本"（不再提示该版本）
- [ ] 通知不阻塞任何操作

**技术要点**：
- 徽标：`Badge` widget 在 NavigationRail 图标上
- 更新详情：使用 `showDialog` 或 BottomSheet
- "忽略此版本" 存储到 shared_preferences

**依赖**：S9.2, S1.1（NavigationRail）
**估算**：2 SP

---

### S9.4: 首次使用引导流程（3 步向导）

**用户故事**：作为新用户，我希望首次打开应用时有简洁的引导帮我完成基础配置，而不是面对空白界面不知所措。

**验收标准**：
- [ ] 检测首次使用（shared_preferences 标记）
- [ ] 3 步引导：
  1. 欢迎页 + 应用简介
  2. Beat Saber 路径设置（集成自动检测 S9.1）
  3. 功能概览（NavigationRail 各功能简介）
- [ ] 引导完成后标记已完成，不再显示
- [ ] 可从设置页重新触发引导
- [ ] 引导可随时跳过
- [ ] 全部文案 L10n

**技术要点**：
- `PageView` + `PageController` 实现步骤切换
- 步进指示器（dots）
- 全屏覆盖层或独立路由

**依赖**：S9.1, S1.6
**估算**：5 SP

---

# Step 4: 依赖验证与实施排序

## 依赖关系总图

```
S1.1 ──→ S1.2 ──→ S5.1 ──→ S5.5
                         ──→ S6.5
S1.3 ──→ S2.5 ──→ S2.4 ──→ S2.11
     ──→ S2.6      ↑       ──→ S6.6
     ──→ S5.3     S1.3
     ──→ S6.2
     ──→ S6.3

S1.5 ──→ S2.1 ──→ S2.2 ──→ S2.3 ──→ S2.7 ──→ S2.8 ──→ S5.6
     ──→ S3.1 ──→ S3.2 ──→ S3.3 ──→ S3.4(+E5)
     ──→ S4.4 ──→ S4.6        ──→ S3.5
     ──→ S5.2                  ──→ S3.6
     ──→ S6.1                  ──→ S3.7
     ──→ S6.4                  ──→ S3.9
                               ──→ S4.2(+S4.1,S4.4)
S1.6 ──→ S1.4 ──→ S1.7
S4.1 (无前置)
```

## 循环依赖检查

**结果：无循环依赖。** 所有 59 个 Story 形成有向无环图（DAG），可安全拓扑排序。

## 关键路径分析

**最长依赖链**（决定 MVP 最短工期）：

```
S1.5(3) → S2.1(5) → S2.2(5) → S2.3(5) → S2.7(3) → S2.8(3) → S5.6(3)
总计: 27 SP，7 个 Story 串联
```

**次关键路径**：

```
S1.5(3) → S3.1(3) → S3.2(8) → S3.3(5) → S3.4(5)
总计: 24 SP，5 个 Story 串联
```

**风险标注**：S3.2（YtDlpService 8SP）是单点最大 Story，考虑在 Sprint 内部优先启动。

## Sprint 实施计划

### Sprint 1: 基础架构（E1 核心）— 25 SP

**目标**：搭好 v2 骨架，后续所有 Epic 可并行展开。

| 周次 | Track A | Track B | 备注 |
|------|---------|---------|------|
| W1 | S1.1 路由重构 (5SP) | S1.3 主题系统 (3SP) + S1.5 Services+AppError (3SP) | 无依赖，并行 |
| W2 | S1.2 Row 布局 (3SP) ← S1.1 | S1.6 路径设置 (3SP) + S4.1 Config 模型 (3SP) | S4.1 提前做 |
| W3 | S1.4 窗口管理 (5SP) ← S1.6 | — | |

S1.7（关闭流程 3SP）延至 Sprint 3，因依赖 DownloadManager 运行时接口。

**Sprint 1 交付**：可运行的 v2 骨架 — NavigationRail 3 Tab 切换、暗色主题、窗口管理、Beat Saber 路径可设置。

---

### Sprint 2: 关卡列表引擎（E2 核心）— 34 SP

**目标**：核心列表功能完整可用。

| 周次 | Track A（数据层） | Track B（UI 组件层） | 备注 |
|------|-------------------|---------------------|------|
| W1 | S2.1 info.dat 解析 (5SP) | S2.5 DifficultyBadge (2SP) + S2.6 StatusIndicator (2SP) | 并行 |
| W2 | S2.2 CacheService (5SP) ← S2.1 | S2.4 LevelListTile (5SP) ← S1.3+S2.5+S2.6 | 并行 |
| W3 | S2.3 BLoC 重构 (5SP) ← S2.1+S2.2 | S2.11 骨架屏 (2SP) ← S2.4 | |
| W4 | S2.7 搜索 (3SP) + S2.9 排序 (2SP) ← S2.3 | S2.10 摘要栏 (2SP) ← S2.3 | |
| W5 | S2.8 筛选 (3SP) ← S2.3+S2.7 | — | |

**Sprint 2 交付**：完整关卡列表 — 500 首 3 秒加载、搜索/筛选/排序、骨架屏、摘要栏。

---

### Sprint 3: 搜索下载 + 配置管理（E3 + E4 核心）— 46 SP

**目标**：核心工作流闭环 — 搜索视频 → 下载 → 创建配置。

| 周次 | Track A（E3 服务层） | Track B（E4 + E3 辅助） | 备注 |
|------|---------------------|------------------------|------|
| W1 | S3.1 VideoRepo 接口 (3SP) + S3.2 YtDlpService 启动 (8SP) | S4.4 原子写入 (3SP) + S4.6 文件占用 (2SP) | S3.2 大 Story |
| W2 | S3.2 YtDlpService 续 | S3.8 错误映射 (3SP) ← S3.2(接口) | |
| W3 | S3.3 DownloadManager (5SP) ← S3.2 | S4.2 配置创建 (3SP) ← S4.1+S4.4 | |
| W4 | S3.5 URL 粘贴 (3SP) + S3.6 进度展示 (3SP) | S3.7 错误重试 (3SP) | |
| W5 | S3.9 遗留迁移 (5SP) | S1.7 关闭流程 (3SP) ← S1.4+DownloadManager | Sprint 1 延期项 |

S3.4（搜索面板 UI）依赖 E5 面板系统，延至 Sprint 4。

**Sprint 3 交付**：yt-dlp 服务层完整、下载队列可用、cinema-video.json 可创建、错误重试可用。

---

### Sprint 4: 面板菜单 + 体验反馈 + 集成（E5 + E6 + 收尾）— 48 SP

**目标**：面板交互完整、UX 打磨、MVP 全功能集成。

| 周次 | Track A（E5 面板） | Track B（E6 体验） | Track C（集成） |
|------|-------------------|-------------------|----------------|
| W1 | S5.1 PanelHost (5SP) + S5.2 PanelCubit (2SP) | S6.1 错误框架 (5SP) | — |
| W2 | S5.3 ContextMenu (3SP) + S5.4 菜单项 (3SP) | S6.2 空状态 (3SP) + S6.3 微交互 (3SP) | — |
| W3 | S5.5 霓虹效果 (2SP) | S6.4 离线模式 (3SP) | S3.4 搜索面板 UI (5SP) ← E5 就绪 |
| W4 | S5.6 延迟淡出 (3SP) | S6.5 键盘导航 (5SP) | S4.3 配置编辑 UI (3SP) + S4.5 文件信息 (2SP) ← E5 |
| W5 | — | S6.6 无障碍 (3SP) | MVP 集成测试 |

**Sprint 4 交付**：**MVP 完成** — 全部核心功能可用，面板、右键菜单、错误处理、空状态、键盘导航就绪。

---

### Sprint 5: 媒体播放（E7）— 23 SP

**目标**：音视频预览 + 同步校准。

| 周次 | Track A | Track B |
|------|---------|---------|
| W1 | S7.1 media_kit 集成 (5SP) | — |
| W2 | S7.2 音频预览 (3SP) | S7.3 视频预览 (3SP) | 并行 |
| W3 | S7.4 同步校准 UI (8SP) | — | 大 Story |
| W4 | S7.5 偏移保存 (2SP) | S7.6 资源管理 (2SP) | |

**Sprint 5 交付**：音视频预览 + 同步校准功能完整。

---

### Sprint 6: 播放列表 + 系统增强（E8 + E9）— 29 SP

**目标**：Growth 功能收尾。

| 周次 | Track A（E8 播放列表） | Track B（E9 系统） |
|------|----------------------|-------------------|
| W1 | S8.1 bplist 解析 (3SP) | S9.1 路径检测 (3SP) + S9.2 UpdateService (3SP) |
| W2 | S8.2 播放列表页面 (5SP) | S9.3 更新通知 (2SP) |
| W3 | S8.3 视频状态 (3SP) | S9.4 引导流程 (5SP) |
| W4 | S8.4 批量导出 (5SP) | — |

**Sprint 6 交付**：**全功能完成**。

---

## 风险矩阵

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| S3.2 YtDlpService (8SP) 复杂度高 | 阻塞 E3 全部下游 | Sprint 3 W1 最先启动，预留 buffer |
| S7.4 同步校准 (8SP) 技术不确定 | 分声道方案可能需要调研 | Sprint 5 前做技术 spike |
| media_kit Windows 兼容性 | 编译或运行问题 | Sprint 4 末做 E7 技术验证 |
| yt-dlp Bilibili 支持 | 搜索参数/解析可能不同 | S3.2 先做 YouTube，Bilibili 作为后续增量 |

## Story Point 分布总览

| Sprint | SP | 累计 | 里程碑 |
|--------|----|------|--------|
| Sprint 1 | 25 | 25 | v2 骨架可运行 |
| Sprint 2 | 34 | 59 | 列表引擎完整 |
| Sprint 3 | 46 | 105 | 搜索下载闭环 |
| Sprint 4 | 48 | 153 | **MVP 发布** |
| Sprint 5 | 23 | 176 | 媒体播放就绪 |
| Sprint 6 | 29 | 205 | **全功能发布** |

---

## E10: 实施质量与可维护性强化 (Post-MVP Hardening)

**目标**：在不回退既有功能的前提下，补齐实施规范、验收可测性与性能护栏，确保后续迭代可持续。

**覆盖来源**：`implementation-readiness-report-2026-03-21.md` 中的 Major/Minor 改进项（Q1-Q8）。

**Story 候选**：
- S10.1: 关键 Story 的 BDD 验收标准补全（Given/When/Then）
- S10.2: 大 Story 拆分与边界重定义（以 S3.2 模式为模板）
- S10.3: 跨 Epic 前向依赖显式治理（依赖标注 + 顺序规则）
- S10.4: 核心流程回归护栏（下载/写入配置/面板流转）
- S10.5: 大规模列表性能护栏（3000+ 数据量验证）
- S10.6: Playlist 下载后增量刷新与匹配一致性修复
- S10.7: 音频播放浮动控制条（Mini Player）
- S10.8: 配置视频缺失时的列表直达下载与工具分流

### S10.1: 关键 Story 的 BDD 验收标准补全（Given/When/Then）

**用户故事**：作为开发者，我希望关键用户流程的验收标准采用 Given/When/Then 格式，便于一致理解、自动化测试和评审。

**验收标准**：
- [ ] 为 E2/E3/E4/E5 中关键 Story 增补 Given/When/Then 场景，不删除现有 checklist
- [ ] 每个关键 Story 至少包含 1 条成功路径和 1 条失败/边界路径
- [ ] 场景覆盖关键约束：超时、文件锁、降级显示、面板切换
- [ ] BDD 文案中不出现实现细节，保持面向行为与结果

**依赖**：无
**估算**：3 SP

---

### S10.2: 大 Story 拆分与边界重定义（以 S3.2 模式为模板）

**用户故事**：作为产品与开发协作方，我希望将过大的 Story 拆分成可并行、可验证的子 Story，降低单点风险。

**验收标准**：
- [ ] 定义 Story 拆分规则（触发条件、拆分粒度、验收边界）
- [ ] 产出 1 个模板示例：将“搜索 + 下载 + 进程管理”拆分为独立子能力
- [ ] 明确每个子 Story 的输入/输出、依赖、完成定义（DoD）
- [ ] 新增 Story 不与既有已完成 Story 冲突或重复

**拆分规则（可执行版）**：

1) 触发条件（满足任一即触发拆分）
- 估算 > 5 SP（默认阈值）
- 单 Story 同时覆盖 2 个以上能力域（如“搜索 + 下载 + 进程治理”）
- 涉及 2 个以上模块边界（如 Services + UI + 状态管理）
- 验收标准无法在一个评审周期内完成可验证闭环

2) 拆分粒度
- 一条子 Story 只承载一个可独立交付的用户结果
- 每条子 Story 在单个生命周期内可完成（`backlog -> done`）
- 子 Story 之间通过“显式依赖”连接，不使用隐式顺序

3) 验收边界模板
- 行为边界：只描述用户可观察行为，不写实现细节
- 数据边界：明确输入来源、输出结构、异常输入处理
- 错误边界：明确失败路径、提示策略、是否可重试
- 性能边界：给出可判定阈值（如超时、响应时间）

4) 质量门槛（INVEST）
- Independent：可独立开发/验证
- Valuable：存在明确用户价值
- Small：规模可控（建议 <= 5 SP）
- Testable：至少 1 条成功 + 1 条失败/边界场景

**S3.2 拆分模板（示例）**：

- 原始 Story：`S3.2 YtDlpService 实现（搜索 + 下载 + 进程管理）`（8 SP）
- 拆分目标：降低串行阻塞，提升可评审性与可回归性

**拆分前后对照矩阵**：

| 维度 | 拆分前（S3.2 单体） | 拆分后（A/B/C 子 Story） |
|---|---|---|
| 能力边界 | 搜索 + 下载 + 进程治理耦合在一条 Story | A=搜索解析，B=下载进度，C=进程治理 |
| 可并行性 | 低（高串行阻塞） | 中-高（A/B/C 可分段并行推进） |
| 验收可测性 | 单体 AC 覆盖范围过大 | 每条子 Story 各自具备成功/失败路径 |
| 风险控制 | 单点失败影响整条 Story | 失败可局部隔离，降低回滚半径 |
| 交付节奏 | 大步交付，评审负担高 | 小步交付，评审与回归更可控 |

**子 Story A（模板）**：搜索能力与结果解析
- 目标：完成搜索命令封装、结果解析、超时与错误映射
- 输入：`query`、`platform`、超时配置（30s）
- 输出：结构化搜索结果（title/url/duration/thumbnail）或可理解错误
- 依赖 Story：`S3.1 VideoRepository`
- 阻塞 Story：无
- 解锁条件：搜索命令与结果解析在超时/异常场景下可独立验收
- DoD：
  - 搜索命令可执行并返回结构化结果
  - 超时与不可用场景可观测、可重试
  - 文案与术语符合 L10n 与现有规则
- BDD：
  - Given 用户输入关键词  
    When 发起搜索且进程在超时内返回  
    Then 返回结构化结果并保持 UI 可响应
  - Given 网络不可用或执行文件不可用  
    When 发起搜索  
    Then 返回可理解错误并提供重试路径

**子 Story B（模板）**：下载链路与进度输出
- 目标：完成下载命令封装、进度解析、任务状态更新
- 输入：`url`、`outputPath`、下载超时（10min）
- 输出：任务状态流（pending/downloading/completed/failed/cancelled）
- 依赖 Story：子 Story A，`S3.3`
- 阻塞 Story：子 Story A
- 解锁条件：下载状态流可被上层 UI 消费并完成失败可重试闭环
- DoD：
  - 下载可启动、可取消、可观察进度
  - 失败状态有明确原因与重试入口
  - 关键状态流转可被 UI 正确消费
- BDD：
  - Given 用户确认下载  
    When 下载开始并持续输出进度  
    Then 任务状态应实时变化并最终进入 completed/failed
  - Given 任务超过超时阈值  
    When 系统执行超时治理  
    Then 任务应被取消并进入 failed，且提示可重试

**子 Story C（模板）**：进程生命周期治理
- 目标：统一治理 Process 启停、跟踪、超时与清理，防止僵尸进程
- 输入：进程句柄、任务 ID、超时策略、取消信号
- 输出：可追踪的进程状态与清理结果
- 依赖 Story：子 Story A/B，`S1.7`
- 阻塞 Story：无
- 解锁条件：进程跟踪、取消、关闭清理均可独立验证且无僵尸进程
- DoD：
  - 维护进程跟踪映射并支持按任务取消
  - 应用关闭时可批量回收活跃进程
  - 无残留僵尸进程与未处理异常
- BDD：
  - Given 系统存在活跃下载进程  
    When 用户触发取消或应用关闭  
    Then 所有相关进程应被回收并记录最终状态
  - Given 进程异常退出  
    When 系统接收退出信号  
    Then 任务应进入失败态并返回可理解错误

**冲突与重复校验（E1-E9 done 对照）**：
- 不重建 E3 已完成能力，只输出“拆分方法与模板”，不回滚既有实现
- 不改动 E1-E9 状态与历史 Story 文本
- 新增内容仅落在 E10 治理条目，作为后续新增 Story 的模板规则
- 对既有能力采用“复用与引用”策略，不创建语义重复 Story

**依赖**：S10.1
**估算**：3 SP

---

### S10.3: 跨 Epic 前向依赖显式治理（依赖标注 + 顺序规则）

**用户故事**：作为迭代规划者，我希望所有跨 Epic 依赖都被显式标注并可追踪，避免执行顺序误判。

**验收标准**：
- [ ] 在受影响 Story 中显式标注“依赖 Story / 阻塞 Story / 解锁条件”
- [ ] 输出统一依赖标注格式并应用到后续新增 Story
- [ ] 对已识别前向依赖（如 E3↔E5、E4↔E5）给出执行顺序建议
- [ ] 依赖变更同步到 sprint tracking（避免状态与依赖不一致）

**统一依赖标注格式（落地标准）**：

- 依赖 Story：当前 Story 依赖的上游 Story（必填）
- 阻塞 Story：当前 Story 完成后可解锁的下游 Story（可空）
- 解锁条件：可观察、可验证、可判定的推进条件（必填）
- 依赖类型：mandatory / discretionary / internal / external（必填）
- 风险等级：high / medium / low（必填）

**跨 Epic 依赖地图（当前识别）**：

| 依赖链 | 上游能力 | 下游消费点 | 主要风险 | 建议顺序 |
|---|---|---|---|---|
| E3 -> E5 | 搜索/下载能力与状态流 | 面板入口与上下文菜单触发 | 能力存在但入口不可用 | 先固化 E3 能力，再落地 E5 入口 |
| E4 -> E5 | 配置读写与原子写入 | 面板编辑与保存反馈 | UI 可编辑但保存链路不完整 | 先验证 E4 写入链路，再开放 E5 编辑交互 |
| E8 -> E2 | playlist 歌曲映射到 level 元信息 | 复用全量歌曲列表展示体验 | 重复实现列表渲染/状态逻辑 | 先复用 E2 元信息与列表组件，再扩展 E8 视图 |

**用户补充场景：playlist 元信息复用（强制案例）**：

- 场景要求：playlist 根据歌曲信息获取对应歌曲元信息，并显示与“全部歌曲列表”一致的界面。
- 依赖 Story：`8-2-playlist-browse-page`、`8-3-playlist-video-status`、`2-3-custom-levels-bloc-refactor`、`2-4-level-list-tile`
- 阻塞 Story：后续 playlist 体验优化与回归护栏条目
- 解锁条件：
  - [ ] playlist 项可稳定映射到 `LevelMetadata`
  - [ ] playlist 视图复用既有列表组件（而非重复实现）
  - [ ] 状态图标与筛选/排序语义与全量列表一致
- 依赖类型：mandatory
- 风险等级：high

**执行顺序建议（可直接执行）**：

1. 先解锁“数据映射”能力（上游）
- 明确 playlist song -> level metadata 的映射规则与缺失兜底
- 对映射失败场景给出降级策略（不阻断整体列表）

2. 再解锁“视图复用”能力（下游）
- 复用 E2 列表项组件与状态表达（难度徽章、状态图标、交互语义）
- 禁止在 E8 新建重复列表渲染逻辑

3. 最后做“状态一致性”收口
- 对筛选/排序/状态标记做跨页面一致性检查
- 确保 playlist 与全量列表的可观察结果一致

**阻塞解除标准（unblock criteria）**：

- blocked-by-data：映射规则已定义并通过样例校验
- blocked-by-ui-reuse：已确认复用 E2 组件，无重复渲染实现
- blocked-by-status-sync：依赖字段与状态流转在 sprint tracking 同步一致

**sprint tracking 同步规则**：

- 依赖字段变更时，必须同步校验 `sprint-status.yaml` 的对应 Story 状态
- 若依赖未满足（可在故事文档中标记 blocked 原因），`sprint-status.yaml` 不得将该 Story 置为 done
- 建议保留最小同步检查清单：
  - [ ] 依赖 Story 是否存在且状态可消费
  - [ ] 阻塞 Story 是否按顺序解锁
  - [ ] 解锁条件是否有可观察证据
  - [ ] 状态变更是否与依赖关系一致

**依赖**：S10.2
**估算**：2 SP

---

### S10.4: 核心流程回归护栏（下载/写入配置/面板流转）

**用户故事**：作为维护者，我希望关键业务链路有最小可执行回归护栏，避免后续改动引入隐性回归。

**验收标准**：
- [ ] 定义 3 条关键回归链路：搜索下载、配置写入、面板开关与切换
- [ ] 每条链路包含“预期状态变化”与“失败时用户反馈”
- [ ] 回归检查清单可在开发完成后快速人工执行
- [ ] 护栏内容与现有 Project Context 规则一致（不引入冲突）

**依赖**：S10.3
**依赖标注（沿用 S10.3 标准）**：
- 依赖 Story：`10-3-cross-epic-dependency-governance`
- 阻塞 Story：`10-5-large-scale-list-performance-guardrails`
- 解锁条件：已输出 3 条核心回归链路并具备可执行检查清单
- 依赖类型：mandatory
- 风险等级：medium
**估算**：3 SP

---

### S10.5: 大规模列表与 Playlist 匹配性能护栏（3000+ 数据量验证）

**用户故事**：作为性能关注用户，我希望在超大数据量下（关卡列表 + Playlist 匹配）也能保持可接受的操作体验，避免版本演进后性能退化。

**验收标准**：
- [ ] 定义 3000+ 关卡场景下的性能验证基线（加载、筛选、排序）与 Playlist 匹配验证基线（首次进入、重进、下载后刷新）
- [ ] 明确可接受阈值与退化告警条件（与 PRD NFR1/NFR2 对齐，首次加载 < 3s、缓存命中 < 1s）
- [ ] 输出针对列表渲染、匹配索引构建、下载完成后状态刷新链路的优化优先级建议
- [ ] 验证项覆盖缓存命中与非命中两类路径，并覆盖单曲下载与批量下载完成后的列表一致性

**依赖**：S10.4
**依赖标注（沿用 S10.3 标准）**：
- 依赖 Story：`10-4-core-flow-regression-guardrails`
- 阻塞 Story：无
- 解锁条件：回归护栏基线已固化，可在 3000+ 数据量场景复用
- 依赖类型：mandatory
- 风险等级：medium
**估算**：5 SP

---

### S10.6: Playlist 下载后增量刷新与匹配一致性修复

**用户故事**：作为 Playlist 用户，我希望歌曲下载完成后列表状态立即更新，未安装计数同步减少，且不需要重启或手动重复进入页面。

**验收标准**：
- [ ] 单曲下载完成后 1 秒内可观察到对应 Playlist 条目从“未安装”转为“已匹配/已就绪”
- [ ] 批量下载完成后，Playlist 未安装计数在任务稳定后自动收敛，不要求手动刷新页面
- [ ] 下载状态更新链路避免重复全量重解析（以增量更新为主），并保持 UI 可响应
- [ ] 匹配策略保持 `key -> hash -> songName` 顺序，且与当前 PRD/UX 状态语义一致
- [ ] 覆盖异常场景：下载失败、任务取消、任务完成但输出目录已存在

**依赖**：S10.3
**依赖标注（沿用 S10.3 标准）**：
- 依赖 Story：`10-3-cross-epic-dependency-governance`
- 阻塞 Story：无
- 解锁条件：完成下载任务状态到 Playlist 视图状态的端到端一致性校验
- 依赖类型：mandatory
- 风险等级：high
**估算**：5 SP

---

### S10.7: 音频播放浮动控制条（Mini Player）

**用户故事**：作为用户，我希望在播放歌曲时底部出现一个迷你播放浮动条，即使滚动列表也能随时停止播放；当播放停止后该浮动条自动隐藏，避免界面干扰。

**验收标准**：
- [ ] 音频开始播放后显示底部浮动控制条；音频停止/结束后自动隐藏
- [ ] 浮动条仅提供“停止”控制，不包含上一首、下一首、暂停按钮
- [ ] 浮动条左侧显示当前歌曲圆形封面，播放中持续旋转
- [ ] 在用户滚动列表或切换同页内容时，浮动条保持可见并可点击停止
- [ ] 实现遵循现有播放器生命周期管理，不引入资源泄漏或残留播放

**依赖**：S7.2, S7.6
**依赖标注（沿用 S10.3 标准）**：
- 依赖 Story：`7-2-audio-preview`, `7-6-player-resource-lifecycle`
- 阻塞 Story：无
- 解锁条件：浮动条显示/隐藏、停止控制、封面旋转与资源回收可端到端验证
- 依赖类型：mandatory
- 风险等级：medium
**估算**：3 SP

---

### S10.8: 配置视频缺失时的列表直达下载与工具分流

**用户故事**：作为用户，我希望当歌曲存在 `cinema-video.json` 但视频文件缺失时，能在歌曲列表直接点击下载，并由系统按 `videoUrl` 自动选择合适下载工具，这样我可以在列表内快速补齐视频而无需切换上下文。

**验收标准**：
- [ ] 对 `configuredMissingFile` 状态歌曲，在列表项提供可点击下载入口（不仅限右键菜单）
- [ ] 点击后 1 秒内任务进入下载管理，并在该歌曲项体现“下载中”防重复触发
- [ ] URL 为直链视频文件（如 `.mp4/.mkv/.webm`）时，走 HTTP 直连下载链路
- [ ] URL 为站点页面/短链等非直链时，走现有下载队列（yt-dlp）链路
- [ ] 下载完成后自动回写 `cinema-video.json.videoFile` 并刷新列表状态；失败/取消有可见反馈

**依赖**：S3.3, S4.4, S8.3
**依赖标注（沿用 S10.3 标准）**：
- 依赖 Story：`3-3-download-manager`, `4-4-atomic-file-write-service`, `8-3-playlist-video-status`
- 阻塞 Story：无
- 解锁条件：从列表点击到状态收敛（下载中->已配置）在单曲场景端到端可验证
- 依赖类型：mandatory
- 风险等级：medium
**估算**：3 SP
