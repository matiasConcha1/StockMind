import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/locations/data/services/location_service.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class LocationInventorySnapshot {
  const LocationInventorySnapshot({
    required this.location,
    required this.products,
    required this.totalUnits,
  });

  final InventoryLocation location;
  final List<Product> products;
  final int totalUnits;
}

class LocationsProvider extends ChangeNotifier {
  LocationsProvider({
    required AuthProvider authProvider,
    required CurrentCompanyProvider currentCompanyProvider,
    required ProductsProvider productsProvider,
    required LocationService locationService,
    required StorageService storageService,
  })  : _authProvider = authProvider,
        _currentCompanyProvider = currentCompanyProvider,
        _productsProvider = productsProvider,
        _locationService = locationService,
        _storageService = storageService {
    _authProvider.addListener(_handleAuthChanged);
    _currentCompanyProvider.addListener(_handleAuthChanged);
    _productsProvider.addListener(notifyListeners);
    _handleAuthChanged();
  }

  static const List<String> baseLocationTypes = [
    'Refrigerador',
    'Congeladora',
    'Caja',
    'Closet',
  ];

  static const String otherLocationType = 'Otro';

  final AuthProvider _authProvider;
  final CurrentCompanyProvider _currentCompanyProvider;
  final ProductsProvider _productsProvider;
  final LocationService _locationService;
  final StorageService _storageService;

  StreamSubscription<List<InventoryLocation>>? _locationsSubscription;
  StreamSubscription<List<String>>? _typesSubscription;
  List<InventoryLocation> _locations = const [];
  List<String> _customTypes = const [];
  bool _locationsLoading = false;
  bool _typesLoading = false;
  String? _error;

  List<InventoryLocation> get locations => List.unmodifiable(_locations);
  bool get isLoading => _locationsLoading || _typesLoading;
  String? get error => _error;
  bool get hasLocations => _locations.isNotEmpty;

  List<String> get locationTypes {
    final unique = <String, String>{};
    for (final type in [...baseLocationTypes, ..._customTypes]) {
      final trimmed = type.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (key == otherLocationType.toLowerCase()) continue;
      unique.putIfAbsent(
        key,
        () => baseLocationTypes
                .map((item) => item.toLowerCase())
                .contains(key)
            ? baseLocationTypes.firstWhere(
                (item) => item.toLowerCase() == key,
              )
            : trimmed,
      );
    }
    final items = unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [...items, otherLocationType];
  }

