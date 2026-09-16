import 'package:flutter/foundation.dart';

import '../core/deletion_result.dart';
import '../core/service_order_status.dart';
import '../core/transition_result.dart';
import '../models/service_order.dart';
import '../repositories/service_order_repository.dart';
import '../services/database_helper.dart';

class ServiceOrderController extends ChangeNotifier {
  ServiceOrderController({ServiceOrderRepository? repository})
    : _repository = repository ?? ServiceOrderRepository();

  static const String unavailableMessage =
      'Não foi possível carregar as ordens de serviço.';

  static const String saveFailedMessage =
      'Não foi possível salvar a ordem de serviço. Tente novamente.';

  static const String deleteFailedMessage =
      'Não foi possível excluir a ordem de serviço. Tente novamente.';

  static const String statusChangeFailedMessage =
      'Não foi possível alterar o status. Tente novamente.';

  static const String deletedMessage = 'Ordem de serviço excluída.';

  static const String deletionBlockedMessage =
      'Só é possível excluir uma ordem com status Aberta. '
      'Para encerrar esta ordem, utilize o cancelamento.';

  static const String notFoundMessage = 'Ordem de serviço não encontrada.';

  final ServiceOrderRepository _repository;

  List<ServiceOrder> _orders = <ServiceOrder>[];

  bool _loading = false;

  String? _error;

  List<ServiceOrder> get orders => _orders;

  bool get loading => _loading;

  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.findAll();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> open(ServiceOrder order) {
    return _write(() => _repository.insert(order));
  }

  Future<bool> update(ServiceOrder order) {
    return _write(() => _repository.update(order));
  }

  Future<DeletionResult> delete(int id) async {
    try {
      final ServiceOrder? stored = await _repository.findById(id);
      if (stored != null && stored.status != ServiceOrderStatus.open) {
        return DeletionResult.blockedByLink;
      }
      await _repository.delete(id);
    } on DatabaseAccessException {
      _error = deleteFailedMessage;
      notifyListeners();
      return DeletionResult.failure;
    }
    _error = null;
    _orders = _orders.where((ServiceOrder order) => order.id != id).toList();
    notifyListeners();
    return DeletionResult.success;
  }

  Future<TransitionResult> changeStatus(
    ServiceOrder order,
    ServiceOrderStatus target,
  ) async {
    final TransitionResult result = order.validateTransitionTo(target);
    if (result != TransitionResult.allowed) {
      return result;
    }
    final DateTime now = DateTime.now();
    final ServiceOrder changed = order.withStatus(
      target,
      completedAt: target == ServiceOrderStatus.completed
          ? DateTime(now.year, now.month, now.day)
          : null,
    );
    _error = null;
    try {
      await _repository.update(changed);
    } on DatabaseAccessException {
      _error = statusChangeFailedMessage;
      notifyListeners();
      rethrow;
    }
    try {
      _orders = await _repository.findAll();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    }
    notifyListeners();
    return result;
  }

  Future<bool> _write(Future<Object?> Function() operation) async {
    _error = null;
    try {
      await operation();
    } on DatabaseAccessException {
      _error = saveFailedMessage;
      notifyListeners();
      return false;
    }
    try {
      _orders = await _repository.findAll();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    }
    notifyListeners();
    return true;
  }
}
