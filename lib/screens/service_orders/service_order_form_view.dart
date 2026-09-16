import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/service_order_controller.dart';
import '../../core/priority.dart';
import '../../core/service_order_labels.dart';
import '../../core/service_order_status.dart';
import '../../models/customer.dart';
import '../../models/equipment.dart';
import '../../models/service_order.dart';
import '../../models/technician.dart';
import '../../repositories/equipment_repository.dart';
import '../../services/database_helper.dart';
import '../../widgets/section_header.dart';

class ServiceOrderFormView extends StatefulWidget {
  const ServiceOrderFormView({
    super.key,
    required this.customers,
    required this.technicians,
    required this.onOpened,
    required this.onCancel,
  });

  static const Key customerFieldKey = Key('serviceOrderFormCustomerField');

  static const Key equipmentFieldKey = Key('serviceOrderFormEquipmentField');

  static const Key problemFieldKey = Key('serviceOrderFormProblemField');

  static const Key priorityFieldKey = Key('serviceOrderFormPriorityField');

  static const Key dueDateFieldKey = Key('serviceOrderFormDueDateField');

  static const Key technicianFieldKey = Key('serviceOrderFormTechnicianField');

  static const Key submitButtonKey = Key('serviceOrderFormSubmitButton');

  static const Key cancelButtonKey = Key('serviceOrderFormCancelButton');

  static const String openFailedMessage =
      'Não foi possível abrir a ordem de serviço. Tente novamente.';

  static const String equipmentUnavailableMessage =
      'Não foi possível carregar os equipamentos do cliente. Tente novamente.';

  final List<Customer> customers;

  final List<Technician> technicians;

  final ValueChanged<String?> onOpened;

  final VoidCallback onCancel;

  static String describeEquipment(Equipment equipment) {
    return <String?>[equipment.type, equipment.brand, equipment.model]
        .whereType<String>()
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .join(' ');
  }

  @override
  State<ServiceOrderFormView> createState() => _ServiceOrderFormViewState();
}