  Future<void> createLocation(
    InventoryLocation location, {
    PickedImageFile? imageFile,
  }) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    debugPrint(
      'LocationsProvider.createLocation: companyId=${companyId ?? 'null'} name=${location.name}',
    );
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para crear ubicaciones.';
      notifyListeners();
      return;
    }
    if (!_authProvider.canManageLocations) {
      _error = 'No tienes permisos para crear ubicaciones.';
      notifyListeners();
      return;
    }
    await _execute(() async {
      final locationId = location.id.isEmpty
          ? _locationService.createLocationId(companyId)
          : location.id;
      String? imageUrl = location.imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadLocationImage(
          uid: userId,
          locationId: locationId,
          file: imageFile,
        );
      }
      await _locationService.createLocation(
        companyId,
        location.copyWith(id: locationId, imageUrl: imageUrl),
      );
      await _saveCustomTypeIfNeededBestEffort(companyId, location.type);
    });
  }

  Future<void> updateLocation(
    InventoryLocation location, {
    PickedImageFile? imageFile,
    bool removeImage = false,
  }) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    debugPrint(
      'LocationsProvider.updateLocation: companyId=${companyId ?? 'null'} locationId=${location.id}',
    );
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para editar ubicaciones.';
      notifyListeners();
      return;
    }
    if (!_authProvider.canManageLocations) {
      _error = 'No tienes permisos para editar ubicaciones.';
      notifyListeners();
      return;
    }
    await _execute(() async {
      String? imageUrl = location.imageUrl;
      if (removeImage) {
        final current = _locationById(location.id);
        await _storageService.deleteImageByUrl(current?.imageUrl);
        imageUrl = null;
      }
      if (imageFile != null) {
        imageUrl = await _storageService.uploadLocationImage(
          uid: userId,
          locationId: location.id,
          file: imageFile,
        );
      }
      await _locationService.updateLocation(
        companyId,
        location.copyWith(imageUrl: imageUrl),
      );
      await _saveCustomTypeIfNeededBestEffort(companyId, location.type);
    });
  }

  Future<bool> deleteLocation(String locationId) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    debugPrint(
      'LocationsProvider.deleteLocation: userId=${userId ?? 'null'} locationId=$locationId',
    );
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para eliminar ubicaciones.';
      notifyListeners();
      return false;
    }
    if (!_authProvider.canDelete) {
      _error = 'Solo un administrador puede eliminar ubicaciones.';
      notifyListeners();
      return false;
    }
    if (productCountForLocation(locationId) > 0) {
      _error =
          'No puedes eliminar una ubicación que todavía tiene productos asignados.';
      notifyListeners();
      return false;
    }
    final existing = _locationById(locationId);
    await _execute(() async {
      await _locationService.deleteLocation(companyId, locationId);
      await _storageService.deleteImageByUrl(existing?.imageUrl);
    });
    return _error == null;
  }

  int productCountForLocation(String locationId) {
    return _productsProvider.products
        .where((product) {
          final quantity = product.locationQuantities[locationId]?.quantity ?? 0;
          return quantity > 0;
        })
        .length;
  }

  int totalUnitsForLocation(String locationId) {
    return _productsProvider.products.fold<int>(0, (sum, product) {
      return sum + (product.locationQuantities[locationId]?.quantity ?? 0);
    });
  }

  List<Product> productsForLocation(String locationId) {
    return _productsProvider.products.where((product) {
      final quantity = product.locationQuantities[locationId]?.quantity ?? 0;
      return quantity > 0;
    }).toList();
  }

  LocationInventorySnapshot buildSnapshot(InventoryLocation location) {
    final products = productsForLocation(location.id);
    return LocationInventorySnapshot(
      location: location,
      products: products,
      totalUnits: totalUnitsForLocation(location.id),
    );
  }

  Future<void> _execute(Future<void> Function() action) async {
    _locationsLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'LocationsProvider._execute FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
      _error = _mapFirebaseError(error);
    } on StorageServiceException catch (error, stackTrace) {
      debugPrint('LocationsProvider._execute storage error: ${error.message}');
      debugPrint('$stackTrace');
      _error = error.message;
    } catch (error, stackTrace) {
      debugPrint('LocationsProvider._execute error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible sincronizar las ubicaciones.';
    } finally {
      _locationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCustomTypeIfNeededBestEffort(
    String companyId,
    String type,
  ) async {
    try {
      await _saveCustomTypeIfNeeded(companyId, type);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'LocationsProvider._saveCustomTypeIfNeededBestEffort FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint(
        'LocationsProvider._saveCustomTypeIfNeededBestEffort error: $error',
      );
      debugPrint('$stackTrace');
    }
  }

  Future<void> _saveCustomTypeIfNeeded(String companyId, String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty) return;
    final isBase = baseLocationTypes
        .map((item) => item.toLowerCase())
        .contains(normalized.toLowerCase());
    if (isBase || normalized.toLowerCase() == otherLocationType.toLowerCase()) {
      return;
    }
    await _locationService.saveLocationTypeIfMissing(companyId, normalized);
  }

  String _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permisos para guardar esta información. Revisa las reglas de Firestore.';
      case 'unavailable':
        return 'Firebase no está disponible en este momento. Intenta nuevamente.';
      case 'not-found':
        return 'No encontramos el recurso solicitado en Firestore.';
      case 'failed-precondition':
        return 'Firestore requiere una configuración adicional para completar la operación.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Ocurrió un error inesperado al guardar.';
    }
  }

  InventoryLocation? _locationById(String locationId) {
    for (final item in _locations) {
      if (item.id == locationId) return item;
    }
    return null;
  }

  void _handleAuthChanged() {
    _locationsSubscription?.cancel();
    _typesSubscription?.cancel();
    _locations = const [];
    _customTypes = const [];
    _error = null;

    final companyId = _currentCompanyProvider.companyId;
    if (companyId == null) {
      _locationsLoading = false;
      _typesLoading = false;
      notifyListeners();
      return;
    }

    _locationsLoading = true;
    _typesLoading = true;
    notifyListeners();

    _locationsSubscription = _locationService.watchLocations(companyId).listen(
      (items) {
        _locations = items;
        _locationsLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('LocationsProvider.watchLocations error: $error');
        debugPrint('$stackTrace');
        _error = 'No fue posible cargar tus ubicaciones.';
        _locationsLoading = false;
        notifyListeners();
      },
    );

    _typesSubscription = _locationService.watchLocationTypes(companyId).listen(
      (items) {
        _customTypes = items;
        _typesLoading = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('LocationsProvider.watchLocationTypes error: $error');
        debugPrint('$stackTrace');
        _error = 'No fue posible cargar los tipos de ubicación.';
        _typesLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _currentCompanyProvider.removeListener(_handleAuthChanged);
    _productsProvider.removeListener(notifyListeners);
    _locationsSubscription?.cancel();
    _typesSubscription?.cancel();
    super.dispose();
  }
}
