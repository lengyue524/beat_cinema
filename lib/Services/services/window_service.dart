import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowService with WindowListener {
  static const String _prefsKey = 'window_bounds';
  static const Size _minSize = Size(960, 640);
  static const Size _defaultSize = Size(1280, 800);

  Future<void> Function()? onCloseRequested;

  Future<void> init() async {
    await windowManager.ensureInitialized();

    final bounds = await _loadBounds();

    final windowOptions = WindowOptions(
      size: bounds?['size'] ?? _defaultSize,
      minimumSize: _minSize,
      center: bounds == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Beat Cinema',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (bounds != null && bounds['position'] != null) {
        await windowManager.setPosition(bounds['position'] as Offset);
      }
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  Future<Map<String, dynamic>?> _loadBounds() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return {
        'size': Size(
          (map['w'] as num).toDouble(),
          (map['h'] as num).toDouble(),
        ),
        'position': Offset(
          (map['x'] as num).toDouble(),
          (map['y'] as num).toDouble(),
        ),
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveBounds() async {
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'w': size.width,
        'h': size.height,
        'x': pos.dx,
        'y': pos.dy,
      }),
    );
  }

  @override
  void onWindowResized() => _saveBounds();

  @override
  void onWindowMoved() => _saveBounds();

  @override
  void onWindowClose() async {
    if (onCloseRequested != null) {
      await onCloseRequested!();
    } else {
      await windowManager.destroy();
    }
  }

  Future<void> dispose() async {
    windowManager.removeListener(this);
  }
}
