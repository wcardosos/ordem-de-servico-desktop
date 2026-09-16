import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/equipment_controller.dart';
import 'package:ordem_de_servico/models/equipment.dart';
import 'package:ordem_de_servico/repositories/equipment_repository.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'equipment_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_equipment_list_test_');

  String subtitleOf(WidgetTester tester, String type) {
    final ListTile tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, type),
    );
    return (tile.subtitle! as Text).data!;
  }

  testWidgets('lists equipment ordered by type with the owning customer name', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await clearEquipmentData(database);
      final int anaId = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      final int carlosId = await insertCustomer(
        database,
        name: 'Carlos Menezes',
        document: '22233344455',
      );
      await insertEquipment(
        database,
        customerId: carlosId,
        type: 'Notebook',
        brand: 'Dell',
      );
      await insertEquipment(
        database,
        customerId: anaId,
        type: 'Ar-condicionado split',
        brand: 'LG',
      );
    });

    await pumpEquipmentModule(tester);

    expect(find.text('Equipamentos'), findsOneWidget);
    expect(find.byKey(EquipmentListView.listKey), findsOneWidget);
    final List<ListTile> tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .toList();
    expect(tiles, hasLength(2));
    expect((tiles[0].title! as Text).data, 'Ar-condicionado split');
    expect((tiles[1].title! as Text).data, 'Notebook');
    expect(
      subtitleOf(tester, 'Ar-condicionado split'),
      contains('Ana Ribeiro'),
    );
    expect(subtitleOf(tester, 'Ar-condicionado split'), contains('LG'));
    expect(subtitleOf(tester, 'Notebook'), contains('Carlos Menezes'));
    expect(subtitleOf(tester, 'Notebook'), contains('Dell'));
    expect(subtitleOf(tester, 'Notebook'), isNot(contains('Ana Ribeiro')));
    expectNoDialogs();
  });

  testWidgets('shows empty state when no equipment exists', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, clearEquipmentData);

    await pumpEquipmentModule(tester);

    expect(find.text('Nenhum equipamento cadastrado.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byKey(EquipmentListView.listKey), findsNothing);
  });

  testWidgets(
    'equipment persists with its customer after closing and reopening the app',
    (WidgetTester tester) async {
      int anaId = 0;
      await withDatabase(tester, (database) async {
        await clearEquipmentData(database);
        anaId = await insertCustomer(
          database,
          name: 'Ana Ribeiro',
          document: '11122233344',
        );
        await insertEquipment(
          database,
          customerId: anaId,
          type: 'Ar-condicionado split',
          brand: 'LG',
          model: 'Dual Inverter',
          serialNumber: 'SN-99120',
          assetTag: 'PAT-014',
          notes: 'Instalado na sala de reuniões',
        );
        await DatabaseHelper.instance.close();
      });

      final EquipmentController controller = await pumpEquipmentModule(tester);

      expect(find.text('Ar-condicionado split'), findsOneWidget);
      final Equipment equipment = controller.equipment.single;
      expect(equipment.customerId, anaId);
      expect(equipment.customerName, 'Ana Ribeiro');
      expect(equipment.type, 'Ar-condicionado split');
      expect(equipment.brand, 'LG');
      expect(equipment.model, 'Dual Inverter');
      expect(equipment.serialNumber, 'SN-99120');
      expect(equipment.assetTag, 'PAT-014');
      expect(equipment.notes, 'Instalado na sala de reuniões');
    },
  );

  testWidgets(
    'shows a friendly message and retry button when the database is unreadable',
    (WidgetTester tester) async {
      DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
          .blockedDirectory()
          .path;

      await pumpEquipmentModule(tester);

      expect(
        find.text('Não foi possível carregar os equipamentos.'),
        findsOneWidget,
      );
      expect(find.byKey(EquipmentListView.retryButtonKey), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expectNoTechnicalErrorText();
      expectNoDialogs();
    },
  );

  testWidgets('findByCustomer returns only that customer equipment by type', (
    WidgetTester tester,
  ) async {
    int anaId = 0;
    int notebookId = 0;
    await withDatabase(tester, (database) async {
      await clearEquipmentData(database);
      anaId = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      final int carlosId = await insertCustomer(
        database,
        name: 'Carlos Menezes',
        document: '22233344455',
      );
      await insertEquipment(
        database,
        customerId: anaId,
        type: 'Bebedouro industrial',
      );
      await insertEquipment(
        database,
        customerId: anaId,
        type: 'Ar-condicionado split',
      );
      notebookId = await insertEquipment(
        database,
        customerId: carlosId,
        type: 'Notebook',
      );
    });
    List<Equipment> anaEquipment = <Equipment>[];
    Equipment? found;
    Equipment? missing;
    await tester.runAsync(() async {
      final EquipmentRepository repository = EquipmentRepository();
      anaEquipment = await repository.findByCustomer(anaId);
      found = await repository.findById(notebookId);
      missing = await repository.findById(-1);
    });
    expect(
      anaEquipment.map((Equipment equipment) => equipment.type).toList(),
      <String>['Ar-condicionado split', 'Bebedouro industrial'],
    );
    expect(
      anaEquipment.every(
        (Equipment equipment) => equipment.customerId == anaId,
      ),
      isTrue,
    );
    expect(found?.type, 'Notebook');
    expect(found?.customerName, 'Carlos Menezes');
    expect(missing, isNull);
  });
}
