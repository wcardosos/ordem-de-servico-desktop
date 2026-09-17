import '../models/service_order.dart';
import 'priority.dart';
import 'service_order_status.dart';

const List<Map<String, Object?>> seedCustomers = <Map<String, Object?>>[
  <String, Object?>{
    'name': 'Ana Ribeiro',
    'document': '11122233344',
    'phone': '11912345678',
    'email': 'ana.ribeiro@example.com',
    'address': 'Rua das Acácias, 120, São Paulo - SP',
  },
  <String, Object?>{
    'name': 'Carlos Menezes',
    'document': '22233344455',
    'phone': '2132654321',
    'email': 'carlos.menezes@example.com',
    'address': 'Avenida Brasil, 850, Rio de Janeiro - RJ',
  },
  <String, Object?>{
    'name': 'Marcos Vieira',
    'document': '33444555000166',
    'phone': '31998761234',
    'email': 'marcos.vieira@example.com',
    'address': 'Rua Minas Gerais, 45, Belo Horizonte - MG',
  },
];

const List<Map<String, Object?>> seedEquipment = <Map<String, Object?>>[
  <String, Object?>{
    'customer_id': 1,
    'type': 'Ar-condicionado split',
    'brand': 'LG',
    'model': 'Dual Inverter',
    'serial_number': 'SN-99120',
    'asset_tag': 'PAT-014',
    'notes': 'Instalado na sala de reuniões',
  },
  <String, Object?>{
    'customer_id': 1,
    'type': 'Impressora multifuncional',
    'brand': 'HP',
    'model': 'LaserJet M428',
    'serial_number': 'BRB1234567',
    'asset_tag': null,
    'notes': null,
  },
  <String, Object?>{
    'customer_id': 2,
    'type': 'Notebook',
    'brand': 'Dell',
    'model': 'Latitude 5420',
    'serial_number': 'DL-5420-883',
    'asset_tag': 'PAT-201',
    'notes': null,
  },
  <String, Object?>{
    'customer_id': 2,
    'type': 'Bebedouro industrial',
    'brand': null,
    'model': null,
    'serial_number': null,
    'asset_tag': null,
    'notes': null,
  },
  <String, Object?>{
    'customer_id': 3,
    'type': 'Nobreak',
    'brand': 'SMS',
    'model': 'Station II 1400VA',
    'serial_number': null,
    'asset_tag': 'MV-007',
    'notes': 'Alimenta o servidor do escritório',
  },
];

const List<Map<String, Object?>> seedTechnicians = <Map<String, Object?>>[
  <String, Object?>{
    'name': 'Bruno Alencar',
    'contact': '83998871122',
    'specialty': 'Informática',
    'active': 1,
  },
  <String, Object?>{
    'name': 'Rafael Duarte',
    'contact': '83997772211',
    'specialty': 'Refrigeração',
    'active': 1,
  },
  <String, Object?>{
    'name': 'Sérgio Lima',
    'contact': '8332214455',
    'specialty': 'Redes e telefonia',
    'active': 0,
  },
];

const List<Map<String, Object?>> seedPartItems = <Map<String, Object?>>[
  <String, Object?>{
    'service_order_id': 1,
    'description': 'Bateria selada 12V 7Ah',
    'quantity': 2,
    'unit_price': 189.90,
  },
  <String, Object?>{
    'service_order_id': 3,
    'description': 'Cabo flat de vídeo',
    'quantity': 1,
    'unit_price': 145.00,
  },
  <String, Object?>{
    'service_order_id': 4,
    'description': 'Rolete de tração',
    'quantity': 1,
    'unit_price': 98.50,
  },
  <String, Object?>{
    'service_order_id': 4,
    'description': 'Kit de limpeza de roletes',
    'quantity': 3,
    'unit_price': 24.90,
  },
  <String, Object?>{
    'service_order_id': 6,
    'description': 'Gás refrigerante R410A',
    'quantity': 2,
    'unit_price': 95.50,
  },
  <String, Object?>{
    'service_order_id': 6,
    'description': 'Filtro secador',
    'quantity': 1,
    'unit_price': 72.00,
  },
];

