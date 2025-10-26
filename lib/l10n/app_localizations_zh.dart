// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get beat_saber_dir => 'BeatSaber目录:';

  @override
  String get choose_dir => '选择目录';

  @override
  String get exe_not_found => '未找到%s';

  @override
  String get languages => '语言';

  @override
  String get refresh_levels => '刷新歌单';

  @override
  String get video_res => '视频分辨率';

  @override
  String get download_complete => '《%s》下载完成。';

  @override
  String get download_start => '《%s》开始下载。';

  @override
  String get download_error => '《%s》下载出错: %s';

  @override
  String get search_tips => '搜索';

  @override
  String get filter_tips => '根据歌名、副标题和作者过滤';

  @override
  String get set_game_path_tips => '请先设置BeatSaver目录';

  @override
  String get search_engine => '搜索引擎';
}
