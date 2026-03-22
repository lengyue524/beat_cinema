import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:beat_cinema/Services/services/ytdlp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YtDlpService.buildPlayableUrlArgs', () {
    test('includes proxy and playback extraction args in custom mode', () async {
      final args = await YtDlpService.buildPlayableUrlArgs(
        url: 'https://www.youtube.com/watch?v=abc',
        extractorArgs: 'youtube:player_client=android,web',
        formatSelector: 'best[ext=mp4]/best',
        proxyMode: ProxyMode.custom,
        customProxy: '127.0.0.1:7890',
      );

      expect(
        args,
        equals([
          '-g',
          '--no-playlist',
          '--no-warnings',
          '--extractor-args',
          'youtube:player_client=android,web',
          '-f',
          'best[ext=mp4]/best',
          '--proxy',
          'http://127.0.0.1:7890',
          'https://www.youtube.com/watch?v=abc',
        ]),
      );
    });

    test('omits proxy when mode is none', () async {
      final args = await YtDlpService.buildPlayableUrlArgs(
        url: 'https://www.bilibili.com/video/BV1xx411c7mD',
        extractorArgs: 'youtube:player_client=tv,web;formats=missing_pot',
        formatSelector: 'best',
        proxyMode: ProxyMode.none,
        customProxy: '',
      );

      expect(args.contains('--proxy'), isFalse);
      expect(args.last, 'https://www.bilibili.com/video/BV1xx411c7mD');
    });
  });
}
