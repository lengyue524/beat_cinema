import 'package:beat_cinema/App/root_page.dart';
import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/CinemaSearch/cinema_search_page.dart';
import 'package:beat_cinema/Modules/Config/config_page.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/custom_levels_page.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/Modules/Downloads/downloads_page.dart';
import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Modules/Playlists/playlist_page.dart';
import 'package:beat_cinema/Services/services/cache_service.dart';
import 'package:beat_cinema/Services/services/level_parse_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _levelsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'levels');
final GlobalKey<NavigatorState> _playlistsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'playlists');
final GlobalKey<NavigatorState> _downloadsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'downloads');
final GlobalKey<NavigatorState> _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

class RoutePath {
  static const String home = "/";
  static const String homeSearch = "/search";
  static const String playlists = "/playlists";
  static const String downloads = "/downloads";
  static const String settings = "/settings";
}

class AppRouter {
  GoRouter appRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: RoutePath.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            final appBloc = context.read<AppBloc>();
            final rootPaths = {
              RoutePath.home,
              RoutePath.playlists,
              RoutePath.downloads,
              RoutePath.settings,
            };
            final showBackButton = !rootPaths.contains(state.uri.path);

            return MultiBlocProvider(
              providers: [
                BlocProvider<CustomLevelsBloc>(
                  create: (context) => CustomLevelsBloc(
                    parseService: LevelParseService(),
                    cacheService: CacheService(),
                  ),
                ),
                BlocProvider<PlaylistBloc>(
                  create: (context) => PlaylistBloc(
                    downloadManager: appBloc.downloadManager,
                  ),
                ),
              ],
              child: Scaffold(
                appBar: AppBar(
                  leading: showBackButton
                      ? IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                        )
                      : null,
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  title: const Text("BeatCinema"),
                ),
                body: RootPage(navigationShell: navigationShell),
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: _levelsNavigatorKey,
              routes: [
                GoRoute(
                  path: RoutePath.home,
                  builder: (context, state) => const CustomLevelsPage(),
                  routes: [
                    GoRoute(
                      path: 'search',
                      builder: (context, state) {
                        LevelInfo levelInfo;
                        if (state.extra is String) {
                          levelInfo =
                              LevelInfo.fromJson(state.extra as String);
                        } else {
                          levelInfo = state.extra as LevelInfo;
                        }
                        return CinemaSearchPage(levelInfo: levelInfo);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _playlistsNavigatorKey,
              routes: [
                GoRoute(
                  path: RoutePath.playlists,
                  builder: (context, state) => const PlaylistPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _downloadsNavigatorKey,
              routes: [
                GoRoute(
                  path: RoutePath.downloads,
                  builder: (context, state) => DownloadsPage(
                    downloadManager: context.read<AppBloc>().downloadManager,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _settingsNavigatorKey,
              routes: [
                GoRoute(
                  path: RoutePath.settings,
                  builder: (context, state) => const ConfigPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
