import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/Route/app_route.dart';
import 'package:beat_cinema/App/theme/app_theme.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Services/services/app_lifecycle_service.dart';
import 'package:beat_cinema/Services/services/player_service.dart';
import 'package:beat_cinema/Services/services/window_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:media_kit/media_kit.dart';

final windowService = WindowService();
late final AppLifecycleService lifecycleService;
final playerService = PlayerService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await initAppLogging();

  await windowService.init();
  lifecycleService = AppLifecycleService(windowService)
    ..playerService = playerService;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final GoRouter _router = AppRouter().appRouter();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = AppBloc();
        AppBloc.loadAppConfig(bloc);
        return bloc;
      },
      child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
        if (state is AppLaunchComplated) {
          return MaterialApp.router(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale((state).local.name),
            routerConfig: _router,
          );
        } else {
          return MaterialApp(
            theme: AppTheme.loading(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                  child: Text(
                "Loading",
                style: Theme.of(context).textTheme.titleLarge,
              )),
            ),
          );
        }
      }),
    );
  }
}
