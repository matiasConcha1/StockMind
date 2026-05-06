import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

class ProductService {
  ProductService({
    FirebaseFirestore? firestore,
    ActivityLogService? activityLogService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLogService = activityLogService ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLogService;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('products');
  }

  String createProductId(String userId) => _collection(userId).doc().id;

  Stream<List<Product>> watchProducts(String userId) {
    debugPrint('ProductService.watchProducts: userId=$userId');
    return _collection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  Future<void> createProduct(String userId, Product product) async {
    final docRef = product.id.isEmpty
        ? _collection(userId).doc()
        : _collection(userId).doc(product.id);
    final productWithCodes = _ensureCodes(
      product.copyWith(id: docRef.id),
      fallbackProductId: docRef.id,
    );
    debugPrint(
      'ProductService.createProduct: userId=$userId productId=${docRef.id}',
    );
    await docRef.set(productWithCodes.toCreateMap());
  }

  Future<void> updateProduct(
    String userId,
    Product product, {
    Product? previousProduct,
    String? stockChangeReason,
  }) async {
    debugPrint(
      'ProductService.updateProduct: userId=$userId productId=${product.id}',
    );
    final productRef = _collection(userId).doc(product.id);
    final productToUpdate = _ensureCodes(product, fallbackProductId: product.id);

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
      userId: userId,
      product: productToUpdate,
      previousProduct: previousProduct,
      stockChangeReason: stockChangeReason,
    );

    final batch = _firestore.batch();
    batch.update(productRef, productToUpdate.toUpdateMap());
    for (final movement in movements) {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_movements')
          .doc(movement.id);
      batch.set(ref, movement.toMap());
    }
    await batch.commit();
  }

  Future<void> ensureProductCodes(String userId, Product product) async {
    final withCodes = _ensureCodes(product, fallbackProductId: product.id);
    if (withCodes.barcode == product.barcode && withCodes.qrCode == product.qrCode) {
      return;
    }
    await _collection(userId).doc(product.id).update({
      'barcode': withCodes.barcode,
      'qrCode': withCodes.qrCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<ProductLookupResult?> findProductByCode(String userId, String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return null;

    final barcodeSnapshot = await _collection(userId)
        .where('barcode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (barcodeSnapshot.docs.isNotEmpty) {
      return ProductLookupResult(
        product: Product.fromFirestore(barcodeSnapshot.docs.first),
        matchType: 'barcode',
        code: normalized,
      );
    }

    final qrSnapshot = await _collection(userId)
        .where('qrCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (qrSnapshot.docs.isNotEmpty) {
      return ProductLookupResult(
        product: Product.fromFirestore(qrSnapshot.docs.first),
        matchType: 'qrCode',
        code: normalized,
      );
    }

    final docSnapshot = await _collection(userId).doc(normalized).get();
    if (docSnapshot.exists) {
      return ProductLookupResult(
        product: Product.fromFirestore(docSnapshot),
        matchType: 'productId',
        code: normalized,
      );
    }

    return null;
  }

  Future<StockAdjustmentResult> adjustProductStock({
    required String userId,
    required String productId,
    required String locationId,
    required String locationName,
    required int quantity,
    required bool increase,
  }) async {
    final productRef = _collection(userId).doc(productId);
    final movementRef = _firestore
        .collection('users')
        .doc(userId)
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
        type: increase ? 'entrada' : 'salida',
        quantity: quantity,
        previousStock: previousStock,
        newStock: newStock,
        reason: increase ? 'Ajuste rápido por escaneo' : 'Descuento rápido por escaneo',
        locationId: locationId,
        locationName: locationName,
        previousQuantityInLocation: previousLocationQuantity,
        newQuantityInLocation: newLocationQuantity,
        previousTotalStock: previousStock,
        newTotalStock: newStock,
        createdAt: DateTime.now(),
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
      userId: userId,
      action: action,
      entityType: 'product',
      entityId: result.product.id,
      entityName: result.product.name,
      description: description,
    );

    return result;
  }

  Future<void> deleteProduct(String userId, String productId) async {
    debugPrint(
      'ProductService.deleteProduct: userId=$userId productId=$productId',
    );
    await _collection(userId).doc(productId).delete();
  }

  Product _ensureCodes(Product product, {required String fallbackProductId}) {
    final barcode = (product.barcode?.trim().isNotEmpty ?? false)
        ? product.barcode!.trim()
        : generateBarcodeValue();
    final qrCode = (product.qrCode?.trim().isNotEmpty ?? false)
        ? product.qrCode!.trim()
        : generateQrCodeValue(
            productId: product.id.isNotEmpty ? product.id : fallbackProductId,
            barcode: barcode,
          );

    return product.copyWith(
      barcode: barcode,
      qrCode: qrCode,
      status: product.stockStatus.code,
    );
  }

  List<StockMovement> _buildMovements({
    required String userId,
    required Product product,
    required Product previousProduct,
    String? stockChangeReason,
  }) {
    final movementCollection = _firestore
        .collection('users')
        .doc(userId)
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
          type: newQuantity > previousQuantity ? 'entrada' : 'salida',
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
          type: product.totalStock > previousProduct.totalStock
              ? 'entrada'
              : 'salida',
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
