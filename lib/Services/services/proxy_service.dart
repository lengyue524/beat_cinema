import 'dart:async';
import 'dart:io';

enum ProxyMode { system, custom, none }

class ProxyService {
  static Future<String?> resolveProxyUrl({
    required ProxyMode mode,
    String? customProxy,
  }) async {
    switch (mode) {
      case ProxyMode.none:
        return null;
      case ProxyMode.custom:
        return normalizeProxyUrl(customProxy);
      case ProxyMode.system:
        return _resolveSystemProxyUrl();
    }
  }

  static String? normalizeProxyUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'http://$value';
  }

  static Future<String?> _resolveSystemProxyUrl() async {
    final envProxy = _resolveProxyFromEnvironment();
    if (envProxy != null) {
      return envProxy;
    }
    if (!Platform.isWindows) {
      return null;
    }
    try {
      final enableResult = await Process.run(
        'reg',
        [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v',
          'ProxyEnable',
        ],
      ).timeout(const Duration(seconds: 2));
      final enableText = '${enableResult.stdout}\n${enableResult.stderr}';
      if (!enableText.contains('0x1')) {
        return null;
      }

      final serverResult = await Process.run(
        'reg',
        [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v',
          'ProxyServer',
        ],
      ).timeout(const Duration(seconds: 2));
      final combined = '${serverResult.stdout}\n${serverResult.stderr}';
      final rawProxy = _extractProxyServerValue(combined);
      return normalizeProxyUrl(rawProxy);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _resolveProxyFromEnvironment() {
    const keys = ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy'];
    for (final key in keys) {
      final value = normalizeProxyUrl(Platform.environment[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String? _extractProxyServerValue(String output) {
    final lines =
        output.split(RegExp(r'\r?\n')).map((line) => line.trim()).toList();
    for (final line in lines) {
      if (!line.toLowerCase().contains('proxyserver')) continue;
      final match = RegExp(r'ProxyServer\s+REG_\w+\s+(.+)$').firstMatch(line);
      if (match == null) continue;
      final raw = match.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;
      if (!raw.contains('=')) return raw;
      for (final segment in raw.split(';')) {
        final kv = segment.split('=');
        if (kv.length != 2) continue;
        final scheme = kv[0].trim().toLowerCase();
        final value = kv[1].trim();
        if (scheme == 'https' && value.isNotEmpty) return value;
      }
      for (final segment in raw.split(';')) {
        final kv = segment.split('=');
        if (kv.length == 2 && kv[1].trim().isNotEmpty) return kv[1].trim();
      }
    }
    return null;
  }
}
