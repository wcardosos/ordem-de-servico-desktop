import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import 'dashboard_view.dart';

class DashboardModule extends StatefulWidget {
  const DashboardModule({super.key});

  @override
  State<DashboardModule> createState() => _DashboardModuleState();
}

class _DashboardModuleState extends State<DashboardModule> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<DashboardController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardView();
  }
}
