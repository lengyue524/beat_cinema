part of 'app_bloc.dart';

@immutable
sealed class AppState {}

final class AppInitial extends AppState {}


final class AppLaunchComplated extends AppState {
  AppLaunchComplated(this.local);
  final AppLocal local;
}