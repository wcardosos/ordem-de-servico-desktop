import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/equipment_controller.dart';
import '../../core/deletion_result.dart';
import '../../models/customer.dart';
import '../../models/equipment.dart';
import '../../repositories/customer_repository.dart';
import '../../services/database_helper.dart';
import 'equipment_form_view.dart';
import 'equipment_list_view.dart';

class EquipmentModule extends StatefulWidget {
  const EquipmentModule({super.key});

  static const Key confirmDeleteButtonKey = Key('equipmentDeleteConfirmButton');

  static const Key cancelDeleteButtonKey = Key('equipmentDeleteCancelButton');

  static const Key closeBlockedDialogButtonKey = Key(
    'equipmentDeleteBlockedCloseButton',
  );

  static const String noCustomersMessage =
      'Cadastre um cliente antes de cadastrar equipamentos.';

  static const String customersUnavailableMessage =
      'Não foi possível carregar os clientes. Tente novamente.';

  @override
  State<EquipmentModule> createState() => _EquipmentModuleState();
}

class _EquipmentModuleState extends State<EquipmentModule> {
  final CustomerRepository _customerRepository = CustomerRepository();

  bool _editing = false;

  bool _busy = false;

  Equipment? _selected;

  List<Customer> _customers = <Customer>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<EquipmentController>().load();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showList() {
    setState(() {
      _editing = false;
      _selected = null;
    });
  }

  Future<void> _openForm([Equipment? equipment]) async {
    setState(() => _busy = true);
    List<Customer>? customers;
    try {
      customers = await _customerRepository.findAll();
    } on DatabaseAccessException {
      customers = null;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (customers == null) {
      _showMessage(EquipmentModule.customersUnavailableMessage);
      return;
    }
    if (customers.isEmpty) {
      _showMessage(EquipmentModule.noCustomersMessage);
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _customers = customers!;
      _selected = equipment;
      _editing = true;
    });
  }

  void _handleSaved() {
    _showList();
    _showMessage(EquipmentController.savedMessage);
  }

  Future<void> _delete(Equipment equipment) async {
    final int? id = equipment.id;
    if (id == null) {
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Excluir equipamento'),
            content: Text('Deseja excluir o equipamento "${equipment.type}"?'),
            actions: <Widget>[
              TextButton(
                key: EquipmentModule.cancelDeleteButtonKey,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: EquipmentModule.confirmDeleteButtonKey,
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
    final EquipmentController controller = context.read<EquipmentController>();
    setState(() => _busy = true);
    final DeletionResult result = await controller.delete(id);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    switch (result) {
      case DeletionResult.success:
        _showMessage(EquipmentController.deletedMessage);
      case DeletionResult.failure:
        _showMessage(EquipmentController.deleteFailedMessage);
      case DeletionResult.blockedByLink:
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Exclusão não permitida'),
            content: Text(
              EquipmentController.blockedByLinkMessage(controller.linkCount),
            ),
            actions: <Widget>[
              FilledButton(
                key: EquipmentModule.closeBlockedDialogButtonKey,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      final Equipment? selected = _selected;
      return EquipmentFormView(
        key: ValueKey<int?>(selected?.id),
        equipment: selected,
        customers: _customers,
        onSaved: _handleSaved,
        onCancel: _showList,
      );
    }
    return EquipmentListView(
      busy: _busy,
      onAdd: _openForm,
      onEdit: _openForm,
      onDelete: _delete,
    );
  }
}
