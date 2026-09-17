import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/service_order_controller.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_orders_module.dart';
import 'package:ordem_de_servico/services/image_file_picker.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../customers/customers_test_support.dart';

export '../customers/customers_test_support.dart'
    show
        TemporaryDatabase,
        withDatabase,
        insertCustomer,
        tapAndWaitForDatabase,
        waitForDatabase,
        tapAndPump,
        expectNoDialogs,
        expectNoTechnicalErrorText;

Future<void> clearServiceOrderData(Database database) async {
  await database.delete('part_items');
  await database.delete('service_orders');
  await database.delete('equipment');
  await database.delete('customers');
  await database.delete('technicians');
}

Future<int> insertEquipmentFor(
  Database database, {
  required int customerId,
  required String type,
}) {
  return database.insert('equipment', <String, Object?>{
    'customer_id': customerId,
    'type': type,
  });
}

Future<int> insertTechnicianNamed(
  Database database, {
  required String name,
  bool active = true,
}) {
  return database.insert('technicians', <String, Object?>{
    'name': name,
    'contact': '83999990000',
    'specialty': 'Refrigeração',
    'active': active ? 1 : 0,
  });
}

Future<int> insertServiceOrder(
  Database database, {
  required String number,
  required int customerId,
  required int equipmentId,
  int? technicianId,
  String problemDescription = 'Não está gelando',
  String priority = 'medium',
  String status = 'open',
  String openedAt = '2026-09-14',
  String dueDate = '2026-09-30',
  String? completedAt,
  String? diagnosis,
  String? solution,
  String? imagePath,
}) {
  return database.insert('service_orders', <String, Object?>{
    'number': number,
    'customer_id': customerId,
    'equipment_id': equipmentId,
    'technician_id': technicianId,
    'problem_description': problemDescription,
    'priority': priority,
    'status': status,
    'opened_at': openedAt,
    'due_date': dueDate,
    'completed_at': completedAt,
    'diagnosis': diagnosis,
    'solution': solution,
    'image_path': imagePath,
  });
}

Future<void> openOrderDetail(WidgetTester tester, String number) async {
  await tapAndWaitForDatabase(tester, find.text(number));
}

Future<List<Map<String, Object?>>> queryServiceOrders(
  WidgetTester tester,
) async {
  List<Map<String, Object?>> rows = <Map<String, Object?>>[];
  await withDatabase(tester, (database) async {
    rows = await database.query('service_orders', orderBy: 'id');
  });
  return rows;
}

Future<ServiceOrderController> pumpServiceOrdersModule(
  WidgetTester tester, {
  ImageFilePicker? pickImage,
}) async {
  tester.view.physicalSize = const Size(1280, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiceOrderController controller = ServiceOrderController();
  addTearDown(controller.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<ServiceOrderController>.value(
            value: controller,
            child: ServiceOrdersModule(pickImage: pickImage ?? pickImageFile),
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

Future<void> searchForTerm(WidgetTester tester, String term) async {
  await tester.enterText(find.byKey(ServiceOrderListView.searchFieldKey), term);
  await tester.pump();
  await waitForDatabase(tester);
}

Future<void> selectFilterOption(
  WidgetTester tester,
  Key selectorKey,
  String label,
) async {
  await tapAndPump(tester, find.byKey(selectorKey));
  await tapAndWaitForDatabase(tester, find.text(label).last);
}

Future<void> selectOption(
  WidgetTester tester,
  Key dropdownKey,
  String label,
) async {
  await tapAndPump(
    tester,
    find.descendant(
      of: find.byKey(dropdownKey),
      matching: find.byType(DropdownButton<int>),
    ),
  );
  await tapAndWaitForDatabase(tester, find.text(label).last);
}

List<String> dropdownLabels(WidgetTester tester, Key dropdownKey) {
  final DropdownButton<int> dropdown = tester.widget<DropdownButton<int>>(
    find.descendant(
      of: find.byKey(dropdownKey),
      matching: find.byType(DropdownButton<int>),
    ),
  );
  return (dropdown.items ?? <DropdownMenuItem<int>>[])
      .map((DropdownMenuItem<int> item) => (item.child as Text).data!)
      .toList();
}

int? dropdownValue(WidgetTester tester, Key dropdownKey) {
  return tester
      .widget<DropdownButton<int>>(
        find.descendant(
          of: find.byKey(dropdownKey),
          matching: find.byType(DropdownButton<int>),
        ),
      )
      .value;
}

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Future<int> insertPartItem(
  Database database, {
  required int serviceOrderId,
  required String description,
  required int quantity,
  required double unitPrice,
}) {
  return database.insert('part_items', <String, Object?>{
    'service_order_id': serviceOrderId,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
  });
}

Future<List<Map<String, Object?>>> queryPartItems(WidgetTester tester) async {
  List<Map<String, Object?>> rows = <Map<String, Object?>>[];
  await withDatabase(tester, (database) async {
    rows = await database.query('part_items', orderBy: 'id');
  });
  return rows;
}

Future<int> partItemIdOf(WidgetTester tester, String description) async {
  final List<Map<String, Object?>> rows = await queryPartItems(tester);
  return rows.firstWhere(
        (Map<String, Object?> row) => row['description'] == description,
      )['id']!
      as int;
}
