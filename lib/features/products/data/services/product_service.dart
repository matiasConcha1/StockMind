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

  Stream<List<Product>> watchProducts(String userId) {
    debugPrint('ProductService.watchProducts: userId=$userId');
    return _collection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  Future<void> createProduct(String userId, Product product) async {
    final docRef = _collection(userId).doc();
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

    if (previousProduct == null || previousProduct.stock == product.stock) {
      await productRef.update(product.toUpdateMap());
      return;
    }

    final movementRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stock_movements')
        .doc();
    final movement = StockMovement(
      id: movementRef.id,
      productId: product.id,
      productName: product.name,
      type: product.stock > previousProduct.stock ? 'entrada' : 'salida',
      quantity: (product.stock - previousProduct.stock).abs(),
      previousStock: previousProduct.stock,
      newStock: product.stock,
      reason: (stockChangeReason?.trim().isNotEmpty ?? false)
          ? stockChangeReason!.trim()
          : 'Ajuste manual de stock',
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.update(productRef, product.toUpdateMap());
    batch.set(movementRef, movement.toMap());
    await batch.commit();
  }

  Future<void> deleteProduct(String userId, String productId) async {
    debugPrint(
      'ProductService.deleteProduct: userId=$userId productId=$productId',
    );
    await _collection(userId).doc(productId).delete();
  }
}
