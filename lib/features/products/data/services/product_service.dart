import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/company_scope_service.dart';
import 'package:stockmind/features/activity_logs/data/services/activity_log_service.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/helpers/product_code_helper.dart';
import 'package:stockmind/features/products/models/product.dart';

class ProductLookupResult {
  const ProductLookupResult({
    required this.product,
    required this.matchType,
    required this.code,
  });

  final Product product;
  final String matchType;
  final String code;
}

class StockAdjustmentResult {
  const StockAdjustmentResult({
    required this.product,
    required this.previousStock,
    required this.newStock,
  });

  final Product product;
  final int previousStock;
  final int newStock;
}

class LocationStockAdjustmentResult {
  const LocationStockAdjustmentResult({
    required this.product,
    required this.previousStock,
    required this.newStock,
  });

  final Product product;
  final int previousStock;
  final int newStock;
}

class ProductService {
  ProductService({
    FirebaseFirestore? firestore,
    ActivityLogService? activityLogService,
    CompanyScopeService? scopeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLogService = activityLogService ?? ActivityLogService(),
        _scopeService =
            scopeService ?? CompanyScopeService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLogService;
  final CompanyScopeService _scopeService;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _scopeService.companyCollection(companyId, 'products');
  }

  String createProductId(String companyId) => _collection(companyId).doc().id;

  Stream<List<Product>> watchProducts(String companyId) {
    debugPrint('ProductService.watchProducts: companyId=$companyId');
    return _collection(companyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Product.fromFirestore)
              .where((product) => !product.isArchived)
              .toList(),
        );
  }

  Future<void> createProduct(String companyId, Product product) async {
    final docRef = product.id.isEmpty
        ? _collection(companyId).doc()
        : _collection(companyId).doc(product.id);
    final productWithCodes = _ensureCodes(
      product.copyWith(id: docRef.id),
      fallbackProductId: docRef.id,
    );
    await _assertBarcodeAvailable(
      companyId: companyId,
      barcode: productWithCodes.barcode,
    );
    debugPrint(
      'ProductService.createProduct: companyId=$companyId productId=${docRef.id}',
    );
    await docRef.set(productWithCodes.toCreateMap());
  }

  Future<void> updateProduct(
    String companyId,
    Product product, {
    Product? previousProduct,
    String? stockChangeReason,
    String? actorUserId,
    String? actorUserName,
  }) async {
    debugPrint(
      'ProductService.updateProduct: companyId=$companyId productId=${product.id}',
    );
    final productRef = _collection(companyId).doc(product.id);
    final productToUpdate = _ensureCodes(product, fallbackProductId: product.id);
    await _assertBarcodeAvailable(
      companyId: companyId,
      barcode: productToUpdate.barcode,
      excludeProductId: product.id,
    );

    if (previousProduct == null) {
      await productRef.update(productToUpdate.toUpdateMap());
      return;
    }

    final stockChanged = previousProduct.totalStock != productToUpdate.totalStock;
    final locationChanged = !_sameLocationQuantities(
      previousProduct.locationQuantities,
      productToUpdate.locationQuantities,
    );

    if (!stockChanged && !locationChanged) {
      await productRef.update(productToUpdate.toUpdateMap());
      return;
    }

    final movements = _buildMovements(
      companyId: companyId,
      product: productToUpdate,
      previousProduct: previousProduct,
      stockChangeReason: stockChangeReason,
      actorUserId: actorUserId,
      actorUserName: actorUserName,
    );

    final batch = _firestore.batch();
    batch.update(productRef, productToUpdate.toUpdateMap());
    for (final movement in movements) {
      final ref = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('stock_movements')
          .doc(movement.id);
      batch.set(ref, movement.toMap());
    }
    await batch.commit();
  }

