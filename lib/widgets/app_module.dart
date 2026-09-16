import 'package:flutter/widgets.dart';

class AppModule {
  const AppModule({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;

  final IconData icon;

  final WidgetBuilder builder;
}
