import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/customer_controller.dart';
import '../controllers/technician_controller.dart';
import '../widgets/app_module.dart';
import 'customers/customers_module.dart';
import 'technicians/technicians_module.dart';

final List<AppModule> appModules = <AppModule>[
  AppModule(
    label: 'Clientes',
    icon: Icons.people_outline,
    builder: (BuildContext context) =>
        ChangeNotifierProvider<CustomerController>(
          create: (BuildContext context) => CustomerController(),
          child: const CustomersModule(),
        ),
  ),
  AppModule(
    label: 'Técnicos',
    icon: Icons.engineering_outlined,
    builder: (BuildContext context) =>
        ChangeNotifierProvider<TechnicianController>(
          create: (BuildContext context) => TechnicianController(),
          child: const TechniciansModule(),
        ),
  ),
];
