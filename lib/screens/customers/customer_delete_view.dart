import 'package:flutter/material.dart';

import '../../core/input_masks.dart';
import '../../models/customer.dart';
import '../../widgets/section_header.dart';

class CustomerDeleteView extends StatelessWidget {
  const CustomerDeleteView({
    super.key,
    required this.customer,
    required this.deleting,
    required this.onCancel,
    required this.onConfirm,
  });

  static const Key cancelButtonKey = Key('customerDeleteCancelButton');

  static const Key confirmButtonKey = Key('customerDeleteConfirmButton');

  final Customer customer;

  final bool deleting;

  final VoidCallback onCancel;

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(title: 'Excluir cliente'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Deseja excluir o cliente "${customer.name}"?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(formatDocument(customer.document)),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      OutlinedButton(
                        key: cancelButtonKey,
                        onPressed: deleting ? null : onCancel,
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        key: confirmButtonKey,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        onPressed: deleting ? null : onConfirm,
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
