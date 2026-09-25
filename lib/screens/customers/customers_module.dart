import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/customer_controller.dart';
import '../../core/deletion_result.dart';
import '../../models/customer.dart';
import '../../widgets/confirmation_dialog.dart';
import 'customer_form_view.dart';
import 'customer_list_view.dart';

enum _CustomerView { list, form }

class CustomersModule extends StatefulWidget {
  const CustomersModule({super.key});

  static const Key confirmDeleteButtonKey = Key('customerDeleteConfirmButton');

  static const Key cancelDeleteButtonKey = Key('customerDeleteCancelButton');

  static const Key closeBlockedDialogButtonKey = Key(
    'customerDeleteBlockedCloseButton',
  );

  @override
  State<CustomersModule> createState() => _CustomersModuleState();
}

class _CustomersModuleState extends State<CustomersModule> {
  _CustomerView _view = _CustomerView.list;

  Customer? _selected;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<CustomerController>().load();
    });
  }

  void _show(_CustomerView view, [Customer? customer]) {
    setState(() {
      _view = view;
      _selected = customer;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSaved() {
    _show(_CustomerView.list);
    _showMessage(CustomerController.savedMessage);
  }

  Future<void> _delete(Customer customer) async {
    final int? id = customer.id;
    if (id == null) {
      return;
    }
    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Excluir cliente',
      message: 'Deseja excluir o cliente "${customer.name}"?',
      confirmLabel: 'Excluir',
      confirmKey: CustomersModule.confirmDeleteButtonKey,
      cancelKey: CustomersModule.cancelDeleteButtonKey,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final CustomerController controller = context.read<CustomerController>();
    setState(() => _busy = true);
    final DeletionResult result = await controller.delete(id);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    switch (result) {
      case DeletionResult.success:
        _showMessage(CustomerController.deletedMessage);
      case DeletionResult.failure:
        _showMessage(CustomerController.deleteFailedMessage);
      case DeletionResult.blockedByLink:
        await showBlockedDialog(
          context,
          message: CustomerController.blockedByLinkMessage(
            controller.linkCount,
          ),
          closeKey: CustomersModule.closeBlockedDialogButtonKey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Customer? selected = _selected;
    switch (_view) {
      case _CustomerView.form:
        return CustomerFormView(
          key: ValueKey<int?>(selected?.id),
          customer: selected,
          onSaved: _handleSaved,
          onCancel: () => _show(_CustomerView.list),
        );
      case _CustomerView.list:
        return CustomerListView(
          busy: _busy,
          onAdd: () => _show(_CustomerView.form),
          onEdit: (Customer customer) => _show(_CustomerView.form, customer),
          onDelete: _delete,
        );
    }
  }
}
