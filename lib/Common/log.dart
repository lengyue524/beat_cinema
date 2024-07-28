import 'package:logging/logging.dart';

final log = Logger("BeatCinema");

extension BeatLogger on Logger {
  void d(Object? message, [Object? error, StackTrace? stackTrace]) {
    finest(message, error, stackTrace);
  }

  void i(Object? message, [Object? error, StackTrace? stackTrace]) {
    info(message, error, stackTrace);
  }

  void w(Object? message, [Object? error, StackTrace? stackTrace]) {
    warning(message, error, stackTrace);
  }

  void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    shout(message, error, stackTrace);
  }
}
