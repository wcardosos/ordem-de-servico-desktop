import 'package:flutter/foundation.dart';

import '../core/deletion_result.dart';
import '../models/technician.dart';
import '../repositories/technician_repository.dart';
import '../services/database_helper.dart';

class TechnicianController extends ChangeNotifier {
  TechnicianController({TechnicianRepository? repository})
    : _repository = repository ?? TechnicianRepository();

  static const String unavailableMessage =
      'Não foi possível carregar os técnicos.';

  static const String savedMessage = 'Técnico salvo com sucesso.';

  static const String saveFailedMessage =
      'Não foi possível salvar o técnico. Tente novamente.';

  static const String deletedMessage = 'Técnico excluído.';

  static const String deleteFailedMessage =
      'Não foi possível excluir o técnico. Tente novamente.';

  static String blockedByLinkMessage(int count) => count == 1
      ? 'Este técnico possui 1 ordem de serviço vinculada e não pode ser excluído.'
      : 'Este técnico possui $count ordens de serviço vinculadas e não pode ser excluído.';

  final TechnicianRepository _repository;

  List<Technician> _technicians = <Technician>[];

  bool _loading = false;

  bool _saving = false;

  String? _error;

  String? _saveError;

  int _linkCount = 0;

  List<Technician> get technicians => _technicians;

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
      _technicians = await _repository.findAll();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Technician technician) async {
    _saving = true;
    _saveError = null;
    notifyListeners();
    try {
      await _repository.save(technician);
    } on DatabaseAccessException {
      _saveError = saveFailedMessage;
      _saving = false;
      notifyListeners();
      return false;
    }
    try {
      _technicians = await _repository.findAll();
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
    _technicians = _technicians
        .where((Technician technician) => technician.id != id)
        .toList();
    notifyListeners();
    return DeletionResult.success;
  }
}
