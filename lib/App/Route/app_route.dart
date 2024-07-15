import 'package:beat_cinema/App/root_page.dart';
import 'package:beat_cinema/Modules/CinemaSearch/cinema_search_page.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/Modules/Menu/cubit/menu_cubit.dart';
import 'package:beat_cinema/models/custom_level/custom_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoutePath {
  static String home = "/";
  static String homeSearch = "/home/search";
}

class AppRouter {
  GoRouter appRouter() {
    return GoRouter(initialLocation: RoutePath.home, routes: [
      ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
                appBar: AppBar(
                  leading: state.fullPath == RoutePath.home
                      ? null
                      : IconButton(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(Icons.arrow_back)),
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  title: const Text("BeatCinema"),
                ),
                body: child);
          },
          routes: [
            GoRoute(
                path: RoutePath.home,
                builder: (context, state) {
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider<MenuCubit>(
                        create: (context) => MenuCubit(),
                      ),
                      BlocProvider<CustomLevelsBloc>(
                        create: (context) => CustomLevelsBloc(),
                      ),
                    ],
                    child: const RootPage(),
                  );
                }),
            GoRoute(
              path: RoutePath.homeSearch,
              builder: (context, state) {
                LevelInfo levelInfo;
                if (state.extra is String) {
                  levelInfo = LevelInfo.fromJson(state.extra as String);
                } else {
                  levelInfo = state.extra as LevelInfo;
                }
                return CinemaSearchPage(levelInfo: levelInfo);
              },
            )
          ])
    ]);
  }
}
