import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/customer_controller.dart';
import 'package:ordem_de_servico/screens/customers/customer_form_view.dart';
import 'package:ordem_de_servico/screens/customers/customer_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'customers_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_customer_form_test_');

  const String validName = 'Ana Ribeiro';
  const String validDocument = '123.456.789-00';
  const String validPhone = '(83) 99999-1234';
  const String storedDocument = '12345678900';
  const String storedPhone = '83999991234';
  const String validEmail = 'ana@exemplo.com';
  const String validAddress = 'Rua das Flores, 120';

  Future<int> countCustomers(WidgetTester tester) async {
    int count = -1;
    await withDatabase(tester, (database) async {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        'SELECT COUNT(*) AS total FROM customers',
      );
      count = rows.first['total']! as int;
    });
    return count;
  }

  Future<void> fillValidData(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(CustomerFormView.nameFieldKey),
      validName,
    );
    await tester.enterText(
      find.byKey(CustomerFormView.documentFieldKey),
      validDocument,
    );
    await tester.enterText(
      find.byKey(CustomerFormView.phoneFieldKey),
      validPhone,
    );
    await tester.enterText(
      find.byKey(CustomerFormView.emailFieldKey),
      validEmail,
    );
    await tester.enterText(
      find.byKey(CustomerFormView.addressFieldKey),
      validAddress,
    );
  }

  Future<void> openNewCustomerForm(WidgetTester tester) async {
    await tapAndPump(tester, find.byKey(CustomerListView.addButtonKey));
    expect(find.byType(CustomerFormView), findsOneWidget);
    expect(find.byType(CustomerListView), findsNothing);
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
  }

  testWidgets(
    'saves a new customer in the main section and returns to the list',
    (WidgetTester tester) async {
      await withDatabase(tester, (database) => database.delete('customers'));
      await pumpCustomersModule(tester);
      expect(find.text(validName), findsNothing);

      await openNewCustomerForm(tester);
      expect(find.text('Novo cliente'), findsOneWidget);
      expect(fieldText(tester, CustomerFormView.nameFieldKey), isEmpty);

      await fillValidData(tester);
      await tapAndWaitForDatabase(
        tester,
        find.byKey(CustomerFormView.saveButtonKey),
      );

      List<Map<String, Object?>> rows = <Map<String, Object?>>[];
      await withDatabase(tester, (database) async {
        rows = await database.query(
          'customers',
          where: 'name = ?',
          whereArgs: <Object?>[validName],
        );
      });
      expect(rows, hasLength(1));
      expect(rows.single['document'], storedDocument);
      expect(rows.single['phone'], storedPhone);
      expect(rows.single['email'], validEmail);
      expect(rows.single['address'], validAddress);

      expect(find.byType(CustomerFormView), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(CustomerListView.listKey),
          matching: find.text(validName),
        ),
        findsOneWidget,
      );
      expect(find.text('Cliente salvo com sucesso.'), findsOneWidget);
      expectNoDialogs();
    },
  );

  testWidgets('edits an existing customer without creating a new one', (
    WidgetTester tester,
  ) async {
    int customerId = 0;
    await withDatabase(tester, (database) async {
      await database.delete('customers');
      customerId = await insertCustomer(
        database,
        name: validName,
        document: storedDocument,
        phone: storedPhone,
        email: validEmail,
        address: validAddress,
      );
    });
    final CustomerController controller = await pumpCustomersModule(tester);

    await tapAndPump(
      tester,
      find.byKey(CustomerListView.editButtonKey(customerId)),
    );

    expect(find.text('Editar cliente'), findsOneWidget);
    expect(fieldText(tester, CustomerFormView.nameFieldKey), validName);
    expect(fieldText(tester, CustomerFormView.documentFieldKey), validDocument);
    expect(fieldText(tester, CustomerFormView.phoneFieldKey), validPhone);
    expect(fieldText(tester, CustomerFormView.emailFieldKey), validEmail);
    expect(fieldText(tester, CustomerFormView.addressFieldKey), validAddress);

    await tester.enterText(
      find.byKey(CustomerFormView.phoneFieldKey),
      '(83) 98888-4321',
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(CustomerFormView.saveButtonKey),
    );

    List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    await withDatabase(tester, (database) async {
      rows = await database.query('customers');
    });
    expect(rows, hasLength(1));
    expect(rows.single['name'], validName);
    expect(rows.single['phone'], '83988884321');
    expect(rows.single['document'], storedDocument);
    expect(find.byType(CustomerFormView), findsNothing);
    expect(controller.customers.single.phone, '83988884321');
  });

  testWidgets('opens the edit form when a customer row is tapped', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('customers');
      await insertCustomer(database, name: validName, document: storedDocument);
    });
    await pumpCustomersModule(tester);

    await tapAndPump(tester, find.text(validName));

    expect(find.text('Editar cliente'), findsOneWidget);
    expect(fieldText(tester, CustomerFormView.nameFieldKey), validName);
  });

  testWidgets('masks document and phone while typing and saves only digits', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) => database.delete('customers'));
    await pumpCustomersModule(tester);
    await openNewCustomerForm(tester);
    await fillValidData(tester);

    await tester.enterText(
      find.byKey(CustomerFormView.documentFieldKey),
      '12345678000195',
    );
    await tester.enterText(
      find.byKey(CustomerFormView.phoneFieldKey),
      '8332221234',
    );

    expect(
      fieldText(tester, CustomerFormView.documentFieldKey),
      '12.345.678/0001-95',
    );
    expect(fieldText(tester, CustomerFormView.phoneFieldKey), '(83) 3222-1234');

    await tapAndWaitForDatabase(
      tester,
      find.byKey(CustomerFormView.saveButtonKey),
    );

    List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    await withDatabase(tester, (database) async {
      rows = await database.query('customers');
    });
    expect(rows, hasLength(1));
    expect(rows.single['document'], '12345678000195');
    expect(rows.single['phone'], '8332221234');
    expect(find.text('12.345.678/0001-95'), findsOneWidget);
  });

  testWidgets('cancelling the form returns to the list without saving', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) => database.delete('customers'));
    await pumpCustomersModule(tester);
    await openNewCustomerForm(tester);
    await fillValidData(tester);

    await tapAndPump(tester, find.byKey(CustomerFormView.cancelButtonKey));

    expect(find.byType(CustomerFormView), findsNothing);
    expect(find.text('Nenhum cliente cadastrado.'), findsOneWidget);
    expect(await countCustomers(tester), 0);
  });

  const List<(String, Key, String, String)> invalidExamples =
      <(String, Key, String, String)>[
        ('nome', CustomerFormView.nameFieldKey, '', 'Informe o nome.'),
        (
          'documento',
          CustomerFormView.documentFieldKey,
          '',
          'Informe o documento.',
        ),
        ('telefone', CustomerFormView.phoneFieldKey, '', 'Informe o telefone.'),
        (
          'endereco',
          CustomerFormView.addressFieldKey,
          '',
          'Informe o endereço.',
        ),
        ('email', CustomerFormView.emailFieldKey, '', 'Informe o e-mail.'),
        (
          'email',
          CustomerFormView.emailFieldKey,
          'ana.exemplo.com',
          'Informe um e-mail válido.',
        ),
        (
          'email',
          CustomerFormView.emailFieldKey,
          '@exemplo.com',
          'Informe um e-mail válido.',
        ),
        (
          'telefone',
          CustomerFormView.phoneFieldKey,
          '123',
          'Informe um telefone válido.',
        ),
      ];

  for (final (String field, Key key, String value, String message)
      in invalidExamples) {
    testWidgets(
      'field "$field" with value "$value" shows "$message" and saves nothing',
      (WidgetTester tester) async {
        await pumpCustomersModule(tester);
        final int countBefore = await countCustomers(tester);
        await openNewCustomerForm(tester);
        await fillValidData(tester);
        await tester.enterText(find.byKey(key), value);

        await tapAndWaitForDatabase(
          tester,
          find.byKey(CustomerFormView.saveButtonKey),
        );

        expect(
          find.descendant(of: find.byKey(key), matching: find.text(message)),
          findsOneWidget,
        );
        expect(find.byType(CustomerFormView), findsOneWidget);
        expect(await countCustomers(tester), countBefore);
      },
    );
  }

  testWidgets('keeps the form open with typed data when saving fails', (
    WidgetTester tester,
  ) async {
    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
        .blockedDirectory()
        .path;
    await pumpCustomersModule(tester);
    await openNewCustomerForm(tester);
    await fillValidData(tester);

    await tapAndWaitForDatabase(
      tester,
      find.byKey(CustomerFormView.saveButtonKey),
    );

    expect(
      find.text('Não foi possível salvar o cliente. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(CustomerFormView), findsOneWidget);
    expect(fieldText(tester, CustomerFormView.nameFieldKey), validName);
    expect(fieldText(tester, CustomerFormView.documentFieldKey), validDocument);
    expect(fieldText(tester, CustomerFormView.phoneFieldKey), validPhone);
    expect(fieldText(tester, CustomerFormView.emailFieldKey), validEmail);
    expect(fieldText(tester, CustomerFormView.addressFieldKey), validAddress);
    expect(find.text('Cliente salvo com sucesso.'), findsNothing);
    expectNoTechnicalErrorText();
    expectNoDialogs();
  });
}
