import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'service_orders_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_order_list_test_');

  Future<void> insertOrder(
    Database database, {
    required String number,
    required int customerId,
    required int equipmentId,
    String status = 'open',
    String priority = 'medium',
    required String dueDate,
  }) async {
    await database.insert('service_orders', <String, Object?>{
      'number': number,
      'customer_id': customerId,
      'equipment_id': equipmentId,
      'problem_description': 'Não está gelando',
      'priority': priority,
      'status': status,
      'opened_at': '2026-08-20',
      'due_date': dueDate,
    });
  }

  Future<void> seedOrders(
    WidgetTester tester,
    List<Map<String, String>> orders,
  ) async {
    await withDatabase(tester, (database) async {
      await clearServiceOrderData(database);
      final int customerId = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      final int equipmentId = await insertEquipmentFor(
        database,
        customerId: customerId,
        type: 'Ar-condicionado split',
      );
      for (final Map<String, String> order in orders) {
        await insertOrder(
          database,
          number: order['number']!,
          customerId: customerId,
          equipmentId: equipmentId,
          status: order['status'] ?? 'open',
          priority: order['priority'] ?? 'medium',
          dueDate: order['dueDate']!,
        );
      }
    });
  }

  Finder inItem(String number, Finder matching) {
    return find.descendant(
      of: find.byKey(ServiceOrderListView.itemKey(number)),
      matching: matching,
    );
  }

  testWidgets(
    'shows number, customer, equipment, status, priority and due date',
    (WidgetTester tester) async {
      await seedOrders(tester, <Map<String, String>>[
        <String, String>{
          'number': 'OS-2026-0001',
          'status': 'open',
          'priority': 'high',
          'dueDate': '2026-09-30',
        },
      ]);

      await pumpServiceOrdersModule(tester);

      expect(find.byKey(ServiceOrderListView.listKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ServiceOrderListView.listKey),
          matching: find.byType(Card),
        ),
        findsOneWidget,
      );
      expect(inItem('OS-2026-0001', find.text('OS-2026-0001')), findsOneWidget);
      expect(inItem('OS-2026-0001', find.text('Ana Ribeiro')), findsOneWidget);
      expect(
        inItem('OS-2026-0001', find.text('Ar-condicionado split')),
        findsOneWidget,
      );
      expect(
        inItem('OS-2026-0001', find.widgetWithText(Chip, 'Aberta')),
        findsOneWidget,
      );
      expect(
        inItem('OS-2026-0001', find.widgetWithText(Chip, 'Alta')),
        findsOneWidget,
      );
      expect(
        inItem('OS-2026-0001', find.textContaining('30/09/2026')),
        findsOneWidget,
      );
      expect(inItem('OS-2026-0001', find.text('Atrasada')), findsNothing);
      expectNoDialogs();
    },
  );

  testWidgets('marks an in-progress order past its due date as overdue', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester, <Map<String, String>>[
      <String, String>{
        'number': 'OS-2026-0002',
        'status': 'inProgress',
        'dueDate': '2026-09-01',
      },
    ]);

    await pumpServiceOrdersModule(tester);

    expect(inItem('OS-2026-0002', find.text('Atrasada')), findsOneWidget);
    expect(
      inItem('OS-2026-0002', find.byKey(ServiceOrderListView.overdueMarkerKey)),
      findsOneWidget,
    );
    expect(
      inItem('OS-2026-0002', find.byIcon(ServiceOrderListView.overdueIcon)),
      findsOneWidget,
    );
  });

  testWidgets('does not mark a completed order past its due date as overdue', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester, <Map<String, String>>[
      <String, String>{
        'number': 'OS-2026-0003',
        'status': 'completed',
        'dueDate': '2026-09-01',
      },
    ]);

    await pumpServiceOrdersModule(tester);

    expect(inItem('OS-2026-0003', find.text('Concluída')), findsOneWidget);
    expect(inItem('OS-2026-0003', find.text('Atrasada')), findsNothing);
    expect(find.byKey(ServiceOrderListView.overdueMarkerKey), findsNothing);
  });

  testWidgets('marks an urgent order with a highlight other priorities lack', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester, <Map<String, String>>[
      <String, String>{
        'number': 'OS-2026-0004',
        'priority': 'urgent',
        'dueDate': '2026-12-01',
      },
      <String, String>{
        'number': 'OS-2026-0005',
        'priority': 'high',
        'dueDate': '2026-12-02',
      },
    ]);

    await pumpServiceOrdersModule(tester);

    expect(
      inItem('OS-2026-0004', find.widgetWithText(Chip, 'Urgente')),
      findsOneWidget,
    );
    expect(
      inItem('OS-2026-0004', find.byIcon(ServiceOrderListView.urgentIcon)),
      findsOneWidget,
    );
    expect(
      inItem('OS-2026-0005', find.byIcon(ServiceOrderListView.urgentIcon)),
      findsNothing,
    );
    final Chip urgentChip = tester.widget<Chip>(
      inItem('OS-2026-0004', find.widgetWithText(Chip, 'Urgente')),
    );
    final Chip highChip = tester.widget<Chip>(
      inItem('OS-2026-0005', find.widgetWithText(Chip, 'Alta')),
    );
    expect(urgentChip.backgroundColor, isNotNull);
    expect(urgentChip.backgroundColor, isNot(highChip.backgroundColor));
  });

  testWidgets('orders are displayed by ascending due date', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester, <Map<String, String>>[
      <String, String>{'number': 'OS-2026-0001', 'dueDate': '2026-09-30'},
      <String, String>{'number': 'OS-2026-0002', 'dueDate': '2026-09-01'},
      <String, String>{'number': 'OS-2026-0003', 'dueDate': '2026-09-15'},
    ]);

    await pumpServiceOrdersModule(tester);

    final List<double> positions = <String>[
      'OS-2026-0002',
      'OS-2026-0003',
      'OS-2026-0001',
    ].map((String number) => tester.getTopLeft(find.text(number)).dy).toList();
    expect(positions[0], lessThan(positions[1]));
    expect(positions[1], lessThan(positions[2]));
  });

  testWidgets('shows the empty state when no service order exists', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, clearServiceOrderData);

    await pumpServiceOrdersModule(tester);

    expect(find.text('Nenhuma ordem de serviço cadastrada.'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.byKey(ServiceOrderListView.addButtonKey), findsOneWidget);
  });

  testWidgets(
    'shows a friendly message and retry button when the database is unreadable',
    (WidgetTester tester) async {
      DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
          .blockedDirectory()
          .path;

      await pumpServiceOrdersModule(tester);

      expect(
        find.text('Não foi possível carregar as ordens de serviço.'),
        findsOneWidget,
      );
      expect(find.byKey(ServiceOrderListView.retryButtonKey), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expectNoTechnicalErrorText();
      expectNoDialogs();
    },
  );

  testWidgets('retry reloads the list once the database is reachable', (
    WidgetTester tester,
  ) async {
    final String workingDirectory = temporaryDatabase.directory.path;
    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
        .blockedDirectory()
        .path;

    await pumpServiceOrdersModule(tester);
    expect(find.byKey(ServiceOrderListView.retryButtonKey), findsOneWidget);

    await tester.runAsync(DatabaseHelper.instance.close);
    DatabaseHelper.databaseDirectoryOverride = workingDirectory;
    await seedOrders(tester, <Map<String, String>>[
      <String, String>{'number': 'OS-2026-0001', 'dueDate': '2026-09-30'},
    ]);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderListView.retryButtonKey),
    );

    expect(find.text('OS-2026-0001'), findsOneWidget);
    expect(find.byKey(ServiceOrderListView.retryButtonKey), findsNothing);
  });
}
