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
