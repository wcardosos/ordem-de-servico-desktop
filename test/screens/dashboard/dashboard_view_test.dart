import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/screens/dashboard/dashboard_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:ordem_de_servico/widgets/side_navbar.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dashboard_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase();
  temporaryDatabase.register('ordem_servico_dashboard_test_');

  Future<Map<String, int>> seedBase(WidgetTester tester) async {
    Map<String, int> identifiers = <String, int>{};
    await withDatabase(tester, (Database database) async {
      identifiers = await seedIndicatorBase(database);
    });
    return identifiers;
  }

  Future<void> clearOrders(WidgetTester tester) async {
    await withDatabase(tester, (Database database) async {
      await database.delete('part_items');
      await database.delete('service_orders');
    });
  }

  testWidgets('shows the eight indicators of the verification base', (
    WidgetTester tester,
  ) async {
    await seedBase(tester);

    await pumpDashboardModule(tester);

    expectIndicator('Total de ordens', '10');
    expectIndicator('Abertas', '2');
    expectIndicator('Em atendimento', '2');
    expectIndicator('Aguardando peça', '2');
    expectIndicator('Concluídas', '2');
    expectIndicator('Urgentes', '2');
    expectIndicator('Atrasadas', '3');
    expect(find.byKey(DashboardView.errorViewKey), findsNothing);
    expectNoTechnicalErrorText();
    expectNoDialogs();
  });

  testWidgets('shows the total amount of parts and labor in reais', (
    WidgetTester tester,
  ) async {
    await seedBase(tester);

    await pumpDashboardModule(tester);

    expectIndicator('Valor total', indicatorBaseTotalAmountLabel);
  });

  testWidgets('shows zeros and no empty list message without service orders', (
    WidgetTester tester,
  ) async {
    await clearOrders(tester);

    await pumpDashboardModule(tester);

    expectIndicator('Total de ordens', '0');
    expectIndicator('Abertas', '0');
    expectIndicator('Em atendimento', '0');
    expectIndicator('Aguardando peça', '0');
    expectIndicator('Concluídas', '0');
    expectIndicator('Urgentes', '0');
    expectIndicator('Atrasadas', '0');
    expectIndicator('Valor total', r'R$ 0,00');
    expect(find.byKey(DashboardView.errorViewKey), findsNothing);
    expect(find.textContaining('Nenhuma'), findsNothing);
    expectNoTechnicalErrorText();
    expectNoDialogs();
  });

  testWidgets(
    'the awaiting part counter matches the orders list under the same filter',
    (WidgetTester tester) async {
      await seedBase(tester);
      await pumpShell(tester);
      expectIndicator('Aguardando peça', '2');

      await openModule(tester, 'Ordens de serviço');
      await selectFilterOption(
        tester,
        ServiceOrderListView.statusFilterKey,
        'Aguardando peça',
      );

      expect(
        find.descendant(
          of: find.byKey(ServiceOrderListView.listKey),
          matching: find.byKey(ServiceOrderListView.itemKey('OS-2026-0006')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(ServiceOrderListView.listKey),
          matching: find.byKey(ServiceOrderListView.itemKey('OS-2026-0007')),
        ),
        findsOneWidget,
      );
      expect(find.text('2 resultados'), findsOneWidget);
    },
  );

  testWidgets('returning to the panel counts an order opened elsewhere', (
    WidgetTester tester,
  ) async {
    await seedBase(tester);
    await pumpShell(tester);
    expectIndicator('Total de ordens', '10');

    await openModule(tester, 'Ordens de serviço');
    await withDatabase(tester, (Database database) async {
      await insertServiceOrder(
        database,
        number: 'OS-2026-0011',
        customerId: 1,
        equipmentId: 1,
      );
    });
    await openModule(tester, 'Painel');

    expectIndicator('Total de ordens', '11');
  });

  testWidgets('returning to the panel reflects a status change', (
    WidgetTester tester,
  ) async {
    final Map<String, int> identifiers = await seedBase(tester);
    await pumpShell(tester);
    expectIndicator('Abertas', '2');
    expect(find.text('Atribuída'), findsNothing);

    await openModule(tester, 'Ordens de serviço');
    await withDatabase(tester, (Database database) async {
      await changeStoredStatus(
        database,
        identifiers['OS-2026-0001']!,
        ServiceOrderStatus.assigned,
      );
    });
    await openModule(tester, 'Painel');

    expectIndicator('Abertas', '1');
    expect(find.text('Atribuída'), findsNothing);
  });

  testWidgets(
    'the panel offers access to orders, customers, technicians and equipment',
    (WidgetTester tester) async {
      await seedBase(tester);

      await pumpShell(tester);

      expect(find.byKey(DashboardView.cardsKey), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(SideNavbar.itemKey('Painel')))
            .selected,
        isTrue,
      );
      expect(find.byKey(SideNavbar.itemKey('Ordens de serviço')), findsOneWidget);
      expect(find.byKey(SideNavbar.itemKey('Clientes')), findsOneWidget);
      expect(find.byKey(SideNavbar.itemKey('Técnicos')), findsOneWidget);
      expect(find.byKey(SideNavbar.itemKey('Equipamentos')), findsOneWidget);
    },
  );

  testWidgets(
    'shows the failure message and a retry button without misleading zeros',
    (WidgetTester tester) async {
      DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
          .blockedDirectory()
          .path;

      await pumpDashboardModule(tester);

      expect(
        find.text('Não foi possível carregar os indicadores.'),
        findsOneWidget,
      );
      expect(find.byKey(DashboardView.retryButtonKey), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byKey(DashboardView.cardsKey), findsNothing);
      expect(find.text('Total de ordens'), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.text(r'R$ 0,00'), findsNothing);
      expectNoTechnicalErrorText();
      expectNoDialogs();

      DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
          .directory
          .path;
      await tapInsideAsync(
        tester,
        find.byKey(DashboardView.retryButtonKey),
      );

      expect(find.byKey(DashboardView.errorViewKey), findsNothing);
      expect(find.byKey(DashboardView.cardsKey), findsOneWidget);
      expect(find.text('Total de ordens'), findsOneWidget);
    },
  );
}
