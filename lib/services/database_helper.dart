import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/seed_data.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const int databaseVersion = 1;

  static const String databaseFileName = 'ordem_servico.db';

  static String? databaseDirectoryOverride;

  static const String enableForeignKeys = 'PRAGMA foreign_keys = ON';

  static const String createUsersTable = '''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
)''';

  static const String createCustomersTable = '''
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  document TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  address TEXT NOT NULL
)''';

  static const String createTechniciansTable = '''
CREATE TABLE technicians (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  contact TEXT NOT NULL,
  specialty TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1
)''';

  static const String createEquipmentTable = '''
CREATE TABLE equipment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  serial_number TEXT,
  asset_tag TEXT,
  notes TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers (id)
)''';

  static const String createServiceOrdersTable = '''
CREATE TABLE service_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  number TEXT NOT NULL UNIQUE,
  customer_id INTEGER NOT NULL,
  equipment_id INTEGER NOT NULL,
  technician_id INTEGER,
  problem_description TEXT NOT NULL,
  priority TEXT NOT NULL,
  status TEXT NOT NULL,
  opened_at TEXT NOT NULL,
  due_date TEXT NOT NULL,
  completed_at TEXT,
  diagnosis TEXT,
  solution TEXT,
  labor_cost REAL NOT NULL DEFAULT 0,
  image_path TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (equipment_id) REFERENCES equipment (id),
  FOREIGN KEY (technician_id) REFERENCES technicians (id)
)''';

  static const String createPartItemsTable = '''
CREATE TABLE part_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  service_order_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  FOREIGN KEY (service_order_id) REFERENCES service_orders (id)
)''';

  static const List<String> createTableStatements = <String>[
    createUsersTable,
    createCustomersTable,
    createTechniciansTable,
    createEquipmentTable,
    createServiceOrdersTable,
    createPartItemsTable,
  ];

  Future<Database>? _connection;

  Future<Database> get database => _connection ??= _open();

  Future<void> close() async {
    final Future<Database>? pending = _connection;
    _connection = null;
    if (pending == null) {
      return;
    }
    try {
      final Database database = await pending;
      await database.close();
    } on DatabaseAccessException {
      return;
    }
  }

  Future<Database> _open() async {
    try {
      final String directoryPath =
          databaseDirectoryOverride ??
          (await getApplicationSupportDirectory()).path;
      await Directory(directoryPath).create(recursive: true);
      return await openDatabase(
        p.join(directoryPath, databaseFileName),
        version: databaseVersion,
        onConfigure: _configureConnection,
        onCreate: _createSchema,
      );
    } catch (_) {
      _connection = null;
      throw const DatabaseAccessException();
    }
  }

  Future<void> _configureConnection(Database database) async {
    await database.execute(enableForeignKeys);
  }

  Future<void> _createSchema(Database database, int version) async {
    final Batch batch = database.batch();
    for (final String statement in createTableStatements) {
      batch.execute(statement);
    }
    batch.insert('users', <String, Object?>{
      'username': 'admin',
      'password': 'admin123',
    });
    for (final Map<String, Object?> customer in seedCustomers) {
      batch.insert('customers', customer);
    }
    for (final Map<String, Object?> equipment in seedEquipment) {
      batch.insert('equipment', equipment);
    }
    for (final Map<String, Object?> technician in seedTechnicians) {
      batch.insert('technicians', technician);
    }
    for (final Map<String, Object?> order in seedServiceOrders(
      DateTime.now(),
    )) {
      batch.insert('service_orders', order);
    }
    for (final Map<String, Object?> partItem in seedPartItems) {
      batch.insert('part_items', partItem);
    }
    await batch.commit(noResult: true);
  }
}

class DatabaseAccessException implements Exception {
  const DatabaseAccessException();

  String get message =>
      'Não foi possível acessar os dados locais do aplicativo.';

  @override
  String toString() => message;
}
