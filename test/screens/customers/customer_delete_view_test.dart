import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/customer_controller.dart';
import 'package:ordem_de_servico/repositories/customer_repository.dart';
import 'package:ordem_de_servico/screens/customers/customer_delete_view.dart';
import 'package:ordem_de_servico/screens/customers/customer_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'customers_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_customer_delete_test_');

  Future<Map<String, int>> prepareCustomers(
    WidgetTester tester, {
    int anaEquipment = 0,
    int anaServiceOrders = 0,
  }) async {
    final Map<String, int> ids = <String, int>{};
    await withDatabase(tester, (database) async {
      await database.delete('part_items');
      await database.delete('service_orders');
      await database.delete('equipment');
      await database.delete('customers');
      ids['Ana Ribeiro'] = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      ids['Marcos Vieira'] = await insertCustomer(
        database,
        name: 'Marcos Vieira',
        document: '33444555000166',
      );
      final int anaId = ids['Ana Ribeiro']!;
      final List<int> equipmentIds = <int>[];
      for (int i = 0; i < anaEquipment; i++) {
        equipmentIds.add(
          await database.insert('equipment', <String, Object?>{
            'customer_id': anaId,
            'type': 'Notebook',
          }),
        );
      }
      for (int i = 0; i < anaServiceOrders; i++) {
        await database.insert('service_orders', <String, Object?>{
          'number': 'OS-2026-${i + 1}',
          'customer_id': anaId,
          'equipment_id': equipmentIds[i % equipmentIds.length],
          'problem_description': 'Não liga',
          'priority': 'Média',
          'status': 'Aberta',
          'opened_at': '2026-09-01',
          'due_date': '2026-09-10',
        });
      }
    });
    return ids;
  }

  Future<bool> customerExists(WidgetTester tester, int id) async {
    bool exists = false;
    await withDatabase(tester, (database) async {
      final List<Map<String, Object?>> rows = await database.query(
        'customers',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      exists = rows.isNotEmpty;
    });
    return exists;
  }

  Future<void> openDeleteView(WidgetTester tester, int id, String name) async {
    await tapAndPump(tester, find.byKey(CustomerListView.deleteButtonKey(id)));
    expect(find.byType(CustomerDeleteView), findsOneWidget);
    expect(find.byType(CustomerListView), findsNothing);
    expect(find.text('Deseja excluir o cliente "$name"?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
    expectNoDialogs();
  }

  testWidgets('deletes a customer without links after confirmation', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareCustomers(tester);
    final int marcosId = ids['Marcos Vieira']!;
    await pumpCustomersModule(tester);

    await openDeleteView(tester, marcosId, 'Marcos Vieira');
    await tapAndWaitForDatabase(
      tester,
      find.byKey(CustomerDeleteView.confirmButtonKey),
    );

    expect(find.byType(CustomerDeleteView), findsNothing);
    expect(await customerExists(tester, marcosId), isFalse);
    expect(find.text('Marcos Vieira'), findsNothing);
    expect(find.text('Ana Ribeiro'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Cliente excluído.'),
      ),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets(
    'blocks deletion of a customer with 2 equipment and 3 service orders',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareCustomers(
        tester,
        anaEquipment: 2,
        anaServiceOrders: 3,
      );
      final int anaId = ids['Ana Ribeiro']!;
      await pumpCustomersModule(tester);

      await openDeleteView(tester, anaId, 'Ana Ribeiro');
      await tapAndWaitForDatabase(
        tester,
        find.byKey(CustomerDeleteView.confirmButtonKey),
      );

      expect(await customerExists(tester, anaId), isTrue);
      expect(find.byType(CustomerListView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CustomerListView.noticeKey),
          matching: find.text(
            'Este cliente possui 5 registros vinculados e não pode ser excluído.',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Ana Ribeiro'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expectNoDialogs();

      await tapAndPump(
        tester,
        find.byKey(CustomerListView.dismissNoticeButtonKey),
      );

      expect(find.byKey(CustomerListView.noticeKey), findsNothing);
      expect(find.text('Ana Ribeiro'), findsOneWidget);
    },
  );

  test('blocked message uses singular for a single linked record', () {
    expect(
      CustomerController.blockedByLinkMessage(1),
      'Este cliente possui 1 registro vinculado e não pode ser excluído.',
    );
    expect(
      CustomerController.blockedByLinkMessage(5),
      'Este cliente possui 5 registros vinculados e não pode ser excluído.',
    );
  });

  testWidgets('countLinks sums equipment and service orders', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareCustomers(
      tester,
      anaEquipment: 2,
      anaServiceOrders: 3,
    );
    int? anaLinks;
    int? marcosLinks;
    await tester.runAsync(() async {
      final CustomerRepository repository = CustomerRepository();
      anaLinks = await repository.countLinks(ids['Ana Ribeiro']!);
      marcosLinks = await repository.countLinks(ids['Marcos Vieira']!);
    });
    expect(anaLinks, 5);
    expect(marcosLinks, 0);
  });

  testWidgets('cancelling the confirmation keeps the customer', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareCustomers(tester);
    final int marcosId = ids['Marcos Vieira']!;
    await pumpCustomersModule(tester);

    await openDeleteView(tester, marcosId, 'Marcos Vieira');
    await tapAndPump(tester, find.byKey(CustomerDeleteView.cancelButtonKey));

    expect(find.byType(CustomerDeleteView), findsNothing);
    expect(await customerExists(tester, marcosId), isTrue);
    expect(find.text('Marcos Vieira'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expectNoDialogs();
  });

  testWidgets(
    'shows a friendly message and keeps the customer when deletion fails',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareCustomers(tester);
      final int marcosId = ids['Marcos Vieira']!;
      await pumpCustomersModule(tester);
      await openDeleteView(tester, marcosId, 'Marcos Vieira');

      final String blockedPath = temporaryDatabase.blockedDirectory().path;
      await tester.runAsync(() => DatabaseHelper.instance.close());
      DatabaseHelper.databaseDirectoryOverride = blockedPath;

      await tapAndWaitForDatabase(
        tester,
        find.byKey(CustomerDeleteView.confirmButtonKey),
      );

      expect(
        find.text('Não foi possível excluir o cliente. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Marcos Vieira'), findsOneWidget);
      expect(find.byKey(CustomerListView.errorViewKey), findsNothing);
      expectNoTechnicalErrorText();
      expectNoDialogs();

      DatabaseHelper.databaseDirectoryOverride =
          temporaryDatabase.directory.path;
      expect(await customerExists(tester, marcosId), isTrue);
    },
  );
}
