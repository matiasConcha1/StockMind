import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppSettingsSnapshot {
  const AppSettingsSnapshot({
    required this.autoArchiveExpiredProducts,
  });

  final bool autoArchiveExpiredProducts;
}

class AppConfigService {
  AppConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _firestore.collection('app_config').doc('settings');

  Stream<AppSettingsSnapshot> watchSettings() {
    return _settingsRef.snapshots().map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      return AppSettingsSnapshot(
        autoArchiveExpiredProducts:
            (data['autoArchiveExpiredProducts'] ?? false) as bool,
      );
    });
  }

  Future<AppSettingsSnapshot> getSettings() async {
    final snapshot = await _settingsRef.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    return AppSettingsSnapshot(
      autoArchiveExpiredProducts:
          (data['autoArchiveExpiredProducts'] ?? false) as bool,
    );
  }

  Future<void> updateAutoArchiveExpiredProducts(bool value) async {
    debugPrint(
      'AppConfigService.updateAutoArchiveExpiredProducts: value=$value',
    );
    try {
      await _settingsRef.set({
        'autoArchiveExpiredProducts': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint(
        'AppConfigService.updateAutoArchiveExpiredProducts: persisted=$value',
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'AppConfigService.updateAutoArchiveExpiredProducts FirebaseException: ${error.code} ${error.message}',
      );
      debugPrint('$stackTrace');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        'AppConfigService.updateAutoArchiveExpiredProducts error: $error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
