# BeatCinema

BeatCinema 是 `BeatSaberCinema` 插件的视频资源管理工具。

它可以帮助你：
- 管理歌曲级别的 `cinema-video.json`
- 按配置链接下载视频
- 在播放列表中下载缺失歌曲
- 在统一下载管理页查看与控制任务

仅支持 Windows 平台。

## 主要功能

- **歌曲列表（Custom Levels）**
  - 支持搜索、排序、筛选
  - 统一歌曲条目与右键菜单操作
  - 视频搜索结果支持应用内直接播放（不跳转外部网页）
  - 支持歌曲与视频音频同步校准（偏移调整）
  - 对“已配置但缺少视频文件”的歌曲提供一键下载
  - 下载工具自动分流：
    - 直链视频文件（`.mp4/.mkv/.webm` 等）走直接 HTTP 下载
    - 平台链接（如 YouTube）走 `yt-dlp`
  - `cinema-video.json` 中支持 `videoID` 兜底（自动拼接 YouTube 链接）

- **播放列表（Playlists）**
  - 解析播放列表并进行歌曲匹配（key/hash/songName 回退）
  - 支持一键下载缺失歌曲（含批量）
  - 下载后优先增量刷新，减少整页重载
  - 加载过程提供解析/匹配/hash 回填进度显示

- **下载管理（Downloads）**
  - 统一查看任务状态（排队/下载中/完成/失败/已取消）
  - 支持重试、取消
  - 左侧导航“下载管理”支持活动任务角标（上限显示 `99+`）

- **代理支持**
  - 代理模式：`系统代理（默认）` / `自定义代理` / `不使用代理`
  - 代理设置同时作用于 `yt-dlp` 与直连 HTTP 下载

## 设置界面

- 设置页已按当前主题样式重构为分组卡片布局，主要包含：
  - **基础设置**：游戏目录、语言、视频分辨率、搜索引擎
  - **代理设置**：代理模式、代理地址、当前模式说明
- 关键操作（切换目录、保存代理）会提供即时提示反馈

## 日志系统

- 所有运行日志会落盘到应用数据目录下的 `logs` 文件夹。
- 当日日志文件命名为：`app-YYYY-MM-DD.log`。
- 启动时会自动归档历史日志（含前一天）为：`app-YYYY-MM-DD.zip`，并删除对应 `.log` 原文件。
- 日志总占用自动治理：`logs` 目录内日志文件总大小上限为 `10MB`。
  - 超限时按“最旧优先”清理；
  - 会优先保护当日日志文件，必要时仅裁剪当日日志到上限范围内。

## 使用方法

- 设置 BeatSaber 安装目录
- 在“歌曲列表”或“播放列表”发起下载
- 在“下载管理”查看和控制任务
- 手动验证清单（搜索代理）：
  - 中文：`docs/manual-verification/search-proxy-checklist.md`
  - English: `docs/manual-verification/search-proxy-checklist.en.md`

**⚠️因bilibili平台限制，未登录情况下仅支持最高480p下载。**

[how-do-i-pass-cookies-to-yt-dlp](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp)

## yt-dlp 版本要求

ModAssistant 下载的 `yt-dlp` 版本通常较旧，建议升级到最新稳定版。

建议：使用 upstream 最新稳定版本。

## yt-dlp 配置

如需自定义 `yt-dlp` 参数，请在 BeatSaber 目录下添加：
`UserData\yt-dlp.conf`

具体参数请参考官方文档：[yt-dlp](https://github.com/yt-dlp/yt-dlp)