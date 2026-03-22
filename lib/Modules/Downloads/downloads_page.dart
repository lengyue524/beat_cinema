import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:flutter/material.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key, this.downloadManager});

  final DownloadManager? downloadManager;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final manager = downloadManager;
    if (manager == null) {
      return Center(
        child: Text(
          l10n?.nav_downloads ?? 'Downloads',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<DownloadTask>>(
            stream: manager.taskStream,
            initialData: manager.tasks,
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    l10n?.download_empty ?? 'No downloads',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return _DownloadTaskTile(
                    task: tasks[index],
                    onRetry: () => manager.retry(tasks[index].taskId),
                    onCancel: () => manager.cancel(tasks[index].taskId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  const _DownloadTaskTile({
    required this.task,
    required this.onRetry,
    required this.onCancel,
  });

  final DownloadTask task;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (task.status == DownloadStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh,
                      size: 18, color: AppColors.warning),
                  onPressed: onRetry,
                  tooltip: 'Retry',
                ),
              if (task.status == DownloadStatus.downloading ||
                  task.status == DownloadStatus.pending)
                IconButton(
                  icon:
                      const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: onCancel,
                  tooltip: 'Cancel',
                ),
            ],
          ),
          if (task.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, left: 32),
              child: LinearProgressIndicator(
                value: task.progress > 0 ? task.progress : null,
                color: AppColors.brandPurple,
                backgroundColor: AppColors.surface3,
              ),
            ),
          if (task.status == DownloadStatus.failed && task.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, left: 32),
              child: Text(
                task.errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    switch (task.status) {
      case DownloadStatus.pending:
        return const Icon(Icons.schedule,
            size: 20, color: AppColors.textSecondary);
      case DownloadStatus.downloading:
        return const SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle,
            size: 20, color: AppColors.brandPurple);
      case DownloadStatus.failed:
        return const Icon(Icons.error, size: 20, color: AppColors.error);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel,
            size: 20, color: AppColors.textDisabled);
    }
  }
}
