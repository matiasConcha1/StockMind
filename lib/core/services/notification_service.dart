import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  static const String _webVapidKey =
      String.fromEnvironment('FCM_WEB_VAPID_KEY');

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _loading = false;
  bool _notificationsEnabled = false;
  String? _token;
  String? _error;

  bool get isLoading => _loading;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get token => _token;
  String? get error => _error;
  bool get isSupported => true;
  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;

  Future<void> setNotificationsEnabled(bool value) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para gestionar notificaciones.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (!value) {
        await _firestore.collection('users').doc(userId).set(
          {
            'notificationsEnabled': false,
            'fcmToken': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        _notificationsEnabled = false;
        _token = null;
        return;
      }

      final permission = await _messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied ||
          permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        _error = 'Debes permitir las notificaciones para activar este canal.';
        _notificationsEnabled = false;
        return;
      }

      final token = await _getToken();
      if (token == null || token.trim().isEmpty) {
        _error = _error ??
            'No se pudo obtener el token de notificaciones para este dispositivo.';
        _notificationsEnabled = false;
        return;
      }

      await _firestore.collection('users').doc(userId).set(
        {
          'notificationsEnabled': true,
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _notificationsEnabled = true;
      _token = token;
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

  Future<void> _handleAuthChanged() async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _notificationsEnabled = false;
      _token = null;
      _error = null;
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
          await _firestore.collection('users').doc(userId).set(
            {
              'notificationsEnabled': true,
              'fcmToken': refreshedToken,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
      _error = null;
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
        if (_webVapidKey.trim().isEmpty) {
          _error =
              'Falta configurar FCM_WEB_VAPID_KEY para obtener el token web.';
          return null;
        }
        return await _messaging.getToken(vapidKey: _webVapidKey);
      }
      return await _messaging.getToken();
    } catch (error, stackTrace) {
      debugPrint('NotificationService._getToken error: $error');
      debugPrint('$stackTrace');
      _error = 'No se pudo obtener el token de notificaciones.';
      return null;
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _foregroundSubscription?.cancel();
    _foregroundController.close();
    super.dispose();
  }
}
