import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/service_order_labels.dart';
import '../../core/service_order_status.dart';
import '../../core/service_order_transitions.dart';
import '../../core/validators.dart';
import '../../models/part_item.dart';
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
    required this.onAddPartItem,
    required this.onRemovePartItem,
    required this.onSaveLaborCost,
    required this.onAttachImage,
    required this.onRemoveImage,
    this.imagePath,
    this.imageMissing = false,
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

  static const Key addPartItemButtonKey = Key('serviceOrderAddPartItemButton');

  static const Key partItemDescriptionFieldKey = Key(
    'serviceOrderPartItemDescriptionField',
  );

  static const Key partItemQuantityFieldKey = Key(
    'serviceOrderPartItemQuantityField',
  );

  static const Key partItemUnitPriceFieldKey = Key(
    'serviceOrderPartItemUnitPriceField',
  );

  static const Key confirmPartItemButtonKey = Key(
    'serviceOrderPartItemConfirmButton',
  );

  static const Key cancelPartItemButtonKey = Key(
    'serviceOrderPartItemCancelButton',
  );

  static const Key laborCostFieldKey = Key('serviceOrderLaborCostField');

  static const Key saveLaborCostButtonKey = Key(
    'serviceOrderSaveLaborCostButton',
  );

  static const Key partsTotalKey = Key('serviceOrderPartsTotal');

  static const Key totalAmountKey = Key('serviceOrderTotalAmount');

  static Key partItemSubtotalKey(int itemId) =>
      ValueKey<String>('serviceOrderPartItemSubtotal-$itemId');

  static Key removePartItemButtonKey(int itemId) =>
      ValueKey<String>('serviceOrderRemovePartItemButton-$itemId');

  static const Key imageSlotKey = Key('serviceOrderDetailImageSlot');

  static const Key attachImageButtonKey = Key('serviceOrderAttachImageButton');

  static const Key removeImageButtonKey = Key('serviceOrderRemoveImageButton');

  static const String imageMissingMessage = 'Imagem não encontrada.';

  static const String noImageMessage = 'Nenhuma imagem anexada.';

  static const String notInformed = 'Não informado';

  static const String noTechnician = 'Sem responsável';

  static const String closedOrderMessage = 'Esta ordem está encerrada.';

  static const String noPartItemsMessage = 'Nenhuma peça registrada.';

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static Key fieldKey(String name) =>
      ValueKey<String>('serviceOrderDetailField-$name');

  final ServiceOrder order;

  final VoidCallback onBack;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  final ValueChanged<ServiceOrderStatus> onChangeStatus;

  final Future<bool> Function(PartItem item) onAddPartItem;

  final Future<void> Function(PartItem item) onRemovePartItem;

  final Future<bool> Function(double laborCost) onSaveLaborCost;

  final VoidCallback onAttachImage;

  final VoidCallback onRemoveImage;

  final String? imagePath;

  final bool imageMissing;

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
                    _PartsSection(
                      key: partsSlotKey,
                      order: order,
                      busy: busy,
                      onAddPartItem: onAddPartItem,
                      onRemovePartItem: onRemovePartItem,
                      onSaveLaborCost: onSaveLaborCost,
                    ),
                    _ImageSection(
                      key: imageSlotKey,
                      imagePath: imagePath,
                      imageMissing: imageMissing,
                      editable: _acceptsValueChanges(order.status),
                      busy: busy,
                      onAttachImage: onAttachImage,
                      onRemoveImage: onRemoveImage,
                    ),
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

bool _acceptsValueChanges(ServiceOrderStatus status) =>
    status != ServiceOrderStatus.completed &&
    status != ServiceOrderStatus.cancelled;

class _PartsSection extends StatefulWidget {
  const _PartsSection({
    super.key,
    required this.order,
    required this.busy,
    required this.onAddPartItem,
    required this.onRemovePartItem,
    required this.onSaveLaborCost,
  });

  final ServiceOrder order;

  final bool busy;

  final Future<bool> Function(PartItem item) onAddPartItem;

  final Future<void> Function(PartItem item) onRemovePartItem;

  final Future<bool> Function(double laborCost) onSaveLaborCost;

  @override
  State<_PartsSection> createState() => _PartsSectionState();
}

