import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CinemaSearchBloc.buildSearchArgs', () {
    test('youtube search includes proxy when provided', () {
      final args = CinemaSearchBloc.buildSearchArgs(
        platform: CinemaSearchPlatform.youtube,
        count: 20,
        text: 'test song',
        proxyUrl: 'http://127.0.0.1:7890',
      );

      expect(
        args,
        equals([
          '--proxy',
          'http://127.0.0.1:7890',
          'ytsearch20:test song',
          '-j',
        ]),
      );
    });

    test('bilibili search omits proxy when not configured', () {
      final args = CinemaSearchBloc.buildSearchArgs(
        platform: CinemaSearchPlatform.bilibili,
        count: 5,
        text: 'abc',
        proxyUrl: null,
      );

      expect(args, equals(['bilisearch5:abc', '-j']));
    });
  });

  group('CinemaSearchBloc.buildSearchCacheKey', () {
    test('normalizes query and proxy for stable cache key', () {
      final key = CinemaSearchBloc.buildSearchCacheKey(
        platform: CinemaSearchPlatform.youtube,
        count: 20,
        text: '  Hello World  ',
        proxyUrl: ' HTTP://127.0.0.1:7890 ',
      );

      expect(
        key,
        equals('youtube|20|hello world|http://127.0.0.1:7890'),
      );
    });
  });
}
