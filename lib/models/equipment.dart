class Equipment {
  const Equipment({
    this.id,
    required this.customerId,
    required this.type,
    this.brand,
    this.model,
    this.serialNumber,
    this.assetTag,
    this.notes,
    this.customerName,
  });

  factory Equipment.fromMap(Map<String, Object?> map) => Equipment(
    id: map['id'] as int?,
    customerId: map['customer_id']! as int,
    type: map['type']! as String,
    brand: map['brand'] as String?,
    model: map['model'] as String?,
    serialNumber: map['serial_number'] as String?,
    assetTag: map['asset_tag'] as String?,
    notes: map['notes'] as String?,
    customerName: map['customer_name'] as String?,
  );

  final int? id;

  final int customerId;

  final String type;

  final String? brand;

  final String? model;

  final String? serialNumber;

  final String? assetTag;

  final String? notes;

  final String? customerName;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'customer_id': customerId,
    'type': type,
    'brand': brand,
    'model': model,
    'serial_number': serialNumber,
    'asset_tag': assetTag,
    'notes': notes,
  };
}
