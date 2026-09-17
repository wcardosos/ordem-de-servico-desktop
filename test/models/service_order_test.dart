import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/core/transition_result.dart';
import 'package:ordem_de_servico/models/part_item.dart';
import 'package:ordem_de_servico/models/service_order.dart';

ServiceOrder buildOrder({
  required ServiceOrderStatus status,
  DateTime? dueDate,
  int? technicianId,
  String? diagnosis,
  String? solution,
  double laborCost = 0,
  List<PartItem> partItems = const <PartItem>[],
}) {
  return ServiceOrder(
    number: 'OS-2026-0001',
    customerId: 1,
    equipmentId: 1,
    problemDescription: 'Não liga',
    priority: Priority.medium,
    status: status,
    openedAt: DateTime(2026, 8, 20),
    dueDate: dueDate ?? DateTime(2026, 9, 30),
    technicianId: technicianId,
    diagnosis: diagnosis,
    solution: solution,
    laborCost: laborCost,
    partItems: partItems,
  );
}

void main() {
  group('isOverdue', () {
    test('is true for an order in progress past its due date', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.inProgress,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(order.isOverdue, isTrue);
    });

    test('is false for a completed order past its due date', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.completed,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(order.isOverdue, isFalse);
    });

    test('is false for a cancelled order past its due date', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.cancelled,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(order.isOverdue, isFalse);
    });

    test('is false for an open order due today', () {
      final DateTime now = DateTime.now();
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.open,
        dueDate: DateTime(now.year, now.month, now.day),
      );

      expect(order.isOverdue, isFalse);
    });

    test('is true for an open order due yesterday', () {
      final DateTime now = DateTime.now();
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.open,
        dueDate: DateTime(now.year, now.month, now.day - 1),
      );

      expect(order.isOverdue, isTrue);
    });

    test('is false for completed or cancelled orders due yesterday', () {
      final DateTime now = DateTime.now();
      final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

      expect(
        buildOrder(
          status: ServiceOrderStatus.completed,
          dueDate: yesterday,
        ).isOverdue,
        isFalse,
      );
      expect(
        buildOrder(
          status: ServiceOrderStatus.cancelled,
          dueDate: yesterday,
        ).isOverdue,
        isFalse,
      );
    });
  });

  group('map conversion', () {
    test('writes dates as ISO text and enums by name', () {
      final ServiceOrder order = ServiceOrder(
        id: 7,
        number: 'OS-2026-0007',
        customerId: 2,
        equipmentId: 3,
        technicianId: 4,
        problemDescription: 'Tela piscando',
        priority: Priority.urgent,
        status: ServiceOrderStatus.awaitingPart,
        openedAt: DateTime(2026, 9, 5),
        dueDate: DateTime(2026, 9, 30),
        completedAt: DateTime(2026, 10, 2),
        diagnosis: 'Cabo flat',
        solution: 'Troca do cabo',
        laborCost: 150.5,
        imagePath: '/tmp/foto.png',
      );

      expect(order.toMap(), <String, Object?>{
        'id': 7,
        'number': 'OS-2026-0007',
        'customer_id': 2,
        'equipment_id': 3,
        'technician_id': 4,
        'problem_description': 'Tela piscando',
        'priority': 'urgent',
        'status': 'awaitingPart',
        'opened_at': '2026-09-05',
        'due_date': '2026-09-30',
        'completed_at': '2026-10-02',
        'diagnosis': 'Cabo flat',
        'solution': 'Troca do cabo',
        'labor_cost': 150.5,
        'image_path': '/tmp/foto.png',
      });
    });

    test('reads a row including joined names', () {
      final ServiceOrder order = ServiceOrder.fromMap(<String, Object?>{
        'id': 3,
        'number': 'OS-2026-0003',
        'customer_id': 1,
        'equipment_id': 2,
        'technician_id': null,
        'problem_description': 'Não imprime',
        'priority': 'high',
        'status': 'open',
        'opened_at': '2026-09-10',
        'due_date': '2026-09-30',
        'completed_at': null,
        'diagnosis': null,
        'solution': null,
        'labor_cost': 0,
        'image_path': null,
        'customer_name': 'Ana Ribeiro',
        'equipment_description': 'Impressora multifuncional HP LaserJet M428',
        'technician_name': null,
      });

      expect(order.id, 3);
      expect(order.number, 'OS-2026-0003');
      expect(order.technicianId, isNull);
      expect(order.priority, Priority.high);
      expect(order.status, ServiceOrderStatus.open);
      expect(order.openedAt, DateTime(2026, 9, 10));
      expect(order.dueDate, DateTime(2026, 9, 30));
      expect(order.completedAt, isNull);
      expect(order.laborCost, 0.0);
      expect(order.customerName, 'Ana Ribeiro');
      expect(
        order.equipmentDescription,
        'Impressora multifuncional HP LaserJet M428',
      );
      expect(order.technicianName, isNull);
    });
  });

  group('validateTransitionTo', () {
    const List<(ServiceOrderStatus, ServiceOrderStatus)> allowedTransitions =
        <(ServiceOrderStatus, ServiceOrderStatus)>[
          (ServiceOrderStatus.open, ServiceOrderStatus.assigned),
          (ServiceOrderStatus.open, ServiceOrderStatus.cancelled),
          (ServiceOrderStatus.assigned, ServiceOrderStatus.inProgress),
          (ServiceOrderStatus.assigned, ServiceOrderStatus.cancelled),
          (ServiceOrderStatus.inProgress, ServiceOrderStatus.awaitingPart),
          (ServiceOrderStatus.inProgress, ServiceOrderStatus.completed),
          (ServiceOrderStatus.inProgress, ServiceOrderStatus.cancelled),
          (ServiceOrderStatus.awaitingPart, ServiceOrderStatus.inProgress),
          (ServiceOrderStatus.awaitingPart, ServiceOrderStatus.cancelled),
        ];

    for (final (ServiceOrderStatus current, ServiceOrderStatus target)
        in allowedTransitions) {
      test(
        'allows ${current.name} to ${target.name} when prerequisites are met',
        () {
          final ServiceOrder order = buildOrder(
            status: current,
            technicianId: 2,
            diagnosis: 'Compressor com falha de partida',
          );

          expect(order.validateTransitionTo(target), TransitionResult.allowed);
        },
      );
    }

    const List<(ServiceOrderStatus, ServiceOrderStatus)> invalidTransitions =
        <(ServiceOrderStatus, ServiceOrderStatus)>[
          (ServiceOrderStatus.open, ServiceOrderStatus.inProgress),
          (ServiceOrderStatus.open, ServiceOrderStatus.completed),
          (ServiceOrderStatus.open, ServiceOrderStatus.open),
          (ServiceOrderStatus.assigned, ServiceOrderStatus.open),
          (ServiceOrderStatus.assigned, ServiceOrderStatus.completed),
          (ServiceOrderStatus.inProgress, ServiceOrderStatus.assigned),
          (ServiceOrderStatus.awaitingPart, ServiceOrderStatus.completed),
          (ServiceOrderStatus.completed, ServiceOrderStatus.inProgress),
          (ServiceOrderStatus.completed, ServiceOrderStatus.cancelled),
          (ServiceOrderStatus.cancelled, ServiceOrderStatus.open),
        ];

    for (final (ServiceOrderStatus current, ServiceOrderStatus target)
        in invalidTransitions) {
      test(
        'rejects ${current.name} to ${target.name} as an invalid target',
        () {
          final ServiceOrder order = buildOrder(
            status: current,
            technicianId: 2,
            diagnosis: 'Compressor com falha de partida',
            solution: 'Compressor substituído',
          );

          expect(
            order.validateTransitionTo(target),
            TransitionResult.invalidTarget,
          );
        },
      );
    }

    test('rejects assignment without a technician', () {
      final ServiceOrder order = buildOrder(status: ServiceOrderStatus.open);

      expect(
        order.validateTransitionTo(ServiceOrderStatus.assigned),
        TransitionResult.technicianNotSet,
      );
    });

    test('rejects completion without diagnosis or solution', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.inProgress,
        diagnosis: '',
      );

      expect(
        order.validateTransitionTo(ServiceOrderStatus.completed),
        TransitionResult.missingDiagnosisAndSolution,
      );
    });

    test('treats a whitespace-only diagnosis as empty', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.inProgress,
        diagnosis: '   ',
      );

      expect(
        order.validateTransitionTo(ServiceOrderStatus.completed),
        TransitionResult.missingDiagnosisAndSolution,
      );
    });
  });

  group('totalAmount', () {
    test('adds the labor cost to the sum of the part item subtotals', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.inProgress,
        laborCost: 150.00,
        partItems: <PartItem>[
          const PartItem(
            serviceOrderId: 1,
            description: 'Compressor 1/3 HP',
            quantity: 1,
            unitPrice: 780.00,
          ),
          const PartItem(
            serviceOrderId: 1,
            description: 'Gás refrigerante R410A',
            quantity: 2,
            unitPrice: 95.50,
          ),
        ],
      );

      expect(order.partsTotal, 971.00);
      expect(order.totalAmount, 1121.00);
    });

    test('is the labor cost alone for an order without part items', () {
      final ServiceOrder order = buildOrder(
        status: ServiceOrderStatus.open,
        laborCost: 200.00,
      );

      expect(order.partsTotal, 0.00);
      expect(order.totalAmount, 200.00);
    });

    test('is zero without part items and without labor cost', () {
      final ServiceOrder order = buildOrder(status: ServiceOrderStatus.open);

      expect(order.partsTotal, 0.00);
      expect(order.totalAmount, 0.00);
    });
  });
}
