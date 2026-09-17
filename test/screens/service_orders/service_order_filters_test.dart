import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/service_order_controller.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'service_orders_test_support.dart';

void main() {
  TemporaryDatabase().register('ordem_servico_order_filters_test_');

  Future<void> seedOrders(WidgetTester tester) async {
    await withDatabase(tester, (Database database) async {
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
      final int marcos = await insertCustomer(
        database,
        name: 'Marcos Vieira',
        document: '33444555000166',
      );
      final int airConditioner = await insertEquipmentFor(
        database,
        customerId: ana,
        type: 'Ar-condicionado split',
      );
      final int notebook = await insertEquipmentFor(
        database,
        customerId: carlos,
        type: 'Notebook',
      );
      final int powerSupply = await insertEquipmentFor(
        database,
        customerId: marcos,
        type: 'Nobreak',
      );
      final int rafael = await insertTechnicianNamed(
        database,
        name: 'Rafael Duarte',
      );
      final int bruno = await insertTechnicianNamed(
        database,
        name: 'Bruno Alencar',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0001',
        customerId: ana,
        equipmentId: airConditioner,
        technicianId: rafael,
        dueDate: '2026-09-10',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0002',
        customerId: ana,
        equipmentId: airConditioner,
        priority: 'high',
        dueDate: '2026-09-11',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0003',
        customerId: ana,
        equipmentId: airConditioner,
        technicianId: bruno,
        status: 'completed',
        dueDate: '2026-09-12',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0004',
        customerId: carlos,
        equipmentId: notebook,
        technicianId: bruno,
        dueDate: '2026-09-13',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0005',
        customerId: marcos,
        equipmentId: powerSupply,
        technicianId: rafael,
        priority: 'urgent',
        dueDate: '2026-09-14',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0006',
        customerId: marcos,
        equipmentId: powerSupply,
        status: 'awaitingPart',
        priority: 'urgent',
        dueDate: '2026-09-15',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0007',
        customerId: marcos,
        equipmentId: powerSupply,
        technicianId: rafael,
        status: 'completed',
        priority: 'low',
        dueDate: '2026-09-16',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0008',
        customerId: marcos,
        equipmentId: powerSupply,
        technicianId: bruno,
        status: 'cancelled',
        dueDate: '2026-09-17',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0009',
        customerId: marcos,
        equipmentId: powerSupply,
        technicianId: rafael,
        status: 'inProgress',
        priority: 'high',
        dueDate: '2026-09-18',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0010',
        customerId: marcos,
        equipmentId: powerSupply,
        status: 'assigned',
        priority: 'low',
        dueDate: '2026-09-19',
      );
    });
  }

  Finder visibleCards() {
    return find.descendant(
      of: find.byKey(ServiceOrderListView.listKey),
      matching: find.byType(Card),
    );
  }

  testWidgets('lists only the orders matching the term and the status', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester);
    final ServiceOrderController controller = await pumpServiceOrdersModule(
      tester,
    );

    await searchForTerm(tester, 'Ana');
    await selectFilterOption(
      tester,
      ServiceOrderListView.statusFilterKey,
      'Aberta',
    );

    expect(controller.orders, hasLength(2));
    expect(visibleCards(), findsNWidgets(2));
    expect(find.text('OS-2026-0001'), findsOneWidget);
    expect(find.text('OS-2026-0002'), findsOneWidget);
    expect(find.text('OS-2026-0003'), findsNothing);
    expect(find.text('OS-2026-0004'), findsNothing);
    expectNoDialogs();
  });

  testWidgets('returning the status selector to "Todos" drops the criterion', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester);
    final ServiceOrderController controller = await pumpServiceOrdersModule(
      tester,
    );
    await selectFilterOption(
      tester,
      ServiceOrderListView.statusFilterKey,
      'Concluída',
    );
    expect(controller.orders, hasLength(2));

    await selectFilterOption(
      tester,
      ServiceOrderListView.statusFilterKey,
      'Todos',
    );

    expect(controller.orders, hasLength(10));
    expect(controller.filter.status, isNull);
    expect(find.byKey(ServiceOrderListView.resultCountKey), findsNothing);
  });

  testWidgets('shows "2 resultados" and offers "Limpar filtros"', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester);
    await pumpServiceOrdersModule(tester);
    expect(find.byKey(ServiceOrderListView.resultCountKey), findsNothing);
    expect(find.text('Limpar filtros'), findsNothing);

    await searchForTerm(tester, 'Ana');
    await selectFilterOption(
      tester,
      ServiceOrderListView.statusFilterKey,
      'Aberta',
    );

    expect(find.text('2 resultados'), findsOneWidget);
    expect(find.byKey(ServiceOrderListView.resultCountKey), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);
    expect(
      find.byKey(ServiceOrderListView.clearFiltersButtonKey),
      findsOneWidget,
    );
  });

  testWidgets('"Limpar filtros" restores every order, empties the search field '
      'and returns the three selectors to "Todos"', (
    WidgetTester tester,
  ) async {
    await seedOrders(tester);
    final ServiceOrderController controller = await pumpServiceOrdersModule(
      tester,
    );
    await searchForTerm(tester, 'Ana');
    await selectFilterOption(
      tester,
      ServiceOrderListView.statusFilterKey,
      'Aberta',
    );
    await selectFilterOption(
      tester,
      ServiceOrderListView.priorityFilterKey,
      'Média',
    );
    await selectFilterOption(
      tester,
      ServiceOrderListView.technicianFilterKey,
      'Rafael Duarte',
    );
    expect(controller.orders, hasLength(1));

    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderListView.clearFiltersButtonKey),
    );

    expect(controller.orders, hasLength(10));
    expect(controller.filter.isActive, isFalse);
    expect(
      tester
          .widget<TextField>(find.byKey(ServiceOrderListView.searchFieldKey))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Todos'), findsNWidgets(3));
    expect(
      find.byKey(ServiceOrderListView.clearFiltersButtonKey),
      findsNothing,
    );
    expect(find.text('OS-2026-0001'), findsOneWidget);
  });

  testWidgets(
    'shows "Nenhuma ordem encontrada para os critérios informados." and '
    'still offers "Limpar filtros"',
    (WidgetTester tester) async {
      await seedOrders(tester);
      final ServiceOrderController controller = await pumpServiceOrdersModule(
        tester,
      );

      await searchForTerm(tester, 'Ana');
      await selectFilterOption(
        tester,
        ServiceOrderListView.priorityFilterKey,
        'Urgente',
      );

      expect(controller.orders, isEmpty);
      expect(
        find.text('Nenhuma ordem encontrada para os critérios informados.'),
        findsOneWidget,
      );
      expect(find.text('Nenhuma ordem de serviço cadastrada.'), findsNothing);
      expect(find.text('Limpar filtros'), findsOneWidget);
      expect(find.text('0 resultados'), findsOneWidget);
      expectNoTechnicalErrorText();
      expectNoDialogs();
    },
  );
}
