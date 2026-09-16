import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/service_order_controller.dart';
import '../../core/priority.dart';
import '../../core/service_order_labels.dart';
import '../../models/service_order.dart';
import '../../widgets/section_header.dart';

class ServiceOrderListView extends StatelessWidget {
  const ServiceOrderListView({
    super.key,
    required this.onAdd,
    required this.onOpen,
    this.busy = false,
  });

  static const Key loadingIndicatorKey = Key(
    'serviceOrderListLoadingIndicator',
  );

  static const Key listKey = Key('serviceOrderListView');

  static const Key errorViewKey = Key('serviceOrderListErrorView');

  static const Key addButtonKey = Key('serviceOrderListAddButton');

  static const Key retryButtonKey = Key('serviceOrderListRetryButton');

  static const Key overdueMarkerKey = Key('serviceOrderOverdueMarker');

  static const IconData overdueIcon = Icons.schedule;

  static const IconData urgentIcon = Icons.priority_high;

  static const String emptyMessage = 'Nenhuma ordem de serviço cadastrada.';

  static Key itemKey(String number) =>
      ValueKey<String>('serviceOrderItem-$number');

  final VoidCallback onAdd;

  final ValueChanged<ServiceOrder> onOpen;

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ServiceOrderController controller = context
        .watch<ServiceOrderController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Ordens de serviço',
          actions: <Widget>[
            FilledButton.icon(
              key: addButtonKey,
              onPressed: busy ? null : onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova ordem'),
            ),
          ],
        ),
        Expanded(child: _buildBody(controller)),
      ],
    );
  }

  Widget _buildBody(ServiceOrderController controller) {
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
    final List<ServiceOrder> orders = controller.orders;
    if (orders.isEmpty) {
      return const Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      key: listKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: orders.length,
      itemBuilder: (BuildContext context, int index) => _ServiceOrderCard(
        order: orders[index],
        onTap: busy ? null : () => onOpen(orders[index]),
      ),
    );
  }
}

class _ServiceOrderCard extends StatelessWidget {
  const _ServiceOrderCard({required this.order, required this.onTap});

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final ServiceOrder order;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool urgent = order.priority == Priority.urgent;
    return Card(
      key: ServiceOrderListView.itemKey(order.number),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(order.number, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.event_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text('Prazo: ${_dateFormat.format(order.dueDate)}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(order.customerName ?? ''),
              Text(
                order.equipmentDescription ?? '',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(label: Text(order.status.label)),
                  Chip(
                    avatar: urgent
                        ? Icon(
                            ServiceOrderListView.urgentIcon,
                            color: colors.onErrorContainer,
                          )
                        : null,
                    label: Text(
                      order.priority.label,
                      style: urgent
                          ? TextStyle(
                              color: colors.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                    backgroundColor: urgent
                        ? colors.errorContainer
                        : colors.surfaceContainerHighest,
                  ),
                  if (order.isOverdue)
                    Chip(
                      key: ServiceOrderListView.overdueMarkerKey,
                      avatar: Icon(
                        ServiceOrderListView.overdueIcon,
                        color: colors.onError,
                      ),
                      label: Text(
                        'Atrasada',
                        style: TextStyle(color: colors.onError),
                      ),
                      backgroundColor: colors.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
