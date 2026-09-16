import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/app_shell.dart';
import 'package:ordem_de_servico/screens/customers/customer_list_view.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_list_view.dart';
import 'package:ordem_de_servico/screens/login_screen.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/screens/technicians/technician_list_view.dart';
import 'package:ordem_de_servico/widgets/app_module.dart';
import 'package:ordem_de_servico/widgets/side_navbar.dart';

import 'customers/customers_test_support.dart';

void main() {
  TemporaryDatabase().register('ordem_servico_app_shell_test_');

  final List<AppModule> fakeModules = <AppModule>[
    AppModule(
      label: 'Primeiro',
      icon: Icons.looks_one_outlined,
      builder: (BuildContext context) => const Text('conteúdo do primeiro'),
    ),
    AppModule(
      label: 'Segundo',
      icon: Icons.looks_two_outlined,
      builder: (BuildContext context) => const Text('conteúdo do segundo'),
    ),
  ];

  Future<void> pumpShell(
    WidgetTester tester, {
    List<AppModule>? modules,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: AppShell(modules: modules)));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
    'shows the customers module selected in the sidebar and its list in the main section',
    (WidgetTester tester) async {
      await pumpShell(tester);

      expect(find.byType(SideNavbar), findsOneWidget);
      final ListTile item = tester.widget<ListTile>(
        find.byKey(SideNavbar.itemKey('Clientes')),
      );
      expect(item.selected, isTrue);
      expect(find.byKey(SideNavbar.signOutButtonKey), findsOneWidget);
      expect(find.byType(CustomerListView), findsOneWidget);
      expect(find.text('Ana Ribeiro'), findsOneWidget);
      expectNoDialogs();
    },
  );

  testWidgets(
    'shows the technicians module in the sidebar and opens its list',
    (WidgetTester tester) async {
      await pumpShell(tester);
      expect(find.byKey(SideNavbar.itemKey('Técnicos')), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(SideNavbar.itemKey('Técnicos')));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester
            .widget<ListTile>(find.byKey(SideNavbar.itemKey('Técnicos')))
            .selected,
        isTrue,
      );
      expect(find.byType(CustomerListView), findsNothing);
      expect(find.byType(TechnicianListView), findsOneWidget);
      expect(find.text('Bruno Alencar'), findsOneWidget);
      expect(find.text('Sérgio Lima'), findsOneWidget);
      expectNoDialogs();
    },
  );

  testWidgets('shows the equipment module in the sidebar and opens its list', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    expect(find.byKey(SideNavbar.itemKey('Equipamentos')), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(SideNavbar.itemKey('Equipamentos')));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester
          .widget<ListTile>(find.byKey(SideNavbar.itemKey('Equipamentos')))
          .selected,
      isTrue,
    );
    expect(find.byType(CustomerListView), findsNothing);
    expect(find.byType(EquipmentListView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(EquipmentListView.listKey),
        matching: find.byType(ListTile),
      ),
      findsNWidgets(5),
    );
    expectNoDialogs();
  });

  testWidgets(
    'shows the service orders module in the sidebar and opens its list',
    (WidgetTester tester) async {
      await pumpShell(tester);
      final Finder item = find.byKey(SideNavbar.itemKey('Ordens de serviço'));
      expect(item, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(item);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.widget<ListTile>(item).selected, isTrue);
      expect(find.byType(CustomerListView), findsNothing);
      expect(find.byType(ServiceOrderListView), findsOneWidget);
      expect(find.byKey(ServiceOrderListView.addButtonKey), findsOneWidget);
      expectNoDialogs();
    },
  );

  testWidgets('selecting a sidebar item swaps the main section content', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, modules: fakeModules);
    expect(find.text('conteúdo do primeiro'), findsOneWidget);

    await tapAndPump(tester, find.byKey(SideNavbar.itemKey('Segundo')));

    expect(find.text('conteúdo do primeiro'), findsNothing);
    expect(find.text('conteúdo do segundo'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.byKey(SideNavbar.itemKey('Segundo')))
          .selected,
      isTrue,
    );
    expect(find.byType(SideNavbar), findsOneWidget);
  });

  testWidgets('signing out returns to the login screen', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, modules: fakeModules);

    await tester.tap(find.byKey(SideNavbar.signOutButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });
}
