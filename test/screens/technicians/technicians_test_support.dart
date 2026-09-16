import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/technician_controller.dart';
import 'package:ordem_de_servico/screens/technicians/technicians_module.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

export '../customers/customers_test_support.dart'
    show
        TemporaryDatabase,
        withDatabase,
        tapAndWaitForDatabase,
        tapAndPump,
        expectNoDialogs,
        expectNoTechnicalErrorText;

Future<int> insertTechnician(
  Database database, {
  required String name,
  String contact = '83999990000',
  String specialty = 'Informática',
  bool active = true,
}) {
  return database.insert('technicians', <String, Object?>{
    'name': name,
    'contact': contact,
    'specialty': specialty,
    'active': active ? 1 : 0,
  });
}

Future<List<int>> insertServiceOrdersForTechnician(
  Database database, {
  required int technicianId,
  required int count,
  String numberPrefix = 'OS-T',
}) async {
  final int customerId = await database.insert('customers', <String, Object?>{
    'name': 'Cliente Vínculo $numberPrefix',
    'document': '11122233344',
    'phone': '11900000000',
    'email': 'vinculo@example.com',
    'address': 'Rua Exemplo, 100',
  });
  final int equipmentId = await database.insert('equipment', <String, Object?>{
    'customer_id': customerId,
    'type': 'Notebook',
  });
  final List<int> ids = <int>[];
  for (int i = 0; i < count; i++) {
    ids.add(
      await database.insert('service_orders', <String, Object?>{
        'number': '$numberPrefix-${i + 1}',
        'customer_id': customerId,
        'equipment_id': equipmentId,
        'technician_id': technicianId,
        'problem_description': 'Não liga',
        'priority': 'Média',
        'status': 'Aberta',
        'opened_at': '2026-09-01',
        'due_date': '2026-09-10',
      }),
    );
  }
  return ids;
}

Future<TechnicianController> pumpTechniciansModule(WidgetTester tester) async {
  final TechnicianController controller = TechnicianController();
  addTearDown(controller.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<TechnicianController>.value(
            value: controller,
            child: const TechniciansModule(),
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
