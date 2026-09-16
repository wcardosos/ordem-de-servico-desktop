import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/login_controller.dart';
import '../widgets/app_module.dart';
import '../widgets/side_navbar.dart';
import 'app_modules.dart';
import 'login_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.modules});

  final List<AppModule>? modules;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  List<AppModule> get _modules => widget.modules ?? appModules;

  void _signOut() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ChangeNotifierProvider<LoginController>(
              create: (BuildContext context) => LoginController(),
              child: const LoginScreen(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<AppModule> modules = _modules;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SideNavbar(
            modules: modules,
            selectedIndex: _selectedIndex,
            onSelected: (int index) => setState(() => _selectedIndex = index),
            onSignOut: _signOut,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: modules.isEmpty
                ? const SizedBox.shrink()
                : KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: modules[_selectedIndex].builder(context),
                  ),
          ),
        ],
      ),
    );
  }
}
