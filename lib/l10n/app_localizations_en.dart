// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get beat_saber_dir => 'Beat Saber dir:';

  @override
  String get choose_dir => 'choose dir';

  @override
  String get exe_not_found => '%s not found';

  @override
  String get languages => 'Languages';

  @override
  String get refresh_levels => 'Refresh Levels';

  @override
  String get video_res => 'Video Resolution';

  @override
  String get download_complete => '%s download complete.';

  @override
  String get download_start => '%s start to download.';

  @override
  String get download_error => '%s download error: %s';

  @override
  String get search_tips => 'Search...';

  @override
  String get filter_tips => 'Filter by Song name, Sub name, Author';

  @override
  String get set_game_path_tips => 'Set BeatSaver Path in settings';

  @override
  String get search_engine => 'Search Engine';
}
