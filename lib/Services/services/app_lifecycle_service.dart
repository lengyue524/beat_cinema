import 'dart:io';

import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Services/services/player_service.dart';
import 'package:beat_cinema/Services/services/window_service.dart';
import 'package:window_manager/window_manager.dart';

class AppLifecycleService {
  final WindowService _windowService;
  PlayerService? playerService;

  AppLifecycleService(this._windowService) {
    _windowService.onCloseRequested = _handleCloseRequested;
  }

  Future<void> _handleCloseRequested() async {
    await playerService?.disposeAll();
    await _killChildProcesses();
    await _windowService.dispose();
    await windowManager.destroy();
  }

  Future<void> _killChildProcesses() async {
    for (final processName in [Constants.ytDlpName, Constants.bbDownName]) {
      try {
        await Process.run(
          'taskkill',
          ['/F', '/IM', processName],
        );
      } catch (_) {
        // taskkill not available or no processes to kill
      }
    }
  }
}
