import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';
import '../services/database_helper.dart';

class CustomerRepository {
  CustomerRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const String tableName = 'customers';

  final DatabaseHelper _databaseHelper;

  Future<List<Customer>> findAll() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        orderBy: 'name',
      );
      return rows.map(Customer.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<Customer?> findById(int id) {
    throw UnimplementedError();
  }

  Future<int> save(Customer customer) async {
    final Database database = await _databaseHelper.database;
    final Map<String, Object?> values = customer.toMap()..remove('id');
    try {
      final int? id = customer.id;
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

  Future<int> countLinks(int customerId) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        'SELECT '
        '(SELECT COUNT(*) FROM equipment WHERE customer_id = ?) + '
        '(SELECT COUNT(*) FROM service_orders WHERE customer_id = ?) '
        'AS total',
        <Object?>[customerId, customerId],
      );
      return (rows.first['total'] as int?) ?? 0;
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }
}
