import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoInfo.fromMap', () {
    test('prefers playable stream url over original webpage url', () {
      final info = VideoInfo.fromMap({
        'title': 'demo',
        'original_url': 'https://www.youtube.com/watch?v=abc',
        'url': 'https://rr.example/video_stream.m3u8',
      });

      expect(info.url, 'https://rr.example/video_stream.m3u8');
    });
  });
}
