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
  final List<LevelInfo> allLevels = [];

  CustomLevelsBloc() : super(CustomLevelsInitial()) {
    on<ReloadCustomLevelsEvent>((event, emit) async {
      allLevels.clear();
      allLevels.addAll(await loadCustomLevels(event.beatSaberPath));
      emit(CustomLevelsLoaded(allLevels));
    });
    on<FilterCustomLevelsEvent>((event, emit) {
      if (event.seatchText != null && event.seatchText!.isNotEmpty) {
        var filtedLevels = allLevels.where((level) {
          var songNameLowcase = level.customLevel.songName?.toLowerCase();
          var songSubNameLowCase = level.customLevel.songSubName?.toLowerCase();
          var songAuthorNameLowCase =
              level.customLevel.songAuthorName?.toLowerCase();
          var searchTextLowCase = event.seatchText?.toLowerCase();
          return songNameLowcase != null &&
                  songNameLowcase.contains(searchTextLowCase!) ||
              songSubNameLowCase != null &&
                  songSubNameLowCase.contains(searchTextLowCase!) ||
              songAuthorNameLowCase != null &&
                  songAuthorNameLowCase.contains(searchTextLowCase!);
        }).toList();
        emit(CustomLevelsLoaded(filtedLevels));
      } else {
        emit(CustomLevelsLoaded(allLevels));
      }
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
          log.e(e);
        }
      }
    }
    return customLevels;
  }
}
