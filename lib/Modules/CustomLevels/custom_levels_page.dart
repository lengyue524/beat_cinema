import 'dart:io';
import 'package:beat_cinema/App/Route/app_route.dart';
import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomLevelsPage extends StatelessWidget {
  const CustomLevelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomLevelsBloc, CustomLevelsState>(
      builder: (context, state) {
        if (state is CustomLevelsInitial) {
          loadCustomLevels(context);
          return initPage(context);
        } else {
          return listPage(context, state as CustomLevelsLoaded);
        }
      },
    );
  }

  // 检查beat saber目录是否设置，并且加载
  void loadCustomLevels(BuildContext context) {
    var beatSaberPath =
        (context.read<AppBloc>().state as AppLaunchComplated).beatSaberPath;
    if (beatSaberPath != null) {
      context
          .read<CustomLevelsBloc>()
          .add(ReloadCustomLevelsEvent(beatSaberPath));
    }
  }

  Widget initPage(BuildContext context) {
    var beatSaverPath = context.read<AppBloc>().beatSaberPath;
    if (beatSaverPath == null || beatSaverPath.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.set_game_path_tips));
    } else {
      return const Center(
          child: SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator.adaptive()));
    }
  }

  Widget listPage(BuildContext context, CustomLevelsLoaded state) {
    return Column(children: [
      Row(
        children: [
          const SizedBox(width: 48, height: 48, child: Icon(Icons.filter)),
          Expanded(
              child: TextField(
            decoration: InputDecoration.collapsed(
                hintText: AppLocalizations.of(context)!.filter_tips),
            onChanged: (value) {
              context
                  .read<CustomLevelsBloc>()
                  .add(FilterCustomLevelsEvent(value));
            },
            style: Theme.of(context).textTheme.bodyLarge,
          )),
        ],
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          itemExtent: 54,
          itemCount: state.levels.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: 54,
              child: Row(
                children: [
                  Image.file(
                    File(
                        "${state.levels[index].levelPath}${Platform.pathSeparator}${state.levels[index].customLevel.coverImageFilename}"),
                    width: 48,
                    height: 48,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: Text(
                              state.levels[index].customLevel.songName ?? ""),
                        )),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  if (state.levels[index].cinemaConfig ==
                                      null) {
                                    context.push(RoutePath.homeSearch,
                                        extra: state.levels[index]);
                                  } else {
                                    log.info("ciname编辑");
                                  }
                                },
                                icon: Icon(
                                    state.levels[index].cinemaConfig == null
                                        ? Icons.movie_edit
                                        : Icons.movie)),
                            IconButton(
                                onPressed: () {
                                  // launchUrl(Uri(
                                  //     scheme: "file",
                                  //     path: state.levels[index].levelPath));
                                  Process.run("explorer", [state.levels[index].levelPath]);
                                },
                                icon: const Icon(Icons.folder))
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}
