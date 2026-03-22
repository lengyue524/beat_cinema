---
project_name: 'beat_cinema'
user_name: 'Lihang'
date: '2026-03-09'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow_rules', 'critical_rules']
status: 'complete'
rule_count: 68
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Flutter**: >=3.0.6 <4.0.0, Material 3 (seed color: `Color.fromARGB(255, 123, 0, 255)`)
- **State Management**: bloc ^9.1.0 + flutter_bloc ^9.1.1 (sealed class events/states, part/part of 分文件)
- **Routing**: go_router ^15.1.2 (ShellRoute + GoRoute, BlocProvider 在路由级注入)
- **L10n**: intl ^0.20.2 + flutter_localizations + flutter_gen (ARB: en/zh)
  - `flutter: generate: true` 启用自动生成，禁止手动创建 app_localizations.dart
  - 禁止引入 `intl_generator`（已废弃），使用 `flutter gen-l10n`
  - 字符串格式化使用 sprintf ^7.0.0，保持与现有代码一致
- **Persistence**: 仅 shared_preferences ^2.2.3，禁止引入其他存储方案
- **JSON**: json_annotation ^4.9.0 + json_serializable ^6.8.0 (dev)
  - 注意：现有模型均为手写 fromMap/toMap，未使用 code generation
  - build_runner ^2.4.10 存在但当前无活跃 codegen 流程
- **UI Utilities**: file_picker ^8.3.2, url_launcher ^6.2.6
- **Logging**: logging ^1.2.0
- **Linting**: flutter_lints ^4.0.0
- **External Tools**: yt-dlp (外部可执行文件，Windows: yt-dlp.exe)
- **Target Platform**: Windows (primary) — 核心功能依赖 dart:io + dart:isolate，不支持 Web
- **Platform dirs**: android/ios/linux/web 目录为脚手架生成，非活跃目标

## Critical Implementation Rules

### Dart Language Rules

- **Null Safety**: 项目使用 sound null safety，所有类型默认 non-nullable
- **Sealed Classes**: Event 和 State 使用 `sealed class` 基类 + `final class` 子类
  - 例: `sealed class CustomLevelsEvent` → `final class LoadCustomLevelsEvent extends CustomLevelsEvent`
- **Part 指令**: BLoC 和 Cubit 均使用 `part` / `part of` 将 state (及 event) 拆分到独立文件
  - bloc 文件: `part 'xxx_event.dart'; part 'xxx_state.dart';`
  - cubit 文件: `part 'xxx_state.dart';`
  - event/state 文件: `part of 'xxx_bloc.dart';` 或 `part of 'xxx_cubit.dart';`
- **BLoC vs Cubit 选择**:
  - 简单状态切换（无复杂事件） → Cubit（直接方法调用）
  - 复杂异步操作/多事件驱动 → BLoC（sealed event 驱动）
- **Import 风格**: 使用包导入 `package:beat_cinema/...`，禁止相对导入
- **异步模式**: 使用 `async/await`；仅在调用外部进程 (yt-dlp) 时使用 `Isolate.run()`，文件 I/O 直接 await
- **错误处理**: try/catch 包裹异步操作，错误通过 emit 错误 State 传播，禁止抛异常到 UI 层
- **模型序列化**: 手写 `fromMap`/`toMap`，字段必须有默认值容错 (`map['key'] ?? defaultValue`)，因为数据来自外部不可控文件
- **枚举**: 使用增强枚举 (enhanced enums)，带字段和方法
- **常量类**: `Constants` 类使用 `static const`，不使用顶级常量
- **日志**: 使用 `logging` 包的 `Logger` 类，禁止 `print()`
- **测试**: 当前无测试代码，无 mock 框架。需要测试时需先提议安装依赖 (bloc_test, mocktail 等)
- **已知问题**: `Constants.dart` 文件名大写 C，导入用小写 — 大小写敏感系统会出错

### Framework-Specific Rules (Flutter + BLoC + GoRouter)

**应用架构:**
- 根 Widget: `BlocProvider<AppBloc>` 在 `main.dart` 中提供全局状态
- `AppBloc` 管理应用级配置：locale、Beat Saber 路径、搜索平台、视频质量
- `AppBloc` 有两个核心状态: `AppInitial`（加载中） → `AppLaunchComplated`（就绪）

