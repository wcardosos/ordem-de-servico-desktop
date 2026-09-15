import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'controllers/login_controller.dart';
import 'screens/login_screen.dart';
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

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final String? failure = errorMessage;
    return MaterialApp(
      title: 'Ordem de Serviço',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: failure != null
          ? Scaffold(body: Center(child: Text(failure)))
          : ChangeNotifierProvider<LoginController>(
              create: (BuildContext context) => LoginController(),
              child: const LoginScreen(),
            ),
    );
  }
}
