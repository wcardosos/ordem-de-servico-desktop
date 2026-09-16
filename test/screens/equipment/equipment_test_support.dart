import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/equipment_controller.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_module.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../customers/customers_test_support.dart';

export '../customers/customers_test_support.dart'
    show
        TemporaryDatabase,
        withDatabase,
        insertCustomer,
        tapAndWaitForDatabase,
        tapAndPump,
        expectNoDialogs,
        expectNoTechnicalErrorText;

Future<void> clearEquipmentData(Database database) async {
  await database.delete('part_items');
  await database.delete('service_orders');
  await database.delete('equipment');
  await database.delete('customers');
}

Future<int> insertEquipment(
  Database database, {
  required int customerId,
  required String type,
  String? brand,
  String? model,
  String? serialNumber,
  String? assetTag,
  String? notes,
}) {
  return database.insert('equipment', <String, Object?>{
    'customer_id': customerId,
    'type': type,
    'brand': brand,
    'model': model,
    'serial_number': serialNumber,
    'asset_tag': assetTag,
    'notes': notes,
  });
}

Future<void> insertServiceOrdersForEquipment(
  Database database, {
  required int customerId,
  required int equipmentId,
  required int count,
}) async {
  for (int i = 0; i < count; i++) {
    await database.insert('service_orders', <String, Object?>{
      'number': 'OS-E-${i + 1}',
      'customer_id': customerId,
      'equipment_id': equipmentId,
      'problem_description': 'Não liga',
      'priority': 'Média',
      'status': 'Aberta',
      'opened_at': '2026-09-01',
      'due_date': '2026-09-10',
    });
  }
}

Future<List<Map<String, Object?>>> queryEquipment(WidgetTester tester) async {
  List<Map<String, Object?>> rows = <Map<String, Object?>>[];
  await withDatabase(tester, (database) async {
    rows = await database.query('equipment', orderBy: 'id');
  });
  return rows;
}

Future<EquipmentController> pumpEquipmentModule(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final EquipmentController controller = EquipmentController();
  addTearDown(controller.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<EquipmentController>.value(
            value: controller,
            child: const EquipmentModule(),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return controller;
}

Future<void> selectCustomer(
  WidgetTester tester,
  Key dropdownKey,
  String name,
) async {
  await tapAndPump(tester, find.byKey(dropdownKey));
  await tapAndPump(tester, find.text(name).last);
}
