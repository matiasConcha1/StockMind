import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/replenishment/data/services/stock_request_service.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';

enum StockRequestFilter { all, pending, approved, completed, cancelled }

class StockRequestsProvider extends ChangeNotifier {
  StockRequestsProvider({
    required AuthProvider authProvider,
    required StockRequestService stockRequestService,
  })  : _authProvider = authProvider,
        _stockRequestService = stockRequestService {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final StockRequestService _stockRequestService;

  StreamSubscription<List<StockRequest>>? _subscription;
  List<StockRequest> _requests = const [];
  StockRequestFilter _filter = StockRequestFilter.all;
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  List<StockRequest> get requests => List.unmodifiable(_requests);
  StockRequestFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _loading;
  String? get error => _error;

  List<StockRequest> get visibleRequests {
    final query = _searchQuery.trim().toLowerCase();
    return _requests.where((request) {
      final matchesQuery = query.isEmpty ||
          request.productName.toLowerCase().contains(query) ||
          request.locationName.toLowerCase().contains(query) ||
          (request.barcode?.toLowerCase().contains(query) ?? false);
      final matchesFilter = switch (_filter) {
        StockRequestFilter.all => true,
        StockRequestFilter.pending => request.isPending,
        StockRequestFilter.approved => request.isApproved,
        StockRequestFilter.completed => request.isCompleted,
        StockRequestFilter.cancelled => request.isCancelled,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get pendingCount => _requests.where((item) => item.isPending).length;
  int get completedThisWeekCount {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _requests.where((item) {
      if (!item.isCompleted || item.completedAt == null) return false;
      return !item.completedAt!.isBefore(weekStart);
    }).length;
  }

  bool hasPendingRequestForProduct(String productId) {
    return _requests.any((item) => item.productId == productId && item.isPending);
  }

  bool hasPendingRequestForProductLocation(String productId, String locationId) {
    return _requests.any(
      (item) =>
          item.productId == productId &&
          item.locationId == locationId &&
          item.isPending,
    );
  }

  void updateFilter(StockRequestFilter value) {
    _filter = value;
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<bool> createRequest(StockRequest request) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para crear solicitudes.';
      notifyListeners();
      return false;
    }
    var success = false;
    await _runAction(() async {
      await _stockRequestService.createRequest(userId, request);
      success = true;
    });
    return success && _error == null;
  }

  Future<bool> approveRequest(StockRequest request) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para aprobar solicitudes.';
      notifyListeners();
      return false;
    }
    var success = false;
    await _runAction(() async {
      await _stockRequestService.approveRequest(userId: userId, request: request);
      success = true;
    });
    return success && _error == null;
  }

  Future<bool> cancelRequest(StockRequest request) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para cancelar solicitudes.';
      notifyListeners();
      return false;
    }
    var success = false;
    await _runAction(() async {
      await _stockRequestService.cancelRequest(userId: userId, request: request);
      success = true;
    });
    return success && _error == null;
  }

  Future<bool> completeRequest(StockRequest request) async {
    final userId = _authProvider.user?.id;
    final userName =
        _authProvider.user?.displayName ?? _authProvider.user?.email ?? 'Usuario';
    if (userId == null) {
      _error = 'Debes iniciar sesión para completar solicitudes.';
      notifyListeners();
      return false;
    }
    var success = false;
    await _runAction(() async {
      await _stockRequestService.completeRequest(
        userId: userId,
        request: request,
        completedByUserId: userId,
        completedByUserName: userName,
      );
      success = true;
    });
    return success && _error == null;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      _error = null;
      await action();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'StockRequestsProvider FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
      _error = _mapFirebaseError(error);
    } catch (error, stackTrace) {
      debugPrint('StockRequestsProvider error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible actualizar la solicitud de reposición.';
    } finally {
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    _subscription?.cancel();
    _requests = const [];
    _error = null;
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = _stockRequestService.watchRequests(userId).listen(
      (items) {
        _requests = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('StockRequestsProvider.watchRequests error: $error');
        debugPrint('$stackTrace');
        _requests = const [];
        _loading = false;
        _error = 'No fue posible cargar las solicitudes de reposición.';
        notifyListeners();
      },
    );
  }

  String _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'already-exists':
        return 'Ya existe una solicitud pendiente para este producto en esa ubicación.';
      case 'permission-denied':
        return 'No tienes permisos para actualizar solicitudes de reposición.';
      case 'failed-precondition':
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'La solicitud ya no puede modificarse.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'No fue posible actualizar la solicitud de reposición.';
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}
