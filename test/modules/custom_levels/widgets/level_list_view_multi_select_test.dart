import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_tile.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/Modules/Panel/cubit/panel_cubit.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness(
    List<LevelMetadata> levels, {
    DeleteSongDirectoriesHandler? onDeleteSongDirectories,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(create: (_) => AppBloc()),
        BlocProvider<PanelCubit>(create: (_) => PanelCubit()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LevelListView.fromLevels(
            levels: levels,
            onDeleteSongDirectories: onDeleteSongDirectories,
          ),
        ),
      ),
    );
  }

  LevelMetadata buildMeta({
    required String path,
    required String songName,
  }) {
    return LevelMetadata(
      levelPath: path,
      songName: songName,
      songAuthorName: 'Author',
      lastModified: DateTime(2026, 1, 1),
      cinemaConfig: CinemaConfig(videoUrl: 'https://example.com/v.mp4'),
      videoStatus: VideoConfigStatus.configuredMissingFile,
    );
  }

  testWidgets('supports ctrl multi selection and shift range selection',
      (tester) async {
    final levels = [
      buildMeta(path: r'D:\Levels\A', songName: 'Song A'),
      buildMeta(path: r'D:\Levels\B', songName: 'Song B'),
      buildMeta(path: r'D:\Levels\C', songName: 'Song C'),
    ];
    await tester.pumpWidget(buildHarness(levels));

    Finder selectedTiles() => find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>)
                  .value
                  .startsWith('level-tile-selected-'),
        );

    await tester.tap(find.byType(LevelListTile).first);
    await tester.pump();
    expect(selectedTiles(), findsNWidgets(1));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byType(LevelListTile).at(1));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(selectedTiles(), findsNWidgets(2));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byType(LevelListTile).at(2));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selectedTiles(), findsNWidgets(2));
  });

  testWidgets('right click menu switches to batch actions in multi-select',
      (tester) async {
    final levels = [
      buildMeta(path: r'D:\Levels\A', songName: 'Song A'),
      buildMeta(path: r'D:\Levels\B', songName: 'Song B'),
    ];
    await tester.pumpWidget(buildHarness(levels));

    await tester.tap(find.byType(LevelListTile).first);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byType(LevelListTile).at(1));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    await tester.tapAt(
      tester.getCenter(find.byType(LevelListTile).at(1)),
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();

    expect(find.text('已选择 2 项'), findsOneWidget);
    expect(find.text('添加到歌单'), findsOneWidget);
    expect(find.text('删除歌曲目录'), findsOneWidget);
    expect(find.text('搜索视频'), findsNothing);
  });

  testWidgets('tap empty area clears current selection', (tester) async {
    final levels = [
      buildMeta(path: r'D:\Levels\A', songName: 'Song A'),
      buildMeta(path: r'D:\Levels\B', songName: 'Song B'),
    ];
    await tester.pumpWidget(buildHarness(levels));

    Finder selectedTiles() => find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>)
                  .value
                  .startsWith('level-tile-selected-'),
        );

    await tester.tap(find.byType(LevelListTile).first);
    await tester.pump();
    expect(selectedTiles(), findsNWidgets(1));

    final listRect = tester.getRect(find.byType(LevelListView));
    await tester.tapAt(Offset(listRect.center.dx, listRect.bottom - 4));
    await tester.pump();

    expect(selectedTiles(), findsNothing);
  });

}
