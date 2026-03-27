import 'dart:io';

import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Modules/Playlists/playlist_cover_candidates.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PlaylistCoverPickerResult {
  const PlaylistCoverPickerResult._({
    this.filePath,
    required this.clearRequested,
  });

  const PlaylistCoverPickerResult.selected(String filePath)
      : this._(filePath: filePath, clearRequested: false);

  const PlaylistCoverPickerResult.clear()
      : this._(filePath: null, clearRequested: true);

  final String? filePath;
  final bool clearRequested;
}

class PlaylistCoverPickerDialog extends StatelessWidget {
  const PlaylistCoverPickerDialog({
    super.key,
    required this.candidates,
  });

  final List<PlaylistCoverCandidate> candidates;

  static Future<PlaylistCoverPickerResult?> show(
    BuildContext context, {
    required List<PlaylistCoverCandidate> candidates,
  }) {
    return showDialog<PlaylistCoverPickerResult>(
      context: context,
      builder: (_) => PlaylistCoverPickerDialog(candidates: candidates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: const Text('选择歌单封面'),
      content: SizedBox(
        width: 420,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: candidates.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) {
            final item = candidates[index];
            return ListTile(
              key: ValueKey('playlist-cover-item-$index'),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(item.filePath),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 40,
                      height: 40,
                      color: AppColors.surface3,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    );
                  },
                ),
              ),
              title: Text(
                item.songName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(
                PlaylistCoverPickerResult.selected(item.filePath),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.common_cancel ?? '取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const PlaylistCoverPickerResult.clear(),
          ),
          child: const Text('清除封面'),
        ),
      ],
    );
  }
}
