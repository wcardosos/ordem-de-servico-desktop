import 'package:sqflite/sqflite.dart';

import '../models/equipment.dart';
import '../services/database_helper.dart';

class EquipmentRepository {
  EquipmentRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const String tableName = 'equipment';

  static const String _selectWithCustomer =
      'SELECT e.id, e.customer_id, e.type, e.brand, e.model, '
      'e.serial_number, e.asset_tag, e.notes, c.name AS customer_name '
      'FROM equipment e '
      'JOIN customers c ON c.id = e.customer_id';

  final DatabaseHelper _databaseHelper;

  Future<List<Equipment>> findAll() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '$_selectWithCustomer ORDER BY e.type, e.id',
      );
      return rows.map(Equipment.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<List<Equipment>> findByCustomer(int customerId) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '$_selectWithCustomer WHERE e.customer_id = ? ORDER BY e.type, e.id',
        <Object?>[customerId],
      );
      return rows.map(Equipment.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<Equipment?> findById(int id) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '$_selectWithCustomer WHERE e.id = ?',
        <Object?>[id],
      );
      return rows.isEmpty ? null : Equipment.fromMap(rows.first);
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<int> save(Equipment equipment) async {
    final Database database = await _databaseHelper.database;
    final Map<String, Object?> values = equipment.toMap()..remove('id');
    try {
      final int? id = equipment.id;
      if (id == null) {
        return await database.insert(tableName, values);
      }
      await database.update(
        tableName,
        values,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      return id;
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

  Future<int> countLinks(int equipmentId) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        'SELECT COUNT(*) AS total FROM service_orders WHERE equipment_id = ?',
        <Object?>[equipmentId],
      );
      return (rows.first['total'] as int?) ?? 0;
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }
}
