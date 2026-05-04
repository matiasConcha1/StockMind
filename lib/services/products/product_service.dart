import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockmind/models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('products');
  }

  Stream<List<Product>> watchProducts(String userId) {
    return _collection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  Future<void> createProduct(String userId, Product product) async {
    await _collection(userId).add(product.toMap());
  }

  Future<void> updateProduct(String userId, Product product) async {
    await _collection(userId).doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String userId, String productId) async {
    await _collection(userId).doc(productId).delete();
  }

  Future<void> seedDemoProducts(String userId) async {
    final batch = _firestore.batch();
    final now = DateTime.now();
    final samples = <Product>[
      Product(
        id: '',
        name: 'Aurora Keyboard Pro',
        category: 'Periféricos',
        sku: 'AUR-KB-01',
        price: 89.99,
        stock: 34,
        minimumStock: 10,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '',
        name: 'Pulse Headset X',
        category: 'Audio',
        sku: 'PUL-HS-04',
        price: 124.50,
        stock: 9,
        minimumStock: 12,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '',
        name: 'Nova Monitor 27"',
        category: 'Pantallas',
        sku: 'NOV-MN-27',
        price: 329.0,
        stock: 14,
        minimumStock: 6,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '',
        name: 'Dock USB-C Studio',
        category: 'Accesorios',
        sku: 'DOC-USB-C',
        price: 59.90,
        stock: 5,
        minimumStock: 8,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final product in samples) {
      batch.set(_collection(userId).doc(), product.toMap());
    }

    await batch.commit();
  }
}
