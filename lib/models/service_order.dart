import '../core/priority.dart';
import '../core/service_order_status.dart';

class ServiceOrder {
  const ServiceOrder({
    this.id,
    required this.number,
    required this.customerId,
    required this.equipmentId,
    this.technicianId,
    required this.problemDescription,
    required this.priority,
    required this.status,
    required this.openedAt,
    required this.dueDate,
    this.completedAt,
    this.diagnosis,
    this.solution,
    this.laborCost = 0,
    this.imagePath,
    this.customerName,
    this.equipmentDescription,
    this.technicianName,
  });

  factory ServiceOrder.fromMap(Map<String, Object?> map) {
    final String? completedAt = map['completed_at'] as String?;
    return ServiceOrder(
      id: map['id'] as int?,
      number: map['number']! as String,
      customerId: map['customer_id']! as int,
      equipmentId: map['equipment_id']! as int,
      technicianId: map['technician_id'] as int?,
      problemDescription: map['problem_description']! as String,
      priority: Priority.values.byName(map['priority']! as String),
      status: ServiceOrderStatus.values.byName(map['status']! as String),
      openedAt: DateTime.parse(map['opened_at']! as String),
      dueDate: DateTime.parse(map['due_date']! as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      diagnosis: map['diagnosis'] as String?,
      solution: map['solution'] as String?,
      laborCost: ((map['labor_cost'] as num?) ?? 0).toDouble(),
      imagePath: map['image_path'] as String?,
      customerName: map['customer_name'] as String?,
      equipmentDescription: map['equipment_description'] as String?,
      technicianName: map['technician_name'] as String?,
    );
  }

  final int? id;

  final String number;

  final int customerId;

  final int equipmentId;

  final int? technicianId;

  final String problemDescription;

  final Priority priority;

  final ServiceOrderStatus status;

  final DateTime openedAt;

  final DateTime dueDate;

  final DateTime? completedAt;

  final String? diagnosis;

  final String? solution;

  final double laborCost;

  final String? imagePath;

  final String? customerName;

  final String? equipmentDescription;

  final String? technicianName;

  bool get isOverdue {
    final DateTime now = DateTime.now();
    return status != ServiceOrderStatus.completed &&
        status != ServiceOrderStatus.cancelled &&
        dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  Map<String, Object?> toMap() {
    final DateTime? completed = completedAt;
    return <String, Object?>{
      'id': id,
      'number': number,
      'customer_id': customerId,
      'equipment_id': equipmentId,
      'technician_id': technicianId,
      'problem_description': problemDescription,
      'priority': priority.name,
      'status': status.name,
      'opened_at': _isoDate(openedAt),
      'due_date': _isoDate(dueDate),
      'completed_at': completed == null ? null : _isoDate(completed),
      'diagnosis': diagnosis,
      'solution': solution,
      'labor_cost': laborCost,
      'image_path': imagePath,
    };
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
