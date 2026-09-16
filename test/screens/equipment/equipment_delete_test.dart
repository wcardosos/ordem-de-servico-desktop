import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/equipment_controller.dart';
import 'package:ordem_de_servico/repositories/equipment_repository.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_list_view.dart';
import 'package:ordem_de_servico/screens/equipment/equipment_module.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'equipment_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_equipment_delete_test_');

  Future<Map<String, int>> prepareEquipment(
    WidgetTester tester, {
    int airConditionerServiceOrders = 0,
  }) async {
    final Map<String, int> ids = <String, int>{};
    await withDatabase(tester, (database) async {
      await clearEquipmentData(database);
      final int anaId = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      ids['Bebedouro industrial'] = await insertEquipment(
        database,
        customerId: anaId,
        type: 'Bebedouro industrial',
      );
      ids['Ar-condicionado split'] = await insertEquipment(
        database,
        customerId: anaId,
        type: 'Ar-condicionado split',
        brand: 'LG',
      );
      if (airConditionerServiceOrders > 0) {
        await insertServiceOrdersForEquipment(
          database,
          customerId: anaId,
          equipmentId: ids['Ar-condicionado split']!,
          count: airConditionerServiceOrders,
        );
      }
    });
    return ids;
  }

  Future<bool> equipmentExists(WidgetTester tester, int id) async {
    final List<Map<String, Object?>> rows = await queryEquipment(tester);
    return rows.any((Map<String, Object?> row) => row['id'] == id);
  }

  Future<void> openConfirmation(WidgetTester tester, int id) async {
    await tapAndPump(tester, find.byKey(EquipmentListView.deleteButtonKey(id)));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Excluir'),
      ),
      findsOneWidget,
    );
  }

  testWidgets('deletes equipment without service orders after confirmation', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareEquipment(tester);
    final int id = ids['Bebedouro industrial']!;
    await pumpEquipmentModule(tester);

    await openConfirmation(tester, id);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentModule.confirmDeleteButtonKey),
    );

    expect(await equipmentExists(tester, id), isFalse);
    expect(find.text('Bebedouro industrial'), findsNothing);
    expect(find.text('Ar-condicionado split'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Equipamento excluído.'),
      ),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets('blocks deletion of equipment with 3 service orders', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareEquipment(
      tester,
      airConditionerServiceOrders: 3,
    );
    final int id = ids['Ar-condicionado split']!;
    await pumpEquipmentModule(tester);

    await openConfirmation(tester, id);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentModule.confirmDeleteButtonKey),
    );

    expect(await equipmentExists(tester, id), isTrue);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(
          'Este equipamento possui 3 ordens de serviço vinculadas e não pode ser excluído.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Equipamento excluído.'), findsNothing);

    await tapAndPump(
      tester,
      find.byKey(EquipmentModule.closeBlockedDialogButtonKey),
    );

    expectNoDialogs();
    expect(find.text('Ar-condicionado split'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the equipment', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareEquipment(tester);
    final int id = ids['Bebedouro industrial']!;
    await pumpEquipmentModule(tester);

    await openConfirmation(tester, id);
    await tapAndWaitForDatabase(
      tester,
      find.byKey(EquipmentModule.cancelDeleteButtonKey),
    );

    expectNoDialogs();
    expect(await equipmentExists(tester, id), isTrue);
    expect(find.text('Bebedouro industrial'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('countLinks counts service orders of the equipment', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareEquipment(
      tester,
      airConditionerServiceOrders: 3,
    );
    int? linked;
    int? free;
    await tester.runAsync(() async {
      final EquipmentRepository repository = EquipmentRepository();
      linked = await repository.countLinks(ids['Ar-condicionado split']!);
      free = await repository.countLinks(ids['Bebedouro industrial']!);
    });
    expect(linked, 3);
    expect(free, 0);
  });

  test('blocked message uses singular for a single service order', () {
    expect(
      EquipmentController.blockedByLinkMessage(1),
      'Este equipamento possui 1 ordem de serviço vinculada e não pode ser excluído.',
    );
  });

  testWidgets(
    'shows a friendly message and keeps the equipment when deletion fails',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareEquipment(tester);
      final int id = ids['Bebedouro industrial']!;
      await pumpEquipmentModule(tester);
      await openConfirmation(tester, id);

      final String blockedPath = temporaryDatabase.blockedDirectory().path;
      await tester.runAsync(() => DatabaseHelper.instance.close());
      DatabaseHelper.databaseDirectoryOverride = blockedPath;

      await tapAndWaitForDatabase(
        tester,
        find.byKey(EquipmentModule.confirmDeleteButtonKey),
      );

      expect(
        find.text('Não foi possível excluir o equipamento. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Bebedouro industrial'), findsOneWidget);
      expectNoTechnicalErrorText();
      expectNoDialogs();

      DatabaseHelper.databaseDirectoryOverride =
          temporaryDatabase.directory.path;
      expect(await equipmentExists(tester, id), isTrue);
    },
  );
}
