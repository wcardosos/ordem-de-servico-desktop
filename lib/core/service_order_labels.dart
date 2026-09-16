import 'priority.dart';
import 'service_order_status.dart';

extension PriorityLabel on Priority {
  String get label => switch (this) {
    Priority.low => 'Baixa',
    Priority.medium => 'Média',
    Priority.high => 'Alta',
    Priority.urgent => 'Urgente',
  };
}

extension ServiceOrderStatusLabel on ServiceOrderStatus {
  String get label => switch (this) {
    ServiceOrderStatus.open => 'Aberta',
    ServiceOrderStatus.assigned => 'Atribuída',
    ServiceOrderStatus.inProgress => 'Em atendimento',
    ServiceOrderStatus.awaitingPart => 'Aguardando peça',
    ServiceOrderStatus.completed => 'Concluída',
    ServiceOrderStatus.cancelled => 'Cancelada',
  };
}
