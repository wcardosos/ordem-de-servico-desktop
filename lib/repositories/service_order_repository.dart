import 'package:sqflite/sqflite.dart';

import '../models/service_order.dart';
import '../services/database_helper.dart';

class ServiceOrderRepository {
  ServiceOrderRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const String tableName = 'service_orders';

  static const String _selectWithNames =
      'SELECT o.*, c.name AS customer_name, '
      "TRIM(e.type || COALESCE(' ' || NULLIF(TRIM(e.brand), ''), '') "
      "|| COALESCE(' ' || NULLIF(TRIM(e.model), ''), '')) "
      'AS equipment_description, '
      't.name AS technician_name '
      'FROM service_orders o '
      'JOIN customers c ON c.id = o.customer_id '
      'JOIN equipment e ON e.id = o.equipment_id '
      'LEFT JOIN technicians t ON t.id = o.technician_id';

  final DatabaseHelper _databaseHelper;

  Future<List<ServiceOrder>> findAll() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '$_selectWithNames ORDER BY o.due_date ASC, o.id ASC',
      );
      return rows.map(ServiceOrder.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<ServiceOrder?> findById(int id) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '$_selectWithNames WHERE o.id = ?',
        <Object?>[id],
      );
      return rows.isEmpty ? null : ServiceOrder.fromMap(rows.first);
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<int> insert(ServiceOrder order) async {
    final Database database = await _databaseHelper.database;
    try {
      return await database.transaction((Transaction transaction) async {
        final String number = await _nextNumberForYear(
          transaction,
          order.openedAt.year,
        );
        final Map<String, Object?> values = order.toMap()
          ..remove('id')
          ..['number'] = number;
        return transaction.insert(tableName, values);
      });
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<void> update(ServiceOrder order) async {
    final Database database = await _databaseHelper.database;
    final Map<String, Object?> values = order.toMap()
      ..remove('id')
      ..remove('number');
    try {
      await database.update(
        tableName,
        values,
        where: 'id = ?',
        whereArgs: <Object?>[order.id],
      );
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<void> delete(int id) async {
    final Database database = await _databaseHelper.database;
    try {
      await database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<String> nextNumber() async {
    final Database database = await _databaseHelper.database;
    try {
      return await _nextNumberForYear(database, DateTime.now().year);
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<String> _nextNumberForYear(DatabaseExecutor executor, int year) async {
    final String prefix = 'OS-$year-';
    final List<Map<String, Object?>> rows = await executor.rawQuery(
      'SELECT MAX(CAST(SUBSTR(number, ?) AS INTEGER)) AS highest '
      'FROM service_orders WHERE number LIKE ?',
      <Object?>[prefix.length + 1, '$prefix%'],
    );
    final int highest = (rows.first['highest'] as int?) ?? 0;
    return '$prefix${(highest + 1).toString().padLeft(4, '0')}';
  }
}
