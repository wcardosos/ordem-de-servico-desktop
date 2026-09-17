import 'priority.dart';
import 'service_order_status.dart';

class ServiceOrderFilter {
  const ServiceOrderFilter({
    this.term = '',
    this.status,
    this.priority,
    this.technicianId,
  });

  const ServiceOrderFilter.empty() : this();

  final String term;

  final ServiceOrderStatus? status;

  final Priority? priority;

  final int? technicianId;

  bool get isActive =>
      term.isNotEmpty ||
      status != null ||
      priority != null ||
      technicianId != null;

  ServiceOrderFilter copyWith({
    String? term,
    ServiceOrderStatus? status,
    Priority? priority,
    int? technicianId,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearTechnicianId = false,
  }) {
    return ServiceOrderFilter(
      term: term ?? this.term,
      status: clearStatus ? null : status ?? this.status,
      priority: clearPriority ? null : priority ?? this.priority,
      technicianId: clearTechnicianId
          ? null
          : technicianId ?? this.technicianId,
    );
  }
}
