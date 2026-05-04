enum MovementType { created, updated, deleted }

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.type,
    required this.timestamp,
  });

  final String id;
  final String productName;
  final int quantity;
  final MovementType type;
  final DateTime timestamp;

  String get title {
    switch (type) {
      case MovementType.created:
        return 'Producto creado';
      case MovementType.updated:
        return 'Stock actualizado';
      case MovementType.deleted:
        return 'Producto eliminado';
    }
  }
}
