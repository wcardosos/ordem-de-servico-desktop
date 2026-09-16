import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/models/service_order.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_form_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'service_orders_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_order_form_test_');

  Future<Map<String, int>> prepareData(WidgetTester tester) async {
    final Map<String, int> ids = <String, int>{};
    await withDatabase(tester, (database) async {
      await clearServiceOrderData(database);
      final int ana = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      final int carlos = await insertCustomer(
        database,
        name: 'Carlos Menezes',
        document: '22233344455',
      );
      ids['Ana Ribeiro'] = ana;
      ids['Carlos Menezes'] = carlos;
      ids['Ar-condicionado split'] = await insertEquipmentFor(
        database,
        customerId: ana,
        type: 'Ar-condicionado split',
      );
      ids['Bebedouro industrial'] = await insertEquipmentFor(
        database,
        customerId: ana,
        type: 'Bebedouro industrial',
      );
      ids['Notebook'] = await insertEquipmentFor(
        database,
        customerId: carlos,
        type: 'Notebook',
      );
      ids['Bruno Alencar'] = await insertTechnicianNamed(
        database,
        name: 'Bruno Alencar',
      );
      ids['Rafael Duarte'] = await insertTechnicianNamed(
        database,
        name: 'Rafael Duarte',
      );
      ids['Sérgio Lima'] = await insertTechnicianNamed(
        database,
        name: 'Sérgio Lima',
        active: false,
      );
    });
    return ids;
  }

  Future<void> openNewOrderForm(WidgetTester tester) async {
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderListView.addButtonKey),
    );
    expect(find.byType(ServiceOrderFormView), findsOneWidget);
    expect(find.byType(ServiceOrderListView), findsNothing);
    expectNoDialogs();
  }

  Future<void> selectPriority(WidgetTester tester, String label) async {
    await tapAndPump(tester, find.byKey(ServiceOrderFormView.priorityFieldKey));
    await tapAndPump(tester, find.text(label).last);
  }

  Future<void> pickDueDate(WidgetTester tester, String usFormattedDate) async {
    await tapAndPump(tester, find.byKey(ServiceOrderFormView.dueDateFieldKey));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tapAndPump(tester, find.byIcon(Icons.edit_outlined));
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      usFormattedDate,
    );
    await tapAndPump(tester, find.text('OK'));
    expect(find.byType(DatePickerDialog), findsNothing);
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
  }

  Finder textUnder(Key key, String text) {
    return find.descendant(of: find.byKey(key), matching: find.text(text));
  }

  Future<void> fillRequiredFields(
    WidgetTester tester, {
    String? skip,
    String dueDate = '09/30/2026',
  }) async {
    if (skip != 'cliente') {
      await selectOption(
        tester,
        ServiceOrderFormView.customerFieldKey,
        'Ana Ribeiro',
      );
      if (skip != 'equipamento') {
        await selectOption(
          tester,
          ServiceOrderFormView.equipmentFieldKey,
          'Ar-condicionado split',
        );
      }
    }
    if (skip != 'problema') {
      await tester.enterText(
        find.byKey(ServiceOrderFormView.problemFieldKey),
        'Não está gelando',
      );
    }
    if (skip != 'data limite') {
      await pickDueDate(tester, dueDate);
    }
    await tester.pump();
  }

  testWidgets(
    'opens an order with all fields as open, dated today, and announces its number',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareData(tester);
      await pumpServiceOrdersModule(tester);
      await openNewOrderForm(tester);

      await selectOption(
        tester,
        ServiceOrderFormView.customerFieldKey,
        'Ana Ribeiro',
      );
      await selectOption(
        tester,
        ServiceOrderFormView.equipmentFieldKey,
        'Ar-condicionado split',
      );
      await tester.enterText(
        find.byKey(ServiceOrderFormView.problemFieldKey),
        'Não está gelando',
      );
      await selectPriority(tester, 'Alta');
      await pickDueDate(tester, '09/30/2026');
      expect(
        fieldText(tester, ServiceOrderFormView.dueDateFieldKey),
        '30/09/2026',
      );
      await selectOption(
        tester,
        ServiceOrderFormView.technicianFieldKey,
        'Rafael Duarte',
      );
      expect(find.text('Abrir OS'), findsOneWidget);
      await tapAndWaitForDatabase(
        tester,
        find.byKey(ServiceOrderFormView.submitButtonKey),
      );

      final List<Map<String, Object?>> rows = await queryServiceOrders(tester);
      expect(rows, hasLength(1));
      final Map<String, Object?> row = rows.single;
      final int year = DateTime.now().year;
      expect(row['number'], 'OS-$year-0001');
      expect(row['status'], 'open');
      expect(row['opened_at'], isoDate(DateTime.now()));
      expect(row['customer_id'], ids['Ana Ribeiro']);
      expect(row['equipment_id'], ids['Ar-condicionado split']);
      expect(row['technician_id'], ids['Rafael Duarte']);
      expect(row['problem_description'], 'Não está gelando');
      expect(row['priority'], 'high');
      expect(row['due_date'], '2026-09-30');
      expect(row['labor_cost'], 0);

      expect(find.byType(ServiceOrderFormView), findsNothing);
      expect(find.byType(ServiceOrderListView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Ordem de serviço OS-$year-0001 aberta.'),
        ),
        findsOneWidget,
      );
      expectNoDialogs();
    },
  );

  testWidgets('opens an order without a responsible technician', (
    WidgetTester tester,
  ) async {
    await prepareData(tester);
    await pumpServiceOrdersModule(tester);
    await openNewOrderForm(tester);

    await fillRequiredFields(tester);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderFormView.submitButtonKey),
    );

    final List<Map<String, Object?>> rows = await queryServiceOrders(tester);
    expect(rows, hasLength(1));
    expect(rows.single['status'], 'open');
    expect(rows.single['technician_id'], isNull);
    expect(rows.single['priority'], 'medium');
    expect(find.byType(ServiceOrderFormView), findsNothing);
  });

  testWidgets(
    'equipment selector offers only the selected customer equipment',
    (WidgetTester tester) async {
      await prepareData(tester);
      await pumpServiceOrdersModule(tester);
      await openNewOrderForm(tester);

      await selectOption(
        tester,
        ServiceOrderFormView.customerFieldKey,
        'Ana Ribeiro',
      );

      final List<String> labels = dropdownLabels(
        tester,
        ServiceOrderFormView.equipmentFieldKey,
      );
      expect(
        labels,
        unorderedEquals(<String>[
          'Ar-condicionado split',
          'Bebedouro industrial',
        ]),
      );
      expect(labels, isNot(contains('Notebook')));
    },
  );

  testWidgets('changing the customer clears the selected equipment', (
    WidgetTester tester,
  ) async {
    await prepareData(tester);
    await pumpServiceOrdersModule(tester);
    await openNewOrderForm(tester);
    await selectOption(
      tester,
      ServiceOrderFormView.customerFieldKey,
      'Ana Ribeiro',
    );
    await selectOption(
      tester,
      ServiceOrderFormView.equipmentFieldKey,
      'Ar-condicionado split',
    );
    expect(
      dropdownValue(tester, ServiceOrderFormView.equipmentFieldKey),
      isNotNull,
    );

    await selectOption(
      tester,
      ServiceOrderFormView.customerFieldKey,
      'Carlos Menezes',
    );

    expect(
      dropdownValue(tester, ServiceOrderFormView.equipmentFieldKey),
      isNull,
    );
    expect(
      textUnder(
        ServiceOrderFormView.equipmentFieldKey,
        'Ar-condicionado split',
      ),
      findsNothing,
    );
    expect(
      dropdownLabels(tester, ServiceOrderFormView.equipmentFieldKey),
      <String>['Notebook'],
    );
  });

  testWidgets('technician selector omits inactive technicians', (
    WidgetTester tester,
  ) async {
    await prepareData(tester);
    await pumpServiceOrdersModule(tester);

    await openNewOrderForm(tester);

    final List<String> labels = dropdownLabels(
      tester,
      ServiceOrderFormView.technicianFieldKey,
    );
    expect(labels, containsAll(<String>['Bruno Alencar', 'Rafael Duarte']));
    expect(labels, isNot(contains('Sérgio Lima')));
  });

  testWidgets('priority defaults to Média', (WidgetTester tester) async {
    await prepareData(tester);
    await pumpServiceOrdersModule(tester);

    await openNewOrderForm(tester);

    expect(
      textUnder(ServiceOrderFormView.priorityFieldKey, 'Média'),
      findsOneWidget,
    );
  });

  const List<(String, Key, String)> requiredExamples = <(String, Key, String)>[
    ('cliente', ServiceOrderFormView.customerFieldKey, 'Selecione o cliente.'),
    (
      'equipamento',
      ServiceOrderFormView.equipmentFieldKey,
      'Selecione o equipamento.',
    ),
    ('problema', ServiceOrderFormView.problemFieldKey, 'Descreva o problema.'),
    (
      'data limite',
      ServiceOrderFormView.dueDateFieldKey,
      'Informe a data limite.',
    ),
  ];

  for (final (String field, Key key, String message) in requiredExamples) {
    testWidgets('empty "$field" shows "$message" and saves nothing', (
      WidgetTester tester,
    ) async {
      await prepareData(tester);
      await pumpServiceOrdersModule(tester);
      await openNewOrderForm(tester);

      await fillRequiredFields(tester, skip: field);
      await tapAndWaitForDatabase(
        tester,
        find.byKey(ServiceOrderFormView.submitButtonKey),
      );

      expect(textUnder(key, message), findsOneWidget);
      expect(find.byType(ServiceOrderFormView), findsOneWidget);
      expect(await queryServiceOrders(tester), isEmpty);
    });
  }

  testWidgets('opens an order with a past due date and it is overdue', (
    WidgetTester tester,
  ) async {
    await prepareData(tester);
    await pumpServiceOrdersModule(tester);
    await openNewOrderForm(tester);

    await fillRequiredFields(tester, dueDate: '09/01/2026');
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderFormView.submitButtonKey),
    );

    final List<Map<String, Object?>> rows = await queryServiceOrders(tester);
    expect(rows, hasLength(1));
    expect(rows.single['due_date'], '2026-09-01');
    expect(ServiceOrder.fromMap(rows.single).isOverdue, isTrue);
    expect(find.byType(ServiceOrderFormView), findsNothing);
  });

  testWidgets('does not open the form when no equipment exists', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await clearServiceOrderData(database);
      await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
    });
    await pumpServiceOrdersModule(tester);

    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderListView.addButtonKey),
    );

    expect(find.byType(ServiceOrderFormView), findsNothing);
    expect(find.byType(ServiceOrderListView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Cadastre um cliente e um equipamento antes de abrir uma ordem de serviço.',
        ),
      ),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets('keeps the form open with typed data when saving fails', (
    WidgetTester tester,
  ) async {
    await prepareData(tester);
    await pumpServiceOrdersModule(tester);
    await openNewOrderForm(tester);
    await fillRequiredFields(tester);

    final String blockedPath = temporaryDatabase.blockedDirectory().path;
    await tester.runAsync(() => DatabaseHelper.instance.close());
    DatabaseHelper.databaseDirectoryOverride = blockedPath;

    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderFormView.submitButtonKey),
    );

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Não foi possível abrir a ordem de serviço. Tente novamente.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(ServiceOrderFormView), findsOneWidget);
    expect(
      textUnder(ServiceOrderFormView.customerFieldKey, 'Ana Ribeiro'),
      findsOneWidget,
    );
    expect(
      textUnder(
        ServiceOrderFormView.equipmentFieldKey,
        'Ar-condicionado split',
      ),
      findsOneWidget,
    );
    expect(
      fieldText(tester, ServiceOrderFormView.problemFieldKey),
      'Não está gelando',
    );
    expect(
      fieldText(tester, ServiceOrderFormView.dueDateFieldKey),
      '30/09/2026',
    );
    expectNoTechnicalErrorText();
    expectNoDialogs();

    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase.directory.path;
    expect(await queryServiceOrders(tester), isEmpty);
  });
}
