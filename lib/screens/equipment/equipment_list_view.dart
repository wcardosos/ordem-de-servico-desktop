import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/equipment_controller.dart';
import '../../models/equipment.dart';
import '../../widgets/section_header.dart';

class EquipmentListView extends StatelessWidget {
  const EquipmentListView({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  static const Key loadingIndicatorKey = Key('equipmentListLoadingIndicator');

  static const Key listKey = Key('equipmentListView');

  static const Key errorViewKey = Key('equipmentListErrorView');

  static const Key retryButtonKey = Key('equipmentListRetryButton');

  static const Key addButtonKey = Key('equipmentListAddButton');

  static Key editButtonKey(int? id) =>
      ValueKey<String>('equipmentEditButton-$id');

  static Key deleteButtonKey(int? id) =>
      ValueKey<String>('equipmentDeleteButton-$id');

  final VoidCallback onAdd;

  final ValueChanged<Equipment> onEdit;

  final ValueChanged<Equipment> onDelete;

  final bool busy;

  static String describe(Equipment equipment) {
    final String brandAndModel = <String?>[equipment.brand, equipment.model]
        .whereType<String>()
        .where((String value) => value.trim().isNotEmpty)
        .join(' ');
    final String customer = equipment.customerName ?? '';
    return <String>[
      brandAndModel,
      customer,
    ].where((String value) => value.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final EquipmentController controller = context.watch<EquipmentController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Equipamentos',
          actions: <Widget>[
            FilledButton.icon(
              key: addButtonKey,
              onPressed: busy ? null : onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo equipamento'),
            ),
          ],
        ),
        Expanded(child: _buildBody(controller)),
      ],
    );
  }

  Widget _buildBody(EquipmentController controller) {
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
    final List<Equipment> equipment = controller.equipment;
    if (equipment.isEmpty) {
      return const Center(child: Text('Nenhum equipamento cadastrado.'));
    }
    return ListView.separated(
      key: listKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: equipment.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Equipment item = equipment[index];
        return ListTile(
          title: Text(item.type),
          subtitle: Text(describe(item)),
          onTap: busy ? null : () => onEdit(item),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                key: editButtonKey(item.id),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar equipamento',
                onPressed: busy ? null : () => onEdit(item),
              ),
              IconButton(
                key: deleteButtonKey(item.id),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir equipamento',
                onPressed: busy ? null : () => onDelete(item),
              ),
            ],
          ),
        );
      },
    );
  }
}
