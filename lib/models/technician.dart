class Technician {
  const Technician({
    this.id,
    required this.name,
    required this.contact,
    required this.specialty,
    this.active = true,
  });

  factory Technician.fromMap(Map<String, Object?> map) => Technician(
    id: map['id'] as int?,
    name: map['name']! as String,
    contact: map['contact']! as String,
    specialty: map['specialty']! as String,
    active: (map['active']! as int) == 1,
  );

  final int? id;

  final String name;

  final String contact;

  final String specialty;

  final bool active;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'name': name,
    'contact': contact,
    'specialty': specialty,
    'active': active ? 1 : 0,
  };
}
