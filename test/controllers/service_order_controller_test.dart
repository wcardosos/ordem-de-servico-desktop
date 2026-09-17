import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/service_order_controller.dart';
import 'package:ordem_de_servico/core/deletion_result.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/core/transition_result.dart';
import 'package:ordem_de_servico/models/part_item.dart';
import 'package:ordem_de_servico/models/service_order.dart';
import 'package:ordem_de_servico/repositories/part_item_repository.dart';
import 'package:ordem_de_servico/repositories/service_order_repository.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../repositories/service_order_test_support.dart';

class DuplicateNumberRepository extends ServiceOrderRepository {
  @override
  Future<int> insert(ServiceOrder order) async {
    final Database database = await DatabaseHelper.instance.database;
    try {
      await database.transaction((Transaction txn) async {
        await txn.insert('service_orders', <String, Object?>{
          ...order.toMap()..remove('id'),
          'number': 'OS-2026-0001',
        });
      });
    } catch (_) {
      throw const DatabaseAccessException();
    }
    return 0;
  }
}

Future<ServiceOrder> storeOrder(
  ServiceOrderController controller, {
  required ServiceOrderStatus status,
  int? technicianId,
  String? diagnosis,
  String? solution,
}) async {
  await controller.open(newOrder());
  final ServiceOrder stored = controller.orders.single;
  await ServiceOrderRepository().update(
    newOrder(
      id: stored.id,
      number: stored.number,
      status: status,
      technicianId: technicianId,
      diagnosis: diagnosis,
      solution: solution,
    ),
  );
  await controller.load();
  return controller.orders.single;
}

Future<int> technicianIdByName(String name) async {
  final Database database = await DatabaseHelper.instance.database;
  final List<Map<String, Object?>> rows = await database.query(
    'technicians',
    columns: <String>['id'],
    where: 'name = ?',
    whereArgs: <Object?>[name],
  );
  return rows.single['id']! as int;
}

