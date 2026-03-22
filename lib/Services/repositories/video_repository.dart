enum VideoPlatform { youtube, bilibili }

class VideoSearchResult {
  final String id;
  final String title;
  final String url;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? author;
  final VideoPlatform platform;

  const VideoSearchResult({
    required this.id,
    required this.title,
    required this.url,
    this.durationSeconds = 0,
    this.thumbnailUrl,
    this.author,
    required this.platform,
  });

  factory VideoSearchResult.fromMap(Map<String, dynamic> map, {VideoPlatform platform = VideoPlatform.youtube}) {
    return VideoSearchResult(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? map['original_url'] as String? ?? '',
      durationSeconds: (map['duration'] as num?)?.toInt() ?? 0,
      thumbnailUrl: map['thumbnail'] as String?,
      author: map['uploader'] as String? ?? map['channel'] as String?,
      platform: platform,
    );
  }
}

class VideoInfo {
  final String title;
  final String url;
  final int durationSeconds;
  final String? ext;

  const VideoInfo({
    required this.title,
    required this.url,
    this.durationSeconds = 0,
    this.ext,
  });

  factory VideoInfo.fromMap(Map<String, dynamic> map) {
    return VideoInfo(
      title: map['title'] as String? ?? '',
      // Prefer direct/playable stream URL for in-app playback.
      url: map['url'] as String? ?? map['original_url'] as String? ?? '',
      durationSeconds: (map['duration'] as num?)?.toInt() ?? 0,
      ext: map['ext'] as String?,
    );
  }
}

class DownloadProgress {
  final String taskId;
  final double percent;
  final String? speed;
  final String? eta;

  const DownloadProgress({
    required this.taskId,
    this.percent = 0,
    this.speed,
    this.eta,
  });
}

enum DownloadStatus { pending, downloading, completed, failed, cancelled }

class DownloadResult {
  final String taskId;
  final DownloadStatus status;
  final String? outputPath;
  final String? errorMessage;

  const DownloadResult({
    required this.taskId,
    required this.status,
    this.outputPath,
    this.errorMessage,
  });
}

abstract class VideoRepository {
  Future<List<VideoSearchResult>> search(
      String query, VideoPlatform platform);

  Future<DownloadResult> download(
    String url,
    String outputDir, {
    String? taskId,
    String? quality,
    void Function(DownloadProgress)? onProgress,
  });

  Future<void> cancelDownload(String taskId);

  Future<VideoInfo> getVideoInfo(String url);
}
