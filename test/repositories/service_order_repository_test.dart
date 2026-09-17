import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_filter.dart';
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

  group('findFiltered', () {
    Future<int> technicianIdOf(String name) async {
      final Database database = await DatabaseHelper.instance.database;
      final List<Map<String, Object?>> rows = await database.query(
        'technicians',
        columns: <String>['id'],
        where: 'name = ?',
        whereArgs: <Object?>[name],
      );
      return rows.single['id']! as int;
    }

    Future<List<String>> numbersOf(ServiceOrderFilter filter) async {
      final List<ServiceOrder> orders = await repository.findFiltered(filter);
      return orders.map((ServiceOrder order) => order.number).toList();
    }

    Future<void> insertAnaAndCarlosOrders() async {
      await repository.insert(
        newOrder(
          customerId: 1,
          equipmentId: 1,
          technicianId: await technicianIdOf('Rafael Duarte'),
        ),
      );
      await repository.insert(
        newOrder(
          customerId: 2,
          equipmentId: 3,
          technicianId: await technicianIdOf('Bruno Alencar'),
        ),
      );
    }

    Future<({int customerId, int equipmentId})> insertCustomerWithEquipment(
      String customerName,
      String equipmentType,
    ) async {
      final Database database = await DatabaseHelper.instance.database;
      final int customerId = await database.insert(
        'customers',
        <String, Object?>{
          'name': customerName,
          'document': '99988877766',
          'phone': '11955554444',
          'email': 'contato@example.com',
          'address': 'Rua Exemplo, 100',
        },
      );
      final int equipmentId = await database.insert(
        'equipment',
        <String, Object?>{'customer_id': customerId, 'type': equipmentType},
      );
      return (customerId: customerId, equipmentId: equipmentId);
    }

    Future<void> insertTenAssortedOrders() async {
      final int bruno = await technicianIdOf('Bruno Alencar');
      final int rafael = await technicianIdOf('Rafael Duarte');
      final List<ServiceOrder> orders = <ServiceOrder>[
        newOrder(
          status: ServiceOrderStatus.open,
          priority: Priority.low,
          dueDate: DateTime(2026, 9, 1),
        ),
        newOrder(
          status: ServiceOrderStatus.open,
          priority: Priority.urgent,
          technicianId: bruno,
          dueDate: DateTime(2026, 9, 2),
        ),
        newOrder(
          status: ServiceOrderStatus.assigned,
          priority: Priority.medium,
          technicianId: rafael,
          dueDate: DateTime(2026, 9, 3),
        ),
        newOrder(
          status: ServiceOrderStatus.inProgress,
          priority: Priority.high,
          technicianId: bruno,
          dueDate: DateTime(2026, 9, 4),
        ),
        newOrder(
          status: ServiceOrderStatus.awaitingPart,
          priority: Priority.urgent,
          technicianId: rafael,
          dueDate: DateTime(2026, 9, 5),
        ),
        newOrder(
          status: ServiceOrderStatus.awaitingPart,
          priority: Priority.medium,
          dueDate: DateTime(2026, 9, 6),
        ),
        newOrder(
          status: ServiceOrderStatus.completed,
          priority: Priority.low,
          technicianId: bruno,
          dueDate: DateTime(2026, 9, 7),
        ),
        newOrder(
          status: ServiceOrderStatus.completed,
          priority: Priority.high,
          technicianId: rafael,
          dueDate: DateTime(2026, 9, 8),
        ),
        newOrder(
          status: ServiceOrderStatus.cancelled,
          priority: Priority.medium,
          dueDate: DateTime(2026, 9, 9),
        ),
        newOrder(
          status: ServiceOrderStatus.open,
          priority: Priority.low,
          technicianId: rafael,
          dueDate: DateTime(2026, 9, 10),
        ),
      ];
      for (final ServiceOrder order in orders) {
        await repository.insert(order);
      }
    }

    test('finds an order by part of its number', () async {
      await insertAnaAndCarlosOrders();

      expect(await numbersOf(const ServiceOrderFilter(term: '0001')), <String>[
        'OS-2026-0001',
      ]);
    });

    test('finds an order by part of the customer name', () async {
      await insertAnaAndCarlosOrders();

      expect(await numbersOf(const ServiceOrderFilter(term: 'Ana')), <String>[
        'OS-2026-0001',
      ]);
    });

    test('finds an order by part of the equipment type', () async {
      await insertAnaAndCarlosOrders();

      expect(
        await numbersOf(const ServiceOrderFilter(term: 'notebook')),
        <String>['OS-2026-0002'],
      );
    });

    test('finds an order by part of the technician name', () async {
      await insertAnaAndCarlosOrders();

      expect(
        await numbersOf(const ServiceOrderFilter(term: 'Duarte')),
        <String>['OS-2026-0001'],
      );
    });

    test(
      'finds the same order for an upper case and a lower case term',
      () async {
        await insertAnaAndCarlosOrders();

        expect(await numbersOf(const ServiceOrderFilter(term: 'ANA')), <String>[
          'OS-2026-0001',
        ]);
        expect(await numbersOf(const ServiceOrderFilter(term: 'ana')), <String>[
          'OS-2026-0001',
        ]);
      },
    );

    test('finds an order by a fragment in the middle of a field', () async {
      await insertAnaAndCarlosOrders();

      expect(
        await numbersOf(const ServiceOrderFilter(term: 'condicionado')),
        <String>['OS-2026-0001'],
      );
    });

    test('finds an order without a technician by the customer name', () async {
      for (int i = 0; i < 4; i++) {
        await repository.insert(newOrder(customerId: 2, equipmentId: 3));
      }
      await repository.insert(newOrder(customerId: 1, equipmentId: 1));

      expect(await numbersOf(const ServiceOrderFilter(term: 'Ana')), <String>[
        'OS-2026-0005',
      ]);
    });

    test('finds an order whose customer name contains an apostrophe', () async {
      final ({int customerId, int equipmentId}) restaurant =
          await insertCustomerWithEquipment(
            "Restaurante D'Angelo",
            'Câmara fria',
          );
      await repository.insert(
        newOrder(
          customerId: 1,
          equipmentId: 1,
          status: ServiceOrderStatus.open,
        ),
      );
      await repository.insert(
        newOrder(
          customerId: restaurant.customerId,
          equipmentId: restaurant.equipmentId,
          status: ServiceOrderStatus.open,
        ),
      );

      expect(
        await numbersOf(const ServiceOrderFilter(term: "D'Angelo")),
        <String>['OS-2026-0002'],
      );
    });

    test('filters by the awaiting part status', () async {
      await insertTenAssortedOrders();

      final List<ServiceOrder> orders = await repository.findFiltered(
        const ServiceOrderFilter(status: ServiceOrderStatus.awaitingPart),
      );

      expect(orders, hasLength(2));
      expect(
        orders.every(
          (ServiceOrder order) =>
              order.status == ServiceOrderStatus.awaitingPart,
        ),
        isTrue,
      );
    });

    test('filters by the completed status', () async {
      await insertTenAssortedOrders();

      final List<ServiceOrder> orders = await repository.findFiltered(
        const ServiceOrderFilter(status: ServiceOrderStatus.completed),
      );

      expect(orders, hasLength(2));
      expect(
        orders.every(
          (ServiceOrder order) => order.status == ServiceOrderStatus.completed,
        ),
        isTrue,
      );
    });

    test('filters by the urgent priority', () async {
      await insertTenAssortedOrders();

      final List<ServiceOrder> orders = await repository.findFiltered(
        const ServiceOrderFilter(priority: Priority.urgent),
      );

      expect(orders, hasLength(2));
      expect(
        orders.every((ServiceOrder order) => order.priority == Priority.urgent),
        isTrue,
      );
    });

    test('filters by the low priority', () async {
      await insertTenAssortedOrders();

      final List<ServiceOrder> orders = await repository.findFiltered(
        const ServiceOrderFilter(priority: Priority.low),
      );

      expect(orders, hasLength(3));
      expect(
        orders.every((ServiceOrder order) => order.priority == Priority.low),
        isTrue,
      );
    });

    test('filters by the technician in charge', () async {
      await insertTenAssortedOrders();
      final int rafael = await technicianIdOf('Rafael Duarte');

      final List<ServiceOrder> orders = await repository.findFiltered(
        ServiceOrderFilter(technicianId: rafael),
      );

      expect(orders, hasLength(4));
      expect(
        orders.every(
          (ServiceOrder order) => order.technicianName == 'Rafael Duarte',
        ),
        isTrue,
      );
    });

    test('keeps the ascending due date order under an active filter', () async {
      await repository.insert(newOrder(dueDate: DateTime(2026, 9, 30)));
      await repository.insert(newOrder(dueDate: DateTime(2026, 9, 1)));
      await repository.insert(newOrder(dueDate: DateTime(2026, 9, 15)));

      final List<ServiceOrder> orders = await repository.findFiltered(
        const ServiceOrderFilter(status: ServiceOrderStatus.open),
      );

      expect(orders.map((ServiceOrder order) => order.dueDate), <DateTime>[
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 30),
      ]);
    });

    test('lists every order when no criterion is active', () async {
      await insertTenAssortedOrders();

      final List<ServiceOrder> filtered = await repository.findFiltered(
        const ServiceOrderFilter.empty(),
      );
      final List<ServiceOrder> all = await repository.findAll();

      expect(filtered, hasLength(10));
      expect(
        filtered.map((ServiceOrder order) => order.number),
        all.map((ServiceOrder order) => order.number),
      );
    });

    test('combines the term with the status criterion', () async {
      await repository.insert(
        newOrder(
          customerId: 1,
          equipmentId: 1,
          status: ServiceOrderStatus.open,
        ),
      );
      await repository.insert(
        newOrder(
          customerId: 1,
          equipmentId: 2,
          status: ServiceOrderStatus.completed,
        ),
      );
      await repository.insert(
        newOrder(
          customerId: 2,
          equipmentId: 3,
          status: ServiceOrderStatus.open,
        ),
      );

      expect(
        await numbersOf(
          const ServiceOrderFilter(
            term: 'Ana',
            status: ServiceOrderStatus.open,
          ),
        ),
        <String>['OS-2026-0001'],
      );
    });
  });
}
