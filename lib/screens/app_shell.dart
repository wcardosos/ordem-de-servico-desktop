import 'package:flutter/material.dart';

import '../widgets/app_module.dart';
import '../widgets/side_navbar.dart';
import 'app_modules.dart';
import 'app_routes.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.modules});

  final List<AppModule>? modules;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  int _selectedIndex = 0;

  List<AppModule> get _modules => widget.modules ?? appModules;

  void _selectModule(int index) {
    final List<AppModule> modules = _modules;
    if (index == _selectedIndex || index < 0 || index >= modules.length) {
      return;
    }
    setState(() => _selectedIndex = index);
    _navigatorKey.currentState?.pushReplacementNamed(modules[index].route);
  }

  Route<void> _generateModuleRoute(RouteSettings settings) {
    final List<AppModule> modules = _modules;
    final int index = modules.indexWhere(
      (AppModule module) => module.route == settings.name,
    );
    return AppRoutes.moduleRoute(modules[index < 0 ? 0 : index], settings);
  }

  List<Route<void>> _generateInitialModuleRoutes(
    NavigatorState navigator,
    String initialRoute,
  ) {
    return <Route<void>>[
      _generateModuleRoute(RouteSettings(name: initialRoute)),
    ];
  }

  void _signOut() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
            onSelected: _selectModule,
            onSignOut: _signOut,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: modules.isEmpty
                ? const SizedBox.shrink()
                : HeroControllerScope.none(
                    child: Navigator(
                      key: _navigatorKey,
                      initialRoute: modules.first.route,
                      onGenerateRoute: _generateModuleRoute,
                      onGenerateInitialRoutes: _generateInitialModuleRoutes,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
