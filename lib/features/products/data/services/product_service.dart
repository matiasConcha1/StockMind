import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    final docRef =
        product.id.isEmpty ? _collection(userId).doc() : _collection(userId).doc(product.id);
    final productToCreate = product.copyWith(id: docRef.id);
    debugPrint(
      'ProductService.createProduct: userId=$userId productId=${docRef.id}',
    );
    await docRef.set(productToCreate.toCreateMap());
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

    if (previousProduct == null) {
      await productRef.update(product.toUpdateMap());
      return;
    }

    final stockChanged = previousProduct.totalStock != product.totalStock;
    final locationChanged = !_sameLocationQuantities(
      previousProduct.locationQuantities,
      product.locationQuantities,
    );

    if (!stockChanged && !locationChanged) {
      await productRef.update(product.toUpdateMap());
      return;
    }

    final movements = _buildMovements(
      userId: userId,
      product: product,
      previousProduct: previousProduct,
      stockChangeReason: stockChangeReason,
    );

    final batch = _firestore.batch();
    batch.update(productRef, product.toUpdateMap());
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

  Future<void> deleteProduct(String userId, String productId) async {
    debugPrint(
      'ProductService.deleteProduct: userId=$userId productId=$productId',
    );
    await _collection(userId).doc(productId).delete();
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
