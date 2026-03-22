import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Core/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';

class ErrorPresenter {
  static void show(
    BuildContext context,
    AppError error, {
    ErrorPresentLevel? overrideLevel,
    VoidCallback? onRetry,
  }) {
    final level = overrideLevel ?? error.defaultPresentLevel;
    final l10n = AppLocalizations.of(context);
    final message = l10n != null
        ? _localizedMessage(l10n, error.userMessageKey)
        : error.userMessageKey;

    switch (level) {
      case ErrorPresentLevel.silent:
        return;
      case ErrorPresentLevel.inline:
        return;
      case ErrorPresentLevel.snackBar:
        _showSnackBar(context, message, error.retryable, onRetry);
      case ErrorPresentLevel.modal:
        _showModal(context, message, error.detail, onRetry);
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    bool retryable,
    VoidCallback? onRetry,
  ) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.error, width: 1),
        ),
        action: retryable && onRetry != null
            ? SnackBarAction(
                label: l10n?.error_retry ?? 'Retry',
                textColor: AppColors.warning,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _showModal(
    BuildContext context,
    String message,
    String? detail,
    VoidCallback? onRetry,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(l10n?.error_title ?? 'Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry();
              },
              child: Text(l10n?.error_retry ?? 'Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.error_ok ?? 'OK'),
          ),
        ],
      ),
    );
  }

  static final _l10nMap = <String, String Function(AppLocalizations)>{
    'error_file_locked': (l) => l.error_file_locked,
    'error_ytdlp_video_unavailable': (l) => l.error_ytdlp_video_unavailable,
    'error_ytdlp_age_restricted': (l) => l.error_ytdlp_age_restricted,
    'error_ytdlp_network': (l) => l.error_ytdlp_network,
    'error_ytdlp_invalid_url': (l) => l.error_ytdlp_invalid_url,
    'error_ytdlp_not_found': (l) => l.error_ytdlp_not_found,
    'error_ytdlp_search_timeout': (l) => l.error_ytdlp_search_timeout,
    'error_ytdlp_unknown': (l) => l.error_ytdlp_unknown,
  };

  static String _localizedMessage(AppLocalizations l10n, String key) {
    final getter = _l10nMap[key];
    if (getter != null) return getter(l10n);
    return key;
  }
}
