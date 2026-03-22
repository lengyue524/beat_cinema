import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  static Widget noLevels(BuildContext context, {VoidCallback? onSetPath}) {
    final l10n = AppLocalizations.of(context);
    return EmptyStateWidget(
      icon: Icons.library_music_outlined,
      title: l10n?.empty_no_levels ?? 'No levels found',
      description: l10n?.empty_no_levels_desc ?? 'Set your Beat Saber path in settings',
      actionLabel: l10n?.empty_no_levels_action ?? 'Open Settings',
      onAction: onSetPath,
    );
  }

  static Widget noSearchResults(BuildContext context, {VoidCallback? onClear}) {
    final l10n = AppLocalizations.of(context);
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: l10n?.empty_no_search ?? 'No results',
      description: l10n?.empty_no_search_desc ?? 'Try a different search term',
      actionLabel: l10n?.empty_no_search_action ?? 'Clear search',
      onAction: onClear,
    );
  }

  static Widget noFilterResults(BuildContext context, {VoidCallback? onClear}) {
    final l10n = AppLocalizations.of(context);
    return EmptyStateWidget(
      icon: Icons.filter_alt_off,
      title: l10n?.empty_no_filter ?? 'No matches',
      description: l10n?.empty_no_filter_desc ?? 'No levels match the current filters',
      actionLabel: l10n?.empty_no_filter_action ?? 'Clear filters',
      onAction: onClear,
    );
  }

  static Widget noVideoResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyStateWidget(
      icon: Icons.video_library_outlined,
      title: l10n?.empty_no_video ?? 'No videos found',
      description: l10n?.empty_no_video_desc ?? 'Try different keywords or another platform',
    );
  }

  static Widget noDownloads(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyStateWidget(
      icon: Icons.download_outlined,
      title: l10n?.empty_no_downloads ?? 'No downloads',
      description: l10n?.empty_no_downloads_desc ?? 'Search for videos or paste a URL to start',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: AppColors.brandPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
