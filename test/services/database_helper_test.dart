import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/models/service_order.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory supportDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    supportDirectory = Directory.systemTemp.createTempSync(
      'ordem_servico_test_',
    );
    DatabaseHelper.databaseDirectoryOverride = supportDirectory.path;
  });

  tearDown(() async {
    try {
      await DatabaseHelper.instance.close();
    } finally {
      DatabaseHelper.databaseDirectoryOverride = null;
      if (supportDirectory.existsSync()) {
        supportDirectory.deleteSync(recursive: true);
      }
    }
  });

  test('creates the database on first run', () async {
    final File databaseFile = File(
      p.join(supportDirectory.path, 'ordem_servico.db'),
    );
    expect(databaseFile.existsSync(), isFalse);

    final Database database = await DatabaseHelper.instance.database;

    expect(databaseFile.existsSync(), isTrue);
    expect(await database.getVersion(), 1);

    final List<Map<String, Object?>> tables = await database.query(
      'sqlite_master',
      columns: <String>['name'],
      where: 'type = ?',
      whereArgs: <Object?>['table'],
    );
    final List<Object?> tableNames = tables
        .map((Map<String, Object?> row) => row['name'])
        .toList();
    expect(
      tableNames,
      containsAll(<String>[
        'users',
        'customers',
        'technicians',
        'equipment',
        'service_orders',
        'part_items',
      ]),
    );

    final List<Map<String, Object?>> users = await database.query('users');
    expect(users, hasLength(1));
    expect(users.single['username'], 'admin');
    expect(users.single['password'], 'admin123');

    final List<Map<String, Object?>> customers = await database.query(
      'customers',
    );
    expect(customers, hasLength(3));

    final List<Map<String, Object?>> technicians = await database.query(
      'technicians',
    );
    expect(technicians, hasLength(3));
    expect(
      technicians.map((Map<String, Object?> row) => row['specialty']).toSet(),
      hasLength(3),
    );
    expect(
      technicians.where((Map<String, Object?> row) => row['active'] == 0),
      isNotEmpty,
    );

    final List<Map<String, Object?>> equipment = await database.query(
      'equipment',
    );
    expect(equipment, hasLength(5));
    expect(
      equipment.map((Map<String, Object?> row) => row['customer_id']).toSet(),
      customers.map((Map<String, Object?> row) => row['id']).toSet(),
    );
    expect(
      equipment.map((Map<String, Object?> row) => row['type']).toSet().length,
      greaterThan(1),
    );
    expect(
      equipment.where(
        (Map<String, Object?> row) => <String>[
          'brand',
          'model',
          'serial_number',
          'asset_tag',
          'notes',
        ].every((String column) => row[column] == null),
      ),
      isNotEmpty,
    );

    expect(await database.query('service_orders'), hasLength(10));
    expect(await database.query('part_items'), isNotEmpty);
  });

  test('seeds part items and labor costs across the demo orders', () async {
    final Database database = await DatabaseHelper.instance.database;

    final List<Map<String, Object?>> items = await database.query('part_items');
    final Set<Object?> ordersWithItems = items
        .map((Map<String, Object?> row) => row['service_order_id'])
        .toSet();
    final List<Map<String, Object?>> orders = await database.query(
      'service_orders',
    );
    final Iterable<Map<String, Object?>> ordersWithLabor = orders.where(
      (Map<String, Object?> row) => (row['labor_cost']! as num) > 0,
    );

    expect(orders, hasLength(10));
    expect(ordersWithItems.length, greaterThanOrEqualTo(4));
    expect(ordersWithLabor.length, greaterThanOrEqualTo(6));
    expect(
      items.map((Map<String, Object?> row) => row['quantity']).toSet().length,
      greaterThan(1),
    );
    expect(
      items.map((Map<String, Object?> row) => row['unit_price']).toSet().length,
      greaterThan(1),
    );
    for (final Map<String, Object?> item in items) {
      expect(item['quantity']! as int, greaterThan(0));
      expect(item['unit_price']! as num, greaterThanOrEqualTo(0));
      expect((item['description']! as String).trim(), isNotEmpty);
      expect(
        orders.map((Map<String, Object?> row) => row['id']),
        contains(item['service_order_id']),
      );
    }
  });

  test('keeps no persisted total column on the service orders table', () async {
    final Database database = await DatabaseHelper.instance.database;

    final List<Map<String, Object?>> columns = await database.rawQuery(
      'PRAGMA table_info(service_orders)',
    );

    final Set<Object?> names = columns
        .map((Map<String, Object?> row) => row['name'])
        .toSet();
    expect(names, contains('labor_cost'));
    expect(names, isNot(contains('total_amount')));
    expect(names, isNot(contains('parts_total')));
    expect(
      names.whereType<String>().where((String name) => name.contains('total')),
      isEmpty,
    );
  });

  test(
    'seeds ten demo service orders across statuses and priorities',
    () async {
      final Database database = await DatabaseHelper.instance.database;

      final List<ServiceOrder> orders = (await database.query('service_orders'))
          .map(ServiceOrder.fromMap)
          .toList();

      expect(orders, hasLength(10));
      expect(
        orders.map((ServiceOrder order) => order.status).toSet(),
        ServiceOrderStatus.values.toSet(),
      );
      expect(
        orders.map((ServiceOrder order) => order.priority).toSet(),
        Priority.values.toSet(),
      );
      expect(
        orders.where((ServiceOrder order) => order.isOverdue).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        orders
            .where((ServiceOrder order) => order.priority == Priority.urgent)
            .length,
        greaterThanOrEqualTo(2),
      );
      expect(
        orders.map((ServiceOrder order) => order.number).toSet(),
        hasLength(10),
      );
      for (final ServiceOrder order in orders) {
        expect(
          RegExp(r'^OS-\d{4}-\d{4}$').hasMatch(order.number),
          isTrue,
          reason: order.number,
        );
        expect(order.number.substring(3, 7), '${order.openedAt.year}');
        final List<Map<String, Object?>> equipment = await database.query(
          'equipment',
          where: 'id = ? AND customer_id = ?',
          whereArgs: <Object?>[order.equipmentId, order.customerId],
        );
        expect(equipment, hasLength(1), reason: order.number);
      }
    },
  );

  test('reopens the existing database without recreating it', () async {
    final Database firstRun = await DatabaseHelper.instance.database;
    expect(await firstRun.query('users'), hasLength(1));
    await DatabaseHelper.instance.close();

    final Database secondRun = await DatabaseHelper.instance.database;

    expect(identical(firstRun, secondRun), isFalse);
    expect(await secondRun.getVersion(), 1);
    final List<Map<String, Object?>> users = await secondRun.query('users');
    expect(users, hasLength(1));
    expect(users.single['username'], 'admin');
  });

  test('enables foreign keys on the open connection', () async {
    final Database database = await DatabaseHelper.instance.database;

    final List<Map<String, Object?>> result = await database.rawQuery(
      'PRAGMA foreign_keys',
    );

    expect(result.single.values.single, 1);
  });

  test(
    'reports a Portuguese message when the database file cannot be accessed',
    () async {
      final Directory blockedDirectory = Directory(
        p.join(supportDirectory.path, 'blocked'),
      )..createSync();
      final ProcessResult chmod = Process.runSync('chmod', <String>[
        '555',
        blockedDirectory.path,
      ]);
      expect(chmod.exitCode, 0);
      addTearDown(() {
        Process.runSync('chmod', <String>['700', blockedDirectory.path]);
      });
      DatabaseHelper.databaseDirectoryOverride = blockedDirectory.path;

      Object? captured;
      try {
        await DatabaseHelper.instance.database;
      } catch (error) {
        captured = error;
      }

      expect(captured, isA<DatabaseAccessException>());
      final DatabaseAccessException failure =
          captured! as DatabaseAccessException;
      expect(
        failure.message,
        'Não foi possível acessar os dados locais do aplicativo.',
      );
      expect(
        failure.toString(),
        'Não foi possível acessar os dados locais do aplicativo.',
      );
      expect(failure.toString(), isNot(contains('Exception')));
      expect(failure.toString(), isNot(contains('sqlite')));
      expect(
        File(p.join(blockedDirectory.path, 'ordem_servico.db')).existsSync(),
        isFalse,
      );
    },
  );
}
