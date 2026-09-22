import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/login_controller.dart';
import '../widgets/app_module.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';

  static const String shell = '/shell';

  static const String dashboard = '/dashboard';

  static const String customers = '/customers';

  static const String technicians = '/technicians';

  static const String equipment = '/equipment';

  static const String serviceOrders = '/service-orders';

  static const Duration moduleTransitionDuration = Duration(milliseconds: 200);

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    login: (BuildContext context) => ChangeNotifierProvider<LoginController>(
      create: (BuildContext context) => LoginController(),
      child: const LoginScreen(),
    ),
    shell: (BuildContext context) => const AppShell(),
  };

  static Route<void> moduleRoute(AppModule module, RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: moduleTransitionDuration,
      reverseTransitionDuration: moduleTransitionDuration,
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) => module.builder(context),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
    );
  }
}
