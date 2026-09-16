import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/customer_controller.dart';
import '../../core/input_masks.dart';
import '../../models/customer.dart';
import '../../widgets/section_header.dart';

class CustomerListView extends StatelessWidget {
  const CustomerListView({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.notice,
    this.onDismissNotice,
  });

  static const Key loadingIndicatorKey = Key('customerListLoadingIndicator');

  static const Key listKey = Key('customerListView');

  static const Key errorViewKey = Key('customerListErrorView');

  static const Key retryButtonKey = Key('customerListRetryButton');

  static const Key addButtonKey = Key('customerListAddButton');

  static const Key noticeKey = Key('customerListNotice');

  static const Key dismissNoticeButtonKey = Key('customerListDismissNotice');

  static Key editButtonKey(int? id) =>
      ValueKey<String>('customerEditButton-$id');

  static Key deleteButtonKey(int? id) =>
      ValueKey<String>('customerDeleteButton-$id');

  final VoidCallback onAdd;

  final ValueChanged<Customer> onEdit;

  final ValueChanged<Customer> onDelete;

  final String? notice;

  final VoidCallback? onDismissNotice;

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = context.watch<CustomerController>();
    final String? currentNotice = notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Clientes',
          actions: <Widget>[
            FilledButton.icon(
              key: addButtonKey,
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo cliente'),
            ),
          ],
        ),
        if (currentNotice != null)
          _Notice(message: currentNotice, onDismiss: onDismissNotice),
        Expanded(child: _buildBody(context, controller)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, CustomerController controller) {
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
    final List<Customer> customers = controller.customers;
    if (customers.isEmpty) {
      return const Center(child: Text('Nenhum cliente cadastrado.'));
    }
    return ListView.separated(
      key: listKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: customers.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Customer customer = customers[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: Text(formatDocument(customer.document)),
          onTap: () => onEdit(customer),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                key: editButtonKey(customer.id),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar cliente',
                onPressed: () => onEdit(customer),
              ),
              IconButton(
                key: deleteButtonKey(customer.id),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir cliente',
                onPressed: () => onDelete(customer),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.onDismiss});

  final String message;

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      key: CustomerListView.noticeKey,
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          IconButton(
            key: CustomerListView.dismissNoticeButtonKey,
            icon: Icon(Icons.close, color: colors.onErrorContainer),
            tooltip: 'Fechar aviso',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