**路由模式:**
- `GoRouter` 配置在 `App/Route/app_route.dart`
- `ShellRoute` 提供共享 Scaffold + AppBar ("BeatCinema")，子路由页面禁止再嵌套 Scaffold
- 模块级 BlocProvider 在路由 builder 中注入（非全局），使用 `MultiBlocProvider`
- 路由级 BlocProvider 随路由销毁自动 close，禁止手动 close
- 路由间数据传递使用 `GoRouterState.extra` + 类型转换（需加 null check）

**BLoC 使用规则:**
- `context.watch<T>()` 仅在 `build()` 方法内使用（响应式重建）
- `context.read<T>()` 用于事件触发（按钮回调等），禁止在 build 内使用
- `BlocBuilder` / `BlocListener` / `BlocConsumer` 监听状态变化

**UI 模式:**
- 使用 `NavigationRail` 做侧边导航（桌面端优化），禁止用 `BottomNavigationBar`
- 页面使用 `StatelessWidget` 或 `StatefulWidget`，禁止引入新的 Widget 基类
- 颜色使用 `Theme.of(context).colorScheme`，禁止硬编码颜色值
- 本地化: `AppLocalizations.of(context)?.keyName ?? 'English fallback'`
  - 新功能必须同时更新 `intl_en.arb` 和 `intl_zh.arb`

**BLoC Provider 注入层级:**
- `AppBloc` → 根级 (main.dart)，生命周期与应用一致
- `MenuCubit` + `CustomLevelsBloc` → 首页路由级
- `CinemaSearchBloc` → 在 `CinemaSearchPage` 内部自建

**模块结构约定:**
- 每个模块在 `lib/Modules/ModuleName/` 下（目录名 PascalCase）
- 模块包含: 页面文件 (`xxx_page.dart`) + `bloc/` 或 `cubit/` 子目录
- Manager 类使用 `static final` 实例模式 + 内部状态 Map 管理并发操作

### Testing Rules

- **当前状态**: 项目无测试代码，`test/` 目录为空
- **测试框架**: 仅 `flutter_test`（SDK 自带），未安装 `bloc_test`、`mocktail`
- **可测试性要求（新代码）**:
  - 新 BLoC/Cubit 应通过构造函数参数注入依赖（路径、配置等），避免内部硬编码
  - 现有 BLoC 直接读文件系统是遗留风格，新代码应避免
- **测试优先级（如需添加）**:
  1. BLoC 单元测试（event → state 转换）— 需安装 `bloc_test`
  2. Model `fromMap`/`toMap` 边界测试（缺失字段、null 值、类型错误）— 最易获得价值
  3. Widget 测试 — 受 `dart:io` 限制，桌面应用中投入产出比低
  4. 集成测试 — 未来可用 `integration_test`（SDK 自带）