class _PartsSectionState extends State<_PartsSection> {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'pt_BR');

  final GlobalKey<FormState> _itemFormKey = GlobalKey<FormState>();

  final GlobalKey<FormState> _laborCostFormKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _quantityController = TextEditingController();

  final TextEditingController _unitPriceController = TextEditingController();

  late final TextEditingController _laborCostController;

  bool _addingItem = false;

  @override
  void initState() {
    super.initState();
    _laborCostController = TextEditingController(
      text: _amountFormat.format(widget.order.laborCost),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _laborCostController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  void _startNewItem() => setState(() => _addingItem = true);

  void _cancelNewItem() {
    setState(() {
      _addingItem = false;
      _descriptionController.clear();
      _quantityController.clear();
      _unitPriceController.clear();
    });
  }

  Future<void> _confirmNewItem() async {
    final FormState? form = _itemFormKey.currentState;
    final int? serviceOrderId = widget.order.id;
    if (form == null || !form.validate() || serviceOrderId == null) {
      return;
    }
    final int? quantity = int.tryParse(_quantityController.text.trim());
    final double? unitPrice = parseDecimal(_unitPriceController.text);
    if (quantity == null || unitPrice == null) {
      return;
    }
    final bool added = await widget.onAddPartItem(
      PartItem(
        serviceOrderId: serviceOrderId,
        description: _descriptionController.text.trim(),
        quantity: quantity,
        unitPrice: unitPrice,
      ),
    );
    if (!added || !mounted) {
      return;
    }
    _cancelNewItem();
  }

  Future<void> _saveLaborCost() async {
    final FormState? form = _laborCostFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final double? laborCost = parseDecimal(_laborCostController.text);
    if (laborCost == null) {
      return;
    }
    await widget.onSaveLaborCost(laborCost);
  }

  Widget _partItemRow(ThemeData theme, PartItem item, bool editable) {
    final int itemId = item.id ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.description, style: theme.textTheme.bodyLarge),
                Text(
                  '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            key: ServiceOrderDetailView.partItemSubtotalKey(itemId),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              formatCurrency(item.subtotal),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (editable)
            IconButton(
              key: ServiceOrderDetailView.removePartItemButtonKey(itemId),
              tooltip: 'Remover item',
              onPressed: widget.busy
                  ? null
                  : () => widget.onRemovePartItem(item),
              icon: const Icon(Icons.delete_outline),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _newItemForm() {
    return Form(
      key: _itemFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            key: ServiceOrderDetailView.partItemDescriptionFieldKey,
            controller: _descriptionController,
            enabled: !widget.busy,
            decoration: _decoration('Descrição da peça'),
            validator: validatePartDescription,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ServiceOrderDetailView.partItemQuantityFieldKey,
                  controller: _quantityController,
                  enabled: !widget.busy,
                  decoration: _decoration('Quantidade'),
                  validator: validateQuantity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: ServiceOrderDetailView.partItemUnitPriceFieldKey,
                  controller: _unitPriceController,
                  enabled: !widget.busy,
                  decoration: _decoration('Valor unitário'),
                  validator: validateUnitPrice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OutlinedButton(
                key: ServiceOrderDetailView.cancelPartItemButtonKey,
                onPressed: widget.busy ? null : _cancelNewItem,
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: ServiceOrderDetailView.confirmPartItemButtonKey,
                onPressed: widget.busy ? null : _confirmNewItem,
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _laborCostForm(bool editable) {
    return Form(
      key: _laborCostFormKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TextFormField(
              key: ServiceOrderDetailView.laborCostFieldKey,
              controller: _laborCostController,
              enabled: editable && !widget.busy,
              decoration: _decoration('Valor da mão de obra'),
              validator: validateLaborCost,
            ),
          ),
          if (editable) ...<Widget>[
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: FilledButton(
                key: ServiceOrderDetailView.saveLaborCostButtonKey,
                onPressed: widget.busy ? null : _saveLaborCost,
                child: const Text('Salvar mão de obra'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ServiceOrder order = widget.order;
    final bool editable = _acceptsValueChanges(order.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Peças utilizadas', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          if (order.partItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                ServiceOrderDetailView.noPartItemsMessage,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ...order.partItems.map(
            (PartItem item) => _partItemRow(theme, item, editable),
          ),
          if (editable)
            if (_addingItem)
              _newItemForm()
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: ServiceOrderDetailView.addPartItemButtonKey,
                  onPressed: widget.busy ? null : _startNewItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                ),
              ),
          const SizedBox(height: 24),
          Text('Mão de obra', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          _laborCostForm(editable),
          const SizedBox(height: 24),
          _AmountRow(
            slotKey: ServiceOrderDetailView.partsTotalKey,
            label: 'Subtotal de peças',
            value: formatCurrency(order.partsTotal),
          ),
          _AmountRow(
            slotKey: ServiceOrderDetailView.totalAmountKey,
            label: 'Valor total',
            value: formatCurrency(order.totalAmount),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    super.key,
    required this.imagePath,
    required this.imageMissing,
    required this.editable,
    required this.busy,
    required this.onAttachImage,
    required this.onRemoveImage,
  });

  final String? imagePath;

  final bool imageMissing;

  final bool editable;

  final bool busy;

  final VoidCallback onAttachImage;

  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? path = imagePath;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Imagem da evidência', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          if (path == null)
            Text(
              imageMissing
                  ? ServiceOrderDetailView.imageMissingMessage
                  : ServiceOrderDetailView.noImageMessage,
              style: theme.textTheme.bodyLarge,
            )
          else
            Image.file(
              File(path),
              height: 240,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorBuilder:
                  (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) => const Icon(Icons.broken_image_outlined, size: 48),
            ),
          if (editable) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                OutlinedButton.icon(
                  key: ServiceOrderDetailView.attachImageButtonKey,
                  onPressed: busy ? null : onAttachImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Anexar imagem'),
                ),
                if (path != null || imageMissing)
                  OutlinedButton.icon(
                    key: ServiceOrderDetailView.removeImageButtonKey,
                    onPressed: busy ? null : onRemoveImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover imagem'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.slotKey,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final Key slotKey;

  final String label;

  final String value;

  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = emphasized
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyLarge;
    return Padding(
      key: slotKey,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style),
          Text(value, style: style),
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
