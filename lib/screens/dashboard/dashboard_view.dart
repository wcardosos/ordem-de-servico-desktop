import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/formatters.dart';
import '../../core/service_order_labels.dart';
import '../../core/service_order_status.dart';
import '../../models/service_order_indicators.dart';
import '../../widgets/section_header.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const Key loadingIndicatorKey = Key('dashboardLoadingIndicator');

  static const Key errorViewKey = Key('dashboardErrorView');

  static const Key retryButtonKey = Key('dashboardRetryButton');

  static const Key cardsKey = Key('dashboardCards');

  static const String title = 'Painel';

  static const String totalLabel = 'Total de ordens';

  static const String openLabel = 'Abertas';

  static final String inProgressLabel = ServiceOrderStatus.inProgress.label;

  static final String awaitingPartLabel =
      ServiceOrderStatus.awaitingPart.label;

  static const String completedLabel = 'Concluídas';

  static const String urgentLabel = 'Urgentes';

  static const String overdueLabel = 'Atrasadas';

  static const String totalAmountLabel = 'Valor total';

  static const String retryLabel = 'Tentar novamente';

  static Key cardKey(String label) => ValueKey<String>('dashboardCard-$label');

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = context
        .watch<DashboardController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(title: title),
        Expanded(child: _buildBody(controller)),
      ],
    );
  }

  Widget _buildBody(DashboardController controller) {
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
              child: const Text(retryLabel),
            ),
          ],
        ),
      );
    }
    final ServiceOrderIndicators indicators = controller.indicators;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Wrap(
        key: cardsKey,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          _IndicatorCard(label: totalLabel, value: '${indicators.total}'),
          _IndicatorCard(label: openLabel, value: '${indicators.open}'),
          _IndicatorCard(
            label: inProgressLabel,
            value: '${indicators.inProgress}',
          ),
          _IndicatorCard(
            label: awaitingPartLabel,
            value: '${indicators.awaitingPart}',
          ),
          _IndicatorCard(
            label: completedLabel,
            value: '${indicators.completed}',
          ),
          _IndicatorCard(label: urgentLabel, value: '${indicators.urgent}'),
          _IndicatorCard(label: overdueLabel, value: '${indicators.overdue}'),
          _IndicatorCard(
            label: totalAmountLabel,
            value: formatCurrency(indicators.totalAmount),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.label, required this.value});

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      key: DashboardView.cardKey(label),
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
