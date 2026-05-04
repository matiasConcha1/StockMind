import 'package:firebase_core/firebase_core.dart';

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
    try {
      await Firebase.initializeApp();
      return const FirebaseBootstrapResult(isReady: true);
    } catch (error) {
      return FirebaseBootstrapResult(
        isReady: false,
        error: error.toString(),
      );
    }
  }
}
