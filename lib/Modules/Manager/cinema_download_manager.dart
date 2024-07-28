import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/dlp_video_info/dlp_video_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

class CinemaDownloadManager {
  CinemaDownloadManager._internal();
  factory CinemaDownloadManager() => _instance;
  static final CinemaDownloadManager _instance =
      CinemaDownloadManager._internal();

  void startCinimaDownload(
      BuildContext context,
      String beatSaberPath,
      DlpVideoInfo videoInfo,
      LevelInfo levelInfo,
      CinemaVideoQuality quality) async {
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((value) {
      String msg = String.fromCharCodes(value);
      if (msg == Constants.sendPortDoneString) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(sprintf(
                AppLocalizations.of(context)!.download_complete,
                [videoInfo.title]))));
      } else {
        log.d("downloadMSG:$msg");
      }
    }, onDone: () {
      receivePort.close();
    }, onError: (e) {
      receivePort.close();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sprintf(AppLocalizations.of(context)!.download_error,
              [videoInfo.title, e.toString()]))));
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sprintf(
            AppLocalizations.of(context)!.download_start, [videoInfo.title]))));
    await compute(
        _downloadCinemaWithYTDlp,
        CinemaDownloadParams(receivePort.sendPort, videoInfo, levelInfo,
            beatSaberPath, quality));
  }

  static void _downloadCinemaWithYTDlp(CinemaDownloadParams params) async {
    // 下载视频
    String dlpPath =
        "${params.beatSaberPath}${Platform.pathSeparator}${Constants.libsDir}${Platform.pathSeparator}${Constants.ytDlpName}";
    List<String> dlpParams = [];
    dlpParams.add(params.videoInfo.originalUrl!);
    dlpParams.add(_qualityParams(params.videoInfo, params.quality));
    dlpParams.add("-o");
    dlpParams.add(
        "${params.levelInfo.levelPath}${Platform.pathSeparator}${params.videoInfo.title}");
    dlpParams.add("--no-cache-dir");
    dlpParams.add("--no-playlist");
    dlpParams.add("--no-part");
    dlpParams.add("--recode-video");
    dlpParams.add("mp4");
    dlpParams.add("--no-mtime");
    dlpParams.add("--socket-timeout");
    dlpParams.add("10");
    var youtubeConfig = await youtubeDLConfig(params.beatSaberPath);
    if (youtubeConfig != null && youtubeConfig.isNotEmpty) {
      dlpParams.add(youtubeConfig);
    }
    Completer comp = Completer();
    Process pr = await Process.start(dlpPath, dlpParams);
    pr.stdout.listen((value) {
      params.sendport.send(value);
    }, onDone: () {
      params.sendport.send(Constants.sendPortDoneString.codeUnits);
      comp.complete();
    });
    await comp.future;
    // 配置Cinema文件

    CinemaConfig cinemaConfig = CinemaConfig();
    cinemaConfig.videoUrl = params.videoInfo.originalUrl;
    cinemaConfig.title = params.videoInfo.title;
    cinemaConfig.videoFile =
        "${params.videoInfo.title}.${params.videoInfo.ext}";
    File cinemaConfigFile = File(
        "${params.levelInfo.levelPath}${Platform.pathSeparator}${Constants.cinemaConfigFileName}");
    await cinemaConfigFile.writeAsString(cinemaConfig.toJson());
  }

  static String _qualityParams(
      DlpVideoInfo videoInfo, CinemaVideoQuality quality) {
    String? url = videoInfo.originalUrl;
    Uri uri = Uri.parse(url ?? "");
    if (url == null ||
        uri.host.contains("youtube") ||
        uri.host.contains("vimeo") ||
        uri.host.contains("bilibili")) {
      return "-f bestvideo[height<=${quality.toValue()}][vcodec*=avc1]+bestaudio[acodec*=mp4]";
    } else if (uri.host.contains("facebook")) {
      return "-f mp4";
    } else {
      return "-f best[height<=${quality.toValue()}][vcodec*=avc1]";
    }
  }

  static Future<String?> youtubeDLConfig(String beatSaberPath) async {
    var configPath =
        "$beatSaberPath${Platform.pathSeparator}${Constants.userDataDir}${Platform.pathSeparator}${Constants.youtubeDLConfig}";
    var configFile = File(configPath);
    if (await configFile.exists()) {
      return await configFile.readAsString();
    }
    return null;
  }
}

class CinemaDownloadParams {
  final String beatSaberPath;
  final CinemaVideoQuality quality;
  final DlpVideoInfo videoInfo;
  final LevelInfo levelInfo;
  final SendPort sendport;
  CinemaDownloadParams(this.sendport, this.videoInfo, this.levelInfo,
      this.beatSaberPath, this.quality);
}
