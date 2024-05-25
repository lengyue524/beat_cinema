import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/root_page.dart';
import 'package:beat_cinema/Modules/Config/bloc/config_bloc.dart';
import 'package:beat_cinema/Modules/Menu/cubit/menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc(),
      child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
        if (state is AppLaunchComplated) {
          return MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 7, 160, 255)),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale((state as AppLaunchComplated).local.name),
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ConfigBloc>(
                  create: (context) => ConfigBloc(),
                ),
                BlocProvider<MenuCubit>(
                  create: (context) => MenuCubit(),
                ),
              ],
              child: const RootPage(),
            ),
          );
        } else {
          AppBloc.loadAppLocal(context);
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
                BlocProvider<ConfigBloc>(
                  create: (context) => ConfigBloc(),
                ),
                BlocProvider<MenuCubit>(
                  create: (context) => MenuCubit(),
                ),
              ],
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: Center(child: Text("Loading", style: Theme.of(context).textTheme.titleLarge,)),
              ),
            ),
          );
        }
      }),
    );
  }
}
