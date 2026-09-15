import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../services/database_helper.dart';

class UserRepository {
  UserRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const String tableName = 'users';

  final DatabaseHelper _databaseHelper;

  Future<List<User>> findAll() async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        orderBy: 'username',
      );
      return rows.map(User.fromMap).toList();
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<User?> findById(int id) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      return rows.isEmpty ? null : User.fromMap(rows.first);
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<User?> findByCredentials({
    required String username,
    required String password,
  }) async {
    final Database database = await _databaseHelper.database;
    try {
      final List<Map<String, Object?>> rows = await database.query(
        tableName,
        where: 'username = ? AND password = ?',
        whereArgs: <Object?>[username, password],
        limit: 1,
      );
      return rows.isEmpty ? null : User.fromMap(rows.first);
    } catch (_) {
      throw const DatabaseAccessException();
    }
  }

  Future<User> save(User user) async {
    final Database database = await _databaseHelper.database;
    final Map<String, Object?> values = user.toMap()..remove('id');
    try {
      final int? id = user.id;
      if (id == null) {
        final int createdId = await database.insert(tableName, values);
        return User(
          id: createdId,
          username: user.username,
          password: user.password,
        );
      }
      await database.update(
        tableName,
        values,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      return user;
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
}
