import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({
    required AuthProvider authProvider,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _authProvider = authProvider,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance {
    _authProvider.addListener(_handleAuthChanged);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _foregroundController.add(message);
    });
    _handleAuthChanged();
  }

  static const String fcmWebVapidKey =
      String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const _deferredPromptKey = 'notification_prompt_deferred_until';
  static const _deviceIdKey = 'notification_device_id';

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  SharedPreferences? _prefs;
  bool _loading = false;
  bool _notificationsEnabled = false;
  bool _promptStateLoaded = false;
  String? _token;
  String? _error;
  String? _statusMessage;
  String? _deviceId;

  bool get isLoading => _loading;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get token => _token;
  String? get error => _error;
  String? get statusMessage => _statusMessage;
  bool get isSupported => true;
  bool get canPromptForNotifications =>
      !_loading && !_notificationsEnabled && !_isPromptDeferred;
  String get notificationStatusLabel => _notificationsEnabled
      ? 'Notificaciones activadas'
      : 'Notificaciones desactivadas';
  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;

  bool get _isPromptDeferred {
    if (!_promptStateLoaded) return true;
    final raw = _prefs?.getInt(_deferredPromptKey);
    if (raw == null) return false;
    return DateTime.now().millisecondsSinceEpoch < raw;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _ensurePrefs();
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para gestionar notificaciones.';
      _statusMessage = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    _statusMessage = null;
    notifyListeners();

    try {
      if (!value) {
        await _persistNotificationState(
          userId: userId,
          enabled: false,
          token: null,
        );
        _notificationsEnabled = false;
        _token = null;
        _statusMessage = 'Notificaciones desactivadas.';
        return;
      }

      final permission = await _messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied ||
          permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        _error = 'Debes permitir notificaciones desde el navegador.';
        _notificationsEnabled = false;
        _token = null;
        return;
      }

      final token = await _getToken();
      if (token == null || token.trim().isEmpty) {
        _error = _error ??
            'No se pudo obtener el token de notificaciones para este dispositivo.';
        _notificationsEnabled = false;
        _token = null;
        return;
      }

      await _persistNotificationState(
        userId: userId,
        enabled: true,
        token: token,
      );
      _notificationsEnabled = true;
      _token = token;
      _statusMessage = 'Notificaciones activadas correctamente.';
      await _prefs?.remove(_deferredPromptKey);
    } catch (error, stackTrace) {
      debugPrint('NotificationService.setNotificationsEnabled error: $error');
      debugPrint('$stackTrace');
      _error =
          'No fue posible configurar las notificaciones en este dispositivo.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deferPrompt({int days = 3}) async {
    await _ensurePrefs();
    final until =
        DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;
    await _prefs?.setInt(_deferredPromptKey, until);
    notifyListeners();
  }

  Future<void> resetDeferredPrompt() async {
    await _ensurePrefs();
    await _prefs?.remove(_deferredPromptKey);
    notifyListeners();
  }

  Future<void> _handleAuthChanged() async {
    await _ensurePrefs();
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _notificationsEnabled = false;
      _token = null;
      _error = null;
      _statusMessage = null;
      notifyListeners();
      return;
    }
    await _loadUserNotificationState(userId);
  }

  Future<void> _loadUserNotificationState(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      _notificationsEnabled = (data['notificationsEnabled'] ?? false) == true;
      _token = (data['fcmToken'] as String?)?.trim().isEmpty ?? true
          ? null
          : (data['fcmToken'] as String).trim();

      if (_notificationsEnabled && (_token == null || _token!.isEmpty)) {
        final refreshedToken = await _getToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          _token = refreshedToken;
          await _persistNotificationState(
            userId: userId,
            enabled: true,
            token: refreshedToken,
          );
          _statusMessage = 'Notificaciones activadas correctamente.';
        }
      } else if (_notificationsEnabled && _token != null && _token!.isNotEmpty) {
        _statusMessage = 'Notificaciones activadas correctamente.';
      } else {
        _statusMessage = null;
      }

      if (_token != null && _token!.isNotEmpty) {
        _error = null;
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationService._loadUserNotificationState error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible cargar el estado de notificaciones.';
    } finally {
      notifyListeners();
    }
  }

  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        if (fcmWebVapidKey.trim().isEmpty) {
          _error = 'Falta configurar la clave web de notificaciones.';
          return null;
        }
        return await _messaging.getToken(vapidKey: fcmWebVapidKey);
      }
      return await _messaging.getToken();
    } catch (error, stackTrace) {
      debugPrint('NotificationService._getToken error: $error');
      debugPrint('$stackTrace');
      _error = 'No se pudo obtener el token de notificaciones.';
      return null;
    }
  }

  Future<void> _persistNotificationState({
    required String userId,
    required bool enabled,
    required String? token,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();
    batch.set(
      userRef,
      {
        'notificationsEnabled': enabled,
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    final tokenRef = userRef.collection('notification_tokens').doc(_deviceId);
    batch.set(
      tokenRef,
      {
        'deviceId': _deviceId,
        'token': token,
        'enabled': enabled,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    _deviceId ??= _prefs!.getString(_deviceIdKey);
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _prefs!.setString(_deviceIdKey, _deviceId!);
    }
    _promptStateLoaded = true;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _foregroundSubscription?.cancel();
    _foregroundController.close();
    super.dispose();
  }
}
