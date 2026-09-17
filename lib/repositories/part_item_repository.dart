import 'package:sqflite/sqflite.dart';

import '../models/part_item.dart';
import '../services/database_helper.dart';

class PartItemRepository {
  PartItemRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const String tableName = 'part_items';

  final DatabaseHelper _databaseHelper;

  Future<List<PartItem>> findByServiceOrder(int serviceOrderId) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        where: 'service_order_id = ?',
        whereArgs: <Object?>[serviceOrderId],
        orderBy: 'id ASC',
      );
      return rows.map(PartItem.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<int> insert(PartItem item) async {
    final Database database = await _databaseHelper.database;
    try {
      return await database.insert(tableName, item.toMap()..remove('id'));
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

  Future<void> deleteByServiceOrder(int serviceOrderId) async {
    final Database database = await _databaseHelper.database;
    try {
      await database.delete(
        tableName,
        where: 'service_order_id = ?',
        whereArgs: <Object?>[serviceOrderId],
      );
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<double> sumAllOrders() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        'SELECT COALESCE(SUM(quantity * unit_price), 0) AS parts_total '
        'FROM $tableName',
      );
      return ((rows.first['parts_total'] as num?) ?? 0).toDouble();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }
}
