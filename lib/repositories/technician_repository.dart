import 'package:sqflite/sqflite.dart';

import '../models/technician.dart';
import '../services/database_helper.dart';

class TechnicianRepository {
  TechnicianRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const String tableName = 'technicians';

  final DatabaseHelper _databaseHelper;

  Future<List<Technician>> findAll() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        orderBy: 'name',
      );
      return rows.map(Technician.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<List<Technician>> findActive() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        where: 'active = 1',
        orderBy: 'name',
      );
      return rows.map(Technician.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<Technician?> findById(int id) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      return rows.isEmpty ? null : Technician.fromMap(rows.first);
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<int> save(Technician technician) async {
    final Database database = await _databaseHelper.database;
    final Map<String, Object?> values = technician.toMap()..remove('id');
    try {
      final int? id = technician.id;
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

  Future<int> countLinks(int technicianId) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        'SELECT COUNT(*) AS total FROM service_orders WHERE technician_id = ?',
        <Object?>[technicianId],
      );
      return (rows.first['total'] as int?) ?? 0;
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }
}
