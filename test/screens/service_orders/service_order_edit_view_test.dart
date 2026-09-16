import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_detail_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_edit_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'service_orders_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_order_edit_test_');

  Future<Map<String, int>> seed(WidgetTester tester) async {
    final Map<String, int> ids = <String, int>{};
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
      ids['Rafael Duarte'] = await insertTechnicianNamed(
        database,
        name: 'Rafael Duarte',
      );
      ids['Sérgio Lima'] = await insertTechnicianNamed(
        database,
        name: 'Sérgio Lima',
        active: false,
      );
      ids['OS-2026-0001'] = await insertServiceOrder(
        database,
        number: 'OS-2026-0001',
        customerId: customerId,
        equipmentId: equipmentId,
        technicianId: ids['Rafael Duarte'],
        priority: 'high',
      );
    });
    return ids;
  }

  Future<void> openEditForm(WidgetTester tester) async {
    await pumpServiceOrdersModule(tester);
    await openOrderDetail(tester, 'OS-2026-0001');
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderDetailView.editButtonKey),
    );
    expect(find.byType(ServiceOrderEditView), findsOneWidget);
    expect(find.byType(ServiceOrderDetailView), findsNothing);
    expectNoDialogs();
  }

  Future<void> selectPriority(WidgetTester tester, String label) async {
    await tapAndPump(tester, find.byKey(ServiceOrderEditView.priorityFieldKey));
    await tapAndPump(tester, find.text(label).last);
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
  }

  Finder textUnder(Key key, String text) {
    return find.descendant(of: find.byKey(key), matching: find.text(text));
  }

  testWidgets('saves priority and diagnosis and the list reflects them', (
    WidgetTester tester,
  ) async {
    await seed(tester);
    await openEditForm(tester);

    await selectPriority(tester, 'Urgente');
    await tester.enterText(
      find.byKey(ServiceOrderEditView.diagnosisFieldKey),
      'Compressor com falha de partida',
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderEditView.saveButtonKey),
    );

    final Map<String, Object?> row = (await queryServiceOrders(tester)).single;
    expect(row['priority'], 'urgent');
    expect(row['diagnosis'], 'Compressor com falha de partida');
    expect(row['number'], 'OS-2026-0001');
    expect(row['opened_at'], '2026-09-14');
    expect(find.byType(ServiceOrderEditView), findsNothing);
    expect(find.byType(ServiceOrderListView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ServiceOrderListView.itemKey('OS-2026-0001')),
        matching: find.widgetWithText(Chip, 'Urgente'),
      ),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets('number, customer, equipment and opening date are not editable', (
    WidgetTester tester,
  ) async {
    await seed(tester);
    await openEditForm(tester);

    const List<(Key, String)> immutableFields = <(Key, String)>[
      (ServiceOrderEditView.numberFieldKey, 'OS-2026-0001'),
      (ServiceOrderEditView.customerFieldKey, 'Ana Ribeiro'),
      (ServiceOrderEditView.equipmentFieldKey, 'Ar-condicionado split'),
      (ServiceOrderEditView.openedAtFieldKey, '14/09/2026'),
    ];
    for (final (Key key, String value) in immutableFields) {
      expect(fieldText(tester, key), value);
      final TextField textField = tester.widget<TextField>(
        find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      );
      expect(textField.readOnly, isTrue);
      expect(textField.enabled, isFalse);
    }
    for (final Key key in <Key>[
      ServiceOrderEditView.problemFieldKey,
      ServiceOrderEditView.diagnosisFieldKey,
      ServiceOrderEditView.solutionFieldKey,
    ]) {
      final TextField textField = tester.widget<TextField>(
        find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      );
      expect(textField.readOnly, isFalse);
    }
  });

  testWidgets('technician selector offers active technicians only', (
    WidgetTester tester,
  ) async {
    await seed(tester);
    await openEditForm(tester);

    final List<String> labels = dropdownLabels(
      tester,
      ServiceOrderEditView.technicianFieldKey,
    );
    expect(labels, contains('Rafael Duarte'));
    expect(
      labels.where((String label) => label.contains('Sérgio Lima')),
      isEmpty,
    );
    expect(
      textUnder(ServiceOrderEditView.technicianFieldKey, 'Rafael Duarte'),
      findsOneWidget,
    );
  });

  testWidgets('keeps an inactive assigned technician visible and saved', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await seed(tester);
    await withDatabase(tester, (database) async {
      await database.update(
        'service_orders',
        <String, Object?>{'technician_id': ids['Sérgio Lima']},
        where: 'id = ?',
        whereArgs: <Object?>[ids['OS-2026-0001']],
      );
    });
    await openEditForm(tester);

    expect(
      textUnder(
        ServiceOrderEditView.technicianFieldKey,
        'Sérgio Lima (inativo)',
      ),
      findsOneWidget,
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderEditView.saveButtonKey),
    );

    final Map<String, Object?> row = (await queryServiceOrders(tester)).single;
    expect(row['technician_id'], ids['Sérgio Lima']);
  });

  testWidgets('keeps the form open with typed data when saving fails', (
    WidgetTester tester,
  ) async {
    await seed(tester);
    await openEditForm(tester);
    await selectPriority(tester, 'Urgente');
    await tester.enterText(
      find.byKey(ServiceOrderEditView.diagnosisFieldKey),
      'Compressor com falha de partida',
    );
    await tester.pump();

    final String blockedPath = temporaryDatabase.blockedDirectory().path;
    await tester.runAsync(() => DatabaseHelper.instance.close());
    DatabaseHelper.databaseDirectoryOverride = blockedPath;

    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderEditView.saveButtonKey),
    );

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Não foi possível salvar as alterações. Tente novamente.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(ServiceOrderEditView), findsOneWidget);
    expect(
      textUnder(ServiceOrderEditView.priorityFieldKey, 'Urgente'),
      findsOneWidget,
    );
    expect(
      fieldText(tester, ServiceOrderEditView.diagnosisFieldKey),
      'Compressor com falha de partida',
    );
    expectNoTechnicalErrorText();
    expectNoDialogs();

    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase.directory.path;
    final Map<String, Object?> row = (await queryServiceOrders(tester)).single;
    expect(row['priority'], 'high');
    expect(row['diagnosis'], isNull);
  });
}
