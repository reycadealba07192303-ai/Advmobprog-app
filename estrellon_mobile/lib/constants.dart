import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String resolveHost() {
  final envHost = dotenv.env['HOST'] ?? 'http://localhost:5000';

  if (!kIsWeb && Platform.isAndroid) {
    // Physical device: use your PC's LAN IP (set in .env as ANDROID_HOST).
    final androidHost = dotenv.env['ANDROID_HOST'];
    if (androidHost != null && androidHost.isNotEmpty) {
      return androidHost;
    }

    // Android emulator fallback: localhost → 10.0.2.2
    if (envHost.contains('localhost')) {
      return envHost.replaceAll('localhost', '10.0.2.2');
    }
  }

  return envHost;
}

late String host;

class Constants {
  static const String appTitle = 'Raguini';
  static const String fontFamily = 'Poppins';
}
