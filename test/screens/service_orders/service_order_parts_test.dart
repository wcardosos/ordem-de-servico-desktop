import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_detail_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_orders_module.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'service_orders_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_order_parts_test_');

  Future<int> seed(
    WidgetTester tester, {
    String status = 'inProgress',
    double laborCost = 0,
    List<Map<String, Object?>> items = const <Map<String, Object?>>[],
  }) async {
    int orderId = 0;
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
      orderId = await insertServiceOrder(
        database,
        number: 'OS-2026-0001',
        customerId: customerId,
        equipmentId: equipmentId,
        status: status,
        diagnosis: 'Compressor com falha de partida',
        solution: 'Compressor substituído',
      );
      await database.update(
        'service_orders',
        <String, Object?>{'labor_cost': laborCost},
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
      );
      for (final Map<String, Object?> item in items) {
        await insertPartItem(
          database,
          serviceOrderId: orderId,
          description: item['description']! as String,
          quantity: item['quantity']! as int,
          unitPrice: (item['unitPrice']! as num).toDouble(),
        );
      }
    });
    return orderId;
  }

  Future<void> openDetail(
    WidgetTester tester, {
    String status = 'inProgress',
    double laborCost = 0,
    List<Map<String, Object?>> items = const <Map<String, Object?>>[],
  }) async {
    await seed(tester, status: status, laborCost: laborCost, items: items);
    await pumpServiceOrdersModule(tester);
    await openOrderDetail(tester, 'OS-2026-0001');
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pump();
  }

  Future<void> revealAndTap(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tapAndWaitForDatabase(tester, target);
  }

  Future<void> typeInto(
    WidgetTester tester,
    Key fieldKey,
    String value,
  ) async {
    await reveal(tester, find.byKey(fieldKey));
    await tester.enterText(find.byKey(fieldKey), value);
    await tester.pump();
  }

  Future<void> fillNewItem(
    WidgetTester tester, {
    String description = 'Compressor 1/3 HP',
    String quantity = '1',
    String unitPrice = '780,00',
  }) async {
    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.addPartItemButtonKey),
    );
    await typeInto(
      tester,
      ServiceOrderDetailView.partItemDescriptionFieldKey,
      description,
    );
    await typeInto(
      tester,
      ServiceOrderDetailView.partItemQuantityFieldKey,
      quantity,
    );
    await typeInto(
      tester,
      ServiceOrderDetailView.partItemUnitPriceFieldKey,
      unitPrice,
    );
  }

  Future<void> confirmNewItem(WidgetTester tester) async {
    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.confirmPartItemButtonKey),
    );
  }

  Finder valueAt(Key slot, String text) {
    return find.descendant(of: find.byKey(slot), matching: find.text(text));
  }

  Finder inSnackBar(String text) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );
  }

  Future<Finder> subtotalOf(WidgetTester tester, String description) async {
    final int id = await partItemIdOf(tester, description);
    return find.byKey(ServiceOrderDetailView.partItemSubtotalKey(id));
  }

  testWidgets('adding an item shows it in the list and updates the total', (
    WidgetTester tester,
  ) async {
    await openDetail(tester);
    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 0,00'),
      findsOneWidget,
    );

    await fillNewItem(tester);
    await confirmNewItem(tester);

    expect(find.text('Compressor 1/3 HP'), findsOneWidget);
    expect(
      find.descendant(
        of: await subtotalOf(tester, 'Compressor 1/3 HP'),
        matching: find.text(r'R$ 780,00'),
      ),
      findsOneWidget,
    );
    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 780,00'),
      findsOneWidget,
    );
    expect(inSnackBar('Item adicionado.'), findsOneWidget);
  });

  testWidgets('saving the labor cost adds it to the total', (
    WidgetTester tester,
  ) async {
    await openDetail(
      tester,
      items: <Map<String, Object?>>[
        <String, Object?>{
          'description': 'Compressor 1/3 HP',
          'quantity': 1,
          'unitPrice': 780.00,
        },
      ],
    );
    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 780,00'),
      findsOneWidget,
    );

    await typeInto(tester, ServiceOrderDetailView.laborCostFieldKey, '150,00');
    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.saveLaborCostButtonKey),
    );

    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 930,00'),
      findsOneWidget,
    );
  });

  testWidgets('shows a subtotal with the brazilian currency format', (
    WidgetTester tester,
  ) async {
    await openDetail(
      tester,
      items: <Map<String, Object?>>[
        <String, Object?>{
          'description': 'Placa eletrônica',
          'quantity': 1,
          'unitPrice': 1234.5,
        },
      ],
    );

    expect(
      find.descendant(
        of: await subtotalOf(tester, 'Placa eletrônica'),
        matching: find.text(r'R$ 1.234,50'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('removes an item after confirmation and recalculates the total', (
    WidgetTester tester,
  ) async {
    await openDetail(
      tester,
      items: <Map<String, Object?>>[
        <String, Object?>{
          'description': 'Compressor 1/3 HP',
          'quantity': 1,
          'unitPrice': 780.00,
        },
        <String, Object?>{
          'description': 'Gás refrigerante R410A',
          'quantity': 2,
          'unitPrice': 95.50,
        },
      ],
    );
    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 971,00'),
      findsOneWidget,
    );
    final int gasId = await partItemIdOf(tester, 'Gás refrigerante R410A');

    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.removePartItemButtonKey(gasId)),
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrdersModule.confirmRemovePartItemButtonKey),
    );

    expect(find.text('Gás refrigerante R410A'), findsNothing);
    expect(find.text('Compressor 1/3 HP'), findsOneWidget);
    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 780,00'),
      findsOneWidget,
    );
    expect(inSnackBar('Item removido.'), findsOneWidget);
    expectNoDialogs();
  });

  testWidgets('cancelling the removal keeps the item in the list', (
    WidgetTester tester,
  ) async {
    await openDetail(
      tester,
      items: <Map<String, Object?>>[
        <String, Object?>{
          'description': 'Compressor 1/3 HP',
          'quantity': 1,
          'unitPrice': 780.00,
        },
      ],
    );
    final int itemId = await partItemIdOf(tester, 'Compressor 1/3 HP');

    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.removePartItemButtonKey(itemId)),
    );
    await tapAndWaitForDatabase(
      tester,
      find.byKey(ServiceOrdersModule.cancelRemovePartItemButtonKey),
    );

    expectNoDialogs();
    expect(find.text('Compressor 1/3 HP'), findsOneWidget);
    expect(await queryPartItems(tester), hasLength(1));
  });

  const List<(String, String)> finalStatuses = <(String, String)>[
    ('completed', 'Concluída'),
    ('cancelled', 'Cancelada'),
  ];

  for (final (String status, String label) in finalStatuses) {
    testWidgets('offers no value changes for an order with status $label', (
      WidgetTester tester,
    ) async {
      await openDetail(
        tester,
        status: status,
        laborCost: 150.00,
        items: <Map<String, Object?>>[
          <String, Object?>{
            'description': 'Compressor 1/3 HP',
            'quantity': 1,
            'unitPrice': 780.00,
          },
        ],
      );
      final int itemId = await partItemIdOf(tester, 'Compressor 1/3 HP');

      expect(
        find.byKey(ServiceOrderDetailView.addPartItemButtonKey),
        findsNothing,
      );
      expect(
        find.byKey(ServiceOrderDetailView.removePartItemButtonKey(itemId)),
        findsNothing,
      );
      expect(
        find.byKey(ServiceOrderDetailView.saveLaborCostButtonKey),
        findsNothing,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(ServiceOrderDetailView.laborCostFieldKey),
            )
            .enabled,
        isFalse,
      );
      expect(
        valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 930,00'),
        findsOneWidget,
      );
    });
  }

  const List<(Key, String, String)> invalidEntries = <(Key, String, String)>[
    (
      ServiceOrderDetailView.partItemDescriptionFieldKey,
      '',
      'Informe a descrição da peça.',
    ),
    (
      ServiceOrderDetailView.partItemQuantityFieldKey,
      '',
      'Informe a quantidade.',
    ),
    (
      ServiceOrderDetailView.partItemQuantityFieldKey,
      '0',
      'A quantidade deve ser maior que zero.',
    ),
    (
      ServiceOrderDetailView.partItemQuantityFieldKey,
      '-2',
      'A quantidade deve ser maior que zero.',
    ),
    (
      ServiceOrderDetailView.partItemQuantityFieldKey,
      'abc',
      'Informe um número inteiro válido.',
    ),
    (
      ServiceOrderDetailView.partItemUnitPriceFieldKey,
      '',
      'Informe o valor unitário.',
    ),
    (
      ServiceOrderDetailView.partItemUnitPriceFieldKey,
      '-10',
      'O valor não pode ser negativo.',
    ),
    (
      ServiceOrderDetailView.partItemUnitPriceFieldKey,
      'abc',
      'Informe um valor válido.',
    ),
  ];

  for (final (Key field, String value, String message) in invalidEntries) {
    testWidgets('a new item with value "$value" shows "$message" and is not '
        'stored', (WidgetTester tester) async {
      await openDetail(tester);

      await fillNewItem(tester);
      await typeInto(tester, field, value);
      await confirmNewItem(tester);

      expect(find.text(message), findsOneWidget);
      expect(await queryPartItems(tester), isEmpty);
      expect(
        find.byKey(ServiceOrderDetailView.confirmPartItemButtonKey),
        findsOneWidget,
      );
    });
  }

  testWidgets('a unit price typed with a comma is stored as a decimal', (
    WidgetTester tester,
  ) async {
    await openDetail(tester);

    await fillNewItem(
      tester,
      description: 'Gás refrigerante R410A',
      quantity: '2',
      unitPrice: '95,50',
    );
    await confirmNewItem(tester);

    expect(
      find.descendant(
        of: await subtotalOf(tester, 'Gás refrigerante R410A'),
        matching: find.text(r'R$ 191,00'),
      ),
      findsOneWidget,
    );
    final List<Map<String, Object?>> stored = await queryPartItems(tester);
    expect(stored.single['unit_price'], 95.50);
  });

  testWidgets('keeps the part list unchanged when storing the item fails', (
    WidgetTester tester,
  ) async {
    await openDetail(
      tester,
      items: <Map<String, Object?>>[
        <String, Object?>{
          'description': 'Compressor 1/3 HP',
          'quantity': 1,
          'unitPrice': 780.00,
        },
      ],
    );
    await fillNewItem(
      tester,
      description: 'Gás refrigerante R410A',
      quantity: '2',
      unitPrice: '95,50',
    );

    final String blockedPath = temporaryDatabase.blockedDirectory().path;
    await tester.runAsync(() => DatabaseHelper.instance.close());
    DatabaseHelper.databaseDirectoryOverride = blockedPath;

    await confirmNewItem(tester);

    expect(
      inSnackBar('Não foi possível adicionar o item. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text(r'R$ 191,00'), findsNothing);
    expect(find.text('Compressor 1/3 HP'), findsOneWidget);
    expect(
      valueAt(ServiceOrderDetailView.totalAmountKey, r'R$ 780,00'),
      findsOneWidget,
    );
    expectNoTechnicalErrorText();

    DatabaseHelper.databaseDirectoryOverride = temporaryDatabase.directory.path;
    expect(await queryPartItems(tester), hasLength(1));
  });
}
