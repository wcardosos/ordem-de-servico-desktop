import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/app_shell.dart';
import 'package:ordem_de_servico/screens/customers/customer_list_view.dart';
import 'package:ordem_de_servico/screens/login_screen.dart';
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
