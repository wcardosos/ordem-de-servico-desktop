class PartItem {
  const PartItem({
    this.id,
    required this.serviceOrderId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  factory PartItem.fromMap(Map<String, Object?> map) => PartItem(
    id: map['id'] as int?,
    serviceOrderId: map['service_order_id']! as int,
    description: map['description']! as String,
    quantity: map['quantity']! as int,
    unitPrice: (map['unit_price']! as num).toDouble(),
  );

  final int? id;

  final int serviceOrderId;

  final String description;

  final int quantity;

  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'service_order_id': serviceOrderId,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}
