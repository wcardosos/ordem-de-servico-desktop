import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/technician_controller.dart';
import '../../core/deletion_result.dart';
import '../../models/technician.dart';
import 'technician_delete_view.dart';
import 'technician_form_view.dart';
import 'technician_list_view.dart';

enum _TechnicianView { list, form, delete }

class TechniciansModule extends StatefulWidget {
  const TechniciansModule({super.key});

  @override
  State<TechniciansModule> createState() => _TechniciansModuleState();
}

class _TechniciansModuleState extends State<TechniciansModule> {
  _TechnicianView _view = _TechnicianView.list;

  Technician? _selected;

  String? _notice;

  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<TechnicianController>().load();
    });
  }

  void _show(_TechnicianView view, [Technician? technician]) {
    setState(() {
      _view = view;
      _selected = technician;
      _notice = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSaved() {
    _show(_TechnicianView.list);
    _showMessage(TechnicianController.savedMessage);
  }

  Future<void> _confirmDeletion() async {
    final int? id = _selected?.id;
    if (id == null) {
      _show(_TechnicianView.list);
      return;
    }
    final TechnicianController controller = context
        .read<TechnicianController>();
    setState(() => _deleting = true);
    final DeletionResult result = await controller.delete(id);
    if (!mounted) {
      return;
    }
    setState(() {
      _deleting = false;
      _view = _TechnicianView.list;
      _selected = null;
      _notice = result == DeletionResult.blockedByLink
          ? TechnicianController.blockedByLinkMessage(controller.linkCount)
          : null;
    });
    switch (result) {
      case DeletionResult.success:
        _showMessage(TechnicianController.deletedMessage);
      case DeletionResult.failure:
        _showMessage(TechnicianController.deleteFailedMessage);
      case DeletionResult.blockedByLink:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Technician? selected = _selected;
    switch (_view) {
      case _TechnicianView.form:
        return TechnicianFormView(
          key: ValueKey<int?>(selected?.id),
          technician: selected,
          onSaved: _handleSaved,
          onCancel: () => _show(_TechnicianView.list),
        );
      case _TechnicianView.delete when selected != null:
        return TechnicianDeleteView(
          technician: selected,
          deleting: _deleting,
          onCancel: () => _show(_TechnicianView.list),
          onConfirm: _confirmDeletion,
        );
      case _TechnicianView.list:
      case _TechnicianView.delete:
        return TechnicianListView(
          notice: _notice,
          onDismissNotice: () => setState(() => _notice = null),
          onAdd: () => _show(_TechnicianView.form),
          onEdit: (Technician technician) =>
              _show(_TechnicianView.form, technician),
          onDelete: (Technician technician) =>
              _show(_TechnicianView.delete, technician),
        );
    }
  }
}
