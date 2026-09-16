import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/technician_controller.dart';
import 'package:ordem_de_servico/screens/technicians/technician_form_view.dart';
import 'package:ordem_de_servico/screens/technicians/technician_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'technicians_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_technician_form_test_');

  const String validName = 'Rafael Duarte';
  const String validContact = '(83) 99777-2211';
  const String storedContact = '83997772211';
  const String validSpecialty = 'Refrigeração';

  Future<int> countTechnicians(WidgetTester tester) async {
    int count = -1;
    await withDatabase(tester, (database) async {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        'SELECT COUNT(*) AS total FROM technicians',
      );
      count = rows.first['total']! as int;
    });
    return count;
  }

  Future<void> fillValidData(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(TechnicianFormView.nameFieldKey),
      validName,
    );
    await tester.enterText(
      find.byKey(TechnicianFormView.contactFieldKey),
      validContact,
    );
    await tester.enterText(
      find.byKey(TechnicianFormView.specialtyFieldKey),
      validSpecialty,
    );
  }

  Future<void> openNewTechnicianForm(WidgetTester tester) async {
    await tapAndPump(tester, find.byKey(TechnicianListView.addButtonKey));
    expect(find.byType(TechnicianFormView), findsOneWidget);
    expect(find.byType(TechnicianListView), findsNothing);
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
  }

  bool activeSwitchValue(WidgetTester tester) {
    return tester
        .widget<SwitchListTile>(find.byKey(TechnicianFormView.activeSwitchKey))
        .value;
  }

  testWidgets('saves a new technician as active and returns to the list', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('service_orders');
      await database.delete('technicians');
    });
    await pumpTechniciansModule(tester);

    await openNewTechnicianForm(tester);
    expect(find.text('Novo técnico'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(TechnicianFormView.activeSwitchKey),
        matching: find.text('Ativo'),
      ),
      findsOneWidget,
    );
    expect(activeSwitchValue(tester), isTrue);

    await fillValidData(tester);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(TechnicianFormView.saveButtonKey),
    );

    List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    await withDatabase(tester, (database) async {
      rows = await database.query('technicians');
    });
    expect(rows, hasLength(1));
    expect(rows.single['name'], validName);
    expect(rows.single['contact'], storedContact);
    expect(rows.single['specialty'], validSpecialty);
    expect(rows.single['active'], 1);

    expect(find.byType(TechnicianFormView), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(TechnicianListView.listKey),
        matching: find.text(validName),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Técnico salvo com sucesso.'),
      ),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets(
    'inactivating a technician keeps its linked service orders unchanged',
    (WidgetTester tester) async {
      int sergioId = 0;
      List<Map<String, Object?>> ordersBefore = <Map<String, Object?>>[];
      await withDatabase(tester, (database) async {
        await database.delete('service_orders');
        await database.delete('technicians');
        sergioId = await insertTechnician(
          database,
          name: 'Sérgio Lima',
          contact: '83988776655',
          specialty: 'Redes',
        );
        await insertServiceOrdersForTechnician(
          database,
          technicianId: sergioId,
          count: 2,
        );
        ordersBefore = await database.query('service_orders', orderBy: 'id');
      });
      final TechnicianController controller = await pumpTechniciansModule(
        tester,
      );

      await tapAndPump(
        tester,
        find.byKey(TechnicianListView.editButtonKey(sergioId)),
      );
      expect(find.text('Editar técnico'), findsOneWidget);
      expect(fieldText(tester, TechnicianFormView.nameFieldKey), 'Sérgio Lima');
      expect(
        fieldText(tester, TechnicianFormView.contactFieldKey),
        '(83) 98877-6655',
      );
      expect(fieldText(tester, TechnicianFormView.specialtyFieldKey), 'Redes');
      expect(activeSwitchValue(tester), isTrue);

      await tapAndPump(tester, find.byKey(TechnicianFormView.activeSwitchKey));
      expect(activeSwitchValue(tester), isFalse);

      await tapAndWaitForDatabase(
        tester,
        find.byKey(TechnicianFormView.saveButtonKey),
      );

      List<Map<String, Object?>> technicians = <Map<String, Object?>>[];
      List<Map<String, Object?>> ordersAfter = <Map<String, Object?>>[];
      await withDatabase(tester, (database) async {
        technicians = await database.query('technicians');
        ordersAfter = await database.query('service_orders', orderBy: 'id');
      });
      expect(technicians, hasLength(1));
      expect(technicians.single['id'], sergioId);
      expect(technicians.single['active'], 0);
      expect(ordersBefore, hasLength(2));
      expect(ordersAfter, ordersBefore);
      expect(
        ordersAfter.every(
          (Map<String, Object?> row) => row['technician_id'] == sergioId,
        ),
        isTrue,
      );
      expect(find.byType(TechnicianFormView), findsNothing);
      expect(controller.technicians.single.active, isFalse);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Sérgio Lima'),
          matching: find.text('Inativo'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('cancelling the form returns to the list without saving', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('service_orders');
      await database.delete('technicians');
    });
    await pumpTechniciansModule(tester);
    await openNewTechnicianForm(tester);
    await fillValidData(tester);

    await tapAndPump(tester, find.byKey(TechnicianFormView.cancelButtonKey));

    expect(find.byType(TechnicianFormView), findsNothing);
    expect(find.text('Nenhum técnico cadastrado.'), findsOneWidget);
    expect(await countTechnicians(tester), 0);
  });

  const List<(String, Key, String, String)> invalidExamples =
      <(String, Key, String, String)>[
        ('nome', TechnicianFormView.nameFieldKey, '', 'Informe o nome.'),
        (
          'contato',
          TechnicianFormView.contactFieldKey,
          '',
          'Informe o contato.',
        ),
        (
          'especialidade',
          TechnicianFormView.specialtyFieldKey,
          '',
          'Informe a especialidade.',
        ),
        (
          'contato',
          TechnicianFormView.contactFieldKey,
          '123',
          'Informe um telefone válido.',
        ),
      ];

  for (final (String field, Key key, String value, String message)
      in invalidExamples) {
    testWidgets(
      'field "$field" with value "$value" shows "$message" and saves nothing',
      (WidgetTester tester) async {
        await pumpTechniciansModule(tester);
        final int countBefore = await countTechnicians(tester);
        await openNewTechnicianForm(tester);
        await fillValidData(tester);
        await tester.enterText(find.byKey(key), value);

        await tapAndWaitForDatabase(
          tester,
          find.byKey(TechnicianFormView.saveButtonKey),
        );

        expect(
          find.descendant(of: find.byKey(key), matching: find.text(message)),
          findsOneWidget,
        );
        expect(find.byType(TechnicianFormView), findsOneWidget);
        expect(await countTechnicians(tester), countBefore);
      },
    );
  }

  testWidgets('keeps the form open with typed data when saving fails', (
    WidgetTester tester,
  ) async {
    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
        .blockedDirectory()
        .path;
    await pumpTechniciansModule(tester);
    await openNewTechnicianForm(tester);
    await fillValidData(tester);

    await tapAndWaitForDatabase(
      tester,
      find.byKey(TechnicianFormView.saveButtonKey),
    );

    expect(
      find.text('Não foi possível salvar o técnico. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(TechnicianFormView), findsOneWidget);
    expect(fieldText(tester, TechnicianFormView.nameFieldKey), validName);
    expect(fieldText(tester, TechnicianFormView.contactFieldKey), validContact);
    expect(
      fieldText(tester, TechnicianFormView.specialtyFieldKey),
      validSpecialty,
    );
    expect(activeSwitchValue(tester), isTrue);
    expect(find.text('Técnico salvo com sucesso.'), findsNothing);
    expectNoTechnicalErrorText();
    expectNoDialogs();
  });
}