- **外部进程**: yt-dlp 和 `Isolate.run()` 相关代码需 mock，禁止测试中调用真实进程
- **SharedPreferences**: 测试时使用内置 `SharedPreferences.setMockInitialValues({})`，无需额外包
- **路径注意**: `Constants` 中路径为 Windows 格式 (`\`)，测试需注意平台差异
- **代理行为**: 实现功能时不要主动添加测试，除非明确被要求；但新代码应保持可测试性

### Code Quality & Style Rules

**文件与目录命名:**
- 功能模块目录: PascalCase (`Modules/CinemaSearch/`, `Modules/CustomLevels/`)
- 数据模型目录: snake_case (`models/custom_level/`, `models/cinema_config/`)
- 所有 .dart 文件: snake_case (`custom_levels_bloc.dart`, `cinema_search_page.dart`)
- 页面文件后缀: `_page.dart`（禁止 `_screen.dart`、`_view.dart`）
- BLoC 文件组合: `xxx_bloc.dart` + `xxx_event.dart` + `xxx_state.dart`
- Cubit 文件组合: `xxx_cubit.dart` + `xxx_state.dart`
- ARB 本地化键: snake_case (`download_complete`，禁止 camelCase)

**代码组织与职责边界:**
- `lib/App/` — 应用级组件（AppBloc、路由、根页面）
- `lib/Common/` — 共享常量和工具（新常量统一加到 `Constants` 类）
- `lib/l10n/` — 国际化 ARB 文件和生成代码
- `lib/models/` — 纯数据类（无业务逻辑）
- `lib/Modules/` — 完整功能模块（页面+状态管理+业务逻辑）

**新文件创建位置:**
- 纯数据结构 → `lib/models/feature_name/`
- 功能页面+BLoC → `lib/Modules/FeatureName/`
- 共享工具/常量 → `lib/Common/`
- 应用级组件 → `lib/App/`

**导入顺序:**
1. `dart:` 核心库
2. `package:` 第三方包
3. `package:beat_cinema/` 项目内包
4. 每组之间空行分隔

**Lint 配置:**
- 使用 `flutter_lints` ^4.0.0 (`package:flutter_lints/flutter.yaml`)
- 无自定义覆盖，遵循默认 lint 规则

### Development Workflow Rules

**Git 工作流:**
- 使用 Git 进行版本控制，Tag 用于版本标记（如 `v0.0.3`）
- 代理不要主动提交代码，除非用户明确要求
- 版本号 (`pubspec.yaml` version) 由用户手动管理，代理禁止擅自修改
- 不要修改 `.gitignore`，除非用户要求

**构建与运行:**
- 开发运行: `flutter run -d windows`（禁止 `-d chrome` 或其他设备）
- 本地化生成: `flutter gen-l10n`（由 `flutter: generate: true` 自动触发）
- 依赖安装: `flutter pub get`（修改 pubspec.yaml 后必须执行或提醒用户）
- 禁止运行 `build_runner build`（除非明确要求）

**修改后的重启提示:**
- 修改 `main.dart`/路由/BLoC 构造函数/BlocProvider → 提示热重启 (Shift+R)
- 修改 Widget build 方法 → 热重载即可 (r)
- 修改 ARB 文件 → 提示需要 `flutter gen-l10n` 或重启应用

**开发环境:**
- 平台: Windows (PowerShell)
- 禁止使用 Linux 特有命令（如 `rm -rf`），使用 PowerShell 等效命令
- yt-dlp.exe 为外部工具，路径在 `Constants` 中配置，代理不要尝试安装或假设在 PATH 中

**依赖管理:**
- 添加新依赖前需告知用户，不可擅自引入
- 禁止引入已废弃的包（如 `intl_generator`）
- pubspec.yaml 版本约束使用 `^` 语法

### Critical Don't-Miss Rules

**反模式（禁止事项）:**
- 禁止引入 `intl_generator` 包（已废弃，使用 `flutter gen-l10n`）
- 禁止手动创建 `app_localizations.dart`（由 flutter_gen 自动生成）
- 禁止在子路由页面中嵌套 `Scaffold`（ShellRoute 已提供）
- 禁止在 `build()` 方法内使用 `context.read()`
- 禁止在 BLoC 中抛异常到 UI 层（使用错误 State）
- 禁止在 `models/` 中添加业务逻辑
- 禁止使用 `print()` 调试（使用 `Logger`）

**已知拼写错误（保持一致，新代码引用时必须使用错误拼写）:**
- `AppLaunchComplated` — 应为 `Completed`
- `CinameSearch` — 事件名中，应为 `Cinema`
- `seatchText` — `FilterCustomLevelsEvent` 中，应为 `searchText`

**路由安全:**
- `GoRouterState.extra` 可能为 null（deep link、后退键），页面必须处理 `extra == null`
- `SharedPreferences` 键名定义在 `Constants` 中，新增前必须检查已有键名避免冲突

**外部数据安全:**
- Beat Saber `info.dat` 格式可能随版本变化，解析必须容错
- yt-dlp JSON 输出格式不可控，所有字段必须有默认值
- 文件路径可能包含中文或特殊字符，需要处理编码
- `cinema-video.json` 文件名固定不可改，写入目标为关卡目录，使用 `CinemaConfig.toMap()` 序列化

**Windows 平台边界条件:**
- `Process.run` 输出可能是 GBK 编码（中文 Windows），不能假设 UTF-8
- Beat Saber 路径可能未设置或目录不存在，所有文件操作需先验证路径有效性
- Beat Saber 运行时文件可能被锁定，文件操作必须 catch `FileSystemException`
- 网络操作需处理超时、yt-dlp 非零退出码、部分下载等异常

**性能注意:**
- `Isolate.run()` 仅用于调用外部进程（yt-dlp），不要用于文件 I/O
- `CustomLevelsBloc` 扫描文件系统可能很慢（大量自定义关卡），注意异步处理
- 避免在 `BlocBuilder` 中做重计算，使用 `buildWhen` 过滤不必要的重建

**并发安全:**
- `CinemaDownloadManager` 的状态 Map 管理多个并发下载，修改时注意 async/await 交错执行可能导致状态不一致

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Update this file if new patterns emerge

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack changes
- Review quarterly for outdated rules
- Remove rules that become obvious over time

Last Updated: 2026-03-09
