import 'dart:io';

import 'package:beat_cinema/Config/bloc/config_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ConfigBloc, ConfigInitial>(builder: (context, state) {
          return Row(children: [
            Expanded(child: Text("Beat Saber目录${state.beatSaberPath}")),
            ElevatedButton(onPressed: () async {
              String? beatSaberDir = await FilePicker.platform.getDirectoryPath();
              // 检查Beat Saber.exe是否在目录下
              String beatSaberExePath = "$beatSaberDir${Platform.pathSeparator}Beat Saber.exe";
              bool beatSaberExeExists = await File(beatSaberExePath).exists();
              if (beatSaberExeExists) {
                if (context.mounted) context.read<ConfigBloc>().add(BeatSaberFolderSetted(beatSaberDir));
              } else {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("未找到Beat Saber.exe")));
              }
            }, child: const Text("选择目录"))
          ]);
        })
      ],
    );
  }
}