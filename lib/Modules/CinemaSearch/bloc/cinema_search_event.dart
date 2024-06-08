part of 'cinema_search_bloc.dart';

@immutable
sealed class CinemaSearchEvent {}

class CinameSearchTextEvent extends CinemaSearchEvent{
  CinameSearchTextEvent(this.searchText, this.platform);
  final String searchText;
  final CinemaSearchPlatform platform;
}