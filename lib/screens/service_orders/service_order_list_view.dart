import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/service_order_controller.dart';
import '../../core/priority.dart';
import '../../core/service_order_filter.dart';
import '../../core/service_order_labels.dart';
import '../../core/service_order_status.dart';
import '../../models/service_order.dart';
import '../../models/technician.dart';
import '../../widgets/section_header.dart';

class ServiceOrderListView extends StatefulWidget {
  const ServiceOrderListView({
    super.key,
    required this.onAdd,
    required this.onOpen,
    this.technicians = const <Technician>[],
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

  static const Key searchFieldKey = Key('serviceOrderListSearchField');

  static const Key statusFilterKey = Key('serviceOrderListStatusFilter');

  static const Key priorityFilterKey = Key('serviceOrderListPriorityFilter');

  static const Key technicianFilterKey = Key(
    'serviceOrderListTechnicianFilter',
  );

  static const Key clearFiltersButtonKey = Key(
    'serviceOrderListClearFiltersButton',
  );

  static const Key resultCountKey = Key('serviceOrderListResultCount');

  static const IconData overdueIcon = Icons.schedule;

  static const IconData urgentIcon = Icons.priority_high;

  static const IconData clearFiltersIcon = Icons.filter_alt_off;

  static const String emptyMessage = 'Nenhuma ordem de serviço cadastrada.';

  static const String noResultsMessage =
      'Nenhuma ordem encontrada para os critérios informados.';

  static const String clearFiltersLabel = 'Limpar filtros';

  static const String everyValueOption = 'Todos';

  static String resultCountLabel(int count) =>
      count == 1 ? '1 resultado' : '$count resultados';

  static Key itemKey(String number) =>
      ValueKey<String>('serviceOrderItem-$number');

  final VoidCallback onAdd;

  final ValueChanged<ServiceOrder> onOpen;

  final List<Technician> technicians;

  final bool busy;

  @override
  State<ServiceOrderListView> createState() => _ServiceOrderListViewState();
}

class _ServiceOrderListViewState extends State<ServiceOrderListView> {
  late final TextEditingController _searchController = TextEditingController(
    text: context.read<ServiceOrderController>().filter.term,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Future<void> _applyTerm(String term) {
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    return controller.applyFilter(controller.filter.copyWith(term: term));
  }

  Future<void> _applyStatus(ServiceOrderStatus? status) {
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    final ServiceOrderFilter filter = controller.filter;
    return controller.applyFilter(
      status == null
          ? filter.copyWith(clearStatus: true)
          : filter.copyWith(status: status),
    );
  }

  Future<void> _applyPriority(Priority? priority) {
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    final ServiceOrderFilter filter = controller.filter;
    return controller.applyFilter(
      priority == null
          ? filter.copyWith(clearPriority: true)
          : filter.copyWith(priority: priority),
    );
  }

  Future<void> _applyTechnician(int? technicianId) {
    final ServiceOrderController controller = context
        .read<ServiceOrderController>();
    final ServiceOrderFilter filter = controller.filter;
    return controller.applyFilter(
      technicianId == null
          ? filter.copyWith(clearTechnicianId: true)
          : filter.copyWith(technicianId: technicianId),
    );
  }

  Future<void> _clearFilters() {
    _searchController.clear();
    return context.read<ServiceOrderController>().clearFilter();
  }

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
              key: ServiceOrderListView.addButtonKey,
              onPressed: widget.busy ? null : widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova ordem'),
            ),
          ],
        ),
        _buildCriteria(controller),
        Expanded(child: _buildBody(controller)),
      ],
    );
  }

  Widget _buildCriteria(ServiceOrderController controller) {
    final ServiceOrderFilter filter = controller.filter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: 320,
                child: TextField(
                  key: ServiceOrderListView.searchFieldKey,
                  controller: _searchController,
                  enabled: !widget.busy,
                  decoration: _decoration(
                    'Buscar por número, cliente, equipamento ou técnico',
                  ).copyWith(prefixIcon: const Icon(Icons.search)),
                  onChanged: _applyTerm,
                ),
              ),
              SizedBox(
                key: ServiceOrderListView.statusFilterKey,
                width: 220,
                child: DropdownButtonFormField<ServiceOrderStatus?>(
                  isExpanded: true,
                  initialValue: filter.status,
                  decoration: _decoration('Status'),
                  items: <DropdownMenuItem<ServiceOrderStatus?>>[
                    const DropdownMenuItem<ServiceOrderStatus?>(
                      child: Text(ServiceOrderListView.everyValueOption),
                    ),
                    ...ServiceOrderStatus.values.map(
                      (ServiceOrderStatus status) =>
                          DropdownMenuItem<ServiceOrderStatus?>(
                            value: status,
                            child: Text(status.label),
                          ),
                    ),
                  ],
                  onChanged: widget.busy ? null : _applyStatus,
                ),
              ),
              SizedBox(
                key: ServiceOrderListView.priorityFilterKey,
                width: 220,
                child: DropdownButtonFormField<Priority?>(
                  isExpanded: true,
                  initialValue: filter.priority,
                  decoration: _decoration('Prioridade'),
                  items: <DropdownMenuItem<Priority?>>[
                    const DropdownMenuItem<Priority?>(
                      child: Text(ServiceOrderListView.everyValueOption),
                    ),
                    ...Priority.values.map(
                      (Priority priority) => DropdownMenuItem<Priority?>(
                        value: priority,
                        child: Text(priority.label),
                      ),
                    ),
                  ],
                  onChanged: widget.busy ? null : _applyPriority,
                ),
              ),
              SizedBox(
                key: ServiceOrderListView.technicianFilterKey,
                width: 220,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: filter.technicianId,
                  decoration: _decoration('Responsável'),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      child: Text(ServiceOrderListView.everyValueOption),
                    ),
                    ...widget.technicians.map(
                      (Technician technician) => DropdownMenuItem<int?>(
                        value: technician.id,
                        child: Text(technician.name),
                      ),
                    ),
                  ],
                  onChanged: widget.busy ? null : _applyTechnician,
                ),
              ),
            ],
          ),
          if (filter.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: <Widget>[
                  Text(
                    ServiceOrderListView.resultCountLabel(
                      controller.orders.length,
                    ),
                    key: ServiceOrderListView.resultCountKey,
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    key: ServiceOrderListView.clearFiltersButtonKey,
                    onPressed: widget.busy ? null : _clearFilters,
                    icon: const Icon(ServiceOrderListView.clearFiltersIcon),
                    label: const Text(ServiceOrderListView.clearFiltersLabel),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ServiceOrderController controller) {
    if (controller.loading) {
      return const Center(
        child: CircularProgressIndicator(
          key: ServiceOrderListView.loadingIndicatorKey,
        ),
      );
    }
    final String? error = controller.error;
    if (error != null) {
      return Center(
        child: Column(
          key: ServiceOrderListView.errorViewKey,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(error),
            const SizedBox(height: 16),
            OutlinedButton(
              key: ServiceOrderListView.retryButtonKey,
              onPressed: controller.load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final List<ServiceOrder> orders = controller.orders;
    if (orders.isEmpty) {
      return Center(
        child: Text(
          controller.filter.isActive
              ? ServiceOrderListView.noResultsMessage
              : ServiceOrderListView.emptyMessage,
        ),
      );
    }
    return ListView.builder(
      key: ServiceOrderListView.listKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: orders.length,
      itemBuilder: (BuildContext context, int index) => _ServiceOrderCard(
        order: orders[index],
        onTap: widget.busy ? null : () => widget.onOpen(orders[index]),
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
