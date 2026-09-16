import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/customer_controller.dart';
import 'package:ordem_de_servico/screens/customers/customers_module.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TemporaryDatabase {
  late Directory directory;

  void register(String prefix) {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      directory = Directory.systemTemp.createTempSync(prefix);
      DatabaseHelper.databaseDirectoryOverride = directory.path;
    });

    tearDown(() async {
      try {
        await DatabaseHelper.instance.close();
      } finally {
        DatabaseHelper.databaseDirectoryOverride = null;
        if (directory.existsSync()) {
          Process.runSync('chmod', <String>['-R', '700', directory.path]);
          directory.deleteSync(recursive: true);
        }
      }
    });
  }

  Directory blockedDirectory() {
    final Directory blocked = Directory(p.join(directory.path, 'blocked'))
      ..createSync();
    final ProcessResult chmod = Process.runSync('chmod', <String>[
      '555',
      blocked.path,
    ]);
    expect(chmod.exitCode, 0);
    return blocked;
  }
}

Future<void> withDatabase(
  WidgetTester tester,
  Future<void> Function(Database database) action,
) async {
  await tester.runAsync(() async {
    await action(await DatabaseHelper.instance.database);
  });
}

Future<int> insertCustomer(
  Database database, {
  required String name,
  required String document,
  String phone = '11900000000',
  String email = 'contato@example.com',
  String address = 'Rua Exemplo, 100',
}) {
  return database.insert('customers', <String, Object?>{
    'name': name,
    'document': document,
    'phone': phone,
    'email': email,
    'address': address,
  });
}

Future<CustomerController> pumpCustomersModule(WidgetTester tester) async {
  final CustomerController controller = CustomerController();
  addTearDown(controller.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<CustomerController>.value(
            value: controller,
            child: const CustomersModule(),
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

Future<void> tapAndWaitForDatabase(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump();
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapAndPump(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void expectNoDialogs() {
  expect(find.byType(Dialog), findsNothing);
  expect(find.byType(AlertDialog), findsNothing);
  expect(find.byType(BottomSheet), findsNothing);
}

void expectNoTechnicalErrorText() {
  expect(find.textContaining('Exception'), findsNothing);
  expect(find.textContaining('sqlite'), findsNothing);
  expect(find.textContaining('#0'), findsNothing);
}
