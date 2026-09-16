import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/service_order_controller.dart';
import '../../core/deletion_result.dart';
import '../../core/service_order_labels.dart';
import '../../core/service_order_status.dart';
import '../../core/service_order_transitions.dart';
import '../../core/transition_result.dart';
import '../../models/customer.dart';
import '../../models/equipment.dart';
import '../../models/service_order.dart';
import '../../models/technician.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/equipment_repository.dart';
import '../../repositories/service_order_repository.dart';
import '../../repositories/technician_repository.dart';
import '../../services/database_helper.dart';
import 'service_order_detail_view.dart';
import 'service_order_edit_view.dart';
import 'service_order_form_view.dart';
import 'service_order_list_view.dart';

class ServiceOrdersModule extends StatefulWidget {
  const ServiceOrdersModule({super.key});

  static const Key confirmDeleteButtonKey = Key(
    'serviceOrderDeleteConfirmButton',
  );

  static const Key cancelDeleteButtonKey = Key(
    'serviceOrderDeleteCancelButton',
  );

  static const Key confirmStatusChangeButtonKey = Key(
    'serviceOrderStatusChangeConfirmButton',
  );

  static const Key cancelStatusChangeButtonKey = Key(
    'serviceOrderStatusChangeCancelButton',
  );

  static const Key closeBlockedDialogButtonKey = Key(
    'serviceOrderDeleteBlockedCloseButton',
  );

  static const String noEquipmentMessage =
      'Cadastre um cliente e um equipamento antes de abrir uma ordem de serviço.';

  static const String formDataUnavailableMessage =
      'Não foi possível carregar os dados do formulário. Tente novamente.';

  static const String orderUnavailableMessage =
      'Não foi possível carregar a ordem de serviço. Tente novamente.';

  static const String updatedMessage = 'Alterações salvas.';

  static const String openedWithoutNumberMessage = 'Ordem de serviço aberta.';

  static String statusChangedMessage(String target) =>
      'Status alterado para $target.';

  static String openedMessage(String number) =>
      'Ordem de serviço $number aberta.';

  @override
  State<ServiceOrdersModule> createState() => _ServiceOrdersModuleState();
}

enum _ModuleView { list, opening, detail, editing }

class _ServiceOrdersModuleState extends State<ServiceOrdersModule> {
  final CustomerRepository _customerRepository = CustomerRepository();

  final EquipmentRepository _equipmentRepository = EquipmentRepository();

  final TechnicianRepository _technicianRepository = TechnicianRepository();

  final ServiceOrderRepository _serviceOrderRepository =
      ServiceOrderRepository();

  _ModuleView _view = _ModuleView.list;

  bool _busy = false;

  List<Customer> _customers = <Customer>[];

  List<Technician> _technicians = <Technician>[];

  ServiceOrder? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ServiceOrderController>().load();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showList() {
    setState(() {
      _view = _ModuleView.list;
      _selected = null;
    });
  }

  void _returnToList() {
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    _showList();
    if (controller.error != null) {
      controller.load();
    }
  }

  Future<void> _openForm() async {
    setState(() => _busy = true);
    List<Customer>? customers;
    List<Equipment>? equipment;
    List<Technician>? technicians;
    try {
      customers = await _customerRepository.findAll();
      equipment = await _equipmentRepository.findAll();
      technicians = await _technicianRepository.findActive();
    } on DatabaseAccessException {
      customers = null;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (customers == null || equipment == null || technicians == null) {
      _showMessage(ServiceOrdersModule.formDataUnavailableMessage);
      return;
    }
    final Set<int> customersWithEquipment = equipment
        .map((Equipment item) => item.customerId)
        .toSet();
    final List<Customer> eligible = customers
        .where(
          (Customer customer) => customersWithEquipment.contains(customer.id),
        )
        .toList();
    if (eligible.isEmpty) {
      _showMessage(ServiceOrdersModule.noEquipmentMessage);
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _customers = eligible;
      _technicians = technicians!;
      _view = _ModuleView.opening;
    });
  }

  void _handleOpened(String? number) {
    _showList();
    _showMessage(
      number == null
          ? ServiceOrdersModule.openedWithoutNumberMessage
          : ServiceOrdersModule.openedMessage(number),
    );
  }

  Future<ServiceOrder?> _fetchOrder(int id) async {
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    setState(() => _busy = true);
    ServiceOrder? order;
    bool failed = false;
    try {
      order = await _serviceOrderRepository.findById(id);
    } on DatabaseAccessException {
      failed = true;
    }
    if (!mounted) {
      return null;
    }
    setState(() => _busy = false);
    if (failed) {
      _showMessage(ServiceOrdersModule.orderUnavailableMessage);
      return null;
    }
    if (order == null) {
      _showList();
      _showMessage(ServiceOrderController.notFoundMessage);
      controller.load();
    }
    return order;
  }

