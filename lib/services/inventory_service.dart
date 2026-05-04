import 'package:stockmind/models/inventory_movement.dart';
import 'package:stockmind/models/product.dart';

class InventoryService {
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Arroz integral',
      quantity: 42,
      minimumStock: 15,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Product(
      id: '2',
      name: 'Aceite de oliva',
      quantity: 8,
      minimumStock: 10,
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Product(
      id: '3',
      name: 'Café premium',
      quantity: 19,
      minimumStock: 12,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: '4',
      name: 'Detergente líquido',
      quantity: 5,
      minimumStock: 6,
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<InventoryMovement> _movements = [
    InventoryMovement(
      id: 'm1',
      productName: 'Aceite de oliva',
      quantity: 8,
      type: MovementType.updated,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    InventoryMovement(
      id: 'm2',
      productName: 'Arroz integral',
      quantity: 42,
      type: MovementType.created,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<Product> getProducts() => List.unmodifiable(_products);

  List<InventoryMovement> getMovements() => List.unmodifiable(_movements);

  Future<void> createProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _products.insert(0, product);
    _movements.insert(
      0,
      InventoryMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productName: product.name,
        quantity: product.quantity,
        type: MovementType.created,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> updateProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) return;

    _products[index] = product;
    _movements.insert(
      0,
      InventoryMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productName: product.name,
        quantity: product.quantity,
        type: MovementType.updated,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> deleteProduct(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final index = _products.indexWhere((item) => item.id == productId);
    if (index == -1) return;

    final product = _products.removeAt(index);
    _movements.insert(
      0,
      InventoryMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productName: product.name,
        quantity: product.quantity,
        type: MovementType.deleted,
        timestamp: DateTime.now(),
      ),
    );
  }
}
