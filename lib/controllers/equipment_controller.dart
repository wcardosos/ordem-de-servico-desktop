import 'package:flutter/foundation.dart';

import '../core/deletion_result.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';
import '../services/database_helper.dart';

class EquipmentController extends ChangeNotifier {
  EquipmentController({EquipmentRepository? repository})
    : _repository = repository ?? EquipmentRepository();

  static const String unavailableMessage =
      'Não foi possível carregar os equipamentos.';

  static const String savedMessage = 'Equipamento salvo com sucesso.';

  static const String saveFailedMessage =
      'Não foi possível salvar o equipamento. Tente novamente.';

  static const String deletedMessage = 'Equipamento excluído.';

  static const String deleteFailedMessage =
      'Não foi possível excluir o equipamento. Tente novamente.';

  static String blockedByLinkMessage(int count) => count == 1
      ? 'Este equipamento possui 1 ordem de serviço vinculada e não pode ser excluído.'
      : 'Este equipamento possui $count ordens de serviço vinculadas e não pode ser excluído.';

  final EquipmentRepository _repository;

  List<Equipment> _equipment = <Equipment>[];

  bool _loading = false;

  bool _saving = false;

  String? _error;

  String? _saveError;

  int _linkCount = 0;

  List<Equipment> get equipment => _equipment;

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
      _equipment = await _repository.findAll();
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Equipment equipment) async {
    _saving = true;
    _saveError = null;
    notifyListeners();
    try {
      await _repository.save(equipment);
    } on DatabaseAccessException {
      _saveError = saveFailedMessage;
      _saving = false;
      notifyListeners();
      return false;
    }
    try {
      _equipment = await _repository.findAll();
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
    _equipment = _equipment
        .where((Equipment equipment) => equipment.id != id)
        .toList();
    notifyListeners();
    return DeletionResult.success;
  }
}
