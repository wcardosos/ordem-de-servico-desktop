import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/dashboard_controller.dart';
import 'package:ordem_de_servico/screens/app_shell.dart';
import 'package:ordem_de_servico/screens/dashboard/dashboard_module.dart';
import 'package:ordem_de_servico/screens/dashboard/dashboard_view.dart';
import 'package:ordem_de_servico/widgets/side_navbar.dart';
import 'package:provider/provider.dart';

export '../../repositories/service_order_test_support.dart'
    show changeStoredStatus, indicatorBaseTotalAmountLabel, seedIndicatorBase;
export '../service_orders/service_orders_test_support.dart';

void useWideSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<DashboardController> pumpDashboardModule(WidgetTester tester) async {
  useWideSurface(tester);
  final DashboardController controller = DashboardController();
  addTearDown(controller.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DashboardController>.value(
            value: controller,
            child: const DashboardModule(),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return controller;
}

Future<void> pumpShell(WidgetTester tester) async {
  useWideSurface(tester);
  await tester.runAsync(() async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapInsideAsync(WidgetTester tester, Finder target) async {
  await tester.runAsync(() async {
    await tester.tap(target);
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> openModule(WidgetTester tester, String label) {
  return tapInsideAsync(tester, find.byKey(SideNavbar.itemKey(label)));
}

void expectIndicator(String label, String value) {
  expect(find.text(label), findsOneWidget);
  expect(
    find.descendant(
      of: find.byKey(DashboardView.cardKey(label)),
      matching: find.text(value),
    ),
    findsOneWidget,
  );
}
