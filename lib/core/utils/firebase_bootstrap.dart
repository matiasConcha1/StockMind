import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.isReady,
    this.error,
  });

  final bool isReady;
  final String? error;
}

class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    debugPrint('FirebaseBootstrap.initialize: starting');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('FirebaseBootstrap.initialize: success');
      return const FirebaseBootstrapResult(isReady: true);
    } catch (error, stackTrace) {
      debugPrint('FirebaseBootstrap.initialize: error -> $error');
      debugPrint('$stackTrace');
      return FirebaseBootstrapResult(
        isReady: false,
        error: error.toString(),
      );
    }
  }
}
