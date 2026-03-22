import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.progress = 0,
  });

  final VideoConfigStatus status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(child: _buildIcon(l10n)),
    );
  }

  Widget _buildIcon(AppLocalizations? l10n) {
    switch (status) {
      case VideoConfigStatus.none:
        return Text(
          '─',
          style: const TextStyle(fontSize: 14, color: AppColors.textDisabled),
          semanticsLabel: l10n?.sem_status_no_video ?? '无视频',
        );
      case VideoConfigStatus.configured:
        return Icon(
          Icons.movie,
          size: 20,
          color: AppColors.brandPurple,
          semanticLabel: l10n?.sem_status_configured ?? '视频已配置',
        );
      case VideoConfigStatus.configuredMissingFile:
        return Icon(
          Icons.cloud_download,
          size: 20,
          color: AppColors.warning,
          semanticLabel:
              l10n?.sem_status_configured_missing_file ?? '视频文件缺失，可下载',
        );
      case VideoConfigStatus.downloading:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2,
            color: AppColors.info,
            semanticsLabel: l10n?.sem_status_downloading ?? '正在下载视频',
          ),
        );
      case VideoConfigStatus.error:
        return Icon(
          Icons.warning_amber,
          size: 20,
          color: AppColors.error,
          semanticLabel: l10n?.sem_status_error ?? '视频状态异常',
        );
    }
  }
}
