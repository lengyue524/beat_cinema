# BeatCinema

BeatCinema is a video resource manager for the `BeatSaberCinema` plugin.

It helps you:
- manage song-level cinema config files (`cinema-video.json`)
- download videos from configured sources
- download missing songs from playlists
- inspect and manage download tasks in one place

Supported platform: Windows only.

## Core Features

- **Songs page (Custom Levels)**
  - Search, sort, and filter songs
  - Unified song list rendering with context menu actions
  - Configured-missing-video status with one-click re-download
  - Download tool routing:
    - direct HTTP download for direct video file URLs (`.mp4`, `.mkv`, `.webm`, etc.)
    - `yt-dlp` for platform links (YouTube, etc.)
  - `videoID` fallback in `cinema-video.json` (builds YouTube URL automatically)

- **Playlists page**
  - Playlist parsing and song matching (key/hash/name fallback strategy)
  - Batch download missing songs
  - Partial/incremental post-download refresh to reduce full-list reloads
  - Loading progress UI for parse/match/hash-backfill stages

- **Downloads page**
  - Queue/task status overview (pending/downloading/completed/failed/cancelled)
  - Retry/cancel operations for tasks
  - Navigation rail downloads badge shows active task count (`99+` cap)

- **Proxy support**
  - Proxy mode: `System` (default) / `Custom` / `None`
  - Proxy config is applied to `yt-dlp` and direct HTTP downloads

## Settings UI

- The settings page is now refactored into themed section cards:
  - **Basic Settings**: game directory, language, video resolution, search engine
  - **Proxy Settings**: proxy mode, proxy address, current mode description
- Key actions (changing game directory, saving proxy) provide immediate feedback.

## Usage

- Set the BeatSaber installation directory
- Go to **Songs** or **Playlists**
- Start download from song actions or playlist missing-song actions
- Manage running tasks in **Downloads**

**⚠️ Due to Bilibili platform restrictions, only downloads up to 480p are supported without logging in.**

[how-do-i-pass-cookies-to-yt-dlp](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp)

## yt-dlp Requirements

The version downloaded by ModAssistant is usually outdated. Please update `yt-dlp` to the latest version.

Recommended: latest stable upstream version.

## yt-dlp Configuration

If you need custom `yt-dlp` options, add them to:
`<BeatSaberDir>\UserData\yt-dlp.conf`

For specific configuration details, please refer to the yt-dlp configuration guide [yt-dlp](https://github.com/yt-dlp/yt-dlp)
