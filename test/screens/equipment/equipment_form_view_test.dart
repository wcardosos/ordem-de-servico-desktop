import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_form_view.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'equipment_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_equipment_form_test_');

  Future<Map<String, int>> prepareCustomers(
    WidgetTester tester, {
    bool withCarlos = true,
  }) async {
    final Map<String, int> ids = <String, int>{};
    await withDatabase(tester, (database) async {
      await clearEquipmentData(database);
      ids['Ana Ribeiro'] = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      if (withCarlos) {
        ids['Carlos Menezes'] = await insertCustomer(
          database,
          name: 'Carlos Menezes',
          document: '22233344455',
        );
      }
    });
    return ids;
  }

  Future<void> openNewEquipmentForm(WidgetTester tester) async {
    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentListView.addButtonKey),
    );
    expect(find.byType(EquipmentFormView), findsOneWidget);
    expect(find.byType(EquipmentListView), findsNothing);
    expectNoDialogs();
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
  }

  Future<void> fillAllFields(WidgetTester tester) async {
    await selectCustomer(
      tester,
      EquipmentFormView.customerFieldKey,
      'Ana Ribeiro',
    );
    await tester.enterText(
      find.byKey(EquipmentFormView.typeFieldKey),
      'Ar-condicionado split',
    );
    await tester.enterText(find.byKey(EquipmentFormView.brandFieldKey), 'LG');
    await tester.enterText(
      find.byKey(EquipmentFormView.modelFieldKey),
      'Dual Inverter',
    );
    await tester.enterText(
      find.byKey(EquipmentFormView.serialNumberFieldKey),
      'SN-99120',
    );
    await tester.enterText(
      find.byKey(EquipmentFormView.assetTagFieldKey),
      'PAT-014',
    );
    await tester.enterText(
      find.byKey(EquipmentFormView.notesFieldKey),
      'Instalado na sala de reuniões',
    );
    await tester.pump();
  }

  testWidgets(
    'saves equipment with all fields linked to the selected customer',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareCustomers(tester);
      await pumpEquipmentModule(tester);
      await openNewEquipmentForm(tester);
      expect(find.text('Novo equipamento'), findsOneWidget);

      await fillAllFields(tester);
      await tapAndWaitForDatabase(
        tester,
        find.byKey(EquipmentFormView.saveButtonKey),
      );

      final List<Map<String, Object?>> rows = await queryEquipment(tester);
      expect(rows, hasLength(1));
      expect(rows.single['customer_id'], ids['Ana Ribeiro']);
      expect(rows.single['type'], 'Ar-condicionado split');
      expect(rows.single['brand'], 'LG');
      expect(rows.single['model'], 'Dual Inverter');
      expect(rows.single['serial_number'], 'SN-99120');
      expect(rows.single['asset_tag'], 'PAT-014');
      expect(rows.single['notes'], 'Instalado na sala de reuniões');

      expect(find.byType(EquipmentFormView), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(EquipmentListView.listKey),
          matching: find.text('Ar-condicionado split'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Equipamento salvo com sucesso.'),
        ),
        findsOneWidget,
      );
      expectNoDialogs();
    },
  );

  testWidgets('saves equipment with only required fields and null optionals', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareCustomers(
      tester,
      withCarlos: false,
    );
    await pumpEquipmentModule(tester);
    await openNewEquipmentForm(tester);

    await selectCustomer(
      tester,
      EquipmentFormView.customerFieldKey,
      'Ana Ribeiro',
    );
    await tester.enterText(
      find.byKey(EquipmentFormView.typeFieldKey),
      'Bebedouro industrial',
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentFormView.saveButtonKey),
    );

    final List<Map<String, Object?>> rows = await queryEquipment(tester);
    expect(rows, hasLength(1));
    expect(rows.single['customer_id'], ids['Ana Ribeiro']);
    expect(rows.single['type'], 'Bebedouro industrial');
    for (final String column in <String>[
      'brand',
      'model',
      'serial_number',
      'asset_tag',
      'notes',
    ]) {
      expect(rows.single[column], isNull, reason: column);
    }
    expect(find.byType(EquipmentFormView), findsNothing);
    expect(find.text('Equipamento salvo com sucesso.'), findsOneWidget);
  });

  testWidgets(
    'editing equipment moves it to another customer without duplicating',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareCustomers(tester);
      int notebookId = 0;
      await withDatabase(tester, (database) async {
        notebookId = await insertEquipment(
          database,
          customerId: ids['Carlos Menezes']!,
          type: 'Notebook',
          brand: 'Dell',
        );
      });
      await pumpEquipmentModule(tester);

      await tapAndWaitForDatabase(
        tester,
        find.byKey(EquipmentListView.editButtonKey(notebookId)),
      );
      expect(find.byType(EquipmentFormView), findsOneWidget);
      expect(find.text('Editar equipamento'), findsOneWidget);
      expect(fieldText(tester, EquipmentFormView.typeFieldKey), 'Notebook');
      expect(fieldText(tester, EquipmentFormView.brandFieldKey), 'Dell');
      expect(
        find.descendant(
          of: find.byKey(EquipmentFormView.customerFieldKey),
          matching: find.text('Carlos Menezes'),
        ),
        findsOneWidget,
      );

      await selectCustomer(
        tester,
        EquipmentFormView.customerFieldKey,
        'Ana Ribeiro',
      );
      await tapAndWaitForDatabase(
        tester,
        find.byKey(EquipmentFormView.saveButtonKey),
      );

      final List<Map<String, Object?>> rows = await queryEquipment(tester);
      expect(rows, hasLength(1));
      expect(rows.single['id'], notebookId);
      expect(rows.single['type'], 'Notebook');
      expect(rows.single['customer_id'], ids['Ana Ribeiro']);
      expect(find.byType(EquipmentFormView), findsNothing);
      final ListTile tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Notebook'),
      );
      expect((tile.subtitle! as Text).data, contains('Ana Ribeiro'));
    },
  );

  const List<(String, Key, String)> requiredExamples = <(String, Key, String)>[
    ('cliente', EquipmentFormView.customerFieldKey, 'Selecione o cliente.'),
    ('tipo', EquipmentFormView.typeFieldKey, 'Informe o tipo.'),
  ];

  for (final (String field, Key key, String message) in requiredExamples) {
    testWidgets('empty "$field" shows "$message" and saves nothing', (
      WidgetTester tester,
    ) async {
      await prepareCustomers(tester);
      await pumpEquipmentModule(tester);
      await openNewEquipmentForm(tester);

      if (field != 'cliente') {
        await selectCustomer(
          tester,
          EquipmentFormView.customerFieldKey,
          'Ana Ribeiro',
        );
      }
      if (field != 'tipo') {
        await tester.enterText(
          find.byKey(EquipmentFormView.typeFieldKey),
          'Notebook',
        );
      }
      await tapAndWaitForDatabase(
        tester,
        find.byKey(EquipmentFormView.saveButtonKey),
      );

      expect(
        find.descendant(of: find.byKey(key), matching: find.text(message)),
        findsOneWidget,
      );
      expect(find.byType(EquipmentFormView), findsOneWidget);
      expect(await queryEquipment(tester), isEmpty);
    });
  }

  testWidgets('does not open the form when no customer exists', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, clearEquipmentData);
    await pumpEquipmentModule(tester);

    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentListView.addButtonKey),
    );

    expect(find.byType(EquipmentFormView), findsNothing);
    expect(find.byType(EquipmentListView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Cadastre um cliente antes de cadastrar equipamentos.',
        ),
      ),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets('keeps the form open with typed data when saving fails', (
    WidgetTester tester,
  ) async {
    await prepareCustomers(tester);
    await pumpEquipmentModule(tester);
    await openNewEquipmentForm(tester);
    await fillAllFields(tester);

    final String blockedPath = temporaryDatabase.blockedDirectory().path;
    await tester.runAsync(() => DatabaseHelper.instance.close());
    DatabaseHelper.databaseDirectoryOverride = blockedPath;

    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentFormView.saveButtonKey),
    );

    expect(
      find.text('Não foi possível salvar o equipamento. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(EquipmentFormView), findsOneWidget);
    expect(
      fieldText(tester, EquipmentFormView.typeFieldKey),
      'Ar-condicionado split',
    );
    expect(fieldText(tester, EquipmentFormView.brandFieldKey), 'LG');
    expect(fieldText(tester, EquipmentFormView.modelFieldKey), 'Dual Inverter');
    expect(
      fieldText(tester, EquipmentFormView.serialNumberFieldKey),
      'SN-99120',
    );
    expect(fieldText(tester, EquipmentFormView.assetTagFieldKey), 'PAT-014');
    expect(
      fieldText(tester, EquipmentFormView.notesFieldKey),
      'Instalado na sala de reuniões',
    );
    expect(
      find.descendant(
        of: find.byKey(EquipmentFormView.customerFieldKey),
        matching: find.text('Ana Ribeiro'),
      ),
      findsOneWidget,
    );
    expect(find.text('Equipamento salvo com sucesso.'), findsNothing);
    expectNoTechnicalErrorText();
    expectNoDialogs();

    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase.directory.path;
    expect(await queryEquipment(tester), isEmpty);
  });
}
