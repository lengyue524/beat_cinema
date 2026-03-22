import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Modules/Panel/cubit/panel_cubit.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PanelHost extends StatelessWidget {
  const PanelHost({super.key, required this.contentBuilder});

  static const double panelWidth = 350;

  final Widget Function(PanelContentType type, dynamic context)
      contentBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PanelCubit, PanelState>(
      builder: (context, state) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (state.isOpen) {
                context.read<PanelCubit>().closePanel();
              }
            },
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: state.isOpen ? panelWidth : 0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(
                left: BorderSide(color: AppColors.brandPurple, width: 1),
              ),
            ),
            child: state.isOpen && state.contentType != null
                ? OverflowBox(
                    alignment: Alignment.topLeft,
                    maxWidth: panelWidth,
                    minWidth: panelWidth,
                    child: SizedBox(
                      width: panelWidth,
                      child: Column(
                        children: [
                          _PanelHeader(
                            title:
                                _panelTitle(context, state.contentType!),
                          ),
                          Expanded(
                            child: contentBuilder(
                                state.contentType!, state.context),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  static String _panelTitle(BuildContext context, PanelContentType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case PanelContentType.search:
        return l10n?.panel_search ?? 'Search';
      case PanelContentType.configEdit:
        return l10n?.panel_config_edit ?? 'Edit Config';
      case PanelContentType.fileInfo:
        return l10n?.panel_file_info ?? 'File Info';
      case PanelContentType.downloadDetail:
        return l10n?.panel_download ?? 'Download';
      case PanelContentType.audioPreview:
        return l10n?.panel_audio_preview ?? 'Audio Preview';
      case PanelContentType.videoPreview:
        return l10n?.panel_video_preview ?? 'Video Preview';
      case PanelContentType.syncCalibration:
        return l10n?.panel_sync ?? 'Sync Calibration';
    }
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => context.read<PanelCubit>().closePanel(),
          ),
        ],
      ),
    );
  }
}
