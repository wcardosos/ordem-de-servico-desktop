import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/priority.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
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
  );
}
