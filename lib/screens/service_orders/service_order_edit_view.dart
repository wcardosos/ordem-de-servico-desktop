import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/service_order_controller.dart';
import '../../core/priority.dart';
import '../../core/service_order_labels.dart';
import '../../models/service_order.dart';
import '../../models/technician.dart';
import '../../widgets/section_header.dart';

class ServiceOrderEditView extends StatefulWidget {
  const ServiceOrderEditView({
    super.key,
    required this.order,
    required this.technicians,
    required this.onSaved,
    required this.onCancel,
  });

  static const Key numberFieldKey = Key('serviceOrderEditNumberField');

  static const Key customerFieldKey = Key('serviceOrderEditCustomerField');

  static const Key equipmentFieldKey = Key('serviceOrderEditEquipmentField');

  static const Key openedAtFieldKey = Key('serviceOrderEditOpenedAtField');

  static const Key problemFieldKey = Key('serviceOrderEditProblemField');

  static const Key priorityFieldKey = Key('serviceOrderEditPriorityField');

  static const Key dueDateFieldKey = Key('serviceOrderEditDueDateField');

  static const Key technicianFieldKey = Key('serviceOrderEditTechnicianField');

  static const Key diagnosisFieldKey = Key('serviceOrderEditDiagnosisField');

  static const Key solutionFieldKey = Key('serviceOrderEditSolutionField');

  static const Key saveButtonKey = Key('serviceOrderEditSaveButton');

  static const Key cancelButtonKey = Key('serviceOrderEditCancelButton');

  static const String saveFailedMessage =
      'Não foi possível salvar as alterações. Tente novamente.';

  final ServiceOrder order;

  final List<Technician> technicians;

  final VoidCallback onSaved;

  final VoidCallback onCancel;

  @override
  State<ServiceOrderEditView> createState() => _ServiceOrderEditViewState();
}

class _ServiceOrderEditViewState extends State<ServiceOrderEditView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late final TextEditingController _numberController;

  late final TextEditingController _customerController;

  late final TextEditingController _equipmentController;

  late final TextEditingController _openedAtController;

  late final TextEditingController _problemController;

  late final TextEditingController _dueDateController;

  late final TextEditingController _diagnosisController;

  late final TextEditingController _solutionController;

  late Priority _priority;

  late DateTime _dueDate;

  int? _technicianId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ServiceOrder order = widget.order;
    _numberController = TextEditingController(text: order.number);
    _customerController = TextEditingController(text: order.customerName);
    _equipmentController = TextEditingController(
      text: order.equipmentDescription,
    );
    _openedAtController = TextEditingController(
      text: _dateFormat.format(order.openedAt),
    );
    _problemController = TextEditingController(text: order.problemDescription);
    _dueDateController = TextEditingController(
      text: _dateFormat.format(order.dueDate),
    );
    _diagnosisController = TextEditingController(text: order.diagnosis);
    _solutionController = TextEditingController(text: order.solution);
    _priority = order.priority;
    _dueDate = order.dueDate;
    _technicianId = order.technicianId;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _customerController.dispose();
    _equipmentController.dispose();
    _openedAtController.dispose();
    _problemController.dispose();
    _dueDateController.dispose();
    _diagnosisController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final String value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
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
    final ServiceOrder original = widget.order;
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    setState(() => _saving = true);
    final bool saved = await controller.update(
      ServiceOrder(
        id: original.id,
        number: original.number,
        customerId: original.customerId,
        equipmentId: original.equipmentId,
        technicianId: _technicianId,
        problemDescription: _problemController.text.trim(),
        priority: _priority,
        status: original.status,
        openedAt: original.openedAt,
        dueDate: _dueDate,
        completedAt: original.completedAt,
        diagnosis: _optional(_diagnosisController),
        solution: _optional(_solutionController),
        laborCost: original.laborCost,
        imagePath: original.imagePath,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(ServiceOrderEditView.saveFailedMessage)),
        );
      return;
    }
    widget.onSaved();
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

  Widget _readOnlyField(
    Key key,
    TextEditingController controller,
    String label,
  ) {
    return _spaced(
      TextFormField(
        key: key,
        controller: controller,
        readOnly: true,
        enabled: false,
        decoration: _decoration(label),
      ),
    );
  }

  List<DropdownMenuItem<int>> _technicianItems() {
    final ServiceOrder order = widget.order;
    final int? assignedId = order.technicianId;
    final bool assignedListed = widget.technicians.any(
      (Technician technician) => technician.id == assignedId,
    );
    return <DropdownMenuItem<int>>[
      const DropdownMenuItem<int>(child: Text('Nenhum')),
      if (assignedId != null && !assignedListed)
        DropdownMenuItem<int>(
          value: assignedId,
          child: Text('${order.technicianName ?? 'Técnico'} (inativo)'),
        ),
      ...widget.technicians.map(
        (Technician technician) => DropdownMenuItem<int>(
          value: technician.id,
          child: Text(technician.name),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = _saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(title: 'Editar ordem de serviço ${widget.order.number}'),
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
                      _readOnlyField(
                        ServiceOrderEditView.numberFieldKey,
                        _numberController,
                        'Número',
                      ),
                      _readOnlyField(
                        ServiceOrderEditView.customerFieldKey,
                        _customerController,
                        'Cliente',
                      ),
                      _readOnlyField(
                        ServiceOrderEditView.equipmentFieldKey,
                        _equipmentController,
                        'Equipamento',
                      ),
                      _readOnlyField(
                        ServiceOrderEditView.openedAtFieldKey,
                        _openedAtController,
                        'Data de abertura',
                      ),
                      _spaced(
                        TextFormField(
                          key: ServiceOrderEditView.problemFieldKey,
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
                          key: ServiceOrderEditView.priorityFieldKey,
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
                                  () => _priority = value ?? _priority,
                                ),
                        ),
                      ),
                      _spaced(
                        TextFormField(
                          key: ServiceOrderEditView.dueDateFieldKey,
                          controller: _dueDateController,
                          readOnly: true,
                          enabled: !saving,
                          decoration: _decoration('Data limite').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: _pickDueDate,
                        ),
                      ),
                      _spaced(
                        KeyedSubtree(
                          key: ServiceOrderEditView.technicianFieldKey,
                          child: DropdownButtonFormField<int>(
                            initialValue: _technicianId,
                            decoration: _decoration('Técnico responsável'),
                            items: _technicianItems(),
                            onChanged: saving
                                ? null
                                : (int? value) =>
                                      setState(() => _technicianId = value),
                          ),
                        ),
                      ),
                      _spaced(
                        TextFormField(
                          key: ServiceOrderEditView.diagnosisFieldKey,
                          controller: _diagnosisController,
                          enabled: !saving,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                          decoration: _decoration('Diagnóstico'),
                        ),
                      ),
                      _spaced(
                        TextFormField(
                          key: ServiceOrderEditView.solutionFieldKey,
                          controller: _solutionController,
                          enabled: !saving,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                          decoration: _decoration('Solução'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            key: ServiceOrderEditView.cancelButtonKey,
                            onPressed: saving ? null : widget.onCancel,
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: ServiceOrderEditView.saveButtonKey,
                            onPressed: saving ? null : _submit,
                            child: const Text('Salvar'),
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
