import 'package:beat_cinema/Core/errors/app_error.dart';

class YtDlpErrorMapper {
  static AppError map(String stderr, int exitCode) {
    final lower = stderr.toLowerCase();

    if (lower.contains('http error 403') ||
        lower.contains('video unavailable')) {
      return const AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_video_unavailable',
        retryable: false,
      );
    }

    if (lower.contains('age-restricted') ||
        lower.contains('sign in to confirm')) {
      return const AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_age_restricted',
        retryable: false,
      );
    }

    if (lower.contains('unable to download') ||
        lower.contains('connection') ||
        lower.contains('timed out') ||
        lower.contains('urlopen error')) {
      return AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_network',
        detail: stderr.length > 200 ? stderr.substring(0, 200) : stderr,
        retryable: true,
      );
    }

    if (lower.contains('not a valid url') ||
        lower.contains('unsupported url')) {
      return AppError(
        type: AppErrorType.parse,
        userMessageKey: 'error_ytdlp_invalid_url',
        detail: stderr,
        retryable: false,
      );
    }

    if (lower.contains('is not recognized') ||
        lower.contains('no such file')) {
      return const AppError(
        type: AppErrorType.process,
        userMessageKey: 'error_ytdlp_not_found',
        detail: 'yt-dlp executable not found',
        retryable: false,
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      userMessageKey: 'error_ytdlp_unknown',
      detail: 'exit=$exitCode ${stderr.length > 200 ? stderr.substring(0, 200) : stderr}',
      retryable: true,
    );
  }
}
