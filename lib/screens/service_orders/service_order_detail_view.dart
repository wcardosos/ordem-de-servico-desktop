import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service_order_labels.dart';
import '../../core/service_order_status.dart';
import '../../core/service_order_transitions.dart';
import '../../models/service_order.dart';
import '../../widgets/section_header.dart';

class ServiceOrderDetailView extends StatelessWidget {
  const ServiceOrderDetailView({
    super.key,
    required this.order,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
    this.busy = false,
  });

  static const Key backButtonKey = Key('serviceOrderDetailBackButton');

  static const Key editButtonKey = Key('serviceOrderDetailEditButton');

  static const Key deleteButtonKey = Key('serviceOrderDetailDeleteButton');

  static const Key statusFlowSlotKey = Key('serviceOrderDetailStatusFlowSlot');

  static const Key statusSelectorKey = Key('serviceOrderStatusSelector');

  static const Key changeStatusButtonKey = Key(
    'serviceOrderChangeStatusButton',
  );

  static const Key partsSlotKey = Key('serviceOrderDetailPartsSlot');

  static const Key imageSlotKey = Key('serviceOrderDetailImageSlot');

  static const String notInformed = 'Não informado';

  static const String noTechnician = 'Sem responsável';

  static const String closedOrderMessage = 'Esta ordem está encerrada.';

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static Key fieldKey(String name) =>
      ValueKey<String>('serviceOrderDetailField-$name');

  final ServiceOrder order;

  final VoidCallback onBack;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  final ValueChanged<ServiceOrderStatus> onChangeStatus;

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
                    _StatusFlow(
                      key: statusFlowSlotKey,
                      order: order,
                      busy: busy,
                      onChangeStatus: onChangeStatus,
                    ),
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

class _StatusFlow extends StatefulWidget {
  const _StatusFlow({
    super.key,
    required this.order,
    required this.busy,
    required this.onChangeStatus,
  });

  final ServiceOrder order;

  final bool busy;

  final ValueChanged<ServiceOrderStatus> onChangeStatus;

  @override
  State<_StatusFlow> createState() => _StatusFlowState();
}

class _StatusFlowState extends State<_StatusFlow> {
  ServiceOrderStatus? _target;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ServiceOrderStatus> targets =
        validTransitions[widget.order.status] ?? const <ServiceOrderStatus>[];
    final ServiceOrderStatus? target = targets.contains(_target)
        ? _target
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Mudança de status', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          if (targets.isEmpty)
            Text(
              ServiceOrderDetailView.closedOrderMessage,
              style: theme.textTheme.bodyLarge,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  key: ServiceOrderDetailView.statusSelectorKey,
                  width: 280,
                  child: DropdownButton<ServiceOrderStatus>(
                    isExpanded: true,
                    value: target,
                    hint: const Text('Selecione o novo status'),
                    items: targets
                        .map(
                          (ServiceOrderStatus status) =>
                              DropdownMenuItem<ServiceOrderStatus>(
                                value: status,
                                child: Text(status.label),
                              ),
                        )
                        .toList(),
                    onChanged: widget.busy
                        ? null
                        : (ServiceOrderStatus? value) =>
                              setState(() => _target = value),
                  ),
                ),
                FilledButton.icon(
                  key: ServiceOrderDetailView.changeStatusButtonKey,
                  onPressed: widget.busy || target == null
                      ? null
                      : () => widget.onChangeStatus(target),
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Alterar status'),
                ),
              ],
            ),
        ],
      ),
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
