import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'cinema_search_event.dart';
part 'cinema_search_state.dart';

enum CinemaSearchPlatform {
  bilibili,
  youtube
}

class CinemaSearchBloc extends Bloc<CinemaSearchEvent, CinemaSearchState> {
  CinemaSearchBloc() : super(CinemaSearchInitial()) {
    on<CinameSearchTextEvent>((event, emit) {
      searchCinema(event.searchText, event.platform);
    });
  }

  void searchCinema(String text, CinemaSearchPlatform platform) async {
    String dlpPath = "yt-dlp.exe";
    ProcessResult pr = await Process.run(dlpPath, []);
    String searchResultStr = pr.stdout as String;
    String searchError = pr.stderr as String;
    print(searchResultStr);
  }
}
