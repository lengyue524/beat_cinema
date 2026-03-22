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
          ),
        ),
      ),
    );

    expect(find.text('Song A'), findsNothing);
    expect(find.byIcon(Icons.stop), findsNothing);
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
}
