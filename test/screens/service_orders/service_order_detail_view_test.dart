import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_detail_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_list_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_orders_module.dart';

import 'service_orders_test_support.dart';

void main() {
  TemporaryDatabase().register('ordem_servico_order_detail_test_');

  Future<Map<String, int>> seed(
    WidgetTester tester,
    List<Map<String, Object?>> orders,
  ) async {
    final Map<String, int> ids = <String, int>{};
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
      for (final Map<String, Object?> order in orders) {
        final String number = order['number']! as String;
        ids[number] = await insertServiceOrder(
          database,
          number: number,
          customerId: customerId,
          equipmentId: equipmentId,
          technicianId: order['withTechnician'] == true ? technicianId : null,
          priority: (order['priority'] as String?) ?? 'medium',
          status: (order['status'] as String?) ?? 'open',
        );
      }
    });
    return ids;
  }

  Finder field(String name, String text) {
    return find.descendant(
      of: find.byKey(ServiceOrderDetailView.fieldKey(name)),
      matching: find.text(text),
    );
  }

  Finder inDialog(String text) {
    return find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(text),
    );
  }

  Finder inSnackBar(String text) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );
  }

  Future<bool> orderExists(WidgetTester tester, String number) async {
    final List<Map<String, Object?>> rows = await queryServiceOrders(tester);
    return rows.any((Map<String, Object?> row) => row['number'] == number);
  }

  testWidgets('tapping a list item shows every field of the order', (
    WidgetTester tester,
  ) async {
    await seed(tester, <Map<String, Object?>>[
      <String, Object?>{
        'number': 'OS-2026-0001',
        'withTechnician': true,
        'priority': 'high',
      },
    ]);
    await pumpServiceOrdersModule(tester);

    await openOrderDetail(tester, 'OS-2026-0001');

    expect(find.byType(ServiceOrderDetailView), findsOneWidget);
    expect(find.byType(ServiceOrderListView), findsNothing);
    expect(field('number', 'OS-2026-0001'), findsOneWidget);
    expect(field('customer', 'Ana Ribeiro'), findsOneWidget);
    expect(field('equipment', 'Ar-condicionado split'), findsOneWidget);
    expect(field('technician', 'Rafael Duarte'), findsOneWidget);
    expect(field('problem', 'Não está gelando'), findsOneWidget);
    expect(field('priority', 'Alta'), findsOneWidget);
    expect(field('status', 'Aberta'), findsOneWidget);
    expect(field('openedAt', '14/09/2026'), findsOneWidget);
    expect(field('dueDate', '30/09/2026'), findsOneWidget);
    expect(find.byKey(ServiceOrderDetailView.editButtonKey), findsOneWidget);
    expect(find.byKey(ServiceOrderDetailView.deleteButtonKey), findsOneWidget);
    expectNoDialogs();
  });

  testWidgets('fields without value show placeholder text', (
    WidgetTester tester,
  ) async {
    await seed(tester, <Map<String, Object?>>[
      <String, Object?>{'number': 'OS-2026-0005'},
    ]);
    await pumpServiceOrdersModule(tester);

    await openOrderDetail(tester, 'OS-2026-0005');

    expect(field('technician', 'Sem responsável'), findsOneWidget);
    expect(field('diagnosis', 'Não informado'), findsOneWidget);
    expect(field('solution', 'Não informado'), findsOneWidget);
  });

  testWidgets('deletes an open order after confirmation', (
    WidgetTester tester,
  ) async {
    await seed(tester, <Map<String, Object?>>[
      <String, Object?>{'number': 'OS-2026-0006'},
    ]);
    await pumpServiceOrdersModule(tester);
    await openOrderDetail(tester, 'OS-2026-0006');

    await tapAndPump(
      tester,
      find.byKey(ServiceOrderDetailView.deleteButtonKey),
    );
    expect(inDialog('Cancelar'), findsOneWidget);
    expect(inDialog('Excluir'), findsOneWidget);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrdersModule.confirmDeleteButtonKey),
    );

    expect(await orderExists(tester, 'OS-2026-0006'), isFalse);
    expect(inSnackBar('Ordem de serviço excluída.'), findsOneWidget);
    expect(find.byType(ServiceOrderListView), findsOneWidget);
    expect(find.text('OS-2026-0006'), findsNothing);
    expectNoDialogs();
  });

  const List<(String, String)> blockedStatuses = <(String, String)>[
    ('assigned', 'Atribuída'),
    ('inProgress', 'Em atendimento'),
    ('awaitingPart', 'Aguardando peça'),
    ('completed', 'Concluída'),
    ('cancelled', 'Cancelada'),
  ];

  for (final (String status, String label) in blockedStatuses) {
    testWidgets('blocks deletion of an order with status $label', (
      WidgetTester tester,
    ) async {
      await seed(tester, <Map<String, Object?>>[
        <String, Object?>{'number': 'OS-2026-0007', 'status': status},
      ]);
      await pumpServiceOrdersModule(tester);
      await openOrderDetail(tester, 'OS-2026-0007');
      expect(field('status', label), findsOneWidget);

      await tapAndWaitForDatabase(
        tester,
        find.byKey(ServiceOrderDetailView.deleteButtonKey),
      );

      expect(
        inDialog(
          'Só é possível excluir uma ordem com status Aberta. Para encerrar esta ordem, utilize o cancelamento.',
        ),
        findsOneWidget,
      );
      expect(inDialog('Excluir'), findsNothing);
      await tapAndPump(
        tester,
        find.byKey(ServiceOrdersModule.closeBlockedDialogButtonKey),
      );
      expectNoDialogs();
      expect(await orderExists(tester, 'OS-2026-0007'), isTrue);
      expect(find.text('Ordem de serviço excluída.'), findsNothing);
      expect(find.byType(ServiceOrderDetailView), findsOneWidget);
    });
  }

  testWidgets('cancelling the deletion confirmation keeps the order', (
    WidgetTester tester,
  ) async {
    await seed(tester, <Map<String, Object?>>[
      <String, Object?>{'number': 'OS-2026-0006'},
    ]);
    await pumpServiceOrdersModule(tester);
    await openOrderDetail(tester, 'OS-2026-0006');

    await tapAndPump(
      tester,
      find.byKey(ServiceOrderDetailView.deleteButtonKey),
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrdersModule.cancelDeleteButtonKey),
    );

    expectNoDialogs();
    expect(await orderExists(tester, 'OS-2026-0006'), isTrue);
    expect(find.byType(ServiceOrderDetailView), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'returns to the list with a notice when the order no longer exists',
    (WidgetTester tester) async {
      final Map<String, int> ids = await seed(tester, <Map<String, Object?>>[
        <String, Object?>{'number': 'OS-2026-0008'},
      ]);
      await pumpServiceOrdersModule(tester);
      await withDatabase(tester, (database) async {
        await database.delete(
          'service_orders',
          where: 'id = ?',
          whereArgs: <Object?>[ids['OS-2026-0008']],
        );
      });

      await openOrderDetail(tester, 'OS-2026-0008');

      expect(find.byType(ServiceOrderDetailView), findsNothing);
      expect(find.byType(ServiceOrderListView), findsOneWidget);
      expect(inSnackBar('Ordem de serviço não encontrada.'), findsOneWidget);
      expect(find.text('OS-2026-0008'), findsNothing);
      expectNoDialogs();
    },
  );
}
