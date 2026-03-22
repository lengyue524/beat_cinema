import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String version;
  final String releaseUrl;
  final String? body;

  const UpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.body,
  });
}

class UpdateService {
  static const _prefsKey = 'last_update_check';
  static const _ignoredKey = 'ignored_version';
  static const _checkInterval = Duration(hours: 24);

  final String owner;
  final String repo;
  final String currentVersion;

  UpdateService({
    required this.owner,
    required this.repo,
    required this.currentVersion,
  });

  Future<UpdateInfo?> checkForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_prefsKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck < _checkInterval.inMilliseconds) return null;

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$owner/$repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      await prefs.setInt(_prefsKey, now);

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';

      if (_isNewer(tagName, currentVersion)) {
        final ignored = prefs.getString(_ignoredKey);
        if (ignored == tagName) return null;

        return UpdateInfo(
          version: tagName,
          releaseUrl: data['html_url'] as String? ?? '',
          body: data['body'] as String?,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> ignoreVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredKey, version);
  }

  bool _isNewer(String remote, String local) {
    final rParts = remote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final lParts = local.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final l = i < lParts.length ? lParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }
}