  Future<void> _openDetail(ServiceOrder listed) async {
    final int? id = listed.id;
    if (id == null) {
      return;
    }
    final ServiceOrder? order = await _fetchOrder(id);
    if (order == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _selected = order;
      _view = _ModuleView.detail;
    });
  }

  Future<void> _openEdit() async {
    final int? id = _selected?.id;
    if (id == null) {
      return;
    }
    final ServiceOrder? order = await _fetchOrder(id);
    if (order == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    List<Technician>? technicians;
    try {
      technicians = await _technicianRepository.findActive();
    } on DatabaseAccessException {
      technicians = null;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (technicians == null) {
      _showMessage(ServiceOrdersModule.formDataUnavailableMessage);
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _selected = order;
      _technicians = technicians!;
      _view = _ModuleView.editing;
    });
  }

  void _handleUpdated() {
    _showList();
    _showMessage(ServiceOrdersModule.updatedMessage);
  }

  Future<void> _showDeletionBlocked() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Exclusão não permitida'),
        content: const Text(ServiceOrderController.deletionBlockedMessage),
        actions: <Widget>[
          FilledButton(
            key: ServiceOrdersModule.closeBlockedDialogButtonKey,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final ServiceOrder? order = _selected;
    final int? id = order?.id;
    if (order == null || id == null) {
      return;
    }
    if (order.status != ServiceOrderStatus.open) {
      await _showDeletionBlocked();
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Excluir ordem de serviço'),
            content: Text(
              'Deseja excluir a ordem de serviço "${order.number}"?',
            ),
            actions: <Widget>[
              TextButton(
                key: ServiceOrdersModule.cancelDeleteButtonKey,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: ServiceOrdersModule.confirmDeleteButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    setState(() => _busy = true);
    final DeletionResult result = await controller.delete(id);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    switch (result) {
      case DeletionResult.success:
        _showList();
        _showMessage(ServiceOrderController.deletedMessage);
      case DeletionResult.failure:
        _showMessage(ServiceOrderController.deleteFailedMessage);
      case DeletionResult.blockedByLink:
        await _showDeletionBlocked();
    }
  }

  Future<void> _changeStatus(ServiceOrderStatus target) async {
    final ServiceOrder? order = _selected;
    if (order == null) {
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Alterar status'),
            content: Text(
              'Deseja alterar o status da ordem de serviço "${order.number}" '
              'de ${order.status.label} para ${target.label}?',
            ),
            actions: <Widget>[
              TextButton(
                key: ServiceOrdersModule.cancelStatusChangeButtonKey,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: ServiceOrdersModule.confirmStatusChangeButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    setState(() => _busy = true);
    TransitionResult? result;
    try {
      result = await controller.changeStatus(order, target);
    } on DatabaseAccessException {
      result = null;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result == null) {
      _showMessage(ServiceOrderController.statusChangeFailedMessage);
      return;
    }
    if (result != TransitionResult.allowed) {
      _showMessage(transitionBlockedMessage(result, order.status, target));
      return;
    }
    final DateTime now = DateTime.now();
    final ServiceOrder changed = controller.orders.firstWhere(
      (ServiceOrder item) => item.id == order.id,
      orElse: () => order.withStatus(
        target,
        completedAt: target == ServiceOrderStatus.completed
            ? DateTime(now.year, now.month, now.day)
            : null,
      ),
    );
    setState(() => _selected = changed);
    _showMessage(ServiceOrdersModule.statusChangedMessage(target.label));
  }

  @override
  Widget build(BuildContext context) {
    final ServiceOrder? selected = _selected;
    switch (_view) {
      case _ModuleView.opening:
        return ServiceOrderFormView(
          customers: _customers,
          technicians: _technicians,
          onOpened: _handleOpened,
          onCancel: _showList,
        );
      case _ModuleView.detail when selected != null:
        return ServiceOrderDetailView(
          key: ValueKey<int?>(selected.id),
          order: selected,
          busy: _busy,
          onBack: _returnToList,
          onEdit: _openEdit,
          onDelete: _delete,
          onChangeStatus: _changeStatus,
        );
      case _ModuleView.editing when selected != null:
        return ServiceOrderEditView(
          key: ValueKey<int?>(selected.id),
          order: selected,
          technicians: _technicians,
          onSaved: _handleUpdated,
          onCancel: () => setState(() => _view = _ModuleView.detail),
        );
      case _ModuleView.list:
      case _ModuleView.detail:
      case _ModuleView.editing:
        return ServiceOrderListView(
          busy: _busy,
          onAdd: _openForm,
          onOpen: _openDetail,
        );
    }
  }
}
