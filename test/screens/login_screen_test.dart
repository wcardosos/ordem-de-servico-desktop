import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/login_controller.dart';
import 'package:ordem_de_servico/models/user.dart';
import 'package:ordem_de_servico/repositories/user_repository.dart';
import 'package:ordem_de_servico/screens/home_screen.dart';
import 'package:ordem_de_servico/screens/login_screen.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CountingUserRepository extends UserRepository {
  int credentialQueryCount = 0;

  @override
  Future<User?> findByCredentials({
    required String username,
    required String password,
  }) {
    credentialQueryCount += 1;
    return super.findByCredentials(username: username, password: password);
  }
}

void main() {
  late Directory supportDirectory;
  late CountingUserRepository repository;
  late LoginController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    supportDirectory = Directory.systemTemp.createTempSync(
      'ordem_servico_login_test_',
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

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    repository = CountingUserRepository();
    controller = LoginController(repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<LoginController>.value(
        value: controller,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }

  Future<void> signIn(
    WidgetTester tester, {
    required String username,
    required String password,
  }) async {
    await tester.enterText(find.byKey(LoginScreen.usernameFieldKey), username);
    await tester.enterText(find.byKey(LoginScreen.passwordFieldKey), password);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'signs in with valid credentials and leaves no login screen on the navigation stack',
    (WidgetTester tester) async {
      await pumpLoginScreen(tester);

      await signIn(tester, username: 'admin', password: 'admin123');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
      expect(repository.credentialQueryCount, 1);
      expect(controller.authenticatedUser?.username, 'admin');
    },
  );

  testWidgets('rejects a wrong password', (WidgetTester tester) async {
    await pumpLoginScreen(tester);

    await signIn(tester, username: 'admin', password: 'errada');

    expect(find.text('Usuário ou senha inválidos.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(repository.credentialQueryCount, 1);
    expect(controller.authenticatedUser, isNull);
    await dismissSnackBar(tester);
  });

  testWidgets('rejects an unknown username', (WidgetTester tester) async {
    await pumpLoginScreen(tester);

    await signIn(tester, username: 'joao', password: 'admin123');

    expect(find.text('Usuário ou senha inválidos.'), findsOneWidget);
    expect(find.text('Usuário não encontrado.'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(repository.credentialQueryCount, 1);
    await dismissSnackBar(tester);
  });

  testWidgets('blocks an empty username before any database query', (
    WidgetTester tester,
  ) async {
    await pumpLoginScreen(tester);

    await signIn(tester, username: '', password: 'admin123');

    expect(find.text('Informe o usuário.'), findsOneWidget);
    expect(repository.credentialQueryCount, 0);
    expect(find.byType(HomeScreen), findsNothing);
    expect(
      File(p.join(supportDirectory.path, 'ordem_servico.db')).existsSync(),
      isFalse,
    );
  });

  testWidgets('blocks an empty password before any database query', (
    WidgetTester tester,
  ) async {
    await pumpLoginScreen(tester);

    await signIn(tester, username: 'admin', password: '');

    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(repository.credentialQueryCount, 0);
    expect(find.byType(HomeScreen), findsNothing);
    expect(
      File(p.join(supportDirectory.path, 'ordem_servico.db')).existsSync(),
      isFalse,
    );
  });

  testWidgets('blocks both empty fields before any database query', (
    WidgetTester tester,
  ) async {
    await pumpLoginScreen(tester);

    await signIn(tester, username: '', password: '');

    expect(find.text('Informe o usuário.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(repository.credentialQueryCount, 0);
    expect(find.byType(HomeScreen), findsNothing);
    expect(
      File(p.join(supportDirectory.path, 'ordem_servico.db')).existsSync(),
      isFalse,
    );
  });

  testWidgets('reports an unreadable database without exception text', (
    WidgetTester tester,
  ) async {
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
    await pumpLoginScreen(tester);

    await signIn(tester, username: 'admin', password: 'admin123');

    expect(
      find.text('Não foi possível validar o acesso. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('sqlite'), findsNothing);
    expect(find.textContaining('#0'), findsNothing);
    expect(repository.credentialQueryCount, 1);
    await dismissSnackBar(tester);
  });
}
