import 'dart:io';

import 'package:beat_cinema/Core/errors/app_error.dart';
import 'package:path/path.dart' as p;

class AtomicFileService {
  static const _windowsSharingViolation = 32;
  static const _maxRetries = 3;

  Future<void> writeString(String filePath, String content) async {
    final tmpPath = '$filePath.tmp';
    final tmpFile = File(tmpPath);

    try {
      await tmpFile.writeAsString(content, flush: true);
    } catch (e) {
      throw AppError.fromException(e, context: 'write tmp');
    }

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        await tmpFile.rename(filePath);
        return;
      } on FileSystemException catch (e) {
        if (_isFileLocked(e) && attempt < _maxRetries - 1) {
          await Future.delayed(
              Duration(milliseconds: 1000 * (1 << attempt)));
          continue;
        }

        try {
          await tmpFile.copy(filePath);
          await tmpFile.delete();
          return;
        } catch (copyErr) {
          throw AppError(
            type: AppErrorType.fileSystem,
            userMessageKey: 'error_file_locked',
            detail: 'File locked: ${p.basename(filePath)}',
            retryable: true,
          );
        }
      }
    }
  }

  bool _isFileLocked(FileSystemException e) {
    return e.osError?.errorCode == _windowsSharingViolation;
  }
}
