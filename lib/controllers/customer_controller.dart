import 'package:flutter/foundation.dart';

import '../core/deletion_result.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../services/database_helper.dart';

class CustomerController extends ChangeNotifier {
  CustomerController({CustomerRepository? repository})
    : _repository = repository ?? CustomerRepository();

  static const String unavailableMessage =
      'Não foi possível carregar os clientes.';

  static const String savedMessage = 'Cliente salvo com sucesso.';

  static const String saveFailedMessage =
      'Não foi possível salvar o cliente. Tente novamente.';

  static const String deletedMessage = 'Cliente excluído.';

  static const String deleteFailedMessage =
      'Não foi possível excluir o cliente. Tente novamente.';

  static String blockedByLinkMessage(int count) => count == 1
      ? 'Este cliente possui 1 registro vinculado e não pode ser excluído.'
      : 'Este cliente possui $count registros vinculados e não pode ser excluído.';

  final CustomerRepository _repository;

  List<Customer> _customers = <Customer>[];

  bool _loading = false;

  bool _saving = false;

  String? _error;

  String? _saveError;

  int _linkCount = 0;

  List<Customer> get customers => _customers;

  bool get loading => _loading;

  bool get saving => _saving;

  String? get error => _error;

  String? get saveError => _saveError;

  int get linkCount => _linkCount;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _repository.findAll();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Customer customer) async {
    _saving = true;
    _saveError = null;
    notifyListeners();
    try {
      await _repository.save(customer);
    } on DatabaseAccessException {
      _saveError = saveFailedMessage;
      _saving = false;
      notifyListeners();
      return false;
    }
    try {
      _customers = await _repository.findAll();
      _error = null;
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _saving = false;
      notifyListeners();
    }
    return true;
  }

  Future<DeletionResult> delete(int id) async {
    try {
      final int links = await _repository.countLinks(id);
      if (links > 0) {
        _linkCount = links;
        return DeletionResult.blockedByLink;
      }
      await _repository.delete(id);
    } on DatabaseAccessException {
      return DeletionResult.failure;
    }
    _customers = _customers
        .where((Customer customer) => customer.id != id)
        .toList();
    notifyListeners();
    return DeletionResult.success;
  }
}
