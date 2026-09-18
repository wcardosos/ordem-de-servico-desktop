import 'package:flutter/foundation.dart';

import '../models/service_order_indicators.dart';
import '../repositories/service_order_repository.dart';
import '../services/database_helper.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({ServiceOrderRepository? repository})
    : _repository = repository ?? ServiceOrderRepository();

  static const String unavailableMessage =
      'Não foi possível carregar os indicadores.';

  final ServiceOrderRepository _repository;

  ServiceOrderIndicators _indicators = const ServiceOrderIndicators.empty();

  bool _loading = false;

  String? _error;

  ServiceOrderIndicators get indicators => _indicators;

  bool get loading => _loading;

  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _indicators = await _repository.findIndicators();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