  Future<void> ensureProductCodes(String companyId, Product product) async {
    final withCodes = _ensureCodes(product, fallbackProductId: product.id);
    if (withCodes.barcode == product.barcode && withCodes.qrCode == product.qrCode) {
      return;
    }
    await _collection(companyId).doc(product.id).update({
      'barcode': withCodes.barcode,
      'qrCode': withCodes.qrCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<ProductLookupResult?> findProductByCode(String companyId, String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return null;

    final barcodeSnapshot = await _collection(companyId)
        .where('barcode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (barcodeSnapshot.docs.isNotEmpty) {
      final product = Product.fromFirestore(barcodeSnapshot.docs.first);
      if (product.isArchived) return null;
      return ProductLookupResult(
        product: product,
        matchType: 'barcode',
        code: normalized,
      );
    }

    final qrSnapshot = await _collection(companyId)
        .where('qrCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (qrSnapshot.docs.isNotEmpty) {
      final product = Product.fromFirestore(qrSnapshot.docs.first);
      if (product.isArchived) return null;
      return ProductLookupResult(
        product: product,
        matchType: 'qrCode',
        code: normalized,
      );
    }

    final docSnapshot = await _collection(companyId).doc(normalized).get();
    if (docSnapshot.exists) {
      final product = Product.fromFirestore(docSnapshot);
      if (product.isArchived) return null;
      return ProductLookupResult(
        product: product,
        matchType: 'productId',
        code: normalized,
      );
    }

    return null;
  }

  Future<StockAdjustmentResult> adjustProductStock({
    required String companyId,
    required String productId,
    required String locationId,
    required String locationName,
    required int quantity,
    required bool increase,
    String movementType = 'adjustment',
    String? reason,
    String? actorUserId,
    String? actorUserName,
  }) async {
    if (quantity < 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'La cantidad mínima permitida es 1.',
      );
    }
    if (locationId.trim().isEmpty || locationName.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Debes seleccionar una ubicación válida para mover stock.',
      );
    }
    final productRef = _collection(companyId).doc(productId);
    final movementRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('stock_movements')
        .doc();

    late final StockAdjustmentResult result;
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No encontramos el producto escaneado.',
        );
      }

