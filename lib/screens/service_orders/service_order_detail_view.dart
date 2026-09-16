import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service_order_labels.dart';
import '../../models/service_order.dart';
import '../../widgets/section_header.dart';

class ServiceOrderDetailView extends StatelessWidget {
  const ServiceOrderDetailView({
    super.key,
    required this.order,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  static const Key backButtonKey = Key('serviceOrderDetailBackButton');

  static const Key editButtonKey = Key('serviceOrderDetailEditButton');

  static const Key deleteButtonKey = Key('serviceOrderDetailDeleteButton');

  static const Key statusFlowSlotKey = Key('serviceOrderDetailStatusFlowSlot');

  static const Key partsSlotKey = Key('serviceOrderDetailPartsSlot');

  static const Key imageSlotKey = Key('serviceOrderDetailImageSlot');

  static const String notInformed = 'Não informado';

  static const String noTechnician = 'Sem responsável';

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static Key fieldKey(String name) =>
      ValueKey<String>('serviceOrderDetailField-$name');

  final ServiceOrder order;

  final VoidCallback onBack;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  final bool busy;

  static String _orPlaceholder(String? value, String placeholder) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? placeholder : text;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? completedAt = order.completedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Ordem de serviço ${order.number}',
          actions: <Widget>[
            OutlinedButton.icon(
              key: backButtonKey,
              onPressed: busy ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              key: deleteButtonKey,
              onPressed: busy ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              key: editButtonKey,
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _DetailField(
                      name: 'number',
                      label: 'Número',
                      value: order.number,
                    ),
                    _DetailField(
                      name: 'customer',
                      label: 'Cliente',
                      value: _orPlaceholder(order.customerName, notInformed),
                    ),
                    _DetailField(
                      name: 'equipment',
                      label: 'Equipamento',
                      value: _orPlaceholder(
                        order.equipmentDescription,
                        notInformed,
                      ),
                    ),
                    _DetailField(
                      name: 'technician',
                      label: 'Técnico responsável',
                      value: order.technicianId == null
                          ? noTechnician
                          : _orPlaceholder(order.technicianName, noTechnician),
                    ),
                    _DetailField(
                      name: 'problem',
                      label: 'Descrição do problema',
                      value: _orPlaceholder(
                        order.problemDescription,
                        notInformed,
                      ),
                    ),
                    _DetailField(
                      name: 'priority',
                      label: 'Prioridade',
                      value: order.priority.label,
                    ),
                    _DetailField(
                      name: 'status',
                      label: 'Status',
                      value: order.status.label,
                    ),
                    _DetailField(
                      name: 'openedAt',
                      label: 'Data de abertura',
                      value: _dateFormat.format(order.openedAt),
                    ),
                    _DetailField(
                      name: 'dueDate',
                      label: 'Data limite',
                      value: _dateFormat.format(order.dueDate),
                    ),
                    if (completedAt != null)
                      _DetailField(
                        name: 'completedAt',
                        label: 'Data de conclusão',
                        value: _dateFormat.format(completedAt),
                      ),
                    _DetailField(
                      name: 'diagnosis',
                      label: 'Diagnóstico',
                      value: _orPlaceholder(order.diagnosis, notInformed),
                    ),
                    _DetailField(
                      name: 'solution',
                      label: 'Solução',
                      value: _orPlaceholder(order.solution, notInformed),
                    ),
                    const SizedBox(key: statusFlowSlotKey),
                    const SizedBox(key: partsSlotKey),
                    const SizedBox(key: imageSlotKey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.name,
    required this.label,
    required this.value,
  });

  final String name;

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      key: ServiceOrderDetailView.fieldKey(name),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
