import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/technician_controller.dart';
import 'package:ordem_de_servico/repositories/technician_repository.dart';
import 'package:ordem_de_servico/screens/technicians/technician_delete_view.dart';
import 'package:ordem_de_servico/screens/technicians/technician_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'technicians_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_technician_delete_test_');

  Future<Map<String, int>> prepareTechnicians(
    WidgetTester tester, {
    int brunoServiceOrders = 0,
  }) async {
    final Map<String, int> ids = <String, int>{};
    await withDatabase(tester, (database) async {
      await database.delete('technicians');
      ids['Bruno Alencar'] = await insertTechnician(
        database,
        name: 'Bruno Alencar',
      );
      ids['Rafael Duarte'] = await insertTechnician(
        database,
        name: 'Rafael Duarte',
        specialty: 'Refrigeração',
      );
      if (brunoServiceOrders > 0) {
        await insertServiceOrdersForTechnician(
          database,
          technicianId: ids['Bruno Alencar']!,
          count: brunoServiceOrders,
        );
      }
    });
    return ids;
  }

  Future<bool> technicianExists(WidgetTester tester, int id) async {
    bool exists = false;
    await withDatabase(tester, (database) async {
      final List<Map<String, Object?>> rows = await database.query(
        'technicians',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      exists = rows.isNotEmpty;
    });
    return exists;
  }

  Future<void> openDeleteView(WidgetTester tester, int id, String name) async {
    await tapAndPump(
      tester,
      find.byKey(TechnicianListView.deleteButtonKey(id)),
    );
    expect(find.byType(TechnicianDeleteView), findsOneWidget);
    expect(find.byType(TechnicianListView), findsNothing);
    expect(find.text('Deseja excluir o técnico "$name"?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
    expectNoDialogs();
  }

  testWidgets(
    'deletes a technician without service orders after confirmation',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareTechnicians(tester);
      final int rafaelId = ids['Rafael Duarte']!;
      await pumpTechniciansModule(tester);

      await openDeleteView(tester, rafaelId, 'Rafael Duarte');
      await tapAndWaitForDatabase(
        tester,
        find.byKey(TechnicianDeleteView.confirmButtonKey),
      );

      expect(find.byType(TechnicianDeleteView), findsNothing);
      expect(await technicianExists(tester, rafaelId), isFalse);
      expect(find.text('Rafael Duarte'), findsNothing);
      expect(find.text('Bruno Alencar'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Técnico excluído.'),
        ),
        findsOneWidget,
      );
      expectNoDialogs();
    },
  );

  testWidgets('blocks deletion of a technician with 4 service orders', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareTechnicians(
      tester,
      brunoServiceOrders: 4,
    );
    final int brunoId = ids['Bruno Alencar']!;
    await pumpTechniciansModule(tester);

    await openDeleteView(tester, brunoId, 'Bruno Alencar');
    await tapAndWaitForDatabase(
      tester,
      find.byKey(TechnicianDeleteView.confirmButtonKey),
    );

    expect(await technicianExists(tester, brunoId), isTrue);
    expect(find.byType(TechnicianListView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(TechnicianListView.noticeKey),
        matching: find.text(
          'Este técnico possui 4 ordens de serviço vinculadas e não pode ser excluído.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Bruno Alencar'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expectNoDialogs();

    await tapAndPump(
      tester,
      find.byKey(TechnicianListView.dismissNoticeButtonKey),
    );

    expect(find.byKey(TechnicianListView.noticeKey), findsNothing);
    expect(find.text('Bruno Alencar'), findsOneWidget);
  });

  test('blocked message uses singular for a single service order', () {
    expect(
      TechnicianController.blockedByLinkMessage(1),
      'Este técnico possui 1 ordem de serviço vinculada e não pode ser excluído.',
    );
    expect(
      TechnicianController.blockedByLinkMessage(4),
      'Este técnico possui 4 ordens de serviço vinculadas e não pode ser excluído.',
    );
  });

  testWidgets('countLinks counts service orders assigned to the technician', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareTechnicians(
      tester,
      brunoServiceOrders: 4,
    );
    int? brunoLinks;
    int? rafaelLinks;
    await tester.runAsync(() async {
      final TechnicianRepository repository = TechnicianRepository();
      brunoLinks = await repository.countLinks(ids['Bruno Alencar']!);
      rafaelLinks = await repository.countLinks(ids['Rafael Duarte']!);
    });
    expect(brunoLinks, 4);
    expect(rafaelLinks, 0);
  });

  testWidgets('cancelling the confirmation keeps the technician', (
    WidgetTester tester,
  ) async {
    final Map<String, int> ids = await prepareTechnicians(tester);
    final int rafaelId = ids['Rafael Duarte']!;
    await pumpTechniciansModule(tester);

    await openDeleteView(tester, rafaelId, 'Rafael Duarte');
    await tapAndPump(tester, find.byKey(TechnicianDeleteView.cancelButtonKey));

    expect(find.byType(TechnicianDeleteView), findsNothing);
    expect(await technicianExists(tester, rafaelId), isTrue);
    expect(find.text('Rafael Duarte'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expectNoDialogs();
  });

  testWidgets(
    'shows a friendly message and keeps the technician when deletion fails',
    (WidgetTester tester) async {
      final Map<String, int> ids = await prepareTechnicians(tester);
      final int rafaelId = ids['Rafael Duarte']!;
      await pumpTechniciansModule(tester);
      await openDeleteView(tester, rafaelId, 'Rafael Duarte');

      final String blockedPath = temporaryDatabase.blockedDirectory().path;
      await tester.runAsync(() => DatabaseHelper.instance.close());
      DatabaseHelper.databaseDirectoryOverride = blockedPath;

      await tapAndWaitForDatabase(
        tester,
        find.byKey(TechnicianDeleteView.confirmButtonKey),
      );

      expect(
        find.text('Não foi possível excluir o técnico. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Rafael Duarte'), findsOneWidget);
      expect(find.byKey(TechnicianListView.errorViewKey), findsNothing);
      expectNoTechnicalErrorText();
      expectNoDialogs();

      DatabaseHelper.databaseDirectoryOverride =
          temporaryDatabase.directory.path;
      expect(await technicianExists(tester, rafaelId), isTrue);
    },
  );
}