      final currentProduct = Product.fromFirestore(snapshot);
      if (currentProduct.isArchived) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'No puedes ajustar stock de un producto archivado.',
        );
      }
      final existingEntry = currentProduct.locationQuantities[locationId];
      final previousLocationQuantity = existingEntry?.quantity ?? 0;
      final previousStock = currentProduct.totalStock;
      final newStock = increase ? previousStock + quantity : previousStock - quantity;

      if (!increase && quantity > previousStock) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message:
              'No puedes descontar mas unidades que el stock disponible.',
        );
      }

      final newLocationQuantity = increase
          ? previousLocationQuantity + quantity
          : previousLocationQuantity - quantity;
      if (newLocationQuantity < 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message:
              'No puedes descontar mas unidades que el stock disponible.',
        );
      }

      final updatedLocations =
          Map<String, ProductLocationQuantity>.from(currentProduct.locationQuantities);
      if (newLocationQuantity == 0) {
        updatedLocations.remove(locationId);
      } else {
        updatedLocations[locationId] = ProductLocationQuantity(
          locationId: locationId,
          locationName: locationName,
          quantity: newLocationQuantity,
        );
      }

      final updatedProduct = _ensureCodes(
        currentProduct.copyWith(
          totalStock: newStock,
          locationQuantities: updatedLocations,
          updatedAt: DateTime.now(),
        ),
        fallbackProductId: currentProduct.id,
      );

      transaction.update(productRef, updatedProduct.toUpdateMap());
      final movement = StockMovement(
        id: movementRef.id,
        productId: currentProduct.id,
        productName: currentProduct.name,
        barcode: currentProduct.barcode,
        type: movementType,
        quantity: quantity,
        previousStock: previousStock,
        newStock: newStock,
        reason: reason ??
            (increase
                ? 'Ajuste rápido por escaneo'
                : 'Descuento rápido por escaneo'),
        locationId: locationId,
        locationName: locationName,
        previousQuantityInLocation: previousLocationQuantity,
        newQuantityInLocation: newLocationQuantity,
        previousTotalStock: previousStock,
        newTotalStock: newStock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: actorUserId,
        userName: actorUserName,
      );
      transaction.set(movementRef, movement.toMap());

      result = StockAdjustmentResult(
        product: updatedProduct,
        previousStock: previousStock,
        newStock: newStock,
      );
    });

    final action = increase ? 'increase_stock' : 'decrease_stock';
    final description = increase
        ? 'Se sumaron $quantity unidades al producto ${result.product.name}. Stock anterior: ${result.previousStock}, stock nuevo: ${result.newStock}.'
        : 'Se descontaron $quantity unidades del producto ${result.product.name}. Stock anterior: ${result.previousStock}, stock nuevo: ${result.newStock}.';
    await _activityLogService.createLog(
      companyId: companyId,
      action: action,
      entityType: 'product',
      entityId: result.product.id,
      entityName: result.product.name,
      description: description,
    );

    return result;
  }

  Future<LocationStockAdjustmentResult> setProductLocationStock({
    required String companyId,
    required String productId,
    required String locationId,
    required String locationName,
    required int newQuantity,
    String? reason,
    String? actorUserId,
    String? actorUserName,
  }) async {
    if (locationId.trim().isEmpty || locationName.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Debes seleccionar una ubicación válida para ajustar stock.',
      );
    }
    final productRef = _collection(companyId).doc(productId);
    final movementRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('stock_movements')
        .doc();

    late final LocationStockAdjustmentResult result;
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No encontramos el producto escaneado.',
        );
      }

      final currentProduct = Product.fromFirestore(snapshot);
      if (currentProduct.isArchived) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'No puedes ajustar stock de un producto archivado.',
        );
      }

      if (newQuantity < 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'La cantidad ajustada no puede ser negativa.',
        );
      }

      final previousStock = currentProduct.totalStock;
      final previousLocationQuantity =
          currentProduct.locationQuantities[locationId]?.quantity ?? 0;
      final delta = newQuantity - previousLocationQuantity;
      final updatedLocations =
          Map<String, ProductLocationQuantity>.from(currentProduct.locationQuantities);

      if (newQuantity == 0) {
        updatedLocations.remove(locationId);
      } else {
        updatedLocations[locationId] = ProductLocationQuantity(
          locationId: locationId,
          locationName: locationName,
          quantity: newQuantity,
        );
      }

      final updatedProduct = _ensureCodes(
        currentProduct.copyWith(
          totalStock: previousStock + delta,
          locationQuantities: updatedLocations,
          updatedAt: DateTime.now(),
        ),
        fallbackProductId: currentProduct.id,
      );

      transaction.update(productRef, updatedProduct.toUpdateMap());
      final movement = StockMovement(
        id: movementRef.id,
        productId: currentProduct.id,
        productName: currentProduct.name,
        barcode: currentProduct.barcode,
        type: 'adjustment',
        quantity: delta.abs(),
        previousStock: previousStock,
        newStock: updatedProduct.totalStock,
        reason: reason ?? 'Ajuste rápido desde escáner',
        locationId: locationId,
        locationName: locationName,
        previousQuantityInLocation: previousLocationQuantity,
        newQuantityInLocation: newQuantity,
        previousTotalStock: previousStock,
        newTotalStock: updatedProduct.totalStock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: actorUserId,
        userName: actorUserName,
      );
      transaction.set(movementRef, movement.toMap());

      result = LocationStockAdjustmentResult(
        product: updatedProduct,
        previousStock: previousStock,
        newStock: updatedProduct.totalStock,
      );
    });

    await _activityLogService.createLog(
      companyId: companyId,
      action: 'adjust_stock',
      entityType: 'product',
      entityId: result.product.id,
      entityName: result.product.name,
      description:
          'Se ajustó el stock del producto ${result.product.name}. Stock anterior: ${result.previousStock}, stock nuevo: ${result.newStock}.',
    );

    return result;
  }

  Future<StockAdjustmentResult> transferProductStock({
    required String companyId,
    required String productId,
    required String sourceLocationId,
    required String sourceLocationName,
    required String targetLocationId,
    required String targetLocationName,
    required int quantity,
    String? actorUserId,
    String? actorUserName,
  }) async {
    if (sourceLocationId.trim().isEmpty ||
        sourceLocationName.trim().isEmpty ||
        targetLocationId.trim().isEmpty ||
        targetLocationName.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Debes indicar ubicación origen y destino para transferir stock.',
      );
    }
    final productRef = _collection(companyId).doc(productId);
    final movementRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('stock_movements')
        .doc();

    late final StockAdjustmentResult result;
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No encontramos el producto escaneado.',
        );
      }

      final currentProduct = Product.fromFirestore(snapshot);
      if (currentProduct.isArchived) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'No puedes mover stock de un producto archivado.',
        );
      }
      if (quantity < 1) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'La transferencia mínima es de 1 unidad.',
        );
      }
      if (sourceLocationId == targetLocationId) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'Debes elegir ubicaciones diferentes para la transferencia.',
        );
      }

      final sourcePrevious =
          currentProduct.locationQuantities[sourceLocationId]?.quantity ?? 0;
      final targetPrevious =
          currentProduct.locationQuantities[targetLocationId]?.quantity ?? 0;
      if (quantity > sourcePrevious) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'No puedes mover más stock del disponible en la ubicación origen.',
        );
      }

      final updatedLocations =
          Map<String, ProductLocationQuantity>.from(currentProduct.locationQuantities);
      final sourceNew = sourcePrevious - quantity;
      final targetNew = targetPrevious + quantity;

      if (sourceNew == 0) {
        updatedLocations.remove(sourceLocationId);
      } else {
        updatedLocations[sourceLocationId] = ProductLocationQuantity(
          locationId: sourceLocationId,
          locationName: sourceLocationName,
          quantity: sourceNew,
        );
      }
      updatedLocations[targetLocationId] = ProductLocationQuantity(
        locationId: targetLocationId,
        locationName: targetLocationName,
        quantity: targetNew,
      );

      final updatedProduct = _ensureCodes(
        currentProduct.copyWith(
          locationQuantities: updatedLocations,
          updatedAt: DateTime.now(),
        ),
        fallbackProductId: currentProduct.id,
      );

      transaction.update(productRef, updatedProduct.toUpdateMap());
      final movement = StockMovement(
        id: movementRef.id,
        productId: currentProduct.id,
        productName: currentProduct.name,
        barcode: currentProduct.barcode,
        type: 'transfer',
        quantity: quantity,
        previousStock: currentProduct.totalStock,
        newStock: updatedProduct.totalStock,
        reason:
            'Transferencia de $sourceLocationName a $targetLocationName',
        locationId: targetLocationId,
        locationName: targetLocationName,
        sourceLocationId: sourceLocationId,
        sourceLocationName: sourceLocationName,
        targetLocationId: targetLocationId,
        targetLocationName: targetLocationName,
        previousQuantityInLocation: sourcePrevious,
        newQuantityInLocation: sourceNew,
        previousTotalStock: currentProduct.totalStock,
        newTotalStock: updatedProduct.totalStock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: actorUserId,
        userName: actorUserName,
      );
      transaction.set(movementRef, movement.toMap());

      result = StockAdjustmentResult(
        product: updatedProduct,
        previousStock: currentProduct.totalStock,
        newStock: updatedProduct.totalStock,
      );
    });

    await _activityLogService.createLog(
      companyId: companyId,
      action: 'transfer_stock',
      entityType: 'product',
      entityId: result.product.id,
      entityName: result.product.name,
      description:
          'Se movieron $quantity unidades del producto ${result.product.name} entre ubicaciones.',
    );
    return result;
  }

  Future<void> archiveProduct({
    required String userId,
    required String companyId,
    required Product product,
    required String deletedBy,
    required String deleteReason,
  }) async {
    debugPrint(
      'ProductService.archiveProduct: companyId=$companyId productId=${product.id}',
    );
    await _collection(companyId).doc(product.id).set({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
      'deleteReason': deleteReason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _activityLogService.createLog(
      companyId: companyId,
      action: 'delete_product',
      entityType: 'product',
      entityId: product.id,
      entityName: product.name,
      description:
          'Se archivó/eliminó manualmente el producto ${product.name}.',
    );
  }

  Product _ensureCodes(Product product, {required String fallbackProductId}) {
    final barcode = (product.barcode?.trim().isNotEmpty ?? false)
        ? product.barcode!.trim()
        : generateBarcodeValue();
    final qrCode = generateQrCodeValue(
      productId: product.id.isNotEmpty ? product.id : fallbackProductId,
      barcode: barcode,
    );

    return product.copyWith(
      barcode: barcode,
      qrCode: qrCode,
      status: product.stockStatus.code,
    );
  }

  Future<void> _assertBarcodeAvailable({
    required String companyId,
    required String? barcode,
    String? excludeProductId,
  }) async {
    final normalized = barcode?.trim() ?? '';
    if (normalized.isEmpty) return;

    final snapshot = await _collection(companyId)
        .where('barcode', isEqualTo: normalized)
        .limit(5)
        .get();

    for (final doc in snapshot.docs) {
      if (excludeProductId != null && doc.id == excludeProductId) {
        continue;
      }
      final existing = Product.fromFirestore(doc);
      if (existing.isArchived) {
        continue;
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'Ya existe un producto con ese código.',
      );
    }
  }

  List<StockMovement> _buildMovements({
    required String companyId,
    required Product product,
    required Product previousProduct,
    String? stockChangeReason,
    String? actorUserId,
    String? actorUserName,
  }) {
    final movementCollection = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('stock_movements');
    final movements = <StockMovement>[];

    final keys = <String>{
      ...previousProduct.locationQuantities.keys,
      ...product.locationQuantities.keys,
    };

    for (final key in keys) {
      final previousItem = previousProduct.locationQuantities[key];
      final nextItem = product.locationQuantities[key];
      final previousQuantity = previousItem?.quantity ?? 0;
      final newQuantity = nextItem?.quantity ?? 0;
      if (previousQuantity == newQuantity) continue;

      final ref = movementCollection.doc();
      movements.add(
        StockMovement(
          id: ref.id,
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          type: 'adjustment',
          quantity: (newQuantity - previousQuantity).abs(),
          previousStock: previousProduct.totalStock,
          newStock: product.totalStock,
          reason: _resolveReason(stockChangeReason),
          locationId: key,
          locationName:
              nextItem?.locationName ?? previousItem?.locationName ?? 'Ubicación',
          previousQuantityInLocation: previousQuantity,
          newQuantityInLocation: newQuantity,
          previousTotalStock: previousProduct.totalStock,
          newTotalStock: product.totalStock,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: actorUserId,
          userName: actorUserName,
        ),
      );
    }

    if (movements.isEmpty && previousProduct.totalStock != product.totalStock) {
      final ref = movementCollection.doc();
      movements.add(
        StockMovement(
          id: ref.id,
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          type: 'adjustment',
          quantity: (product.totalStock - previousProduct.totalStock).abs(),
          previousStock: previousProduct.totalStock,
          newStock: product.totalStock,
          reason: _resolveReason(stockChangeReason),
          locationId: '',
          locationName: 'Sin ubicación asignada',
          previousQuantityInLocation: previousProduct.totalStock,
          newQuantityInLocation: product.totalStock,
          previousTotalStock: previousProduct.totalStock,
          newTotalStock: product.totalStock,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: actorUserId,
          userName: actorUserName,
        ),
      );
    }

    return movements;
  }

  bool _sameLocationQuantities(
    Map<String, ProductLocationQuantity> previous,
    Map<String, ProductLocationQuantity> next,
  ) {
    if (previous.length != next.length) return false;
    for (final entry in previous.entries) {
      final other = next[entry.key];
      if (other == null) return false;
      if (other.quantity != entry.value.quantity ||
          other.locationName != entry.value.locationName) {
        return false;
      }
    }
    return true;
  }

  String _resolveReason(String? stockChangeReason) {
    if (stockChangeReason == null || stockChangeReason.trim().isEmpty) {
      return 'Ajuste manual de stock';
    }
    return stockChangeReason.trim();
  }
}
