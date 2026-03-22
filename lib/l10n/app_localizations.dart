import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @beat_saber_dir.
  ///
  /// In en, this message translates to:
  /// **'Beat Saber dir:'**
  String get beat_saber_dir;

  /// No description provided for @choose_dir.
  ///
  /// In en, this message translates to:
  /// **'choose dir'**
  String get choose_dir;

  /// No description provided for @exe_not_found.
  ///
  /// In en, this message translates to:
  /// **'%s not found'**
  String get exe_not_found;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @refresh_levels.
  ///
  /// In en, this message translates to:
  /// **'Refresh Levels'**
  String get refresh_levels;

  /// No description provided for @video_res.
  ///
  /// In en, this message translates to:
  /// **'Video Resolution'**
  String get video_res;

  /// No description provided for @download_complete.
  ///
  /// In en, this message translates to:
  /// **'%s download complete.'**
  String get download_complete;

  /// No description provided for @download_start.
  ///
  /// In en, this message translates to:
  /// **'%s start to download.'**
  String get download_start;

  /// No description provided for @download_error.
  ///
  /// In en, this message translates to:
  /// **'%s download error: %s'**
  String get download_error;

  /// No description provided for @search_tips.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search_tips;

  /// No description provided for @filter_tips.
  ///
  /// In en, this message translates to:
  /// **'Filter by Song name, Sub name, Author'**
  String get filter_tips;

  /// No description provided for @set_game_path_tips.
  ///
  /// In en, this message translates to:
  /// **'Set BeatSaver Path in settings'**
  String get set_game_path_tips;

  /// No description provided for @search_engine.
  ///
  /// In en, this message translates to:
  /// **'Search Engine'**
  String get search_engine;

  /// No description provided for @nav_levels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get nav_levels;

  /// No description provided for @nav_downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get nav_downloads;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @summary_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summary_total;

  /// No description provided for @summary_configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get summary_configured;

  /// No description provided for @summary_downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get summary_downloading;

  /// No description provided for @sort_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort_tooltip;

  /// No description provided for @sort_song_name.
  ///
  /// In en, this message translates to:
  /// **'Song Name'**
  String get sort_song_name;

  /// No description provided for @sort_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get sort_author;

  /// No description provided for @sort_modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get sort_modified;

  /// No description provided for @filter_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter_tooltip;

  /// No description provided for @more_tooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more_tooltip;

  /// No description provided for @filter_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get filter_clear;

  /// No description provided for @status_no_video.
  ///
  /// In en, this message translates to:
  /// **'No video'**
  String get status_no_video;

  /// No description provided for @status_configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get status_configured;

  /// No description provided for @status_configured_missing_file.
  ///
  /// In en, this message translates to:
  /// **'Configured (missing file)'**
  String get status_configured_missing_file;

  /// No description provided for @status_downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get status_downloading;

  /// No description provided for @paste_url_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste video URL (YouTube / Bilibili)'**
  String get paste_url_hint;

  /// No description provided for @download_empty.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get download_empty;

  /// No description provided for @error_file_locked.
  ///
  /// In en, this message translates to:
  /// **'File is locked by another program, please close it and retry'**
  String get error_file_locked;

  /// No description provided for @error_ytdlp_video_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable or private'**
  String get error_ytdlp_video_unavailable;

  /// No description provided for @error_ytdlp_age_restricted.
  ///
  /// In en, this message translates to:
  /// **'Age-restricted video, sign in required'**
  String get error_ytdlp_age_restricted;

  /// No description provided for @error_ytdlp_network.
  ///
  /// In en, this message translates to:
  /// **'Network error, please check your connection'**
  String get error_ytdlp_network;

  /// No description provided for @error_ytdlp_invalid_url.
  ///
  /// In en, this message translates to:
  /// **'Invalid or unsupported URL'**
  String get error_ytdlp_invalid_url;

  /// No description provided for @error_ytdlp_not_found.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp not found, please install it first'**
  String get error_ytdlp_not_found;

  /// No description provided for @error_ytdlp_search_timeout.
  ///
  /// In en, this message translates to:
  /// **'Search timed out, try again'**
  String get error_ytdlp_search_timeout;

  /// No description provided for @error_ytdlp_unknown.
  ///
  /// In en, this message translates to:
  /// **'Download error occurred'**
  String get error_ytdlp_unknown;

  /// No description provided for @error_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get error_retry;

  /// No description provided for @error_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get error_ok;

  /// No description provided for @error_title.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error_title;

  /// No description provided for @empty_no_levels.
  ///
  /// In en, this message translates to:
  /// **'No levels found'**
  String get empty_no_levels;

  /// No description provided for @empty_no_levels_desc.
  ///
  /// In en, this message translates to:
  /// **'Set your Beat Saber path in settings'**
  String get empty_no_levels_desc;

  /// No description provided for @empty_no_levels_action.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get empty_no_levels_action;

  /// No description provided for @empty_no_search.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get empty_no_search;

  /// No description provided for @empty_no_search_desc.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get empty_no_search_desc;

  /// No description provided for @empty_no_search_action.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get empty_no_search_action;

  /// No description provided for @empty_no_filter.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get empty_no_filter;

  /// No description provided for @empty_no_filter_desc.
  ///
  /// In en, this message translates to:
  /// **'No levels match the current filters'**
  String get empty_no_filter_desc;

  /// No description provided for @empty_no_filter_action.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get empty_no_filter_action;

  /// No description provided for @empty_no_video.
  ///
  /// In en, this message translates to:
  /// **'No videos found'**
  String get empty_no_video;

  /// No description provided for @empty_no_video_desc.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or another platform'**
  String get empty_no_video_desc;

  /// No description provided for @empty_no_downloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get empty_no_downloads;

  /// No description provided for @empty_no_downloads_desc.
  ///
  /// In en, this message translates to:
  /// **'Search for videos or paste a URL to start'**
  String get empty_no_downloads_desc;

  /// No description provided for @nav_playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get nav_playlists;

  /// No description provided for @panel_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get panel_search;

  /// No description provided for @panel_config_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Config'**
  String get panel_config_edit;

  /// No description provided for @panel_file_info.
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get panel_file_info;

  /// No description provided for @panel_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get panel_download;

  /// No description provided for @panel_audio_preview.
  ///
  /// In en, this message translates to:
  /// **'Audio Preview'**
  String get panel_audio_preview;

  /// No description provided for @panel_video_preview.
  ///
  /// In en, this message translates to:
  /// **'Video Preview'**
  String get panel_video_preview;

  /// No description provided for @panel_sync.
  ///
  /// In en, this message translates to:
  /// **'Sync Calibration'**
  String get panel_sync;

  /// No description provided for @config_video_file.
  ///
  /// In en, this message translates to:
  /// **'Video File'**
  String get config_video_file;

  /// No description provided for @config_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get config_title;

  /// No description provided for @config_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get config_author;

  /// No description provided for @config_video_url.
  ///
  /// In en, this message translates to:
  /// **'Video URL'**
  String get config_video_url;

  /// No description provided for @config_offset.
  ///
  /// In en, this message translates to:
  /// **'Offset (ms)'**
  String get config_offset;

  /// No description provided for @config_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration (ms)'**
  String get config_duration;

  /// No description provided for @config_loop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get config_loop;

  /// No description provided for @config_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get config_save;

  /// No description provided for @config_saved.
  ///
  /// In en, this message translates to:
  /// **'Config saved'**
  String get config_saved;

  /// No description provided for @config_page_title.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get config_page_title;

  /// No description provided for @config_page_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Path, download strategy and proxy configuration'**
  String get config_page_subtitle;

  /// No description provided for @config_section_basic_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Core environment and preferences'**
  String get config_section_basic_subtitle;

  /// Proxy section title on settings page
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get config_section_proxy_title;

  /// Proxy section subtitle on settings page
  ///
  /// In en, this message translates to:
  /// **'Network access strategy for download pipeline'**
  String get config_section_proxy_subtitle;

  /// Label for proxy mode field
  ///
  /// In en, this message translates to:
  /// **'Proxy Mode'**
  String get config_label_proxy_mode;

  /// Label for proxy address field
  ///
  /// In en, this message translates to:
  /// **'Proxy Address'**
  String get config_label_proxy_address;

  /// No description provided for @config_proxy_mode_system.
  ///
  /// In en, this message translates to:
  /// **'System Proxy (Default)'**
  String get config_proxy_mode_system;

  /// No description provided for @config_proxy_mode_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy'**
  String get config_proxy_mode_custom;

  /// No description provided for @config_proxy_mode_none.
  ///
  /// In en, this message translates to:
  /// **'No Proxy'**
  String get config_proxy_mode_none;

  /// No description provided for @config_proxy_mode_desc_system.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect system proxy, recommended for daily use'**
  String get config_proxy_mode_desc_system;

  /// No description provided for @config_proxy_mode_desc_custom.
  ///
  /// In en, this message translates to:
  /// **'Specify proxy server manually for restricted networks'**
  String get config_proxy_mode_desc_custom;

  /// No description provided for @config_proxy_mode_desc_none.
  ///
  /// In en, this message translates to:
  /// **'Direct network access without proxy'**
  String get config_proxy_mode_desc_none;

  /// Placeholder hint for proxy address input
  ///
  /// In en, this message translates to:
  /// **'127.0.0.1:7890 or http://127.0.0.1:7890'**
  String get config_proxy_address_hint;

  /// No description provided for @config_proxy_saved_mode.
  ///
  /// In en, this message translates to:
  /// **'Proxy mode updated'**
  String get config_proxy_saved_mode;

  /// No description provided for @config_proxy_saved_address.
  ///
  /// In en, this message translates to:
  /// **'Proxy address saved'**
  String get config_proxy_saved_address;

  /// No description provided for @config_game_dir_saved.
  ///
  /// In en, this message translates to:
  /// **'Game directory updated'**
  String get config_game_dir_saved;

  /// No description provided for @sync_channel_separation.
  ///
  /// In en, this message translates to:
  /// **'Channel separation'**
  String get sync_channel_separation;

  /// No description provided for @sync_filter_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Filter unavailable'**
  String get sync_filter_unavailable;

  /// No description provided for @sync_channel_sep_active.
  ///
  /// In en, this message translates to:
  /// **'L=Song R=Video'**
  String get sync_channel_sep_active;

  /// No description provided for @config_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get config_required;

  /// No description provided for @file_info_no_videos.
  ///
  /// In en, this message translates to:
  /// **'No video files in this level'**
  String get file_info_no_videos;

  /// No description provided for @file_info_referenced.
  ///
  /// In en, this message translates to:
  /// **'Referenced in config'**
  String get file_info_referenced;

  /// No description provided for @ctx_search_video.
  ///
  /// In en, this message translates to:
  /// **'Search video'**
  String get ctx_search_video;

  /// No description provided for @ctx_audio_preview.
  ///
  /// In en, this message translates to:
  /// **'Audio preview'**
  String get ctx_audio_preview;

  /// No description provided for @ctx_video_preview.
  ///
  /// In en, this message translates to:
  /// **'Video preview'**
  String get ctx_video_preview;

  /// No description provided for @ctx_sync_calibration.
  ///
  /// In en, this message translates to:
  /// **'Sync calibration'**
  String get ctx_sync_calibration;

  /// No description provided for @ctx_edit_config.
  ///
  /// In en, this message translates to:
  /// **'Edit config'**
  String get ctx_edit_config;

  /// No description provided for @ctx_file_info.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get ctx_file_info;

  /// No description provided for @ctx_open_folder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get ctx_open_folder;

  /// No description provided for @ctx_copy_name.
  ///
  /// In en, this message translates to:
  /// **'Copy song name'**
  String get ctx_copy_name;

  /// No description provided for @ctx_delete_config.
  ///
  /// In en, this message translates to:
  /// **'Delete config'**
  String get ctx_delete_config;

  /// No description provided for @ctx_download_configured_video.
  ///
  /// In en, this message translates to:
  /// **'Download configured video'**
  String get ctx_download_configured_video;

  /// No description provided for @download_task_config_video_title.
  ///
  /// In en, this message translates to:
  /// **'Config Video: {songName}'**
  String download_task_config_video_title(String songName);

  /// No description provided for @dialog_delete_config_title.
  ///
  /// In en, this message translates to:
  /// **'Delete config?'**
  String get dialog_delete_config_title;

  /// No description provided for @dialog_delete_config_content.
  ///
  /// In en, this message translates to:
  /// **'Remove cinema-video.json for {songName}?'**
  String dialog_delete_config_content(String songName);

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @mini_player_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get mini_player_stop;

  /// No description provided for @mini_player_cover_semantic.
  ///
  /// In en, this message translates to:
  /// **'Cover art of current playing song'**
  String get mini_player_cover_semantic;

  /// No description provided for @snack_config_video_url_missing.
  ///
  /// In en, this message translates to:
  /// **'No valid video URL in current config'**
  String get snack_config_video_url_missing;

  /// No description provided for @snack_download_service_not_ready.
  ///
  /// In en, this message translates to:
  /// **'Download service not ready, please set game path first'**
  String get snack_download_service_not_ready;

  /// No description provided for @snack_video_file_unresolved.
  ///
  /// In en, this message translates to:
  /// **'Download finished but no video file detected'**
  String get snack_video_file_unresolved;

  /// No description provided for @snack_video_file_recovered.
  ///
  /// In en, this message translates to:
  /// **'Video file recovered'**
  String get snack_video_file_recovered;

  /// No description provided for @snack_video_download_failed.
  ///
  /// In en, this message translates to:
  /// **'Configured video download failed'**
  String get snack_video_download_failed;

  /// No description provided for @snack_video_download_enqueued.
  ///
  /// In en, this message translates to:
  /// **'Added to download queue'**
  String get snack_video_download_enqueued;

  /// No description provided for @search_tooltip_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get search_tooltip_download;

  /// No description provided for @search_tooltip_downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get search_tooltip_downloaded;

  /// No description provided for @search_tooltip_open_link.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get search_tooltip_open_link;

  /// No description provided for @sem_status_no_video.
  ///
  /// In en, this message translates to:
  /// **'No video'**
  String get sem_status_no_video;

  /// No description provided for @sem_status_configured.
  ///
  /// In en, this message translates to:
  /// **'Video configured'**
  String get sem_status_configured;

  /// No description provided for @sem_status_configured_missing_file.
  ///
  /// In en, this message translates to:
  /// **'Video missing, download available'**
  String get sem_status_configured_missing_file;

  /// No description provided for @sem_status_downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading video'**
  String get sem_status_downloading;

  /// No description provided for @sem_status_error.
  ///
  /// In en, this message translates to:
  /// **'Video status error'**
  String get sem_status_error;

  /// No description provided for @sem_action_play_video.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get sem_action_play_video;

  /// No description provided for @playlist_empty.
  ///
  /// In en, this message translates to:
  /// **'No playlists found'**
  String get playlist_empty;

  /// No description provided for @playlist_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Place .bplist files in Beat Saber/Playlists'**
  String get playlist_empty_desc;

  /// No description provided for @playlist_songs.
  ///
  /// In en, this message translates to:
  /// **'songs'**
  String get playlist_songs;

  /// No description provided for @playlist_configured.
  ///
  /// In en, this message translates to:
  /// **'configured'**
  String get playlist_configured;

  /// No description provided for @playlist_matched.
  ///
  /// In en, this message translates to:
  /// **'matched'**
  String get playlist_matched;

  /// No description provided for @playlist_not_installed.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get playlist_not_installed;

  /// No description provided for @playlist_filter_unconfigured.
  ///
  /// In en, this message translates to:
  /// **'Show unconfigured only'**
  String get playlist_filter_unconfigured;

  /// No description provided for @playlist_list_title.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlist_list_title;

  /// No description provided for @playlist_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get playlist_export;

  /// No description provided for @playlist_all_configured.
  ///
  /// In en, this message translates to:
  /// **'All songs are configured'**
  String get playlist_all_configured;

  /// No description provided for @playlist_export_done.
  ///
  /// In en, this message translates to:
  /// **'Export complete'**
  String get playlist_export_done;

  /// No description provided for @playlist_rebuild_button.
  ///
  /// In en, this message translates to:
  /// **'Rebuild index'**
  String get playlist_rebuild_button;

  /// No description provided for @playlist_rebuild_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Rebuild song index'**
  String get playlist_rebuild_confirm_title;

  /// No description provided for @playlist_rebuild_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding index can be slow. Continue?'**
  String get playlist_rebuild_confirm_message;

  /// No description provided for @playlist_rebuild_confirm_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue rebuild'**
  String get playlist_rebuild_confirm_continue;

  /// No description provided for @playlist_rebuild_stage_scan.
  ///
  /// In en, this message translates to:
  /// **'Preparing index rebuild...'**
  String get playlist_rebuild_stage_scan;

  /// No description provided for @playlist_rebuild_stage_hash.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding song hash index...'**
  String get playlist_rebuild_stage_hash;

  /// No description provided for @playlist_rebuild_stage_save.
  ///
  /// In en, this message translates to:
  /// **'Saving index cache...'**
  String get playlist_rebuild_stage_save;

  /// No description provided for @playlist_rebuild_success.
  ///
  /// In en, this message translates to:
  /// **'Index rebuild completed'**
  String get playlist_rebuild_success;

  /// No description provided for @playlist_rebuild_failed.
  ///
  /// In en, this message translates to:
  /// **'Index rebuild failed'**
  String get playlist_rebuild_failed;

  /// No description provided for @playlist_rebuild_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get playlist_rebuild_retry;

  /// No description provided for @playlist_rebuild_error_permission.
  ///
  /// In en, this message translates to:
  /// **'Permission denied for song or cache directory'**
  String get playlist_rebuild_error_permission;

  /// No description provided for @playlist_rebuild_error_path_not_found.
  ///
  /// In en, this message translates to:
  /// **'Song directory not found, please verify Beat Saber path'**
  String get playlist_rebuild_error_path_not_found;

  /// No description provided for @playlist_rebuild_error_cache_write.
  ///
  /// In en, this message translates to:
  /// **'Failed to write index cache, check disk and permissions'**
  String get playlist_rebuild_error_cache_write;

  /// No description provided for @playlist_rebuild_error_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error while rebuilding index'**
  String get playlist_rebuild_error_unknown;

  /// No description provided for @playlist_loading_default.
  ///
  /// In en, this message translates to:
  /// **'Loading playlists...'**
  String get playlist_loading_default;

  /// No description provided for @playlist_loading_parse_playlists.
  ///
  /// In en, this message translates to:
  /// **'Reading playlist files...'**
  String get playlist_loading_parse_playlists;

  /// No description provided for @playlist_loading_refresh_levels_fast.
  ///
  /// In en, this message translates to:
  /// **'Refreshing local song index (fast)...'**
  String get playlist_loading_refresh_levels_fast;

  /// No description provided for @playlist_loading_refresh_levels_hash.
  ///
  /// In en, this message translates to:
  /// **'Building song hash index (slower, fallback only)...'**
  String get playlist_loading_refresh_levels_hash;

  /// No description provided for @playlist_loading_match_songs.
  ///
  /// In en, this message translates to:
  /// **'Matching playlist songs...'**
  String get playlist_loading_match_songs;

  /// No description provided for @playlist_loading_level_progress.
  ///
  /// In en, this message translates to:
  /// **'Parsed level folders {processed} / {total}  ({percent})'**
  String playlist_loading_level_progress(
      int processed, int total, String percent);

  /// No description provided for @playlist_loading_song_progress.
  ///
  /// In en, this message translates to:
  /// **'Matched songs {processed} / {total}  ({percent})'**
  String playlist_loading_song_progress(
      int processed, int total, String percent);

  /// No description provided for @playlist_loading_playlists_progress.
  ///
  /// In en, this message translates to:
  /// **'Playlist files {parsed} / {total}'**
  String playlist_loading_playlists_progress(int parsed, int total);

  /// No description provided for @levels_loading_title.
  ///
  /// In en, this message translates to:
  /// **'Loading songs...'**
  String get levels_loading_title;

  /// No description provided for @levels_loading_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning song folders...'**
  String get levels_loading_scanning;

  /// No description provided for @levels_loading_parsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing songs...'**
  String get levels_loading_parsing;

  /// No description provided for @levels_loading_progress.
  ///
  /// In en, this message translates to:
  /// **'Parsed songs: {parsed} / {total}'**
  String levels_loading_progress(int parsed, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
