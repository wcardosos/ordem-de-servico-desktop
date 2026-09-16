import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/customer_controller.dart';
import 'package:ordem_de_servico/models/customer.dart';
import 'package:ordem_de_servico/screens/customers/customer_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'customers_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_customer_list_test_');

  testWidgets('lists registered customers ordered by name', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('service_orders');
      await database.delete('equipment');
      await database.delete('customers');
      await insertCustomer(
        database,
        name: 'Marcos Vieira',
        document: '33344455566',
      );
      await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      await insertCustomer(
        database,
        name: 'Carlos Menezes',
        document: '22233344455',
      );
    });

    await pumpCustomersModule(tester);

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.byKey(CustomerListView.addButtonKey), findsOneWidget);
    expect(find.byKey(CustomerListView.listKey), findsOneWidget);
    final List<ListTile> tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .toList();
    expect(tiles, hasLength(3));
    expect((tiles[0].title! as Text).data, 'Ana Ribeiro');
    expect((tiles[0].subtitle! as Text).data, '111.222.333-44');
    expect((tiles[1].title! as Text).data, 'Carlos Menezes');
    expect((tiles[1].subtitle! as Text).data, '222.333.444-55');
    expect((tiles[2].title! as Text).data, 'Marcos Vieira');
    expect((tiles[2].subtitle! as Text).data, '333.444.555-66');
    expectNoDialogs();
  });

  testWidgets('shows empty state when no customers exist', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('service_orders');
      await database.delete('equipment');
      await database.delete('customers');
    });

    await pumpCustomersModule(tester);

    expect(find.text('Nenhum cliente cadastrado.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byKey(CustomerListView.listKey), findsNothing);
  });

  testWidgets('customer persists after closing and reopening the app', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('service_orders');
      await database.delete('equipment');
      await database.delete('customers');
      await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '99988877766',
        phone: '11911112222',
        email: 'ana.persistida@example.com',
        address: 'Rua Persistencia, 42',
      );
      await DatabaseHelper.instance.close();
    });

    final CustomerController controller = await pumpCustomersModule(tester);

    expect(find.text('Ana Ribeiro'), findsOneWidget);
    expect(find.text('999.888.777-66'), findsOneWidget);
    expect(controller.customers, hasLength(1));
    final Customer customer = controller.customers.single;
    expect(customer.name, 'Ana Ribeiro');
    expect(customer.document, '99988877766');
    expect(customer.phone, '11911112222');
    expect(customer.email, 'ana.persistida@example.com');
    expect(customer.address, 'Rua Persistencia, 42');
  });

  testWidgets(
    'shows a friendly message and retry button when the database is unreadable',
    (WidgetTester tester) async {
      DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
          .blockedDirectory()
          .path;

      await pumpCustomersModule(tester);

      expect(
        find.text('Não foi possível carregar os clientes.'),
        findsOneWidget,
      );
      expect(find.byKey(CustomerListView.retryButtonKey), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expectNoTechnicalErrorText();
      expectNoDialogs();
    },
  );
}
