import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/technician_controller.dart';
import '../../models/technician.dart';
import '../../widgets/section_header.dart';

class TechnicianListView extends StatelessWidget {
  const TechnicianListView({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  static const Key loadingIndicatorKey = Key('technicianListLoadingIndicator');

  static const Key listKey = Key('technicianListView');

  static const Key errorViewKey = Key('technicianListErrorView');

  static const Key retryButtonKey = Key('technicianListRetryButton');

  static const Key addButtonKey = Key('technicianListAddButton');

  static Key editButtonKey(int? id) =>
      ValueKey<String>('technicianEditButton-$id');

  static Key deleteButtonKey(int? id) =>
      ValueKey<String>('technicianDeleteButton-$id');

  final VoidCallback onAdd;

  final ValueChanged<Technician> onEdit;

  final ValueChanged<Technician> onDelete;

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final TechnicianController controller = context
        .watch<TechnicianController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Técnicos',
          actions: <Widget>[
            FilledButton.icon(
              key: addButtonKey,
              onPressed: busy ? null : onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo técnico'),
            ),
          ],
        ),
        Expanded(child: _buildBody(context, controller)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TechnicianController controller) {
    if (controller.loading) {
      return const Center(
        child: CircularProgressIndicator(key: loadingIndicatorKey),
      );
    }
    final String? error = controller.error;
    if (error != null) {
      return Center(
        child: Column(
          key: errorViewKey,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(error),
            const SizedBox(height: 16),
            OutlinedButton(
              key: retryButtonKey,
              onPressed: controller.load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final List<Technician> technicians = controller.technicians;
    if (technicians.isEmpty) {
      return const Center(child: Text('Nenhum técnico cadastrado.'));
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListView.separated(
      key: listKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: technicians.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Technician technician = technicians[index];
        return ListTile(
          title: Text(technician.name),
          subtitle: Text(technician.specialty),
          onTap: busy ? null : () => onEdit(technician),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Chip(
                label: Text(technician.active ? 'Ativo' : 'Inativo'),
                backgroundColor: technician.active
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: technician.active
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: editButtonKey(technician.id),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar técnico',
                onPressed: busy ? null : () => onEdit(technician),
              ),
              IconButton(
                key: deleteButtonKey(technician.id),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir técnico',
                onPressed: busy ? null : () => onDelete(technician),
              ),
            ],
          ),
        );
      },
    );
  }
}