void main() {
  setUpServiceOrderDatabase();

  group('changeStatus', () {
    test('completes an order with a diagnosis and records today', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.inProgress,
        diagnosis: 'Compressor com falha de partida',
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.completed,
      );

      final DateTime now = DateTime.now();
      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.allowed);
      expect(stored!.status, ServiceOrderStatus.completed);
      expect(stored.completedAt, DateTime(now.year, now.month, now.day));
      expect(stored.diagnosis, 'Compressor com falha de partida');
      expect(controller.orders.single.status, ServiceOrderStatus.completed);
    });

    test('completes an order with only a solution', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.inProgress,
        solution: 'Compressor substituído',
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.completed,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.allowed);
      expect(stored!.status, ServiceOrderStatus.completed);
    });

    test('refuses completion without diagnosis or solution', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.inProgress,
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.completed,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.missingDiagnosisAndSolution);
      expect(stored!.status, ServiceOrderStatus.inProgress);
      expect(stored.completedAt, isNull);
    });

    test('refuses completion with a whitespace-only diagnosis', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.inProgress,
        diagnosis: '   ',
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.completed,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.missingDiagnosisAndSolution);
      expect(stored!.status, ServiceOrderStatus.inProgress);
      expect(stored.completedAt, isNull);
    });

    test('assigns an order with a technician', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.open,
        technicianId: await technicianIdByName('Rafael Duarte'),
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.assigned,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.allowed);
      expect(stored!.status, ServiceOrderStatus.assigned);
      expect(stored.technicianName, 'Rafael Duarte');
    });

    test('refuses assignment without a technician', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.open,
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.assigned,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.technicianNotSet);
      expect(stored!.status, ServiceOrderStatus.open);
    });

    test('cancels an order awaiting a part without a reason', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.awaitingPart,
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.cancelled,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.allowed);
      expect(stored!.status, ServiceOrderStatus.cancelled);
      expect(stored.completedAt, isNull);
    });

    test('refuses an invalid target without writing', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.completed,
        diagnosis: 'Compressor com falha de partida',
      );

      final TransitionResult result = await controller.changeStatus(
        order,
        ServiceOrderStatus.cancelled,
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(result, TransitionResult.invalidTarget);
      expect(stored!.status, ServiceOrderStatus.completed);
    });

    test('sets the status change error when the write fails', () async {
      final ServiceOrderController controller = ServiceOrderController();
      final ServiceOrder order = await storeOrder(
        controller,
        status: ServiceOrderStatus.awaitingPart,
      );
      final ServiceOrder broken = newOrder(
        id: order.id,
        number: order.number,
        status: ServiceOrderStatus.awaitingPart,
        equipmentId: 999,
      );

      await expectLater(
        controller.changeStatus(broken, ServiceOrderStatus.cancelled),
        throwsA(isA<DatabaseAccessException>()),
      );

      final ServiceOrder? stored = await ServiceOrderRepository().findById(
        order.id!,
      );
      expect(
        controller.error,
        ServiceOrderController.statusChangeFailedMessage,
      );
      expect(stored!.status, ServiceOrderStatus.awaitingPart);
    });
  });

  test('load fills the orders and clears loading', () async {
    await ServiceOrderRepository().insert(newOrder());
    final ServiceOrderController controller = ServiceOrderController();

    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    expect(controller.orders, hasLength(1));
    expect(controller.orders.single.number, 'OS-2026-0001');
  });

  test('open inserts the order and refreshes the list', () async {
    final ServiceOrderController controller = ServiceOrderController();

    final bool saved = await controller.open(newOrder());

    expect(saved, isTrue);
    expect(controller.error, isNull);
    expect(controller.orders.single.number, 'OS-2026-0001');
  });

  test('open returns false with a message on a duplicate number', () async {
    final ServiceOrderController controller = ServiceOrderController(
      repository: DuplicateNumberRepository(),
    );
    expect(await controller.open(newOrder()), isTrue);

    final bool saved = await controller.open(newOrder());

    expect(saved, isFalse);
    expect(controller.error, isNotNull);
    expect(controller.error, isNot(contains('UNIQUE')));
    expect(await ServiceOrderRepository().findAll(), hasLength(1));
  });

  test('open returns false without writing when the insert fails', () async {
    final ServiceOrderController controller = ServiceOrderController();

    final bool saved = await controller.open(newOrder(equipmentId: 999));

    expect(saved, isFalse);
    expect(controller.error, isNotNull);
    expect(await ServiceOrderRepository().findAll(), isEmpty);
  });

  test('update saves changes and keeps the number', () async {
    final ServiceOrderController controller = ServiceOrderController();
    await controller.open(newOrder());
    final ServiceOrder stored = controller.orders.single;

    final bool saved = await controller.update(
      newOrder(id: stored.id, number: stored.number, priority: Priority.high),
    );

    expect(saved, isTrue);
    expect(controller.orders.single.priority, Priority.high);
    expect(controller.orders.single.number, 'OS-2026-0001');
  });

  test('update returns false with a message when the write fails', () async {
    final ServiceOrderController controller = ServiceOrderController();
    await controller.open(newOrder());
    final ServiceOrder stored = controller.orders.single;

    final bool saved = await controller.update(
      newOrder(id: stored.id, number: stored.number, equipmentId: 999),
    );

    expect(saved, isFalse);
    expect(controller.error, isNotNull);
    final ServiceOrder? unchanged = await ServiceOrderRepository().findById(
      stored.id!,
    );
    expect(unchanged!.equipmentId, 1);
  });

  test('delete removes the order', () async {
    final ServiceOrderController controller = ServiceOrderController();
    await controller.open(newOrder());
    final int id = controller.orders.single.id!;

    final DeletionResult result = await controller.delete(id);

    expect(result, DeletionResult.success);
    expect(controller.orders, isEmpty);
    expect(await ServiceOrderRepository().findById(id), isNull);
  });

  test('delete also removes the part items of the order', () async {
    final ServiceOrderController controller = ServiceOrderController();
    await controller.open(newOrder());
    final int id = controller.orders.single.id!;
    final PartItemRepository partItems = PartItemRepository();
    for (final List<Object> part in <List<Object>>[
      <Object>['Rolete de tração', 1, 98.50],
      <Object>['Kit de limpeza de roletes', 3, 24.90],
      <Object>['Gás refrigerante R410A', 2, 95.50],
    ]) {
      await partItems.insert(
        PartItem(
          serviceOrderId: id,
          description: part[0] as String,
          quantity: part[1] as int,
          unitPrice: part[2] as double,
        ),
      );
    }
    expect(await partItems.findByServiceOrder(id), hasLength(3));

    final DeletionResult result = await controller.delete(id);

    expect(result, DeletionResult.success);
    expect(await partItems.findByServiceOrder(id), isEmpty);
    expect(await ServiceOrderRepository().findById(id), isNull);
  });

  for (final ServiceOrderStatus status in ServiceOrderStatus.values.where(
    (ServiceOrderStatus status) => status != ServiceOrderStatus.open,
  )) {
    test(
      'delete is blocked and keeps an order with status ${status.name}',
      () async {
        final ServiceOrderController controller = ServiceOrderController();
        await controller.open(newOrder());
        final ServiceOrder stored = controller.orders.single;
        await ServiceOrderRepository().update(
          newOrder(id: stored.id, number: stored.number, status: status),
        );
        await controller.load();

        final DeletionResult result = await controller.delete(stored.id!);

        expect(result, DeletionResult.blockedByLink);
        expect(await ServiceOrderRepository().findById(stored.id!), isNotNull);
        expect(controller.orders, hasLength(1));
      },
    );
  }
}
