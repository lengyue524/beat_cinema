import 'dart:io';

enum AppErrorType {
  fileSystem,
  network,
  process,
  parse,
  unknown,
}

enum ErrorPresentLevel {
  silent,
  inline,
  snackBar,
  modal,
}

class AppError {
  final AppErrorType type;
  final String userMessageKey;
  final String? detail;
  final bool retryable;

  const AppError({
    required this.type,
    required this.userMessageKey,
    this.detail,
    this.retryable = false,
  });

  ErrorPresentLevel get defaultPresentLevel {
    switch (type) {
      case AppErrorType.parse:
        return ErrorPresentLevel.silent;
      case AppErrorType.fileSystem:
        return ErrorPresentLevel.snackBar;
      case AppErrorType.network:
        return ErrorPresentLevel.snackBar;
      case AppErrorType.process:
        return ErrorPresentLevel.modal;
      case AppErrorType.unknown:
        return ErrorPresentLevel.snackBar;
    }
  }

  factory AppError.fromException(Object e, {String? context}) {
    if (e is FileSystemException) {
      return AppError(
        type: AppErrorType.fileSystem,
        userMessageKey: 'error_file_system',
        detail: '${context ?? ''} ${e.message} (path: ${e.path})',
        retryable: true,
      );
    }

    if (e is SocketException) {
      return AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_network',
        detail: '${context ?? ''} ${e.message}',
        retryable: true,
      );
    }

    if (e is ProcessException) {
      return AppError(
        type: AppErrorType.process,
        userMessageKey: 'error_process',
        detail: '${context ?? ''} ${e.executable}: ${e.message}',
        retryable: false,
      );
    }

    if (e is FormatException) {
      return AppError(
        type: AppErrorType.parse,
        userMessageKey: 'error_parse',
        detail: '${context ?? ''} ${e.message}',
        retryable: false,
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      userMessageKey: 'error_unknown',
      detail: '${context ?? ''} $e',
      retryable: false,
    );
  }

  @override
  String toString() => 'AppError($type, key=$userMessageKey, detail=$detail)';
}
