import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ordem_de_servico/core/service_order_labels.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_detail_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_orders_module.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'service_orders_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_status_change_test_');

  Future<void> seed(
    WidgetTester tester, {
    required String status,
    bool withTechnician = true,
    String? diagnosis,
  }) async {
    await withDatabase(tester, (database) async {
      await clearServiceOrderData(database);
      final int customerId = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      final int equipmentId = await insertEquipmentFor(
        database,
        customerId: customerId,
        type: 'Ar-condicionado split',
      );
      final int technicianId = await insertTechnicianNamed(
        database,
        name: 'Rafael Duarte',
      );
      await insertServiceOrder(
        database,
        number: 'OS-2026-0001',
        customerId: customerId,
        equipmentId: equipmentId,
        technicianId: withTechnician ? technicianId : null,
        status: status,
        diagnosis: diagnosis,
      );
    });
  }

  Future<void> openDetail(
    WidgetTester tester, {
    required String status,
    bool withTechnician = true,
    String? diagnosis,
  }) async {
    await seed(
      tester,
      status: status,
      withTechnician: withTechnician,
      diagnosis: diagnosis,
    );
    await pumpServiceOrdersModule(tester);
    await openOrderDetail(tester, 'OS-2026-0001');
  }

  Finder field(String name, String text) {
    return find.descendant(
      of: find.byKey(ServiceOrderDetailView.fieldKey(name)),
      matching: find.text(text),
    );
  }

  Finder inSnackBar(String text) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );
  }

  Finder selector() {
    return find.descendant(
      of: find.byKey(ServiceOrderDetailView.statusSelectorKey),
      matching: find.byType(DropdownButton<ServiceOrderStatus>),
    );
  }

  Future<void> chooseAndConfirm(WidgetTester tester, String label) async {
    await tapAndPump(tester, selector());
    await tapAndPump(tester, find.text(label).last);
    await tapAndPump(
      tester,
      find.byKey(ServiceOrderDetailView.changeStatusButtonKey),
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrdersModule.confirmStatusChangeButtonKey),
    );
  }

  Future<String?> storedStatus(WidgetTester tester) async {
    final List<Map<String, Object?>> rows = await queryServiceOrders(tester);
    return rows.single['status'] as String?;
  }

  testWidgets('offers only valid target statuses in the selector', (
    WidgetTester tester,
  ) async {
    await openDetail(tester, status: 'inProgress');

    await tapAndPump(tester, selector());

    final DropdownButton<ServiceOrderStatus> dropdown = tester
        .widget<DropdownButton<ServiceOrderStatus>>(selector());
    expect(
      (dropdown.items ?? <DropdownMenuItem<ServiceOrderStatus>>[])
          .map((DropdownMenuItem<ServiceOrderStatus> item) => item.value!.label)
          .toList(),
      <String>['Aguardando peça', 'Concluída', 'Cancelada'],
    );
    expect(find.text('Aguardando peça'), findsWidgets);
    expect(find.text('Concluída'), findsWidgets);
    expect(find.text('Cancelada'), findsWidgets);
    expect(find.text('Aberta'), findsNothing);
    expect(find.text('Atribuída'), findsNothing);
  });

  testWidgets('changes the status after confirmation and updates the list', (
    WidgetTester tester,
  ) async {
    await openDetail(tester, status: 'assigned');
    expect(field('status', 'Atribuída'), findsOneWidget);

    await chooseAndConfirm(tester, 'Em atendimento');

    expect(field('status', 'Em atendimento'), findsOneWidget);
    expect(inSnackBar('Status alterado para Em atendimento.'), findsOneWidget);
    expect(await storedStatus(tester), 'inProgress');
    expectNoDialogs();

    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrderDetailView.backButtonKey),
    );

    expect(find.byType(ServiceOrderListView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ServiceOrderListView.itemKey('OS-2026-0001')),
        matching: find.text('Em atendimento'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows no selector for an order in a final status', (
    WidgetTester tester,
  ) async {
    await openDetail(tester, status: 'completed');

    expect(field('status', 'Concluída'), findsOneWidget);
    expect(find.byKey(ServiceOrderDetailView.statusSelectorKey), findsNothing);
    expect(find.byType(DropdownButton<ServiceOrderStatus>), findsNothing);
    expect(
      find.byKey(ServiceOrderDetailView.changeStatusButtonKey),
      findsNothing,
    );
    expect(find.text('Esta ordem está encerrada.'), findsOneWidget);
  });

  testWidgets('blocks assignment when no technician is set', (
    WidgetTester tester,
  ) async {
    await openDetail(tester, status: 'open', withTechnician: false);

    await chooseAndConfirm(tester, 'Atribuída');

    expect(
      find.text('Defina o técnico responsável antes de atribuir a ordem.'),
      findsOneWidget,
    );
    expect(field('status', 'Aberta'), findsOneWidget);
    expect(await storedStatus(tester), 'open');
  });

  testWidgets('blocks completion without diagnosis and solution', (
    WidgetTester tester,
  ) async {
    await openDetail(tester, status: 'inProgress');

    await chooseAndConfirm(tester, 'Concluída');

    expect(
      find.text(
        'Informe o diagnóstico ou a solução antes de concluir a ordem.',
      ),
      findsOneWidget,
    );
    expect(field('status', 'Em atendimento'), findsOneWidget);
    expect(await storedStatus(tester), 'inProgress');
  });

  testWidgets('shows the completion date after completing an order', (
    WidgetTester tester,
  ) async {
    await openDetail(
      tester,
      status: 'inProgress',
      diagnosis: 'Compressor com falha de partida',
    );

    await chooseAndConfirm(tester, 'Concluída');

    final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    expect(field('status', 'Concluída'), findsOneWidget);
    expect(field('completedAt', today), findsOneWidget);
    expect(find.text('Esta ordem está encerrada.'), findsOneWidget);
    expect(await storedStatus(tester), 'completed');
  });

  testWidgets('keeps the status when saving the change fails', (
    WidgetTester tester,
  ) async {
    await openDetail(tester, status: 'assigned');

    await tapAndPump(tester, selector());
    await tapAndPump(tester, find.text('Em atendimento').last);
    await tapAndPump(
      tester,
      find.byKey(ServiceOrderDetailView.changeStatusButtonKey),
    );

    final String blockedPath = temporaryDatabase.blockedDirectory().path;
    await tester.runAsync(() => DatabaseHelper.instance.close());
    DatabaseHelper.databaseDirectoryOverride = blockedPath;

    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrdersModule.confirmStatusChangeButtonKey),
    );

    expect(
      inSnackBar('Não foi possível alterar o status. Tente novamente.'),
      findsOneWidget,
    );
    expect(field('status', 'Atribuída'), findsOneWidget);
    expect(find.byType(ServiceOrderDetailView), findsOneWidget);
    expectNoTechnicalErrorText();
    expectNoDialogs();

    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase.directory.path;
    expect(await storedStatus(tester), 'assigned');
  });
}
