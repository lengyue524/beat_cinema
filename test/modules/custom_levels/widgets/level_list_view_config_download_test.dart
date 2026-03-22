import 'dart:async';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/Modules/Panel/cubit/panel_cubit.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/ytdlp_service.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDownloadManager extends DownloadManager {
  _FakeDownloadManager()
      : super(
          YtDlpService(beatSaberPath: r'D:\BeatSaber'),
        );

  final _taskController = StreamController<List<DownloadTask>>.broadcast();
  int enqueueCalls = 0;
  int enqueueCustomCalls = 0;
  String? lastTaskId;

  @override
  Stream<List<DownloadTask>> get taskStream => _taskController.stream;

  @override
  String enqueue({
    required String url,
    required String outputDir,
    required String title,
    String? quality,
    Map<String, String> metadata = const {},
  }) {
    enqueueCalls++;
    lastTaskId = 'task-enqueue-$enqueueCalls';
    return lastTaskId!;
  }

  @override
  String enqueueCustom({
    required String title,
    Map<String, String> metadata = const {},
    Future<DownloadResult> Function(
            DownloadTask task, void Function(double progress) onProgress)?
        runner,
    Future<void> Function(DownloadTask task)? cancel,
  }) {
    enqueueCustomCalls++;
    lastTaskId = 'task-custom-$enqueueCustomCalls';
    return lastTaskId!;
  }

  void emitTasks(List<DownloadTask> tasks) {
    _taskController.add(tasks);
  }

  @override
  void dispose() {
    _taskController.close();
    super.dispose();
  }
}

void main() {
  Widget buildHarness({
    required AppBloc appBloc,
    required List<LevelListItem> items,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>.value(value: appBloc),
        BlocProvider<PanelCubit>(create: (_) => PanelCubit()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LevelListView(items: items),
        ),
      ),
    );
  }

  LevelMetadata buildMeta({String? url, String? videoId}) {
    return LevelMetadata(
      levelPath: r'D:\BeatSaber\CustomLevels\A',
      songName: 'Song A',
      songAuthorName: 'Author A',
      lastModified: DateTime(2026, 1, 1),
      cinemaConfig: CinemaConfig(videoUrl: url, videoId: videoId),
      videoStatus: VideoConfigStatus.configuredMissingFile,
    );
  }

  testWidgets('direct video url uses enqueueCustom and enters pending state',
      (tester) async {
    final appBloc = AppBloc();
    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    final item = LevelListItem.level(
      buildMeta(url: 'https://example.com/video.mp4'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();

    expect(fakeManager.enqueueCustomCalls, 1);
    expect(fakeManager.enqueueCalls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download), findsNothing);
  });

  testWidgets('non direct url uses enqueue', (tester) async {
    final appBloc = AppBloc();
    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    final item = LevelListItem.level(
      buildMeta(url: 'https://www.youtube.com/watch?v=abc'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();

    expect(fakeManager.enqueueCalls, 1);
    expect(fakeManager.enqueueCustomCalls, 0);
  });

  testWidgets('double tap direct download only enqueues once', (tester) async {
    final appBloc = AppBloc();
    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    final item = LevelListItem.level(
      buildMeta(url: 'https://example.com/video.mp4'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    final iconFinder = find.byIcon(Icons.cloud_download);
    expect(iconFinder, findsOneWidget);

    await tester.tap(iconFinder);
    await tester.tap(iconFinder);
    await tester.pump();

    expect(fakeManager.enqueueCustomCalls, 1);
    expect(fakeManager.enqueueCalls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('double tap non direct url only enqueues once', (tester) async {
    final appBloc = AppBloc();
    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    final item = LevelListItem.level(
      buildMeta(url: 'https://www.youtube.com/watch?v=abc'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    final iconFinder = find.byIcon(Icons.cloud_download);
    expect(iconFinder, findsOneWidget);

    await tester.tap(iconFinder);
    await tester.tap(iconFinder);
    await tester.pump();

    expect(fakeManager.enqueueCalls, 1);
    expect(fakeManager.enqueueCustomCalls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('download task completion clears pending state', (tester) async {
    final appBloc = AppBloc();
    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    final item = LevelListItem.level(
      buildMeta(url: 'https://example.com/video.mp4'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final completedTask = DownloadTask(
      taskId: fakeManager.lastTaskId!,
      url: 'https://example.com/video.mp4',
      outputDir: r'D:\BeatSaber\CustomLevels\A',
      title: 'done',
      status: DownloadStatus.completed,
      outputPath: r'D:\BeatSaber\CustomLevels\A',
    );
    fakeManager.emitTasks([completedTask]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.movie), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download), findsNothing);
  });

  testWidgets('videoId fallback builds youtube url and uses enqueue',
      (tester) async {
    final appBloc = AppBloc();
    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    final item = LevelListItem.level(
      buildMeta(videoId: 'dQw4w9WgXcQ'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();

    expect(fakeManager.enqueueCalls, 1);
    expect(fakeManager.enqueueCustomCalls, 0);
  });

  testWidgets('rebinds task stream when manager becomes available later',
      (tester) async {
    final appBloc = AppBloc();
    final item = LevelListItem.level(
      buildMeta(videoId: 'dQw4w9WgXcQ'),
    );
    await tester.pumpWidget(
      buildHarness(
        appBloc: appBloc,
        items: [item],
      ),
    );

    final fakeManager = _FakeDownloadManager();
    appBloc.downloadManager = fakeManager;

    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final completedTask = DownloadTask(
      taskId: fakeManager.lastTaskId!,
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      outputDir: r'D:\BeatSaber\CustomLevels\A',
      title: 'done',
      status: DownloadStatus.completed,
      outputPath: r'D:\BeatSaber\CustomLevels\A',
    );
    fakeManager.emitTasks([completedTask]);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
