import 'dart:io';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Modules/Config/bloc/config_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16),
      children: [
        BlocBuilder<ConfigBloc, ConfigInitial>(builder: (context, state) {
          return SizedBox(
            height: 48,
            child: Row(children: [
              Expanded(
                  child: Text(
                      "${AppLocalizations.of(context)?.beat_saber_dir}${state.beatSaberPath}",
                      style: Theme.of(context).textTheme.bodyMedium)),
              ElevatedButton(
                  onPressed: () async {
                    String? beatSaberDir =
                        await FilePicker.platform.getDirectoryPath();
                    // 检查Beat Saber.exe是否在目录下
                    String beatSaberExePath =
                        "$beatSaberDir${Platform.pathSeparator}${Constants.beatSaberExe}";
                    bool beatSaberExeExists =
                        await File(beatSaberExePath).exists();
                    if (beatSaberExeExists) {
                      if (context.mounted) {
                        context
                            .read<ConfigBloc>()
                            .add(BeatSaberFolderSetted(beatSaberDir));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(sprintf(
                                AppLocalizations.of(context)!.exe_not_found,
                                [Constants.beatSaberExe]))));
                      }
                    }
                  },
                  child: Text("${AppLocalizations.of(context)?.choose_dir}",
                      style: Theme.of(context).textTheme.titleMedium))
            ]),
          );
        }),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                  child: Text("${AppLocalizations.of(context)?.languages}")),
              BlocBuilder<AppBloc, AppState>(
                builder: (context, state) {
                  return DropdownButton(
                      value:
                          (context.read<AppBloc>().state as AppLaunchComplated)
                              .local,
                      items:
                          AppLocal.values.map<DropdownMenuItem<AppLocal>>((e) {
                        return DropdownMenuItem<AppLocal>(
                            value: e, child: Text(e.name));
                      }).toList(),
                      onChanged: (e) {
                        AppBloc.saveAppLocal(e!);
                        context.read<AppBloc>().add(AppLoadComplatedEvent(e));
                      });
                },
              )
            ],
          ),
        )
      ],
    );
  }
}
