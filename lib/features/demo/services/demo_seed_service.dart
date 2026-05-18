import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockmind/core/services/alert_service.dart';
import 'package:stockmind/core/services/company_scope_service.dart';
import 'package:stockmind/features/products/models/product.dart';

class DemoSeedService {
  DemoSeedService({
    FirebaseFirestore? firestore,
    CompanyScopeService? scopeService,
    AlertService? alertService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _scopeService =
            scopeService ?? CompanyScopeService(firestore: firestore),
        _alertService = alertService ?? AlertService();

  final FirebaseFirestore _firestore;
  final CompanyScopeService _scopeService;
  final AlertService _alertService;

  Future<String> ensurePersonalDemoWorkspace({
    required String uid,
    required String displayName,
    required String email,
    required String accountType,
  }) async {
    final companyId = 'demo_$uid';
    final companyRef = _scopeService.companyDoc(companyId);
    final userRef = _scopeService.rootUsers().doc(uid);
    final companySnapshot = await companyRef.get();
    final companyName = 'Demo Workspace';

    final batch = _firestore.batch();
    batch.set(companyRef, {
      'id': companyId,
      'ownerId': uid,
      'plan': 'demo',
      'companyName': companyName,
      'logoUrl': null,
      'settings': {
        'defaultMinStock': 5,
        'multiTenantReady': true,
        'demoMode': true,
        'sharedDemo': false,
        'workspaceType': 'personal',
      },
      if (!companySnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(companyRef.collection('users').doc(uid), {
      'uid': uid,
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
      'invitedBy': uid,
      'status': 'accepted',
      'accountType': accountType,
      'email': email,
      'displayName': displayName,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'companyIds': FieldValue.arrayUnion([companyId]),
      'currentCompanyId': companyId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    final hasProducts = (await _scopeService
            .companyCollection(companyId, 'products')
            .limit(1)
            .get())
        .docs
        .isNotEmpty;
    if (!hasProducts) {
      await seedCompany(
        companyId: companyId,
        companyName: companyName,
        actorUserId: uid,
        actorUserName: displayName.trim().isEmpty ? 'Demo Admin' : displayName,
      );
    }
    return companyId;
  }

  Future<void> resetDemoWorkspace({
    required String companyId,
    required String companyName,
    required String actorUserId,
    required String actorUserName,
  }) async {
    final companySnapshot = await _scopeService.companyDoc(companyId).get();
    final settings =
        (companySnapshot.data()?['settings'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
    if (settings['demoMode'] != true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'Solo puedes resetear workspaces marcados como demo.',
      );
    }
    for (final collectionName in const [
      'products',
      'locations',
      'location_types',
      'alerts',
      'stock_movements',
      'stock_requests',
      'activity_logs',
      'company_profile',
    ]) {
      await _deleteCollection(companyId, collectionName);
    }
    await _scopeService.companyDoc(companyId).set({
      'settings': {
        ...settings,
        'demoMode': true,
        'sharedDemo': false,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await seedCompany(
      companyId: companyId,
      companyName: companyName,
      actorUserId: actorUserId,
      actorUserName: actorUserName,
    );
  }

  Future<void> seedCompany({
    required String companyId,
    required String companyName,
    required String actorUserId,
    required String actorUserName,
  }) async {
    final companyRef = _scopeService.companyDoc(companyId);
    final productsRef = _scopeService.companyCollection(companyId, 'products');
    final locationsRef = _scopeService.companyCollection(companyId, 'locations');
    final movementsRef =
        _scopeService.companyCollection(companyId, 'stock_movements');
    final requestsRef =
        _scopeService.companyCollection(companyId, 'stock_requests');
    final activityLogsRef =
        _scopeService.companyCollection(companyId, 'activity_logs');
    final companyProfileRef =
        _scopeService.companyCollection(companyId, 'company_profile').doc('company_profile');

    final productSnapshot = await productsRef.limit(1).get();
    final locationSnapshot = await locationsRef.limit(1).get();
    final movementSnapshot = await movementsRef.limit(1).get();
    final requestSnapshot = await requestsRef.limit(1).get();
    final companySnapshot = await companyRef.get();
    final companyData = companySnapshot.data() ?? const <String, dynamic>{};
    final settings =
        (companyData['settings'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    if (productSnapshot.docs.isNotEmpty ||
        locationSnapshot.docs.isNotEmpty ||
        movementSnapshot.docs.isNotEmpty ||
        requestSnapshot.docs.isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message:
            'Esta empresa ya tiene datos reales o demo. Crea una nueva empresa si quieres una demo limpia.',
      );
    }

    final now = DateTime.now();
    final warehouseId = locationsRef.doc().id;
    final storefrontId = locationsRef.doc().id;
    final transitId = locationsRef.doc().id;

    final products = <Product>[
      _buildProduct(
        id: productsRef.doc().id,
        name: 'Leche Entera 1L',
        category: 'Lácteos',
        price: 1290,
        totalStock: 84,
        minStock: 18,
        updatedAt: now.subtract(const Duration(hours: 2)),
        locationStocks: {
          warehouseId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Bodega Central',
            quantity: 52,
          ),
          storefrontId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Sala de Ventas',
            quantity: 32,
          ),
        },
      ),
      _buildProduct(
        id: productsRef.doc().id,
        name: 'Yogurt Natural 125g',
        category: 'Lácteos',
        price: 690,
        totalStock: 11,
        minStock: 15,
        updatedAt: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 4)),
        locationStocks: {
          warehouseId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Bodega Central',
            quantity: 6,
          ),
          storefrontId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Sala de Ventas',
            quantity: 5,
          ),
        },
      ),
      _buildProduct(
        id: productsRef.doc().id,
        name: 'Pollo Congelado 900g',
        category: 'Proteínas',
        price: 4890,
        totalStock: 39,
        minStock: 10,
        updatedAt: now.subtract(const Duration(days: 2)),
        locationStocks: {
          warehouseId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Bodega Central',
            quantity: 22,
          ),
          transitId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Tránsito',
            quantity: 17,
          ),
        },
      ),
      _buildProduct(
        id: productsRef.doc().id,
        name: 'Arándanos 250g',
        category: 'Frutas',
        price: 2590,
        totalStock: 0,
        minStock: 8,
        updatedAt: now.subtract(const Duration(hours: 10)),
        expiryDate: now.subtract(const Duration(days: 1)),
        locationStocks: {},
      ),
      _buildProduct(
        id: productsRef.doc().id,
        name: 'Bebida Cola 1.5L',
        category: 'Bebidas',
        price: 1990,
        totalStock: 65,
        minStock: 20,
        updatedAt: now.subtract(const Duration(days: 3)),
        locationStocks: {
          warehouseId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Bodega Central',
            quantity: 40,
          ),
          storefrontId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Sala de Ventas',
            quantity: 25,
          ),
        },
      ),
      _buildProduct(
        id: productsRef.doc().id,
        name: 'Pan Molde Integral',
        category: 'Panadería',
        price: 1790,
        totalStock: 7,
        minStock: 12,
        updatedAt: now.subtract(const Duration(hours: 18)),
        expiryDate: now.add(const Duration(days: 2)),
        locationStocks: {
          storefrontId: const ProductLocationQuantity(
            locationId: '',
            locationName: 'Sala de Ventas',
            quantity: 7,
          ),
        },
      ),
    ];

    final batch = _firestore.batch();

    batch.set(companyRef, {
      'updatedAt': FieldValue.serverTimestamp(),
      'settings': {
        ...settings,
        'demoMode': true,
        'demoSeededAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    batch.set(companyProfileRef, {
      'id': 'company_profile',
      'name': companyName,
      'industry': 'Retail / Grocery',
      'phone': '+56 9 5555 5555',
      'email': 'ops@$companyId.demo',
      'address': 'Sucursal piloto · Demo pública',
      'website': 'https://stockmind.app',
      'createdBy': actorUserId,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(locationsRef.doc(warehouseId), {
      'id': warehouseId,
      'name': 'Bodega Central',
      'description': 'Centro de almacenamiento principal para la demo.',
      'type': 'Caja',
      'imageUrl': null,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
    });
    batch.set(locationsRef.doc(storefrontId), {
      'id': storefrontId,
      'name': 'Sala de Ventas',
      'description': 'Punto de salida y reposición rápida.',
      'type': 'Refrigerador',
      'imageUrl': null,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
    });
    batch.set(locationsRef.doc(transitId), {
      'id': transitId,
      'name': 'Tránsito',
      'description': 'Preparación y consolidación antes de despacho.',
      'type': 'Closet',
      'imageUrl': null,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
    });

    for (final product in products) {
      batch.set(productsRef.doc(product.id), product.toCreateMap());
    }

    final movements = [
      _movementMap(
        id: movementsRef.doc().id,
        product: products[0],
        type: 'entry',
        quantity: 24,
        previousTotalStock: 60,
        newTotalStock: 84,
        locationId: warehouseId,
        locationName: 'Bodega Central',
        previousLocationQuantity: 28,
        newLocationQuantity: 52,
        reason: 'Recepción de proveedor',
        createdAt: now.subtract(const Duration(days: 6)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[1],
        type: 'exit',
        quantity: 8,
        previousTotalStock: 19,
        newTotalStock: 11,
        locationId: storefrontId,
        locationName: 'Sala de Ventas',
        previousLocationQuantity: 13,
        newLocationQuantity: 5,
        reason: 'Venta en tienda',
        createdAt: now.subtract(const Duration(days: 5)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[2],
        type: 'transfer',
        quantity: 7,
        previousTotalStock: 39,
        newTotalStock: 39,
        locationId: transitId,
        locationName: 'Tránsito',
        previousLocationQuantity: 10,
        newLocationQuantity: 17,
        reason: 'Rebalanceo interno',
        createdAt: now.subtract(const Duration(days: 4)),
        sourceLocationId: warehouseId,
        sourceLocationName: 'Bodega Central',
        targetLocationId: transitId,
        targetLocationName: 'Tránsito',
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[3],
        type: 'expired',
        quantity: 4,
        previousTotalStock: 4,
        newTotalStock: 0,
        locationId: storefrontId,
        locationName: 'Sala de Ventas',
        previousLocationQuantity: 4,
        newLocationQuantity: 0,
        reason: 'Merma por vencimiento',
        createdAt: now.subtract(const Duration(days: 3)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[5],
        type: 'exit',
        quantity: 5,
        previousTotalStock: 12,
        newTotalStock: 7,
        locationId: storefrontId,
        locationName: 'Sala de Ventas',
        previousLocationQuantity: 12,
        newLocationQuantity: 7,
        reason: 'Venta rápida',
        createdAt: now.subtract(const Duration(days: 2)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[4],
        type: 'entry',
        quantity: 18,
        previousTotalStock: 47,
        newTotalStock: 65,
        locationId: warehouseId,
        locationName: 'Bodega Central',
        previousLocationQuantity: 22,
        newLocationQuantity: 40,
        reason: 'Reposición semanal',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[0],
        type: 'exit',
        quantity: 6,
        previousTotalStock: 90,
        newTotalStock: 84,
        locationId: storefrontId,
        locationName: 'Sala de Ventas',
        previousLocationQuantity: 38,
        newLocationQuantity: 32,
        reason: 'Despacho al punto de venta',
        createdAt: now.subtract(const Duration(hours: 12)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _movementMap(
        id: movementsRef.doc().id,
        product: products[1],
        type: 'adjustment',
        quantity: 2,
        previousTotalStock: 9,
        newTotalStock: 11,
        locationId: warehouseId,
        locationName: 'Bodega Central',
        previousLocationQuantity: 4,
        newLocationQuantity: 6,
        reason: 'Conteo cíclico',
        createdAt: now.subtract(const Duration(hours: 6)),
        userId: actorUserId,
        userName: actorUserName,
      ),
    ];

    for (final movement in movements) {
      batch.set(movementsRef.doc(movement['id']! as String), movement);
    }

    final requests = [
      _requestMap(
        id: requestsRef.doc().id,
        product: products[5],
        locationId: storefrontId,
        locationName: 'Sala de Ventas',
        currentStock: 7,
        requestedQuantity: 20,
        reason: 'Rotación alta antes del fin de semana',
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 20)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        userId: actorUserId,
        userName: actorUserName,
      ),
      _requestMap(
        id: requestsRef.doc().id,
        product: products[1],
        locationId: storefrontId,
        locationName: 'Sala de Ventas',
        currentStock: 11,
        requestedQuantity: 16,
        reason: 'Reposición por vencimiento cercano',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
        completedAt: now.subtract(const Duration(days: 4)),
        userId: actorUserId,
        userName: actorUserName,
      ),
    ];

    for (final request in requests) {
      batch.set(requestsRef.doc(request['id']! as String), request);
    }

    final logs = [
      _activityLogMap(
        action: 'seed_demo',
        entityType: 'company',
        entityId: companyId,
        entityName: companyName,
        description: 'Se cargó un workspace demo con datos ficticios.',
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
      _activityLogMap(
        action: 'create_product',
        entityType: 'product',
        entityId: products[5].id,
        entityName: products[5].name,
        description: 'Pan Molde Integral quedó marcado con stock bajo.',
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      _activityLogMap(
        action: 'create_stock_request',
        entityType: 'stock_request',
        entityId: requests[0]['id']! as String,
        entityName: products[5].name,
        description: 'Se creó una solicitud de reposición prioritaria para sala de ventas.',
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
    ];
    for (final log in logs) {
      batch.set(activityLogsRef.doc(), log);
    }

    await batch.commit();
    await _alertService.checkAllProductAlerts(
      companyId: companyId,
      products: products,
    );
  }

  Product _buildProduct({
    required String id,
    required String name,
    required String category,
    required double price,
    required int totalStock,
    required int minStock,
    required DateTime updatedAt,
    required Map<String, ProductLocationQuantity> locationStocks,
    DateTime? expiryDate,
  }) {
    final fixedLocations = <String, ProductLocationQuantity>{
      for (final entry in locationStocks.entries)
        entry.key: ProductLocationQuantity(
          locationId: entry.key,
          locationName: entry.value.locationName,
          quantity: entry.value.quantity,
        ),
    };
    return Product(
      id: id,
      name: name,
      category: category,
      price: price,
      totalStock: totalStock,
      minStock: minStock,
      status: '',
      locationQuantities: fixedLocations,
      createdAt: updatedAt.subtract(const Duration(days: 7)),
      updatedAt: updatedAt,
      expiryDate: expiryDate,
    );
  }

  Map<String, dynamic> _movementMap({
    required String id,
    required Product product,
    required String type,
    required int quantity,
    required int previousTotalStock,
    required int newTotalStock,
    required String locationId,
    required String locationName,
    required int previousLocationQuantity,
    required int newLocationQuantity,
    required String reason,
    required DateTime createdAt,
    required String userId,
    required String userName,
    String? sourceLocationId,
    String? sourceLocationName,
    String? targetLocationId,
    String? targetLocationName,
  }) {
    return {
      'id': id,
      'productId': product.id,
      'productName': product.name,
      'barcode': product.barcode,
      'type': type,
      'quantity': quantity,
      'previousStock': previousTotalStock,
      'newStock': newTotalStock,
      'reason': reason,
      'locationId': locationId,
      'locationName': locationName,
      'sourceLocationId': sourceLocationId,
      'sourceLocationName': sourceLocationName,
      'targetLocationId': targetLocationId,
      'targetLocationName': targetLocationName,
      'previousQuantityInLocation': previousLocationQuantity,
      'newQuantityInLocation': newLocationQuantity,
      'previousTotalStock': previousTotalStock,
      'newTotalStock': newTotalStock,
      'updatedStock': newTotalStock,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> _requestMap({
    required String id,
    required Product product,
    required String locationId,
    required String locationName,
    required int currentStock,
    required int requestedQuantity,
    required String reason,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    required String userId,
    required String userName,
  }) {
    return {
      'id': id,
      'productId': product.id,
      'productName': product.name,
      'barcode': product.barcode,
      'locationId': locationId,
      'locationName': locationName,
      'currentStock': currentStock,
      'requestedQuantity': requestedQuantity,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt),
      'userId': userId,
      'userName': userName,
    };
  }

  Map<String, dynamic> _activityLogMap({
    required String action,
    required String entityType,
    required String entityId,
    required String entityName,
    required String description,
    required DateTime createdAt,
  }) {
    return {
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'entityName': entityName,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Future<void> _deleteCollection(String companyId, String collectionName) async {
    final snapshot =
        await _scopeService.companyCollection(companyId, collectionName).get();
    if (snapshot.docs.isEmpty) return;
    WriteBatch? batch;
    var operations = 0;
    for (final doc in snapshot.docs) {
      batch ??= _firestore.batch();
      batch.delete(doc.reference);
      operations++;
      if (operations == 350) {
        await batch.commit();
        batch = null;
        operations = 0;
      }
    }
    if (batch != null && operations > 0) {
      await batch.commit();
    }
  }
}
