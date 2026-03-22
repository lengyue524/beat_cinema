import 'dart:io';

import 'package:beat_cinema/Common/constants.dart';
import 'package:path/path.dart' as p;

class BeatSaberDetector {
  static const _steamDefault =
      r'C:\Program Files (x86)\Steam\steamapps\common\Beat Saber';
  static const _steamLibFolders =
      r'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf';

  Future<List<String>> detectPaths() async {
    final found = <String>[];

    if (await _isValid(_steamDefault)) {
      found.add(_steamDefault);
    }

    final libraryPaths = await _parseSteamLibraries();
    for (final lib in libraryPaths) {
      final bsPath = p.join(lib, 'steamapps', 'common', 'Beat Saber');
      if (await _isValid(bsPath) && !found.contains(bsPath)) {
        found.add(bsPath);
      }
    }

    return found;
  }

  Future<bool> _isValid(String path) async {
    final exe = File(p.join(path, Constants.beatSaberExe));
    return exe.exists();
  }

  Future<List<String>> _parseSteamLibraries() async {
    final file = File(_steamLibFolders);
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final pathRegex = RegExp(r'"path"\s+"([^"]+)"');
      return pathRegex
          .allMatches(content)
          .map((m) => m.group(1)!.replaceAll(r'\\', r'\'))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
