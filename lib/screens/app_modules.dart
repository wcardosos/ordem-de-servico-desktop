import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/customer_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/service_order_controller.dart';
import '../controllers/technician_controller.dart';
import '../widgets/app_module.dart';
import 'customers/customers_module.dart';
import 'dashboard/dashboard_module.dart';
import 'equipment/equipment_module.dart';
import 'service_orders/service_orders_module.dart';
import 'technicians/technicians_module.dart';

final List<AppModule> appModules = <AppModule>[
  AppModule(
    label: 'Painel',
    icon: Icons.dashboard_outlined,
    builder: (BuildContext context) =>
        ChangeNotifierProvider<DashboardController>(
          create: (BuildContext context) => DashboardController(),
          child: const DashboardModule(),
        ),
  ),
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
  AppModule(
    label: 'Equipamentos',
    icon: Icons.devices_other_outlined,
    builder: (BuildContext context) =>
        ChangeNotifierProvider<EquipmentController>(
          create: (BuildContext context) => EquipmentController(),
          child: const EquipmentModule(),
        ),
  ),
  AppModule(
    label: 'Ordens de serviço',
    icon: Icons.assignment_outlined,
    builder: (BuildContext context) =>
        ChangeNotifierProvider<ServiceOrderController>(
          create: (BuildContext context) => ServiceOrderController(),
          child: const ServiceOrdersModule(),
        ),
  ),
];
