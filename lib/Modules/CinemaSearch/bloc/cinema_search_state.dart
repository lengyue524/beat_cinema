part of 'cinema_search_bloc.dart';

@immutable
sealed class CinemaSearchState {}

final class CinemaSearchInitial extends CinemaSearchState {}

final class CinemaSearchLoading extends CinemaSearchState {}

final class CinemaSearchLoaded extends CinemaSearchState {}