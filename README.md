# BeatCinema

BeatCinema is a video resource management tool for the `BeatSaberCinema` plugin, supporting video downloads from YouTube and Bilibili, and automatically generating configuration files.

Supported platform: Windows only.

# Usage Instructions

- Set the BeatSaber installation directory
- Select a song
- Download video

**⚠️ Due to Bilibili platform restrictions, only downloads up to 480p are supported without logging in.**

I have tried to set up login status, but it was unsuccessful. If you succeed, please let me know.

[how-do-i-pass-cookies-to-yt-dlp](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp)

**⚠️ yt-dlp version requirements**

The version downloaded by ModAssistant is relatively low. Please update yt-dlp to the latest version.

The version I have tested: 2024.04.09

# TODO

- [ ] Cinema Video Playback Offset Settings
- [ ] Playlist List

# yt-dlp Configuration

If you need to customize yt-dlp configuration, please add the configuration to the `UserData\yt-dlp.conf` file in the BeatSaber game directory.

For specific configuration details, please refer to the yt-dlp configuration guide [yt-dlp](https://github.com/yt-dlp/yt-dlp)
