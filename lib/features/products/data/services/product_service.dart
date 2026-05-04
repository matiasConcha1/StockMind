import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> updateProduct(String userId, Product product) async {
    debugPrint(
      'ProductService.updateProduct: userId=$userId productId=${product.id}',
    );
    await _collection(userId).doc(product.id).update(product.toUpdateMap());
  }

  Future<void> deleteProduct(String userId, String productId) async {
    debugPrint(
      'ProductService.deleteProduct: userId=$userId productId=$productId',
    );
    await _collection(userId).doc(productId).delete();
  }
}
