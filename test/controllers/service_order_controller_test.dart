import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/service_order_controller.dart';
import 'package:ordem_de_servico/core/deletion_result.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/models/service_order.dart';
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

void main() {
  setUpServiceOrderDatabase();

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
