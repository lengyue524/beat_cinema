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

  @override
  String get nav_levels => 'Levels';

  @override
  String get nav_downloads => 'Downloads';

  @override
  String get nav_settings => 'Settings';

  @override
  String get summary_total => 'Total';

  @override
  String get summary_configured => 'Configured';

  @override
  String get summary_downloading => 'Downloading';

  @override
  String get sort_tooltip => 'Sort';

  @override
  String get sort_song_name => 'Song Name';

  @override
  String get sort_author => 'Author';

  @override
  String get sort_modified => 'Modified';

  @override
  String get filter_tooltip => 'Filter';

  @override
  String get more_tooltip => 'More';

  @override
  String get filter_clear => 'Clear filters';

  @override
  String get status_no_video => 'No video';

  @override
  String get status_configured => 'Configured';

  @override
  String get status_configured_missing_file => 'Configured (missing file)';

  @override
  String get status_downloading => 'Downloading';

  @override
  String get paste_url_hint => 'Paste video URL (YouTube / Bilibili)';

  @override
  String get download_empty => 'No downloads yet';

  @override
  String get error_file_locked =>
      'File is locked by another program, please close it and retry';

  @override
  String get error_ytdlp_video_unavailable => 'Video unavailable or private';

  @override
  String get error_ytdlp_age_restricted =>
      'Age-restricted video, sign in required';

  @override
  String get error_ytdlp_network =>
      'Network error, please check your connection';

  @override
  String get error_ytdlp_invalid_url => 'Invalid or unsupported URL';

  @override
  String get error_ytdlp_not_found =>
      'yt-dlp not found, please install it first';

  @override
  String get error_bbdown_not_found =>
      'BBDown not found, please place BBDown.exe in Libs directory';

  @override
  String get error_bbdown_login_required =>
      'Bilibili resource requires login, please run BBDown login in settings';

  @override
  String get error_bbdown_network =>
      'BBDown failed to process this video, please retry';

  @override
  String get error_bbdown_unknown => 'BBDown processing failed';

  @override
  String get error_ytdlp_search_timeout => 'Search timed out, try again';

  @override
  String get error_ytdlp_unknown => 'Download error occurred';

  @override
  String get error_retry => 'Retry';

  @override
  String get error_ok => 'OK';

  @override
  String get error_title => 'Error';

  @override
  String get empty_no_levels => 'No levels found';

  @override
  String get empty_no_levels_desc => 'Set your Beat Saber path in settings';

  @override
  String get empty_no_levels_action => 'Open Settings';

  @override
  String get empty_no_search => 'No results';

  @override
  String get empty_no_search_desc => 'Try a different search term';

  @override
  String get empty_no_search_action => 'Clear search';

  @override
  String get empty_no_filter => 'No matches';

  @override
  String get empty_no_filter_desc => 'No levels match the current filters';

  @override
  String get empty_no_filter_action => 'Clear filters';

  @override
  String get empty_no_video => 'No videos found';

  @override
  String get empty_no_video_desc =>
      'Try different keywords or another platform';

  @override
  String get empty_no_downloads => 'No downloads';

  @override
  String get empty_no_downloads_desc =>
      'Search for videos or paste a URL to start';

  @override
  String get nav_playlists => 'Playlists';

  @override
  String get panel_search => 'Search';

  @override
  String get panel_config_edit => 'Edit Config';

  @override
  String get panel_file_info => 'File Info';

  @override
  String get panel_download => 'Download';

  @override
  String get panel_audio_preview => 'Audio Preview';

  @override
  String get panel_video_preview => 'Video Preview';

  @override
  String get panel_sync => 'Sync Calibration';

  @override
  String get config_video_file => 'Video File';

  @override
  String get config_title => 'Title';

  @override
  String get config_author => 'Author';

  @override
  String get config_video_url => 'Video URL';

  @override
  String get config_offset => 'Offset (ms)';

  @override
  String get config_duration => 'Duration (ms)';

  @override
  String get config_loop => 'Loop';

  @override
  String get config_save => 'Save';

  @override
  String get config_saved => 'Config saved';

  @override
  String get config_page_title => 'App Settings';

  @override
  String get config_page_subtitle =>
      'Path, download strategy and proxy configuration';

  @override
  String get config_section_basic_subtitle =>
      'Core environment and preferences';

  @override
  String get config_section_proxy_title => 'Proxy';

  @override
  String get config_section_proxy_subtitle =>
      'Network access strategy for download pipeline';

  @override
  String get config_label_proxy_mode => 'Proxy Mode';

  @override
  String get config_label_proxy_address => 'Proxy Address';

  @override
  String get config_proxy_mode_system => 'System Proxy (Default)';

  @override
  String get config_proxy_mode_custom => 'Custom Proxy';

  @override
  String get config_proxy_mode_none => 'No Proxy';

  @override
  String get config_proxy_mode_desc_system =>
      'Auto-detect system proxy, recommended for daily use';

  @override
  String get config_proxy_mode_desc_custom =>
      'Specify proxy server manually for restricted networks';

  @override
  String get config_proxy_mode_desc_none =>
      'Direct network access without proxy';

  @override
  String get config_proxy_address_hint =>
      '127.0.0.1:7890 or http://127.0.0.1:7890';

  @override
  String get config_proxy_saved_mode => 'Proxy mode updated';

  @override
  String get config_proxy_saved_address => 'Proxy address saved';

  @override
  String get config_section_bbdown_title => 'BBDown';

  @override
  String get config_section_bbdown_subtitle =>
      'Bilibili engine login and session management';

  @override
  String get config_label_bbdown_login => 'BBDown Login';

  @override
  String get config_bbdown_login_action => 'Start Login';

  @override
  String get config_bbdown_missing_hint =>
      'BBDown.exe not detected. Place it in the Libs directory before login.';

  @override
  String get config_bbdown_download_action => 'Download Latest';

  @override
  String get config_bbdown_download_started =>
      'Start downloading latest BBDown...';

  @override
  String get config_bbdown_download_done => 'BBDown downloaded successfully';

  @override
  String get config_bbdown_download_failed =>
      'Failed to download latest BBDown';

  @override
  String get config_bbdown_login_started => 'BBDown login window started';

  @override
  String get config_bbdown_login_failed => 'Failed to start BBDown login';

  @override
  String get config_bbdown_login_success =>
      'BBDown login detected successfully';

  @override
  String get config_bbdown_login_pending =>
      'Login not detected yet. Complete login and refresh status.';

  @override
  String get config_bbdown_login_checking => 'Checking...';

  @override
  String get config_bbdown_status_logged_in => 'Logged in';

  @override
  String get config_bbdown_status_not_logged_in => 'Not logged in';

  @override
  String get config_bbdown_status_unknown => 'Login status unknown';

  @override
  String get config_game_dir_saved => 'Game directory updated';

  @override
  String get sync_channel_separation => 'Channel separation';

  @override
  String get sync_filter_unavailable => 'Filter unavailable';

  @override
  String get sync_channel_sep_active => 'L=Song R=Video';

  @override
  String get config_required => 'Required';

  @override
  String get file_info_no_videos => 'No video files in this level';

  @override
  String get file_info_referenced => 'Referenced in config';

  @override
  String get ctx_search_video => 'Search video';

  @override
  String get ctx_audio_preview => 'Audio preview';

  @override
  String get ctx_video_preview => 'Video preview';

  @override
  String get ctx_sync_calibration => 'Sync calibration';

  @override
  String get ctx_edit_config => 'Edit config';

  @override
  String get ctx_file_info => 'File info';

  @override
  String get ctx_open_folder => 'Open folder';

  @override
  String get ctx_copy_name => 'Copy song name';

  @override
  String get ctx_delete_config => 'Delete config';

  @override
  String get ctx_download_configured_video => 'Download configured video';

  @override
  String download_task_config_video_title(String songName) {
    return 'Config Video: $songName';
  }

  @override
  String get dialog_delete_config_title => 'Delete config?';

  @override
  String dialog_delete_config_content(String songName) {
    return 'Remove cinema-video.json for $songName?';
  }

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get mini_player_stop => 'Stop playback';

  @override
  String get mini_player_cover_semantic => 'Cover art of current playing song';

  @override
  String get snack_config_video_url_missing =>
      'No valid video URL in current config';

  @override
  String get snack_download_service_not_ready =>
      'Download service not ready, please set game path first';

  @override
  String get snack_video_file_unresolved =>
      'Download finished but no video file detected';

  @override
  String get snack_video_file_recovered => 'Video file recovered';

  @override
  String get snack_video_download_failed => 'Configured video download failed';

  @override
  String get snack_video_download_enqueued => 'Added to download queue';

  @override
  String get search_tooltip_download => 'Download';

  @override
  String get search_tooltip_downloaded => 'Downloaded';

  @override
  String get search_tooltip_open_link => 'Open link';

  @override
  String get search_open_link_failed =>
      'Unable to open the webpage. Please try again.';

  @override
  String get search_bbdown_missing_fallback =>
      'BBDown is not installed. Fallback to yt-dlp is active. Install BBDown to enable the dedicated Bilibili engine.';

  @override
  String get search_tooltip_play => 'Play in app';

  @override
  String get search_tooltip_play_loading => 'Preparing playback';

  @override
  String get search_play_failed => 'Failed to play video. Please try again.';

  @override
  String get search_play_fallback_title => 'Switch to download playback';

  @override
  String get search_play_fallback_message =>
      'Remote playback failed. Download first and play locally?';

  @override
  String get search_play_fallback_confirm => 'Switch and play';

  @override
  String get search_play_fallback_loading =>
      'Downloading video for local playback...';

  @override
  String search_play_failed_with_reason(String reason) {
    return 'Failed to play video: $reason';
  }

  @override
  String get sem_status_no_video => 'No video';

  @override
  String get sem_status_configured => 'Video configured';

  @override
  String get sem_status_configured_missing_file =>
      'Video missing, download available';

  @override
  String get sem_status_downloading => 'Downloading video';

  @override
  String get sem_status_error => 'Video status error';

  @override
  String get sem_action_play_video => 'Play video';

  @override
  String get playlist_empty => 'No playlists found';

  @override
  String get playlist_empty_desc =>
      'Place .bplist files in Beat Saber/Playlists';

  @override
  String get playlist_songs => 'songs';

  @override
  String get playlist_configured => 'configured';

  @override
  String get playlist_matched => 'matched';

  @override
  String get playlist_not_installed => 'Not installed';

  @override
  String get playlist_filter_unconfigured => 'Show unconfigured only';

  @override
  String get playlist_list_title => 'Playlists';

  @override
  String get playlist_export => 'Export';

  @override
  String get playlist_all_configured => 'All songs are configured';

  @override
  String get playlist_export_done => 'Export complete';

  @override
  String get playlist_rebuild_button => 'Rebuild index';

  @override
  String get playlist_rebuild_confirm_title => 'Rebuild song index';

  @override
  String get playlist_rebuild_confirm_message =>
      'Rebuilding index can be slow. Continue?';

  @override
  String get playlist_rebuild_confirm_continue => 'Continue rebuild';

  @override
  String get playlist_rebuild_stage_scan => 'Preparing index rebuild...';

  @override
  String get playlist_rebuild_stage_hash => 'Rebuilding song hash index...';

  @override
  String get playlist_rebuild_stage_save => 'Saving index cache...';

  @override
  String get playlist_rebuild_success => 'Index rebuild completed';

  @override
  String get playlist_rebuild_failed => 'Index rebuild failed';

  @override
  String get playlist_rebuild_retry => 'Retry';

  @override
  String get playlist_rebuild_error_permission =>
      'Permission denied for song or cache directory';

  @override
  String get playlist_rebuild_error_path_not_found =>
      'Song directory not found, please verify Beat Saber path';

  @override
  String get playlist_rebuild_error_cache_write =>
      'Failed to write index cache, check disk and permissions';

  @override
  String get playlist_rebuild_error_unknown =>
      'Unexpected error while rebuilding index';

  @override
  String get playlist_loading_default => 'Loading playlists...';

  @override
  String get playlist_loading_parse_playlists => 'Reading playlist files...';

  @override
  String get playlist_loading_refresh_levels_fast =>
      'Refreshing local song index (fast)...';

  @override
  String get playlist_loading_refresh_levels_hash =>
      'Building song hash index (slower, fallback only)...';

  @override
  String get playlist_loading_match_songs => 'Matching playlist songs...';

  @override
  String playlist_loading_level_progress(
      int processed, int total, String percent) {
    return 'Parsed level folders $processed / $total  ($percent)';
  }

  @override
  String playlist_loading_song_progress(
      int processed, int total, String percent) {
    return 'Matched songs $processed / $total  ($percent)';
  }

  @override
  String playlist_loading_playlists_progress(int parsed, int total) {
    return 'Playlist files $parsed / $total';
  }

  @override
  String get levels_loading_title => 'Loading songs...';

  @override
  String get levels_loading_scanning => 'Scanning song folders...';

  @override
  String get levels_loading_parsing => 'Parsing songs...';

  @override
  String levels_loading_progress(int parsed, int total) {
    return 'Parsed songs: $parsed / $total';
  }
}
