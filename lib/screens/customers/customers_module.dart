import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/customer_controller.dart';
import '../../core/deletion_result.dart';
import '../../models/customer.dart';
import 'customer_delete_view.dart';
import 'customer_form_view.dart';
import 'customer_list_view.dart';

enum _CustomerView { list, form, delete }

class CustomersModule extends StatefulWidget {
  const CustomersModule({super.key});

  @override
  State<CustomersModule> createState() => _CustomersModuleState();
}

class _CustomersModuleState extends State<CustomersModule> {
  _CustomerView _view = _CustomerView.list;

  Customer? _selected;

  String? _notice;

  bool _deleting = false;

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
      _notice = null;
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

  Future<void> _confirmDeletion() async {
    final int? id = _selected?.id;
    if (id == null) {
      _show(_CustomerView.list);
      return;
    }
    final CustomerController controller = context.read<CustomerController>();
    setState(() => _deleting = true);
    final DeletionResult result = await controller.delete(id);
    if (!mounted) {
      return;
    }
    setState(() {
      _deleting = false;
      _view = _CustomerView.list;
      _selected = null;
      _notice = result == DeletionResult.blockedByLink
          ? CustomerController.blockedByLinkMessage(controller.linkCount)
          : null;
    });
    switch (result) {
      case DeletionResult.success:
        _showMessage(CustomerController.deletedMessage);
      case DeletionResult.failure:
        _showMessage(CustomerController.deleteFailedMessage);
      case DeletionResult.blockedByLink:
        break;
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
      case _CustomerView.delete when selected != null:
        return CustomerDeleteView(
          customer: selected,
          deleting: _deleting,
          onCancel: () => _show(_CustomerView.list),
          onConfirm: _confirmDeletion,
        );
      case _CustomerView.list:
      case _CustomerView.delete:
        return CustomerListView(
          notice: _notice,
          onDismissNotice: () => setState(() => _notice = null),
          onAdd: () => _show(_CustomerView.form),
          onEdit: (Customer customer) => _show(_CustomerView.form, customer),
          onDelete: (Customer customer) =>
              _show(_CustomerView.delete, customer),
        );
    }
  }
}
