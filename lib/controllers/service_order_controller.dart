import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/deletion_result.dart';
import '../core/service_order_filter.dart';
import '../core/service_order_status.dart';
import '../core/transition_result.dart';
import '../models/part_item.dart';
import '../models/service_order.dart';
import '../repositories/part_item_repository.dart';
import '../repositories/service_order_repository.dart';
import '../services/database_helper.dart';
import '../services/image_service.dart';

class ServiceOrderController extends ChangeNotifier {
  ServiceOrderController({
    ServiceOrderRepository? repository,
    PartItemRepository? partItemRepository,
    ImageService? imageService,
  }) : _repository = repository ?? ServiceOrderRepository(),
       _partItemRepository = partItemRepository ?? PartItemRepository(),
       _imageService = imageService ?? ImageService();

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

  static const String unacceptedImageMessage =
      'Selecione um arquivo JPG ou PNG.';

  static const String attachImageFailedMessage =
      'Não foi possível anexar a imagem. Tente novamente.';

  static const String removeImageFailedMessage =
      'Não foi possível remover a imagem. Tente novamente.';

  static const String partItemsUnavailableMessage =
      'Não foi possível carregar as peças da ordem de serviço.';

  static const String addPartItemFailedMessage =
      'Não foi possível adicionar o item. Tente novamente.';

  static const String removePartItemFailedMessage =
      'Não foi possível remover o item. Tente novamente.';

  final ServiceOrderRepository _repository;

  final PartItemRepository _partItemRepository;

  final ImageService _imageService;

  List<ServiceOrder> _orders = <ServiceOrder>[];

  List<PartItem> _partItems = <PartItem>[];

  bool _loading = false;

  String? _error;

  ServiceOrderFilter _filter = const ServiceOrderFilter.empty();

  List<ServiceOrder> get orders => _orders;

  List<PartItem> get partItems => _partItems;

  bool get loading => _loading;

  String? get error => _error;

  ServiceOrderFilter get filter => _filter;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.findFiltered(_filter);
    } on DatabaseAccessException {
      _error = unavailableMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter(ServiceOrderFilter filter) async {
    _filter = filter;
    _error = null;
    try {
      _orders = await _repository.findFiltered(filter);
    } on DatabaseAccessException {
      _error = unavailableMessage;
    }
    notifyListeners();
  }

  Future<void> clearFilter() => applyFilter(const ServiceOrderFilter.empty());

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
      await _partItemRepository.deleteByServiceOrder(id);
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
      _orders = await _repository.findFiltered(_filter);
    } on DatabaseAccessException {
      _error = unavailableMessage;
    }
    notifyListeners();
    return result;
  }

  Future<void> loadPartItems(int serviceOrderId) async {
    _error = null;
    try {
      _partItems = await _partItemRepository.findByServiceOrder(serviceOrderId);
    } on DatabaseAccessException {
      _partItems = <PartItem>[];
      _error = partItemsUnavailableMessage;
    }
    notifyListeners();
  }

  Future<bool> addPartItem(PartItem item) {
    return _writePartItem(
      item.serviceOrderId,
      () => _partItemRepository.insert(item),
      addPartItemFailedMessage,
    );
  }

  Future<bool> removePartItem(int itemId) {
    final int? serviceOrderId = _serviceOrderIdOfPartItem(itemId);
    if (serviceOrderId == null) {
      return Future<bool>.value(false);
    }
    return _writePartItem(
      serviceOrderId,
      () => _partItemRepository.delete(itemId),
      removePartItemFailedMessage,
    );
  }

  Future<bool> updateLaborCost(ServiceOrder order, double laborCost) {
    return _write(() => _repository.update(_withLaborCost(order, laborCost)));
  }

  Future<bool> attachImage(ServiceOrder order, String sourcePath) async {
    if (!_hasAcceptedExtension(sourcePath)) {
      _error = unacceptedImageMessage;
      notifyListeners();
      return false;
    }
    String relativePath;
    try {
      relativePath = await _imageService.save(sourcePath, order.number);
    } catch (_) {
      _error = attachImageFailedMessage;
      notifyListeners();
      return false;
    }
    final bool saved = await _write(
      () => _repository.update(_withImagePath(order, relativePath)),
    );
    if (!saved) {
      await _discardImageFile(relativePath);
    }
    return saved;
  }

  Future<bool> removeImage(ServiceOrder order) async {
    final String? relativePath = order.imagePath;
    final bool saved = await _write(
      () => _repository.update(_withImagePath(order, null)),
    );
    if (!saved) {
      _error = removeImageFailedMessage;
      notifyListeners();
      return false;
    }
    if (relativePath != null) {
      await _discardImageFile(relativePath);
    }
    return true;
  }

  Future<void> _discardImageFile(String relativePath) async {
    try {
      await _imageService.remove(relativePath);
    } catch (_) {
      return;
    }
  }

  static bool _hasAcceptedExtension(String sourcePath) {
    final String extension = p.extension(sourcePath).toLowerCase();
    return extension.length > 1 &&
        ImageService.acceptedExtensions.contains(extension.substring(1));
  }

  int? _serviceOrderIdOfPartItem(int itemId) {
    for (final PartItem item in _partItems) {
      if (item.id == itemId) {
        return item.serviceOrderId;
      }
    }
    return null;
  }

  static ServiceOrder _withImagePath(ServiceOrder order, String? imagePath) {
    return ServiceOrder(
      id: order.id,
      number: order.number,
      customerId: order.customerId,
      equipmentId: order.equipmentId,
      technicianId: order.technicianId,
      problemDescription: order.problemDescription,
      priority: order.priority,
      status: order.status,
      openedAt: order.openedAt,
      dueDate: order.dueDate,
      completedAt: order.completedAt,
      diagnosis: order.diagnosis,
      solution: order.solution,
      laborCost: order.laborCost,
      imagePath: imagePath,
      partItems: order.partItems,
      customerName: order.customerName,
      equipmentDescription: order.equipmentDescription,
      technicianName: order.technicianName,
    );
  }

  static ServiceOrder _withLaborCost(ServiceOrder order, double laborCost) {
    return ServiceOrder(
      id: order.id,
      number: order.number,
      customerId: order.customerId,
      equipmentId: order.equipmentId,
      technicianId: order.technicianId,
      problemDescription: order.problemDescription,
      priority: order.priority,
      status: order.status,
      openedAt: order.openedAt,
      dueDate: order.dueDate,
      completedAt: order.completedAt,
      diagnosis: order.diagnosis,
      solution: order.solution,
      laborCost: laborCost,
      imagePath: order.imagePath,
      partItems: order.partItems,
      customerName: order.customerName,
      equipmentDescription: order.equipmentDescription,
      technicianName: order.technicianName,
    );
  }

  Future<bool> _writePartItem(
    int serviceOrderId,
    Future<Object?> Function() operation,
    String failureMessage,
  ) async {
    _error = null;
    try {
      await operation();
    } on DatabaseAccessException {
      _error = failureMessage;
      notifyListeners();
      return false;
    }
    try {
      _partItems = await _partItemRepository.findByServiceOrder(serviceOrderId);
    } on DatabaseAccessException {
      _error = partItemsUnavailableMessage;
    }
    notifyListeners();
    return true;
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
      _orders = await _repository.findFiltered(_filter);
    } on DatabaseAccessException {
      _error = unavailableMessage;
    }
    notifyListeners();
    return true;
  }
}
