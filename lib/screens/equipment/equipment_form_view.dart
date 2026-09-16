import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/equipment_controller.dart';
import '../../core/validators.dart';
import '../../models/customer.dart';
import '../../models/equipment.dart';
import '../../widgets/section_header.dart';

class EquipmentFormView extends StatefulWidget {
  const EquipmentFormView({
    super.key,
    this.equipment,
    required this.customers,
    required this.onSaved,
    required this.onCancel,
  });

  static const Key customerFieldKey = Key('equipmentFormCustomerField');

  static const Key typeFieldKey = Key('equipmentFormTypeField');

  static const Key brandFieldKey = Key('equipmentFormBrandField');

  static const Key modelFieldKey = Key('equipmentFormModelField');

  static const Key serialNumberFieldKey = Key('equipmentFormSerialNumberField');

  static const Key assetTagFieldKey = Key('equipmentFormAssetTagField');

  static const Key notesFieldKey = Key('equipmentFormNotesField');

  static const Key saveButtonKey = Key('equipmentFormSaveButton');

  static const Key cancelButtonKey = Key('equipmentFormCancelButton');

  final Equipment? equipment;

  final List<Customer> customers;

  final VoidCallback onSaved;

  final VoidCallback onCancel;

  @override
  State<EquipmentFormView> createState() => _EquipmentFormViewState();
}

class _EquipmentFormViewState extends State<EquipmentFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _typeController;

  late final TextEditingController _brandController;

  late final TextEditingController _modelController;

  late final TextEditingController _serialNumberController;

  late final TextEditingController _assetTagController;

  late final TextEditingController _notesController;

  int? _customerId;

  @override
  void initState() {
    super.initState();
    final Equipment? equipment = widget.equipment;
    _typeController = TextEditingController(text: equipment?.type);
    _brandController = TextEditingController(text: equipment?.brand);
    _modelController = TextEditingController(text: equipment?.model);
    _serialNumberController = TextEditingController(
      text: equipment?.serialNumber,
    );
    _assetTagController = TextEditingController(text: equipment?.assetTag);
    _notesController = TextEditingController(text: equipment?.notes);
    final int? customerId = equipment?.customerId;
    _customerId =
        widget.customers.any((Customer customer) => customer.id == customerId)
        ? customerId
        : null;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _assetTagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final String value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    final int? customerId = _customerId;
    if (form == null || !form.validate() || customerId == null) {
      return;
    }
    final EquipmentController controller = context.read<EquipmentController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool saved = await controller.save(
      Equipment(
        id: widget.equipment?.id,
        customerId: customerId,
        type: _typeController.text.trim(),
        brand: _optional(_brandController),
        model: _optional(_modelController),
        serialNumber: _optional(_serialNumberController),
        assetTag: _optional(_assetTagController),
        notes: _optional(_notesController),
      ),
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      widget.onSaved();
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          controller.saveError ?? EquipmentController.saveFailedMessage,
        ),
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required bool enabled,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: key,
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = context.watch<EquipmentController>().saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: widget.equipment == null
              ? 'Novo equipamento'
              : 'Editar equipamento',
        ),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<int>(
                          key: EquipmentFormView.customerFieldKey,
                          initialValue: _customerId,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.customers
                              .map(
                                (Customer customer) => DropdownMenuItem<int>(
                                  value: customer.id,
                                  child: Text(customer.name),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (int? value) =>
                                    setState(() => _customerId = value),
                          validator: (int? value) =>
                              value == null ? 'Selecione o cliente.' : null,
                        ),
                      ),
                      _buildField(
                        key: EquipmentFormView.typeFieldKey,
                        controller: _typeController,
                        label: 'Tipo',
                        enabled: !saving,
                        validator: (String? value) =>
                            requiredField(value, 'tipo'),
                      ),
                      _buildField(
                        key: EquipmentFormView.brandFieldKey,
                        controller: _brandController,
                        label: 'Marca',
                        enabled: !saving,
                      ),
                      _buildField(
                        key: EquipmentFormView.modelFieldKey,
                        controller: _modelController,
                        label: 'Modelo',
                        enabled: !saving,
                      ),
                      _buildField(
                        key: EquipmentFormView.serialNumberFieldKey,
                        controller: _serialNumberController,
                        label: 'Número de série',
                        enabled: !saving,
                      ),
                      _buildField(
                        key: EquipmentFormView.assetTagFieldKey,
                        controller: _assetTagController,
                        label: 'Patrimônio',
                        enabled: !saving,
                      ),
                      _buildField(
                        key: EquipmentFormView.notesFieldKey,
                        controller: _notesController,
                        label: 'Observações',
                        enabled: !saving,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            key: EquipmentFormView.cancelButtonKey,
                            onPressed: saving ? null : widget.onCancel,
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: EquipmentFormView.saveButtonKey,
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
