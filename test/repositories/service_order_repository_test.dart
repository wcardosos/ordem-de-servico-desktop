import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/models/service_order.dart';
import 'package:ordem_de_servico/repositories/service_order_repository.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'service_order_test_support.dart';

void main() {
  setUpServiceOrderDatabase();

  late ServiceOrderRepository repository;

  setUp(() {
    repository = ServiceOrderRepository();
  });

  Future<String> numberOf(int id) async {
    final ServiceOrder? order = await repository.findById(id);
    return order!.number;
  }

  test('generates OS-2026-0001 for the first order of the year', () async {
    final int id = await repository.insert(
      newOrder(openedAt: DateTime(2026, 3, 2)),
    );

    expect(await numberOf(id), 'OS-2026-0001');
  });

  test('generates OS-2026-0003 after OS-2026-0001 and OS-2026-0002', () async {
    final int first = await repository.insert(newOrder());
    final int second = await repository.insert(newOrder());
    expect(await numberOf(first), 'OS-2026-0001');
    expect(await numberOf(second), 'OS-2026-0002');

    final int third = await repository.insert(newOrder());

    expect(await numberOf(third), 'OS-2026-0003');
  });

  test('restarts the sequence when the opening year changes', () async {
    for (int i = 0; i < 7; i++) {
      await repository.insert(newOrder(openedAt: DateTime(2026, 5, i + 1)));
    }

    final int id = await repository.insert(
      newOrder(openedAt: DateTime(2027, 1, 4)),
    );

    expect(await numberOf(id), 'OS-2027-0001');
  });

  test('ten consecutive inserts produce ten distinct numbers', () async {
    for (int i = 0; i < 10; i++) {
      await repository.insert(newOrder());
    }

    final List<ServiceOrder> orders = await repository.findAll();

    expect(orders, hasLength(10));
    expect(
      orders.map((ServiceOrder order) => order.number).toSet(),
      hasLength(10),
    );
  });

  test('keeps the number when the order is updated', () async {
    late int id;
    for (int i = 0; i < 4; i++) {
      id = await repository.insert(newOrder());
    }
    expect(await numberOf(id), 'OS-2026-0004');
    final ServiceOrder stored = (await repository.findById(id))!;
    expect(stored.priority, Priority.medium);

    await repository.update(
      newOrder(
        id: id,
        number: 'OS-2099-9999',
        priority: Priority.high,
        openedAt: stored.openedAt,
        dueDate: stored.dueDate,
      ),
    );

    final ServiceOrder updated = (await repository.findById(id))!;
    expect(updated.number, 'OS-2026-0004');
    expect(updated.priority, Priority.high);
  });

  test('stores the due date as ISO text in the table', () async {
    final int id = await repository.insert(
      newOrder(dueDate: DateTime(2026, 9, 30)),
    );

    final Database database = await DatabaseHelper.instance.database;
    final List<Map<String, Object?>> rows = await database.query(
      'service_orders',
      columns: <String>['due_date'],
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );

    expect(rows.single['due_date'], '2026-09-30');
  });

  test(
    'continues after the highest number when an order was deleted',
    () async {
      final int first = await repository.insert(newOrder());
      final int second = await repository.insert(newOrder());
      expect(await numberOf(first), 'OS-2026-0001');
      expect(await numberOf(second), 'OS-2026-0002');

      await repository.delete(first);
      final int third = await repository.insert(newOrder());

      expect(await numberOf(third), 'OS-2026-0003');
      expect(await repository.findById(first), isNull);
      expect(await repository.findAll(), hasLength(2));
    },
  );

  test('suggests the next number for the current year', () async {
    final int year = DateTime.now().year;
    final String expectedFirst = 'OS-$year-0001';
    expect(await repository.nextNumber(), expectedFirst);

    await repository.insert(newOrder(openedAt: DateTime(year, 1, 1)));

    expect(await repository.nextNumber(), 'OS-$year-0002');
  });

  test('lists orders with joined names ordered by due date', () async {
    await repository.insert(
      newOrder(
        customerId: 1,
        equipmentId: 2,
        technicianId: 1,
        dueDate: DateTime(2026, 10, 5),
      ),
    );
    await repository.insert(
      newOrder(
        customerId: 2,
        equipmentId: 4,
        priority: Priority.urgent,
        status: ServiceOrderStatus.inProgress,
        dueDate: DateTime(2026, 9, 20),
      ),
    );

    final List<ServiceOrder> orders = await repository.findAll();

    expect(orders.map((ServiceOrder order) => order.dueDate), <DateTime>[
      DateTime(2026, 9, 20),
      DateTime(2026, 10, 5),
    ]);
    expect(orders.first.customerName, 'Carlos Menezes');
    expect(orders.first.equipmentDescription, 'Bebedouro industrial');
    expect(orders.first.technicianName, isNull);
    expect(orders.first.priority, Priority.urgent);
    expect(orders.first.status, ServiceOrderStatus.inProgress);
    expect(orders.last.customerName, 'Ana Ribeiro');
    expect(
      orders.last.equipmentDescription,
      'Impressora multifuncional HP LaserJet M428',
    );
    expect(orders.last.technicianName, 'Bruno Alencar');
  });

  test('reports a database failure when the insert violates a link', () async {
    await expectLater(
      repository.insert(newOrder(equipmentId: 999)),
      throwsA(isA<DatabaseAccessException>()),
    );

    expect(await repository.findAll(), isEmpty);
  });
}
