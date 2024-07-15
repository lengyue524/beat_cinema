import 'dart:io';

import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/custom_level/custom_level.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'custom_levels_event.dart';
part 'custom_levels_state.dart';

class CustomLevelsBloc extends Bloc<CustomLevelsEvent, CustomLevelsState> {
  CustomLevelsBloc() : super(CustomLevelsInitial()) {
    on<ReloadCustomLevelsEvent>((event, emit) async {
      emit(CustomLevelsLoaded(await loadCustomLevels(event.beatSaberPath)));
    });
  }

  Future<List<LevelInfo>> loadCustomLevels(String beatSaverPath) async {
    List<LevelInfo> customLevels = [];
    String customLevelsPath =
        "$beatSaverPath${Platform.pathSeparator}${Constants.dataDir}${Platform.pathSeparator}${Constants.customLevelsDir}";
    Directory customLevelsDir = Directory(customLevelsPath);
    if (!(await customLevelsDir.exists())) {
      return customLevels;
    }
    List<FileSystemEntity> levelsDir = await customLevelsDir.list().toList();
    for (FileSystemEntity levelDir in levelsDir) {
      if (levelDir is Directory) {
        String infoPath =
            "${levelDir.path}${Platform.pathSeparator}${Constants.customLevelInfoName}";
        try {
          File info = File(infoPath);
          String levelInfoStr = await info.readAsString();
          CustomLevel level = CustomLevel.fromJson(levelInfoStr);
          LevelInfo levelInfo = LevelInfo(levelDir.path, level, null);
          // 读取ciname配置
          String cinemaConfigPath =
              "${levelDir.path}${Platform.pathSeparator}${Constants.cinemaConfigFileName}";
          File cinemaInfo = File(cinemaConfigPath);
          if (await cinemaInfo.exists()) {
            String cinemaConfigStr = await cinemaInfo.readAsString();
            CinemaConfig cinemaConfig = CinemaConfig.fromJson(cinemaConfigStr);
            levelInfo.cinemaConfig = cinemaConfig;
          }
          customLevels.add(levelInfo);
        } catch (e) {
          log.shout(e);
        }
      }
    }
    return customLevels;
  }
}
