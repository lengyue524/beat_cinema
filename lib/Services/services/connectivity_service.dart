import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ConnectivityService {
  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  Timer? _timer;

  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _check();
    _timer = Timer.periodic(interval, (_) => _check());
  }

  Future<void> _check() async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 5));
      isOnline.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      isOnline.value = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    isOnline.dispose();
  }
}