class _ServiceOrderFormViewState extends State<ServiceOrderFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final EquipmentRepository _equipmentRepository = EquipmentRepository();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final TextEditingController _problemController = TextEditingController();

  final TextEditingController _dueDateController = TextEditingController();

  int? _customerId;

  int? _equipmentId;

  int? _technicianId;

  Priority _priority = Priority.medium;

  DateTime? _dueDate;

  List<Equipment> _equipment = <Equipment>[];

  int _equipmentRequest = 0;

  bool _saving = false;

  @override
  void dispose() {
    _problemController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectCustomer(int? customerId) async {
    final int request = ++_equipmentRequest;
    setState(() {
      _customerId = customerId;
      _equipmentId = null;
      _equipment = <Equipment>[];
    });
    if (customerId == null) {
      return;
    }
    List<Equipment>? equipment;
    try {
      equipment = await _equipmentRepository.findByCustomer(customerId);
    } on DatabaseAccessException {
      equipment = null;
    }
    if (!mounted || request != _equipmentRequest) {
      return;
    }
    if (equipment == null) {
      _showMessage(ServiceOrderFormView.equipmentUnavailableMessage);
      return;
    }
    setState(() => _equipment = equipment!);
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _dueDate = DateTime(picked.year, picked.month, picked.day);
      _dueDateController.text = _dateFormat.format(picked);
    });
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final int? customerId = _customerId;
    final int? equipmentId = _equipmentId;
    final DateTime? dueDate = _dueDate;
    if (customerId == null || equipmentId == null || dueDate == null) {
      return;
    }
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    final Set<int?> existingIds = controller.orders
        .map((ServiceOrder order) => order.id)
        .toSet();
    final DateTime now = DateTime.now();
    setState(() => _saving = true);
    final bool opened = await controller.open(
      ServiceOrder(
        number: '',
        customerId: customerId,
        equipmentId: equipmentId,
        technicianId: _technicianId,
        problemDescription: _problemController.text.trim(),
        priority: _priority,
        status: ServiceOrderStatus.open,
        openedAt: DateTime(now.year, now.month, now.day),
        dueDate: dueDate,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!opened) {
      _showMessage(ServiceOrderFormView.openFailedMessage);
      return;
    }
    ServiceOrder? created;
    for (final ServiceOrder order in controller.orders) {
      if (!existingIds.contains(order.id) &&
          (created == null || (order.id ?? 0) > (created.id ?? 0))) {
        created = order;
      }
    }
    widget.onOpened(created?.number);
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Widget _spaced(Widget child) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = _saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(title: 'Nova ordem de serviço'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _spaced(
                        DropdownButtonFormField<int>(
                          key: ServiceOrderFormView.customerFieldKey,
                          initialValue: _customerId,
                          decoration: _decoration('Cliente'),
                          items: widget.customers
                              .map(
                                (Customer customer) => DropdownMenuItem<int>(
                                  value: customer.id,
                                  child: Text(customer.name),
                                ),
                              )
                              .toList(),
                          onChanged: saving ? null : _selectCustomer,
                          validator: (int? value) =>
                              value == null ? 'Selecione o cliente.' : null,
                        ),
                      ),
                      _spaced(
                        KeyedSubtree(
                          key: ServiceOrderFormView.equipmentFieldKey,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey<String>(
                              'equipment-$_customerId-$_equipmentRequest',
                            ),
                            initialValue: _equipmentId,
                            decoration: _decoration('Equipamento'),
                            items: _equipment
                                .map(
                                  (Equipment item) => DropdownMenuItem<int>(
                                    value: item.id,
                                    child: Text(
                                      ServiceOrderFormView.describeEquipment(
                                        item,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: saving
                                ? null
                                : (int? value) =>
                                      setState(() => _equipmentId = value),
                            validator: (int? value) => value == null
                                ? 'Selecione o equipamento.'
                                : null,
                          ),
                        ),
                      ),
                      _spaced(
                        TextFormField(
                          key: ServiceOrderFormView.problemFieldKey,
                          controller: _problemController,
                          enabled: !saving,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                          decoration: _decoration('Descrição do problema'),
                          validator: (String? value) =>
                              value == null || value.trim().isEmpty
                              ? 'Descreva o problema.'
                              : null,
                        ),
                      ),
                      _spaced(
                        DropdownButtonFormField<Priority>(
                          key: ServiceOrderFormView.priorityFieldKey,
                          initialValue: _priority,
                          decoration: _decoration('Prioridade'),
                          items: Priority.values
                              .map(
                                (Priority priority) =>
                                    DropdownMenuItem<Priority>(
                                      value: priority,
                                      child: Text(priority.label),
                                    ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (Priority? value) => setState(
                                  () => _priority = value ?? Priority.medium,
                                ),
                          validator: (Priority? value) =>
                              value == null ? 'Selecione a prioridade.' : null,
                        ),
                      ),
                      _spaced(
                        TextFormField(
                          key: ServiceOrderFormView.dueDateFieldKey,
                          controller: _dueDateController,
                          readOnly: true,
                          enabled: !saving,
                          decoration: _decoration('Data limite').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: _pickDueDate,
                          validator: (String? value) => _dueDate == null
                              ? 'Informe a data limite.'
                              : null,
                        ),
                      ),
                      _spaced(
                        KeyedSubtree(
                          key: ServiceOrderFormView.technicianFieldKey,
                          child: DropdownButtonFormField<int>(
                            initialValue: _technicianId,
                            decoration: _decoration('Técnico responsável'),
                            items: <DropdownMenuItem<int>>[
                              const DropdownMenuItem<int>(
                                child: Text('Nenhum'),
                              ),
                              ...widget.technicians.map(
                                (Technician technician) =>
                                    DropdownMenuItem<int>(
                                      value: technician.id,
                                      child: Text(technician.name),
                                    ),
                              ),
                            ],
                            onChanged: saving
                                ? null
                                : (int? value) =>
                                      setState(() => _technicianId = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            key: ServiceOrderFormView.cancelButtonKey,
                            onPressed: saving ? null : widget.onCancel,
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: ServiceOrderFormView.submitButtonKey,
                            onPressed: saving ? null : _submit,
                            child: const Text('Abrir OS'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
