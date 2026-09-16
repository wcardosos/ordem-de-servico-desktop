import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/technician_controller.dart';
import 'package:ordem_de_servico/models/technician.dart';
import 'package:ordem_de_servico/repositories/technician_repository.dart';
import 'package:ordem_de_servico/screens/technicians/technician_list_view.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'technicians_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_technician_list_test_');

  Finder labelInTile(String name, String label) {
    return find.descendant(
      of: find.widgetWithText(ListTile, name),
      matching: find.text(label),
    );
  }

  testWidgets('lists technicians ordered by name with their situation', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('technicians');
      await insertTechnician(
        database,
        name: 'Sérgio Lima',
        specialty: 'Redes',
        active: false,
      );
      await insertTechnician(
        database,
        name: 'Rafael Duarte',
        specialty: 'Refrigeração',
      );
      await insertTechnician(
        database,
        name: 'Bruno Alencar',
        specialty: 'Informática',
      );
    });

    await pumpTechniciansModule(tester);

    expect(find.text('Técnicos'), findsOneWidget);
    expect(find.byKey(TechnicianListView.addButtonKey), findsOneWidget);
    expect(find.byKey(TechnicianListView.listKey), findsOneWidget);
    final List<ListTile> tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .toList();
    expect(tiles, hasLength(3));
    expect((tiles[0].title! as Text).data, 'Bruno Alencar');
    expect((tiles[0].subtitle! as Text).data, 'Informática');
    expect((tiles[1].title! as Text).data, 'Rafael Duarte');
    expect((tiles[1].subtitle! as Text).data, 'Refrigeração');
    expect((tiles[2].title! as Text).data, 'Sérgio Lima');
    expect((tiles[2].subtitle! as Text).data, 'Redes');
    expect(labelInTile('Sérgio Lima', 'Inativo'), findsOneWidget);
    expect(labelInTile('Sérgio Lima', 'Ativo'), findsNothing);
    expect(labelInTile('Bruno Alencar', 'Ativo'), findsOneWidget);
    expect(labelInTile('Rafael Duarte', 'Ativo'), findsOneWidget);
    expect(labelInTile('Bruno Alencar', 'Inativo'), findsNothing);
    expect(labelInTile('Rafael Duarte', 'Inativo'), findsNothing);
    expectNoDialogs();
  });

  testWidgets('shows empty state when no technicians exist', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) => database.delete('technicians'));

    await pumpTechniciansModule(tester);

    expect(find.text('Nenhum técnico cadastrado.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byKey(TechnicianListView.listKey), findsNothing);
  });

  testWidgets('technician persists after closing and reopening the app', (
    WidgetTester tester,
  ) async {
    await withDatabase(tester, (database) async {
      await database.delete('technicians');
      await insertTechnician(
        database,
        name: 'Sérgio Lima',
        contact: '83988776655',
        specialty: 'Redes',
        active: false,
      );
      await DatabaseHelper.instance.close();
    });

    final TechnicianController controller = await pumpTechniciansModule(tester);

    expect(find.text('Sérgio Lima'), findsOneWidget);
    expect(controller.technicians, hasLength(1));
    final Technician technician = controller.technicians.single;
    expect(technician.name, 'Sérgio Lima');
    expect(technician.contact, '83988776655');
    expect(technician.specialty, 'Redes');
    expect(technician.active, isFalse);
  });

  testWidgets(
    'shows a friendly message and retry button when the database is unreadable',
    (WidgetTester tester) async {
      DatabaseHelper.databaseDirectoryOverride = temporaryDatabase
          .blockedDirectory()
          .path;

      await pumpTechniciansModule(tester);

      expect(
        find.text('Não foi possível carregar os técnicos.'),
        findsOneWidget,
      );
      expect(find.byKey(TechnicianListView.retryButtonKey), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expectNoTechnicalErrorText();
      expectNoDialogs();
    },
  );

  testWidgets('findActive returns only active technicians ordered by name', (
    WidgetTester tester,
  ) async {
    int? rafaelId;
    await withDatabase(tester, (database) async {
      await database.delete('technicians');
      await insertTechnician(database, name: 'Sérgio Lima', active: false);
      rafaelId = await insertTechnician(database, name: 'Rafael Duarte');
      await insertTechnician(database, name: 'Bruno Alencar');
    });
    List<Technician> active = <Technician>[];
    Technician? found;
    Technician? missing;
    await tester.runAsync(() async {
      final TechnicianRepository repository = TechnicianRepository();
      active = await repository.findActive();
      found = await repository.findById(rafaelId!);
      missing = await repository.findById(-1);
    });
    expect(
      active.map((Technician technician) => technician.name).toList(),
      <String>['Bruno Alencar', 'Rafael Duarte'],
    );
    expect(found?.name, 'Rafael Duarte');
    expect(found?.active, isTrue);
    expect(missing, isNull);
  });
}
