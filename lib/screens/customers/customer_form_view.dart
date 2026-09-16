import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/customer_controller.dart';
import '../../core/input_masks.dart';
import '../../core/validators.dart';
import '../../models/customer.dart';
import '../../widgets/section_header.dart';

class CustomerFormView extends StatefulWidget {
  const CustomerFormView({
    super.key,
    this.customer,
    required this.onSaved,
    required this.onCancel,
  });

  static const Key nameFieldKey = Key('customerFormNameField');

  static const Key documentFieldKey = Key('customerFormDocumentField');

  static const Key phoneFieldKey = Key('customerFormPhoneField');

  static const Key emailFieldKey = Key('customerFormEmailField');

  static const Key addressFieldKey = Key('customerFormAddressField');

  static const Key saveButtonKey = Key('customerFormSaveButton');

  static const Key cancelButtonKey = Key('customerFormCancelButton');

  final Customer? customer;

  final VoidCallback onSaved;

  final VoidCallback onCancel;

  @override
  State<CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends State<CustomerFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  late final TextEditingController _documentController;

  late final TextEditingController _phoneController;

  late final TextEditingController _emailController;

  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final Customer? customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name);
    _documentController = TextEditingController(
      text: formatDocument(customer?.document ?? ''),
    );
    _phoneController = TextEditingController(
      text: formatPhone(customer?.phone ?? ''),
    );
    _emailController = TextEditingController(text: customer?.email);
    _addressController = TextEditingController(text: customer?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validatePhoneField(String? value) =>
      requiredField(value, 'telefone') ?? validatePhone(value);

  String? _validateEmailField(String? value) =>
      requiredField(value, 'e-mail') ?? validateEmail(value);

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final CustomerController controller = context.read<CustomerController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool saved = await controller.save(
      Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        document: digitsOnly(_documentController.text),
        phone: digitsOnly(_phoneController.text),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
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
          controller.saveError ?? CustomerController.saveFailedMessage,
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
    final bool saving = context.watch<CustomerController>().saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: widget.customer == null ? 'Novo cliente' : 'Editar cliente',
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
                        key: CustomerFormView.nameFieldKey,
                        controller: _nameController,
                        label: 'Nome',
                        enabled: !saving,
                        validator: (String? value) =>
                            requiredField(value, 'nome'),
                      ),
                      _buildField(
                        key: CustomerFormView.documentFieldKey,
                        controller: _documentController,
                        label: 'Documento (CPF/CNPJ)',
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        mask: DigitMaskFormatter.document(),
                        validator: (String? value) =>
                            requiredField(value, 'documento'),
                      ),
                      _buildField(
                        key: CustomerFormView.phoneFieldKey,
                        controller: _phoneController,
                        label: 'Telefone',
                        enabled: !saving,
                        keyboardType: TextInputType.phone,
                        mask: DigitMaskFormatter.phone(),
                        validator: _validatePhoneField,
                      ),
                      _buildField(
                        key: CustomerFormView.emailFieldKey,
                        controller: _emailController,
                        label: 'E-mail',
                        enabled: !saving,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmailField,
                      ),
                      _buildField(
                        key: CustomerFormView.addressFieldKey,
                        controller: _addressController,
                        label: 'Endereço',
                        enabled: !saving,
                        validator: (String? value) =>
                            requiredField(value, 'endereço'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            key: CustomerFormView.cancelButtonKey,
                            onPressed: saving ? null : widget.onCancel,
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: CustomerFormView.saveButtonKey,
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
