import 'dart:io';

import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileInfoPanel extends StatelessWidget {
  const FileInfoPanel({super.key, required this.metadata});
  final LevelMetadata metadata;

  static const _videoExtensions = {'.mp4', '.mkv', '.webm', '.avi', '.mov'};

  List<File> _findVideoFiles() {
    final dir = Directory(metadata.levelPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            _videoExtensions.contains(p.extension(f.path).toLowerCase()))
        .toList();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final videoFiles = _findVideoFiles();
    final referencedFile = metadata.cinemaConfig?.videoFile;

    if (videoFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            l10n?.file_info_no_videos ?? 'No video files in this level',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: videoFiles.length,
      itemBuilder: (context, index) {
        final file = videoFiles[index];
        final name = p.basename(file.path);
        final ext =
            p.extension(file.path).toUpperCase().replaceFirst('.', '');
        final size = _formatSize(file.lengthSync());
        final isReferenced = referencedFile != null && name == referencedFile;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isReferenced ? AppColors.surface3 : AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
            border: isReferenced
                ? Border.all(color: AppColors.brandPurple, width: 1)
                : null,
          ),
          child: Row(
            children: [
              const Icon(Icons.video_file,
                  size: 24, color: AppColors.brandPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$ext  •  $size',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isReferenced)
                Tooltip(
                  message:
                      l10n?.file_info_referenced ?? 'Referenced in config',
                  child: const Icon(Icons.link,
                      size: 16, color: AppColors.brandPurple),
                ),
            ],
          ),
        );
      },
    );
  }
}
