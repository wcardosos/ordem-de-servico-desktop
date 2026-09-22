import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/app_routes.dart';
import 'services/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  String? errorMessage;
  try {
    await DatabaseHelper.instance.database;
  } on DatabaseAccessException catch (failure) {
    errorMessage = failure.message;
  }

  runApp(ServiceOrderApp(errorMessage: errorMessage));
}

class ServiceOrderApp extends StatelessWidget {
  const ServiceOrderApp({super.key, this.errorMessage});

  static const String _title = 'Ordem de Serviço';

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final String? failure = errorMessage;
    final ThemeData theme = ThemeData(colorSchemeSeed: Colors.indigo);
    if (failure != null) {
      return MaterialApp(
        title: _title,
        theme: theme,
        home: Scaffold(body: Center(child: Text(failure))),
      );
    }
    return MaterialApp(
      title: _title,
      theme: theme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
