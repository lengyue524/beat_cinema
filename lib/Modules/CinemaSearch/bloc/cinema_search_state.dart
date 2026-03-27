part of 'cinema_search_bloc.dart';

@immutable
sealed class CinemaSearchState {}

final class CinemaSearchInitial extends CinemaSearchState {}

final class CinemaSearchLoading extends CinemaSearchState {}

final class CinemaSearchLoaded extends CinemaSearchState {
  CinemaSearchLoaded({required this.videoInfos});
  final List<DlpVideoInfo> videoInfos;
}

final class CinemaSearchFailure extends CinemaSearchState {
  CinemaSearchFailure({
    required this.errorKey,
  });

  final String errorKey;
}
