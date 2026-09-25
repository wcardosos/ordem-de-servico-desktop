import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/technician_controller.dart';
import '../../core/deletion_result.dart';
import '../../models/technician.dart';
import '../../widgets/confirmation_dialog.dart';
import 'technician_form_view.dart';
import 'technician_list_view.dart';

enum _TechnicianView { list, form }

class TechniciansModule extends StatefulWidget {
  const TechniciansModule({super.key});

  static const Key confirmDeleteButtonKey = Key(
    'technicianDeleteConfirmButton',
  );

  static const Key cancelDeleteButtonKey = Key('technicianDeleteCancelButton');

  static const Key closeBlockedDialogButtonKey = Key(
    'technicianDeleteBlockedCloseButton',
  );

  @override
  State<TechniciansModule> createState() => _TechniciansModuleState();
}

class _TechniciansModuleState extends State<TechniciansModule> {
  _TechnicianView _view = _TechnicianView.list;

  Technician? _selected;

  bool _busy = false;

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

  Future<void> _delete(Technician technician) async {
    final int? id = technician.id;
    if (id == null) {
      return;
    }
    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Excluir técnico',
      message: 'Deseja excluir o técnico "${technician.name}"?',
      confirmLabel: 'Excluir',
      confirmKey: TechniciansModule.confirmDeleteButtonKey,
      cancelKey: TechniciansModule.cancelDeleteButtonKey,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final TechnicianController controller = context
        .read<TechnicianController>();
    setState(() => _busy = true);
    final DeletionResult result = await controller.delete(id);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    switch (result) {
      case DeletionResult.success:
        _showMessage(TechnicianController.deletedMessage);
      case DeletionResult.failure:
        _showMessage(TechnicianController.deleteFailedMessage);
      case DeletionResult.blockedByLink:
        await showBlockedDialog(
          context,
          message: TechnicianController.blockedByLinkMessage(
            controller.linkCount,
          ),
          closeKey: TechniciansModule.closeBlockedDialogButtonKey,
        );
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
      case _TechnicianView.list:
        return TechnicianListView(
          busy: _busy,
          onAdd: () => _show(_TechnicianView.form),
          onEdit: (Technician technician) =>
              _show(_TechnicianView.form, technician),
          onDelete: _delete,
        );
    }
  }
}
