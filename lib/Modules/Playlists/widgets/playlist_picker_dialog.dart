import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaylistPickerDialog extends StatefulWidget {
  const PlaylistPickerDialog({
    super.key,
    required this.playlists,
    required this.mode,
    this.currentPlaylistPath,
    this.initialQuery = '',
  });

  final List<PlaylistWithStatus> playlists;
  final PlaylistMutationMode mode;
  final String? currentPlaylistPath;
  final String initialQuery;

  static Future<String?> show(
    BuildContext context, {
    required List<PlaylistWithStatus> playlists,
    required PlaylistMutationMode mode,
    String? currentPlaylistPath,
    String initialQuery = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PlaylistPickerDialog(
        playlists: playlists,
        mode: mode,
        currentPlaylistPath: currentPlaylistPath,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<PlaylistPickerDialog> createState() => _PlaylistPickerDialogState();
}

class _PlaylistPickerDialogState extends State<PlaylistPickerDialog> {
  late final TextEditingController _queryController;
  String _query = '';
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _queryController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidates = _buildCandidates();
    final normalizedActiveIndex = _normalizeActiveIndex(candidates);
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _onKeyEvent(event, candidates),
      child: AlertDialog(
        title: Text(
          widget.mode == PlaylistMutationMode.move
              ? (l10n?.playlist_move_to_playlist ?? '移动到歌单')
              : (l10n?.ctx_add_to_playlist ?? '添加到歌单'),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('playlist-picker-search-input'),
                controller: _queryController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                    _activeIndex = _findFirstEnabledIndex(_buildCandidates());
                  });
                },
                decoration: InputDecoration(
                  hintText: l10n?.playlist_picker_search_hint ?? '搜索歌单名称',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: candidates.isEmpty
                    ? Center(
                        child: Text(
                          l10n?.playlist_picker_empty ?? '未找到可选歌单',
                          key: const ValueKey('playlist-picker-empty'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final candidate = candidates[index];
                          final disabled = candidate.disabled;
                          return ListTile(
                            key: ValueKey('playlist-picker-item-$index'),
                            selected: index == normalizedActiveIndex && !disabled,
                            enabled: !disabled,
                            title: _buildHighlightedTitle(candidate.title, _query),
                            subtitle: disabled
                                ? Text(
                                    l10n?.playlist_picker_current_disabled ??
                                        '当前歌单不可作为移动目标',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            onTap: disabled
                                ? null
                                : () => Navigator.of(context).pop(candidate.path),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.common_cancel ?? '取消'),
          ),
        ],
      ),
    );
  }

  List<_PlaylistCandidate> _buildCandidates() {
    final query = _query.toLowerCase();
    return widget.playlists.where((playlist) {
      if (query.isEmpty) return true;
      return playlist.info.title.toLowerCase().contains(query);
    }).map((playlist) {
      final isCurrent = widget.currentPlaylistPath != null &&
          widget.currentPlaylistPath == playlist.info.filePath;
      final disabled = widget.mode == PlaylistMutationMode.move && isCurrent;
      return _PlaylistCandidate(
        title: playlist.info.title,
        path: playlist.info.filePath,
        disabled: disabled,
      );
    }).toList(growable: false);
  }

  Widget _buildHighlightedTitle(String title, String query) {
    if (query.isEmpty) return Text(title);
    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerTitle.indexOf(lowerQuery);
    if (index < 0) return Text(title);
    final end = index + query.length;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(
            text: title.substring(index, end),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: title.substring(end)),
        ],
      ),
    );
  }

  int _findFirstEnabledIndex(List<_PlaylistCandidate> candidates) {
    for (var i = 0; i < candidates.length; i++) {
      if (!candidates[i].disabled) return i;
    }
    return -1;
  }

  int _normalizeActiveIndex(List<_PlaylistCandidate> candidates) {
    if (candidates.isEmpty) return -1;
    if (_activeIndex >= 0 &&
        _activeIndex < candidates.length &&
        !candidates[_activeIndex].disabled) {
      return _activeIndex;
    }
    return _findFirstEnabledIndex(candidates);
  }

  KeyEventResult _onKeyEvent(
    KeyEvent event,
    List<_PlaylistCandidate> candidates,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _activeIndex = _moveActiveIndex(candidates, forward: true);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _activeIndex = _moveActiveIndex(candidates, forward: false);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final index = _normalizeActiveIndex(candidates);
      if (index >= 0 && index < candidates.length) {
        final candidate = candidates[index];
        if (!candidate.disabled) {
          Navigator.of(context).pop(candidate.path);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int _moveActiveIndex(
    List<_PlaylistCandidate> candidates, {
    required bool forward,
  }) {
    if (candidates.isEmpty) return -1;
    var current = _normalizeActiveIndex(candidates);
    if (current < 0) return -1;
    for (var step = 1; step <= candidates.length; step++) {
      final index = forward
          ? (current + step) % candidates.length
          : (current - step + candidates.length) % candidates.length;
      if (!candidates[index].disabled) {
        return index;
      }
    }
    return current;
  }
}

class _PlaylistCandidate {
  const _PlaylistCandidate({
    required this.title,
    required this.path,
    required this.disabled,
  });

  final String title;
  final String path;
  final bool disabled;
}
