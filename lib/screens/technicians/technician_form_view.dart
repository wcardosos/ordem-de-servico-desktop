import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/technician_controller.dart';
import '../../core/input_masks.dart';
import '../../core/validators.dart';
import '../../models/technician.dart';
import '../../widgets/section_header.dart';

class TechnicianFormView extends StatefulWidget {
  const TechnicianFormView({
    super.key,
    this.technician,
    required this.onSaved,
    required this.onCancel,
  });

  static const Key nameFieldKey = Key('technicianFormNameField');

  static const Key contactFieldKey = Key('technicianFormContactField');

  static const Key specialtyFieldKey = Key('technicianFormSpecialtyField');

  static const Key activeSwitchKey = Key('technicianFormActiveSwitch');

  static const Key saveButtonKey = Key('technicianFormSaveButton');

  static const Key cancelButtonKey = Key('technicianFormCancelButton');

  final Technician? technician;

  final VoidCallback onSaved;

  final VoidCallback onCancel;

  @override
  State<TechnicianFormView> createState() => _TechnicianFormViewState();
}

class _TechnicianFormViewState extends State<TechnicianFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  late final TextEditingController _contactController;

  late final TextEditingController _specialtyController;

  late bool _active;

  @override
  void initState() {
    super.initState();
    final Technician? technician = widget.technician;
    _nameController = TextEditingController(text: technician?.name);
    _contactController = TextEditingController(
      text: formatPhone(technician?.contact ?? ''),
    );
    _specialtyController = TextEditingController(text: technician?.specialty);
    _active = technician?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  String? _validateContactField(String? value) =>
      requiredField(value, 'contato') ?? validatePhone(value);

  String? _validateSpecialtyField(String? value) =>
      requiredField(value, 'especialidade') == null
      ? null
      : 'Informe a especialidade.';

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final TechnicianController controller = context
        .read<TechnicianController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool saved = await controller.save(
      Technician(
        id: widget.technician?.id,
        name: _nameController.text.trim(),
        contact: digitsOnly(_contactController.text),
        specialty: _specialtyController.text.trim(),
        active: _active,
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
          controller.saveError ?? TechnicianController.saveFailedMessage,
        ),
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    TextInputFormatter? mask,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: key,
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: mask == null ? null : <TextInputFormatter>[mask],
        textInputAction: TextInputAction.next,
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
    final bool saving = context.watch<TechnicianController>().saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: widget.technician == null ? 'Novo técnico' : 'Editar técnico',
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
                      _buildField(
                        key: TechnicianFormView.nameFieldKey,
                        controller: _nameController,
                        label: 'Nome',
                        enabled: !saving,
                        validator: (String? value) =>
                            requiredField(value, 'nome'),
                      ),
                      _buildField(
                        key: TechnicianFormView.contactFieldKey,
                        controller: _contactController,
                        label: 'Contato',
                        enabled: !saving,
                        keyboardType: TextInputType.phone,
                        mask: DigitMaskFormatter.phone(),
                        validator: _validateContactField,
                      ),
                      _buildField(
                        key: TechnicianFormView.specialtyFieldKey,
                        controller: _specialtyController,
                        label: 'Especialidade',
                        enabled: !saving,
                        validator: _validateSpecialtyField,
                      ),
                      SwitchListTile(
                        key: TechnicianFormView.activeSwitchKey,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ativo'),
                        value: _active,
                        onChanged: saving
                            ? null
                            : (bool value) => setState(() => _active = value),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            key: TechnicianFormView.cancelButtonKey,
                            onPressed: saving ? null : widget.onCancel,
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: TechnicianFormView.saveButtonKey,
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