List<Map<String, Object?>> seedServiceOrders(DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  final List<ServiceOrder> orders = <ServiceOrder>[
    ServiceOrder(
      number: '',
      customerId: 3,
      equipmentId: 5,
      technicianId: 2,
      problemDescription: 'Nobreak emite bipes e não segura carga',
      priority: Priority.low,
      status: ServiceOrderStatus.completed,
      openedAt: day(-30),
      dueDate: day(-20),
      completedAt: day(-22),
      diagnosis: 'Bateria interna sem capacidade',
      solution: 'Bateria substituída e autonomia testada',
      laborCost: 180.00,
    ),
    ServiceOrder(
      number: '',
      customerId: 1,
      equipmentId: 1,
      problemDescription: 'Cliente desistiu da manutenção preventiva',
      priority: Priority.medium,
      status: ServiceOrderStatus.cancelled,
      openedAt: day(-25),
      dueDate: day(-15),
    ),
    ServiceOrder(
      number: '',
      customerId: 2,
      equipmentId: 3,
      technicianId: 1,
      problemDescription: 'Tela piscando e desligamentos aleatórios',
      priority: Priority.urgent,
      status: ServiceOrderStatus.completed,
      openedAt: day(-15),
      dueDate: day(-12),
      completedAt: day(-13),
      diagnosis: 'Cabo flat da tela danificado',
      solution: 'Cabo flat substituído',
      laborCost: 220.00,
    ),
    ServiceOrder(
      number: '',
      customerId: 1,
      equipmentId: 2,
      technicianId: 1,
      problemDescription: 'Atolamento de papel constante',
      priority: Priority.medium,
      status: ServiceOrderStatus.awaitingPart,
      openedAt: day(-12),
      dueDate: day(-1),
      diagnosis: 'Rolete de tração gasto',
      laborCost: 150.00,
    ),
    ServiceOrder(
      number: '',
      customerId: 2,
      equipmentId: 3,
      technicianId: 1,
      problemDescription: 'Não reconhece o carregador',
      priority: Priority.high,
      status: ServiceOrderStatus.assigned,
      openedAt: day(-10),
      dueDate: day(-3),
      laborCost: 130.00,
    ),
    ServiceOrder(
      number: '',
      customerId: 2,
      equipmentId: 4,
      technicianId: 2,
      problemDescription: 'Água saindo em temperatura ambiente',
      priority: Priority.high,
      status: ServiceOrderStatus.inProgress,
      openedAt: day(-6),
      dueDate: day(3),
      laborCost: 240.00,
    ),
    ServiceOrder(
      number: '',
      customerId: 1,
      equipmentId: 1,
      problemDescription: 'Não está gelando',
      priority: Priority.urgent,
      status: ServiceOrderStatus.open,
      openedAt: day(-5),
      dueDate: day(-2),
    ),
    ServiceOrder(
      number: '',
      customerId: 1,
      equipmentId: 1,
      technicianId: 2,
      problemDescription: 'Barulho excessivo na unidade externa',
      priority: Priority.medium,
      status: ServiceOrderStatus.assigned,
      openedAt: day(-4),
      dueDate: day(5),
    ),
    ServiceOrder(
      number: '',
      customerId: 3,
      equipmentId: 5,
      technicianId: 1,
      problemDescription: 'Desliga ao alternar para a bateria',
      priority: Priority.urgent,
      status: ServiceOrderStatus.inProgress,
      laborCost: 190.00,
      openedAt: day(-3),
      dueDate: day(1),
    ),
    ServiceOrder(
      number: '',
      customerId: 3,
      equipmentId: 5,
      problemDescription: 'Revisão preventiva anual',
      priority: Priority.low,
      status: ServiceOrderStatus.open,
      openedAt: day(-1),
      dueDate: day(10),
    ),
  ];

  final Map<int, int> sequenceByYear = <int, int>{};
  return orders.map((ServiceOrder order) {
    final int year = order.openedAt.year;
    final int sequence = (sequenceByYear[year] ?? 0) + 1;
    sequenceByYear[year] = sequence;
    return order.toMap()
      ..remove('id')
      ..['number'] = 'OS-$year-${sequence.toString().padLeft(4, '0')}';
  }).toList();
}
