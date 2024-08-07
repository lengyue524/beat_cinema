import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/Route/app_route.dart';
import 'package:beat_cinema/Modules/Menu/cubit/menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final AppRouter _appRouter = AppRouter();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc(),
      child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
        if (state is AppLaunchComplated) {
          return MaterialApp.router(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 123, 0, 255)),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale((state).local.name),
            routerConfig: _appRouter.appRouter(),
            // home: MultiBlocProvider(
            //   providers: [
            //     BlocProvider<ConfigBloc>(
            //       create: (context) => ConfigBloc(),
            //     ),
            //     BlocProvider<MenuCubit>(
            //       create: (context) => MenuCubit(),
            //     ),
            //     BlocProvider<CustomLevelsBloc>(
            //       create: (context) => CustomLevelsBloc(),
            //     ),
            //   ],
            //   child: const RootPage(),
            // ),
          );
        } else {
          AppBloc.loadAppConfig(context);
          return MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 7, 160, 255)),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<MenuCubit>(
                  create: (context) => MenuCubit(),
                ),
              ],
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                    child: Text(
                  "Loading",
                  style: Theme.of(context).textTheme.titleLarge,
                )),
              ),
            ),
          );
        }
      }),
    );
  }
}
