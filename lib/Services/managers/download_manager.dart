import 'dart:async';
import 'dart:collection';

import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/ytdlp_service.dart';

class DownloadTask {
  final String taskId;
  final String url;
  final String outputDir;
  final String title;
  final String? quality;
  DownloadStatus status;
  double progress;
  String? errorMessage;
  String? outputPath;
  final Future<DownloadResult> Function(
          DownloadTask task, void Function(double progress) onProgress)?
      customRunner;
  final Future<void> Function(DownloadTask task)? customCancel;
  final Map<String, String> metadata;

  DownloadTask({
    required this.taskId,
    required this.url,
    required this.outputDir,
    required this.title,
    this.quality,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.errorMessage,
    this.outputPath,
    this.customRunner,
    this.customCancel,
    this.metadata = const {},
  });
}

class DownloadManager {
  final YtDlpService _service;
  final int maxConcurrent;

  final List<DownloadTask> _tasks = [];
  final Queue<DownloadTask> _queue = Queue();
  int _activeCount = 0;

  final _controller = StreamController<List<DownloadTask>>.broadcast();
  Stream<List<DownloadTask>> get taskStream => _controller.stream;
  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  DownloadManager(this._service, {this.maxConcurrent = 3});

  String enqueue({
    required String url,
    required String outputDir,
    required String title,
    String? quality,
    Map<String, String> metadata = const {},
  }) {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = DownloadTask(
      taskId: taskId,
      url: url,
      outputDir: outputDir,
      title: title,
      quality: quality,
      metadata: metadata,
    );
    _tasks.add(task);
    _queue.add(task);
    log.i(
      '[DownloadManager] enqueue taskId=$taskId title=$title '
      'url=$url queueSize=${_queue.length}',
    );
    _notify();
    _processQueue();
    return taskId;
  }

  String enqueueCustom({
    required String title,
    Map<String, String> metadata = const {},
    Future<DownloadResult> Function(
            DownloadTask task, void Function(double progress) onProgress)?
        runner,
    Future<void> Function(DownloadTask task)? cancel,
  }) {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = DownloadTask(
      taskId: taskId,
      url: '',
      outputDir: '',
      title: title,
      metadata: metadata,
      customRunner: runner,
      customCancel: cancel,
    );
    _tasks.add(task);
    _queue.add(task);
    log.i(
      '[DownloadManager] enqueue custom taskId=$taskId title=$title '
      'queueSize=${_queue.length}',
    );
    _notify();
    _processQueue();
    return taskId;
  }

  void retry(String taskId) {
    final idx = _tasks.indexWhere((t) => t.taskId == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];
    task.status = DownloadStatus.pending;
    task.progress = 0;
    task.errorMessage = null;
    _queue.add(task);
    log.i('[DownloadManager] retry taskId=$taskId');
    _notify();
    _processQueue();
  }

  Future<void> cancel(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.taskId == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];
    if (task.status == DownloadStatus.downloading) {
      if (task.customCancel != null) {
        await task.customCancel!(task);
      } else {
        await _service.cancelDownload(taskId);
      }
    }
    task.status = DownloadStatus.cancelled;
    log.i('[DownloadManager] cancel taskId=$taskId');
    _queue.removeWhere((t) => t.taskId == taskId);
    _notify();
  }

  Future<void> cancelAll() async {
    log.i('[DownloadManager] cancel all tasks count=${_tasks.length}');
    for (final task in _tasks) {
      if (task.status == DownloadStatus.downloading) {
        if (task.customCancel != null) {
          await task.customCancel!(task);
        } else {
          await _service.cancelDownload(task.taskId);
        }
      }
      if (task.status == DownloadStatus.pending ||
          task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.cancelled;
      }
    }
    _queue.clear();
    _activeCount = 0;
    _notify();
  }

  void _processQueue() {
    while (_activeCount < maxConcurrent && _queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (task.status != DownloadStatus.pending) continue;
      _activeCount++;
      task.status = DownloadStatus.downloading;
      log.i(
        '[DownloadManager] start taskId=${task.taskId} '
        'active=$_activeCount remainingQueue=${_queue.length}',
      );
      _notify();
      _runTask(task);
    }
  }

  Future<void> _runTask(DownloadTask task) async {
    try {
      final result = task.customRunner != null
          ? await task.customRunner!(
              task,
              (progress) {
                task.progress = progress;
                _notify();
              },
            )
          : await _service.download(
              task.url,
              task.outputDir,
              taskId: task.taskId,
              quality: task.quality,
              onProgress: (p) {
                task.progress = p.percent / 100;
                _notify();
              },
            );
      task.status = result.status;
      task.outputPath = result.outputPath;
      task.errorMessage = result.errorMessage;
      log.i(
        '[DownloadManager] finish taskId=${task.taskId} status=${task.status.name}',
      );
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      log.e('[DownloadManager] exception taskId=${task.taskId} error=$e', e);
    } finally {
      _activeCount--;
      _notify();
      _processQueue();
    }
  }

  void _notify() {
    _controller.add(List.unmodifiable(_tasks));
  }

  void dispose() {
    _controller.close();
  }
}
