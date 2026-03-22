import 'package:beat_cinema/Modules/CustomLevels/widgets/mini_audio_player_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not render when invisible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniAudioPlayerBar(
            visible: false,
            songName: 'Song A',
            onStop: () {},
            stopTooltip: 'Stop',
            position: Duration.zero,
            duration: Duration.zero,
          ),
        ),
      ),
    );

    expect(find.text('Song A'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('renders and triggers stop callback when visible', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniAudioPlayerBar(
            visible: true,
            songName: 'Song B',
            onStop: () => tapped = true,
            stopTooltip: 'Stop',
            position: const Duration(seconds: 10),
            duration: const Duration(seconds: 100),
          ),
        ),
      ),
    );

    expect(find.text('Song B'), findsOneWidget);
    expect(find.byTooltip('Stop'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('dragging progress triggers seek callback', (tester) async {
    Duration? seekedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniAudioPlayerBar(
            visible: true,
            songName: 'Song C',
            onStop: () {},
            stopTooltip: 'Stop',
            position: const Duration(seconds: 5),
            duration: const Duration(seconds: 120),
            onSeek: (value) => seekedTo = value,
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    await tester.drag(sliderFinder, const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 120));

    expect(seekedTo, isNotNull);
    expect(seekedTo!.inMilliseconds, greaterThan(0));
  });
}
