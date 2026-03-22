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

  @override
  String get nav_levels => '歌曲列表';

  @override
  String get nav_downloads => '下载管理';

  @override
  String get nav_settings => '设置';

  @override
  String get summary_total => '总数';

  @override
  String get summary_configured => '已配置';

  @override
  String get summary_downloading => '下载中';

  @override
  String get sort_tooltip => '排序';

  @override
  String get sort_song_name => '歌名';

  @override
  String get sort_author => '作者';

  @override
  String get sort_modified => '修改时间';

  @override
  String get filter_tooltip => '筛选';

  @override
  String get more_tooltip => '更多';

  @override
  String get filter_clear => '清除筛选';

  @override
  String get status_no_video => '无视频';

  @override
  String get status_configured => '已配置';

  @override
  String get status_configured_missing_file => '已配置（缺少文件）';

  @override
  String get status_downloading => '下载中';

  @override
  String get paste_url_hint => '粘贴视频链接（YouTube / Bilibili）';

  @override
  String get download_empty => '暂无下载任务';

  @override
  String get error_file_locked => '文件被其他程序占用，请关闭后重试';

  @override
  String get error_ytdlp_video_unavailable => '视频不可用或已私密';

  @override
  String get error_ytdlp_age_restricted => '年龄限制视频，需登录';

  @override
  String get error_ytdlp_network => '网络错误，请检查连接';

  @override
  String get error_ytdlp_invalid_url => '无效或不支持的链接';

  @override
  String get error_ytdlp_not_found => '未找到 yt-dlp，请先安装';

  @override
  String get error_bbdown_not_found => '未找到 BBDown，请先将 BBDown.exe 放入 Libs 目录';

  @override
  String get error_bbdown_login_required =>
      'Bilibili 资源需要登录，请先在设置中执行 BBDown 登录';

  @override
  String get error_bbdown_network => 'BBDown 处理失败，请检查网络后重试';

  @override
  String get error_bbdown_unknown => 'BBDown 处理失败';

  @override
  String get error_ytdlp_search_timeout => '搜索超时，请重试';

  @override
  String get error_ytdlp_unknown => '下载发生错误';

  @override
  String get error_retry => '重试';

  @override
  String get error_ok => '确定';

  @override
  String get error_title => '错误';

  @override
  String get empty_no_levels => '未找到关卡';

  @override
  String get empty_no_levels_desc => '请在设置中配置 Beat Saber 路径';

  @override
  String get empty_no_levels_action => '打开设置';

  @override
  String get empty_no_search => '无搜索结果';

  @override
  String get empty_no_search_desc => '试试其他搜索词';

  @override
  String get empty_no_search_action => '清除搜索';

  @override
  String get empty_no_filter => '无匹配结果';

  @override
  String get empty_no_filter_desc => '没有关卡匹配当前筛选条件';

  @override
  String get empty_no_filter_action => '清除筛选';

  @override
  String get empty_no_video => '未找到视频';

  @override
  String get empty_no_video_desc => '试试其他关键词或换个平台';

  @override
  String get empty_no_downloads => '暂无下载任务';

  @override
  String get empty_no_downloads_desc => '搜索视频或粘贴链接开始下载';

  @override
  String get nav_playlists => '播放列表';

  @override
  String get panel_search => '搜索';

  @override
  String get panel_config_edit => '编辑配置';

  @override
  String get panel_file_info => '文件信息';

  @override
  String get panel_download => '下载';

  @override
  String get panel_audio_preview => '音频预览';

  @override
  String get panel_video_preview => '视频预览';

  @override
  String get panel_sync => '同步校准';

  @override
  String get config_video_file => '视频文件';

  @override
  String get config_title => '标题';

  @override
  String get config_author => '作者';

  @override
  String get config_video_url => '视频链接';

  @override
  String get config_offset => '偏移量 (ms)';

  @override
  String get config_duration => '时长 (ms)';

  @override
  String get config_loop => '循环播放';

  @override
  String get config_save => '保存';

  @override
  String get config_saved => '配置已保存';

  @override
  String get config_page_title => '应用设置';

  @override
  String get config_page_subtitle => '路径、下载策略与代理配置';

  @override
  String get config_section_basic_subtitle => '基础环境与偏好设置';

  @override
  String get config_section_proxy_title => '代理';

  @override
  String get config_section_proxy_subtitle => '用于下载链路的网络访问策略';

  @override
  String get config_label_proxy_mode => '代理模式';

  @override
  String get config_label_proxy_address => '代理地址';

  @override
  String get config_proxy_mode_system => '系统代理（默认）';

  @override
  String get config_proxy_mode_custom => '自定义代理';

  @override
  String get config_proxy_mode_none => '不使用代理';

  @override
  String get config_proxy_mode_desc_system => '自动读取系统代理配置，推荐日常使用';

  @override
  String get config_proxy_mode_desc_custom => '手动指定代理地址，适用于特殊网络环境';

  @override
  String get config_proxy_mode_desc_none => '不走代理，直接访问网络';

  @override
  String get config_proxy_address_hint =>
      '127.0.0.1:7890 或 http://127.0.0.1:7890';

  @override
  String get config_proxy_saved_mode => '代理模式已更新';

  @override
  String get config_proxy_saved_address => '代理地址已保存';

  @override
  String get config_section_bbdown_title => 'BBDown';

  @override
  String get config_section_bbdown_subtitle => 'Bilibili 引擎登录与会话管理';

  @override
  String get config_label_bbdown_login => 'BBDown 登录';

  @override
  String get config_bbdown_login_action => '开始登录';

  @override
  String get config_bbdown_missing_hint => '未检测到 BBDown.exe，请先放入 Libs 目录后再登录。';

  @override
  String get config_bbdown_download_action => '下载最新版';

  @override
  String get config_bbdown_download_started => '开始下载最新 BBDown...';

  @override
  String get config_bbdown_download_done => 'BBDown 下载完成';

  @override
  String get config_bbdown_download_failed => 'BBDown 下载失败，请稍后重试';

  @override
  String get config_bbdown_login_started => '已启动 BBDown 登录窗口';

  @override
  String get config_bbdown_login_failed => '启动 BBDown 登录失败';

  @override
  String get config_bbdown_login_success => '检测到 BBDown 登录成功';

  @override
  String get config_bbdown_login_pending => '暂未检测到登录成功，请完成登录后刷新状态';

  @override
  String get config_bbdown_login_checking => '检测中...';

  @override
  String get config_bbdown_status_logged_in => '已登录';

  @override
  String get config_bbdown_status_not_logged_in => '未登录';

  @override
  String get config_bbdown_status_unknown => '登录状态未知';

  @override
  String get config_game_dir_saved => '游戏目录已更新';

  @override
  String get sync_channel_separation => '声道分离';

  @override
  String get sync_filter_unavailable => '滤镜不可用';

  @override
  String get sync_channel_sep_active => 'L=歌曲  R=视频';

  @override
  String get config_required => '必填';

  @override
  String get file_info_no_videos => '该关卡目录中没有视频文件';

  @override
  String get file_info_referenced => '已在配置中引用';

  @override
  String get ctx_search_video => '搜索视频';

  @override
  String get ctx_audio_preview => '音频预览';

  @override
  String get ctx_video_preview => '视频预览';

  @override
  String get ctx_sync_calibration => '同步校准';

  @override
  String get ctx_edit_config => '编辑配置';

  @override
  String get ctx_file_info => '文件信息';

  @override
  String get ctx_open_folder => '打开文件夹';

  @override
  String get ctx_copy_name => '复制歌名';

  @override
  String get ctx_delete_config => '删除配置';

  @override
  String get ctx_download_configured_video => '按配置下载视频';

  @override
  String download_task_config_video_title(String songName) {
    return '配置视频：$songName';
  }

  @override
  String get dialog_delete_config_title => '删除配置？';

  @override
  String dialog_delete_config_content(String songName) {
    return '确认删除 $songName 的 cinema-video.json 吗？';
  }

  @override
  String get common_cancel => '取消';

  @override
  String get common_delete => '删除';

  @override
  String get mini_player_stop => '停止播放';

  @override
  String get mini_player_cover_semantic => '当前播放歌曲封面';

  @override
  String get snack_config_video_url_missing => '当前配置没有可用的视频链接';

  @override
  String get snack_download_service_not_ready => '下载服务未初始化，请先设置游戏路径';

  @override
  String get snack_video_file_unresolved => '下载完成，但未识别到视频文件';

  @override
  String get snack_video_file_recovered => '已补齐视频文件';

  @override
  String get snack_video_download_failed => '配置视频下载失败';

  @override
  String get snack_video_download_enqueued => '已加入下载队列';

  @override
  String get search_tooltip_download => '下载';

  @override
  String get search_tooltip_downloaded => '已下载';

  @override
  String get search_tooltip_open_link => '打开链接';

  @override
  String get search_open_link_failed => '无法打开网页链接，请稍后重试';

  @override
  String get search_bbdown_missing_fallback =>
      '未检测到 BBDown，当前已回退使用 yt-dlp。请安装 BBDown 以启用 Bilibili 专用引擎。';

  @override
  String get search_tooltip_play => '应用内播放';

  @override
  String get search_tooltip_play_loading => '正在准备播放';

  @override
  String get search_play_failed => '视频播放失败，请稍后重试';

  @override
  String get search_play_fallback_title => '切换下载播放模式';

  @override
  String get search_play_fallback_message => '在线播放失败，是否切换为下载后播放？';

  @override
  String get search_play_fallback_confirm => '切换并播放';

  @override
  String get search_play_fallback_loading => '正在下载视频用于本地播放...';

  @override
  String search_play_failed_with_reason(String reason) {
    return '视频播放失败：$reason';
  }

  @override
  String get sem_status_no_video => '无视频';

  @override
  String get sem_status_configured => '视频已配置';

  @override
  String get sem_status_configured_missing_file => '视频文件缺失，可下载';

  @override
  String get sem_status_downloading => '正在下载视频';

  @override
  String get sem_status_error => '视频状态异常';

  @override
  String get sem_action_play_video => '播放视频';

  @override
  String get playlist_empty => '未找到播放列表';

  @override
  String get playlist_empty_desc => '请将 .bplist 文件放入 Beat Saber/Playlists 目录';

  @override
  String get playlist_songs => '首歌';

  @override
  String get playlist_configured => '已配置';

  @override
  String get playlist_matched => '已匹配';

  @override
  String get playlist_not_installed => '未安装';

  @override
  String get playlist_filter_unconfigured => '仅显示未配置';

  @override
  String get playlist_list_title => '播放列表';

  @override
  String get playlist_export => '导出';

  @override
  String get playlist_all_configured => '所有歌曲均已配置';

  @override
  String get playlist_export_done => '导出完成';

  @override
  String get playlist_rebuild_button => '重建索引';

  @override
  String get playlist_rebuild_confirm_title => '重建歌曲索引';

  @override
  String get playlist_rebuild_confirm_message => '重建索引可能较慢，是否继续？';

  @override
  String get playlist_rebuild_confirm_continue => '继续重建';

  @override
  String get playlist_rebuild_stage_scan => '正在准备重建索引...';

  @override
  String get playlist_rebuild_stage_hash => '正在重建歌曲哈希索引...';

  @override
  String get playlist_rebuild_stage_save => '正在写入索引缓存...';

  @override
  String get playlist_rebuild_success => '索引重建完成';

  @override
  String get playlist_rebuild_failed => '索引重建失败';

  @override
  String get playlist_rebuild_retry => '重试';

  @override
  String get playlist_rebuild_error_permission => '没有足够权限访问歌曲目录或缓存目录';

  @override
  String get playlist_rebuild_error_path_not_found =>
      '歌曲目录不存在，请检查 Beat Saber 路径';

  @override
  String get playlist_rebuild_error_cache_write => '索引缓存写入失败，请检查磁盘和权限';

  @override
  String get playlist_rebuild_error_unknown => '重建索引时出现未知错误';

  @override
  String get playlist_loading_default => '正在加载歌单...';

  @override
  String get playlist_loading_parse_playlists => '正在读取歌单文件...';

  @override
  String get playlist_loading_refresh_levels_fast => '正在刷新本地歌曲索引（快速）...';

  @override
  String get playlist_loading_refresh_levels_hash => '正在补充歌曲哈希索引（较慢，仅异常时）...';

  @override
  String get playlist_loading_match_songs => '正在匹配歌单歌曲...';

  @override
  String playlist_loading_level_progress(
      int processed, int total, String percent) {
    return '已解析谱面目录 $processed / $total  ($percent)';
  }

  @override
  String playlist_loading_song_progress(
      int processed, int total, String percent) {
    return '已匹配歌曲 $processed / $total  ($percent)';
  }

  @override
  String playlist_loading_playlists_progress(int parsed, int total) {
    return '歌单文件 $parsed / $total';
  }

  @override
  String get levels_loading_title => '正在加载歌曲列表...';

  @override
  String get levels_loading_scanning => '正在扫描歌曲目录...';

  @override
  String get levels_loading_parsing => '正在解析歌曲...';

  @override
  String levels_loading_progress(int parsed, int total) {
    return '已解析歌曲 $parsed / $total';
  }
}
