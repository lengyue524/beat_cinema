part of 'cinema_search_bloc.dart';

@immutable
sealed class CinemaSearchEvent {}

class CinameSearchTextEvent extends CinemaSearchEvent {
  CinameSearchTextEvent(this.searchText, this.count, this.appBloc);
  final String searchText;
  final int count;
  final AppBloc appBloc;
}
