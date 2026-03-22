# Story 1.1: StatefulShellRoute + NavigationRail 路由重构

Status: review

## Story

As a 用户,
I want 通过侧边导航在功能页面间切换时，之前页面的滚动位置和输入状态保持不变,
so that 我不会因为切换页面而丢失工作上下文。

## Acceptance Criteria

1. ShellRoute 替换为 StatefulShellRoute，每个 tab 对应独立 Navigator 分支
2. IndexedStack 保持所有页面的 widget 状态（切换后再返回，列表滚动位置不变）
3. NavigationRail 固定 72px 宽，仅图标模式（labelType: none），悬停显示 Tooltip
4. 至少 3 个 tab：关卡列表（首页）、下载管理（占位）、设置
5. 页面切换无可感知延迟（< 16ms，单帧渲染）— IndexedStack 本身满足此要求
6. 所有用户可见文案使用 L10n ARB key（NavigationRail tooltip 文案）
7. 现有 CinemaSearchPage 的路由跳转（GoRouterState.extra 传参）继续正常工作
8. MenuCubit 被移除，导航完全由 StatefulShellRoute 内置 index 管理
9. 现有 AppBloc 根级注入和 AppBar 共享行为不受影响

## Tasks / Subtasks

- [x] Task 1: 重构 app_route.dart — ShellRoute → StatefulShellRoute (AC: #1, #4, #7)
  - [x] 1.1: 定义 3 个 StatefulShellBranch（关卡列表、下载管理、设置），各带独立 GlobalKey<NavigatorState>
  - [x] 1.2: 关卡列表分支保留 CustomLevelsBloc BlocProvider（提升至 shell builder 层级）
  - [x] 1.3: 下载管理分支创建占位页面 DownloadsPage
  - [x] 1.4: 设置分支路由到现有 ConfigPage
  - [x] 1.5: CinemaSearchPage 作为关卡列表分支的子路由（保持 GoRouterState.extra 传参）
  - [x] 1.6: ShellRoute 的 Scaffold + AppBar 逻辑迁移到 StatefulShellRoute 的 builder
- [x] Task 2: 重构 root_page.dart — 绑定 StatefulShellRoute 导航状态 (AC: #2, #3, #5, #8)
  - [x] 2.1: root_page.dart 改为接收 StatefulNavigationShell child 参数
  - [x] 2.2: NavigationRail selectedIndex 绑定 navigationShell.currentIndex
  - [x] 2.3: onDestinationSelected 调用 navigationShell.goBranch(index)
  - [x] 2.4: NavigationRail 配置: 仅图标模式（labelType: none）、固定 72px 宽
  - [x] 2.5: 每个 destination 添加 tooltip（L10n 文案，label 作为 tooltip）
  - [x] 2.6: Row 布局: NavigationRail | VerticalDivider | Expanded(child) — child 即 navigationShell
  - [x] 2.7: 移除对 MenuCubit 的依赖（不再 import、不再 BlocBuilder）
- [x] Task 3: 删除 MenuCubit 及关联代码 (AC: #8)
  - [x] 3.1: 删除 lib/Modules/Menu/ 整个目录（menu_cubit.dart + menu_state.dart）
  - [x] 3.2: 删除 lib/App/main_page.dart（其页面切换逻辑已由 StatefulShellRoute 替代）
  - [x] 3.3: 清理所有文件中对 MenuCubit / MenuState / MenuItem / MainPage 的 import 引用
  - [x] 3.4: main.dart 中移除加载屏的 MenuCubit BlocProvider
- [x] Task 4: L10n — 添加 NavigationRail tooltip ARB key (AC: #6)
  - [x] 4.1: intl_en.arb 添加: nav_levels "Levels", nav_downloads "Downloads", nav_settings "Settings"
  - [x] 4.2: intl_zh.arb 添加: nav_levels "关卡列表", nav_downloads "下载管理", nav_settings "设置"
- [x] Task 5: 创建下载管理占位页面 (AC: #4)
  - [x] 5.1: 创建 lib/Modules/Downloads/downloads_page.dart — StatelessWidget 居中占位文案
- [x] Task 6: 验证与回归 (AC: #2, #7, #9)
  - [x] 6.1: flutter analyze 通过，无新增 error/warning
  - [x] 6.2: CinemaSearchPage 路由路径更新为 /search（子路由），GoRouterState.extra 传参逻辑不变
  - [x] 6.3: AppBloc 在根级注入，CustomLevelsBloc 在 shell builder 注入 — 所有分支均可访问
  - [x] 6.4: AppBar 共享行为迁移到 StatefulShellRoute builder，返回按钮基于 rootPaths 判断
  - [x] 6.5: L10n gen-l10n 执行成功，nav_levels/nav_downloads/nav_settings getter 已生成

## Dev Notes

### 核心实现策略

**当前架构（需替换）：**
- `app_route.dart`: `ShellRoute` 包裹 `Scaffold(appBar: ..., body: child)`，内含两个 `GoRoute`（home, homeSearch）
- `root_page.dart`: `BlocBuilder<MenuCubit>` 控制 `NavigationRail.selectedIndex`，`Expanded(child: MainPage())`
- `main_page.dart`: `BlocBuilder<MenuCubit>` 根据 `MenuItem` 枚举 switch 返回不同页面（CustomLevelsPage / ConfigPage）
- `MenuCubit`: 简单 Cubit，`setMenu(MenuItem)` → `emit(MenuState)`
- 页面切换时 widget 树完全重建，无状态保持

**目标架构：**
- `app_route.dart`: `StatefulShellRoute.indexedStack(branches: [...], builder: ...)` 替代 ShellRoute
- `root_page.dart`: 接收 `StatefulNavigationShell` 参数，NavigationRail 直接绑定 shell 的 currentIndex/goBranch
- `MenuCubit` 和 `MainPage` 完全删除
- `IndexedStack`（StatefulShellRoute 内置）自动保持页面状态

### 关键 API 参考

**StatefulShellRoute.indexedStack 构造函数：**
```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return ScaffoldWithNavigation(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(
      navigatorKey: _levelsSectionNavigatorKey,
      routes: [ GoRoute(path: '/', ...) ],
    ),
    StatefulShellBranch(
      navigatorKey: _downloadsSectionNavigatorKey,
      routes: [ GoRoute(path: '/downloads', ...) ],
    ),
    StatefulShellBranch(
      navigatorKey: _settingsSectionNavigatorKey,
      routes: [ GoRoute(path: '/settings', ...) ],
    ),
  ],
)
```

**NavigationShell 使用：**
```dart
// 在 builder 中获取 StatefulNavigationShell
navigationShell.currentIndex  // 当前选中分支
navigationShell.goBranch(index)  // 切换分支
// navigationShell 本身是 Widget，放入 Expanded 即可
```

**NavigationRail 绑定：**
```dart
NavigationRail(
  selectedIndex: navigationShell.currentIndex,
  onDestinationSelected: (index) => navigationShell.goBranch(index),
  labelType: NavigationRailLabelType.none, // 仅图标
  minWidth: 72,
  destinations: [...],
)
```

### ⚠️ 关键注意事项

1. **已知拼写 `AppLaunchComplated`**：不可修改，新代码引用时必须使用此拼写
2. **CinemaSearchPage 子路由**：必须保留在关卡列表分支内作为子路由，`GoRouterState.extra` 传 `LevelInfo` 对象，页面内有 `extra is String` 判断需保留
3. **BlocProvider 注入位置**：
   - `CustomLevelsBloc` 当前在 home 路由的 builder 中创建 → 迁移到关卡列表分支的根路由 builder 中
   - `AppBloc` 在 main.dart 根级 → 不动
4. **ShellRoute 的 Scaffold+AppBar**：当前 ShellRoute builder 提供共享 Scaffold + AppBar（标题 "BeatCinema"，条件返回按钮）→ 迁移到 StatefulShellRoute builder 中
5. **导入风格**：使用 `package:beat_cinema/...` 绝对导入，禁止相对导入
6. **main.dart 加载屏**：`AppInitial` 状态时有 `MenuCubit` BlocProvider 需清理（第53-68行）
7. **下载管理页面**：仅创建占位，不实现功能（功能在 E3 实现）
8. **go_router 版本**：^15.1.2 已内置 StatefulShellRoute，无需升级

### 现有文件清单（需修改）

| 文件 | 操作 | 说明 |
|------|------|------|
| lib/App/Route/app_route.dart | 重写 | ShellRoute → StatefulShellRoute.indexedStack |
| lib/App/root_page.dart | 重写 | MenuCubit → StatefulNavigationShell 绑定 |
| lib/App/main_page.dart | 删除 | 逻辑由 StatefulShellRoute 替代 |
| lib/Modules/Menu/cubit/menu_cubit.dart | 删除 | 导航由 StatefulShellRoute 管理 |
| lib/Modules/Menu/cubit/menu_state.dart | 删除 | 随 MenuCubit 一起删除 |
| lib/main.dart | 修改 | 清理 MenuCubit import 和加载屏 BlocProvider |
| lib/l10n/intl_en.arb | 修改 | 添加 nav tooltip key |
| lib/l10n/intl_zh.arb | 修改 | 添加 nav tooltip key |
| lib/Modules/Downloads/downloads_page.dart | 新建 | 下载管理占位页 |

### 现有代码关键片段

**app_route.dart 当前结构：**
- `RoutePath.home = "/"`，`RoutePath.homeSearch = "/home/search"`
- ShellRoute builder 提供 `Scaffold(appBar: AppBar(title: "BeatCinema", leading: 条件返回按钮), body: child)`
- home 路由 builder 中创建 `MultiBlocProvider([MenuCubit, CustomLevelsBloc], child: RootPage)`
- homeSearch 路由 builder 中从 `state.extra` 解析 `LevelInfo`

**root_page.dart 当前结构：**
- `BlocBuilder<MenuCubit>` → `Row [ NavigationRail(2 destinations) | VerticalDivider | Expanded(MainPage) ]`
- NavigationRail destinations: Home (Icon.home), Settings (Icon.settings)
- selectedIndex 绑定 `state.menu.index`
- onDestinationSelected 调用 `MenuCubit.setMenu(MenuItem.values[value])`

**main.dart 加载屏（AppInitial 状态）：**
- 第63-68行有 `MenuCubit` BlocProvider 包裹 Loading 容器 — 需清理

### Project Structure Notes

- 新增 `lib/Modules/Downloads/` 目录（PascalCase，符合模块命名规范）
- `lib/Modules/Menu/` 目录整体删除
- `lib/App/main_page.dart` 删除
- 路由文件位置不变：`lib/App/Route/app_route.dart`
- RoutePath 类可扩展新路径（/downloads, /settings）

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#UI架构] — StatefulShellRoute + Row 布局决策
- [Source: _bmad-output/planning-artifacts/epics.md#S1.1] — Story 规格和验收标准
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#主布局] — Row[Rail(72px)|Expanded|Panel] 布局定义
- [Source: _bmad-output/project-context.md#路由模式] — GoRouter 使用规则和 BlocProvider 注入层级
- [Source: _bmad-output/project-context.md#已知拼写错误] — AppLaunchComplated 等拼写保持

## Dev Agent Record

### Agent Model Used

claude-4.6-opus-high-thinking (Cursor Agent)

### Debug Log References

- flutter analyze: 0 new errors, 2 pre-existing issues (unreachable_switch_default in cinema_search_bloc, avoid_print in main.dart)
- flutter gen-l10n: success, 3 new ARB keys generated

### Completion Notes List

- ShellRoute → StatefulShellRoute.indexedStack 重构完成，3 个分支各带独立 NavigatorKey
- CustomLevelsBloc 提升到 shell builder 层级（BlocProvider 包裹 Scaffold），确保 ConfigPage 的刷新按钮跨分支可访问
- NavigationRail 绑定 navigationShell.currentIndex/goBranch，72px 图标模式，L10n tooltip
- RoutePath.homeSearch 从 /home/search 改为 /search（sub-route of / with relative path 'search'）
- AppBar 返回按钮根据 rootPaths set 判断是否显示
- MenuCubit + MainPage 完全删除，导航完全由 StatefulShellRoute 管理
- main.dart 加载屏移除 MultiBlocProvider 包裹（仅含 MenuCubit，已无需要）
- 新增 Downloads 占位页面 lib/Modules/Downloads/downloads_page.dart

### File List

**新建:**
- lib/Modules/Downloads/downloads_page.dart

**重写:**
- lib/App/Route/app_route.dart (ShellRoute → StatefulShellRoute.indexedStack)
- lib/App/root_page.dart (MenuCubit → StatefulNavigationShell)

**修改:**
- lib/main.dart (移除 MenuCubit import 和加载屏 BlocProvider)
- lib/l10n/intl_en.arb (添加 nav_levels, nav_downloads, nav_settings)
- lib/l10n/intl_zh.arb (添加 nav_levels, nav_downloads, nav_settings)

**删除:**
- lib/App/main_page.dart
- lib/Modules/Menu/cubit/menu_cubit.dart
- lib/Modules/Menu/cubit/menu_state.dart

**自动生成（flutter gen-l10n）:**
- .dart_tool/flutter_gen/gen_l10n/app_localizations.dart
- .dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart
- .dart_tool/flutter_gen/gen_l10n/app_localizations_zh.dart
