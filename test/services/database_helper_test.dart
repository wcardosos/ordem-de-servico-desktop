import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory supportDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    supportDirectory = Directory.systemTemp.createTempSync(
      'ordem_servico_test_',
    );
    DatabaseHelper.databaseDirectoryOverride = supportDirectory.path;
  });

  tearDown(() async {
    try {
      await DatabaseHelper.instance.close();
    } finally {
      DatabaseHelper.databaseDirectoryOverride = null;
      if (supportDirectory.existsSync()) {
        supportDirectory.deleteSync(recursive: true);
      }
    }
  });

  test('creates the database on first run', () async {
    final File databaseFile = File(
      p.join(supportDirectory.path, 'ordem_servico.db'),
    );
    expect(databaseFile.existsSync(), isFalse);

    final Database database = await DatabaseHelper.instance.database;

    expect(databaseFile.existsSync(), isTrue);
    expect(await database.getVersion(), 1);

    final List<Map<String, Object?>> tables = await database.query(
      'sqlite_master',
      columns: <String>['name'],
      where: 'type = ?',
      whereArgs: <Object?>['table'],
    );
    final List<Object?> tableNames = tables
        .map((Map<String, Object?> row) => row['name'])
        .toList();
    expect(
      tableNames,
      containsAll(<String>[
        'users',
        'customers',
        'technicians',
        'equipment',
        'service_orders',
        'part_items',
      ]),
    );

    final List<Map<String, Object?>> users = await database.query('users');
    expect(users, hasLength(1));
    expect(users.single['username'], 'admin');
    expect(users.single['password'], 'admin123');

    for (final String table in <String>[
      'customers',
      'technicians',
      'equipment',
      'service_orders',
      'part_items',
    ]) {
      expect(await database.query(table), isEmpty, reason: table);
    }
  });

  test('reopens the existing database without recreating it', () async {
    final Database firstRun = await DatabaseHelper.instance.database;
    expect(await firstRun.query('users'), hasLength(1));
    await DatabaseHelper.instance.close();

    final Database secondRun = await DatabaseHelper.instance.database;

    expect(identical(firstRun, secondRun), isFalse);
    expect(await secondRun.getVersion(), 1);
    final List<Map<String, Object?>> users = await secondRun.query('users');
    expect(users, hasLength(1));
    expect(users.single['username'], 'admin');
  });

  test('enables foreign keys on the open connection', () async {
    final Database database = await DatabaseHelper.instance.database;

    final List<Map<String, Object?>> result = await database.rawQuery(
      'PRAGMA foreign_keys',
    );

    expect(result.single.values.single, 1);
  });

  test(
    'reports a Portuguese message when the database file cannot be accessed',
    () async {
      final Directory blockedDirectory = Directory(
        p.join(supportDirectory.path, 'blocked'),
      )..createSync();
      final ProcessResult chmod = Process.runSync('chmod', <String>[
        '555',
        blockedDirectory.path,
      ]);
      expect(chmod.exitCode, 0);
      addTearDown(() {
        Process.runSync('chmod', <String>['700', blockedDirectory.path]);
      });
      DatabaseHelper.databaseDirectoryOverride = blockedDirectory.path;

      Object? captured;
      try {
        await DatabaseHelper.instance.database;
      } catch (error) {
        captured = error;
      }

      expect(captured, isA<DatabaseAccessException>());
      final DatabaseAccessException failure =
          captured! as DatabaseAccessException;
      expect(
        failure.message,
        'Não foi possível acessar os dados locais do aplicativo.',
      );
      expect(
        failure.toString(),
        'Não foi possível acessar os dados locais do aplicativo.',
      );
      expect(failure.toString(), isNot(contains('Exception')));
      expect(failure.toString(), isNot(contains('sqlite')));
      expect(
        File(p.join(blockedDirectory.path, 'ordem_servico.db')).existsSync(),
        isFalse,
      );
    },
  );
}
