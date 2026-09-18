import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/models/part_item.dart';
import 'package:ordem_de_servico/models/service_order.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void setUpServiceOrderDatabase() {
  late Directory supportDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    supportDirectory = Directory.systemTemp.createTempSync(
      'ordem_servico_orders_test_',
    );
    DatabaseHelper.databaseDirectoryOverride = supportDirectory.path;
    final Database database = await DatabaseHelper.instance.database;
    await database.delete('part_items');
    await database.delete('service_orders');
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
}

ServiceOrder newOrder({
  int? id,
  String number = '',
  int customerId = 1,
  int equipmentId = 1,
  int? technicianId,
  String problemDescription = 'Não liga',
  Priority priority = Priority.medium,
  ServiceOrderStatus status = ServiceOrderStatus.open,
  DateTime? openedAt,
  DateTime? dueDate,
  String? diagnosis,
  String? solution,
  double laborCost = 0,
  List<PartItem> partItems = const <PartItem>[],
}) {
  return ServiceOrder(
    id: id,
    number: number,
    customerId: customerId,
    equipmentId: equipmentId,
    technicianId: technicianId,
    problemDescription: problemDescription,
    priority: priority,
    status: status,
    openedAt: openedAt ?? DateTime(2026, 9, 10),
    dueDate: dueDate ?? DateTime(2026, 9, 30),
    diagnosis: diagnosis,
    solution: solution,
    laborCost: laborCost,
    partItems: partItems,
  );
}

const String indicatorBaseTotalAmountLabel = r'R$ 2.941,00';

String _isoDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Future<Map<String, int>> seedIndicatorBase(Database database) async {
  await database.delete('part_items');
  await database.delete('service_orders');
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String day(int offset) =>
      _isoDay(DateTime(today.year, today.month, today.day + offset));

  const List<List<Object>> base = <List<Object>>[
    <Object>['OS-2026-0001', 'open', 'high', 16, 0.0],
    <Object>['OS-2026-0002', 'open', 'urgent', -13, 0.0],
    <Object>['OS-2026-0003', 'assigned', 'medium', 6, 100.0],
    <Object>['OS-2026-0004', 'inProgress', 'high', 4, 150.0],
    <Object>['OS-2026-0005', 'inProgress', 'urgent', -9, 200.0],
    <Object>['OS-2026-0006', 'awaitingPart', 'medium', 11, 120.0],
    <Object>['OS-2026-0007', 'awaitingPart', 'low', -4, 80.0],
    <Object>['OS-2026-0008', 'completed', 'medium', -13, 180.0],
    <Object>['OS-2026-0009', 'completed', 'low', -6, 90.0],
    <Object>['OS-2026-0010', 'cancelled', 'high', -12, 0.0],
  ];

  final Map<String, int> identifiers = <String, int>{};
  for (final List<Object> order in base) {
    identifiers[order[0] as String] = await database.insert(
      'service_orders',
      <String, Object?>{
        'number': order[0],
        'customer_id': 1,
        'equipment_id': 1,
        'problem_description': 'Não está gelando',
        'priority': order[2],
        'status': order[1],
        'opened_at': day(-20),
        'due_date': day(order[3] as int),
        'labor_cost': order[4],
      },
    );
  }

  const List<List<Object>> parts = <List<Object>>[
    <Object>['OS-2026-0004', 'Placa de controle', 2, 485.50],
    <Object>['OS-2026-0005', 'Bateria selada', 4, 80.00],
    <Object>['OS-2026-0006', 'Gás refrigerante', 3, 160.00],
    <Object>['OS-2026-0008', 'Cabo flat de vídeo', 1, 250.00],
  ];
  for (final List<Object> item in parts) {
    await database.insert('part_items', <String, Object?>{
      'service_order_id': identifiers[item[0] as String],
      'description': item[1],
      'quantity': item[2],
      'unit_price': item[3],
    });
  }
  return identifiers;
}

Future<void> changeStoredStatus(
  Database database,
  int id,
  ServiceOrderStatus status,
) async {
  await database.update(
    'service_orders',
    <String, Object?>{'status': status.name},
    where: 'id = ?',
    whereArgs: <Object?>[id],
  );
}
