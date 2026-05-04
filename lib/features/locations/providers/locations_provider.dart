import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
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
    required ProductsProvider productsProvider,
    required LocationService locationService,
  })  : _authProvider = authProvider,
        _productsProvider = productsProvider,
        _locationService = locationService {
    _authProvider.addListener(_handleAuthChanged);
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
  final ProductsProvider _productsProvider;
  final LocationService _locationService;

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

  Future<void> createLocation(InventoryLocation location) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para crear ubicaciones.';
      notifyListeners();
      return;
    }
    await _execute(() async {
      await _locationService.createLocation(userId, location);
      await _saveCustomTypeIfNeeded(userId, location.type);
    });
  }

  Future<void> updateLocation(InventoryLocation location) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para editar ubicaciones.';
      notifyListeners();
      return;
    }
    await _execute(() async {
      await _locationService.updateLocation(userId, location);
      await _saveCustomTypeIfNeeded(userId, location.type);
    });
  }

  Future<bool> deleteLocation(String locationId) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para eliminar ubicaciones.';
      notifyListeners();
      return false;
    }
    if (productCountForLocation(locationId) > 0) {
      _error =
          'No puedes eliminar una ubicación que todavía tiene productos asignados.';
      notifyListeners();
      return false;
    }
    await _execute(() => _locationService.deleteLocation(userId, locationId));
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
    } catch (error, stackTrace) {
      debugPrint('LocationsProvider._execute error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible sincronizar las ubicaciones.';
    } finally {
      _locationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCustomTypeIfNeeded(String userId, String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty) return;
    final isBase = baseLocationTypes
        .map((item) => item.toLowerCase())
        .contains(normalized.toLowerCase());
    if (isBase || normalized.toLowerCase() == otherLocationType.toLowerCase()) {
      return;
    }
    await _locationService.saveLocationTypeIfMissing(userId, normalized);
  }

  void _handleAuthChanged() {
    _locationsSubscription?.cancel();
    _typesSubscription?.cancel();
    _locations = const [];
    _customTypes = const [];
    _error = null;

    final userId = _authProvider.user?.id;
    if (userId == null) {
      _locationsLoading = false;
      _typesLoading = false;
      notifyListeners();
      return;
    }

    _locationsLoading = true;
    _typesLoading = true;
    notifyListeners();

    _locationsSubscription = _locationService.watchLocations(userId).listen(
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

    _typesSubscription = _locationService.watchLocationTypes(userId).listen(
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
    _productsProvider.removeListener(notifyListeners);
    _locationsSubscription?.cancel();
    _typesSubscription?.cancel();
    super.dispose();
  }
}
