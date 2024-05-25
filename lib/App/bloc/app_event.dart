part of 'app_bloc.dart';
enum AppLocal {
  en,
  zh
}
@immutable
sealed class AppEvent {}

final class AppLoadComplatedEvent extends AppEvent {
  AppLoadComplatedEvent(this.local);
  final AppLocal local;
}