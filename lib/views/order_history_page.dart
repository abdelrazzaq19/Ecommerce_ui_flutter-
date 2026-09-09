import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/order_provider.dart';
import '../state/shell_tab_controller.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import '../widgets/app_states.dart';
import 'order_detail_page.dart';

/// Past orders, newest first.
///
/// No delivery status is shown. This app has no fulfilment behind it, and a
/// made-up "Shipped" badge would be a lie dressed as a feature.
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.isEmpty
          ? EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Orders you place are kept here on this device.',
              action: FilledButton.icon(
                onPressed: () {
                  context
                      .read<ShellTabController>()
                      .goTo(ShellTabController.homeTab);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Browse products'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSizes.detailContentWidth),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _OrderRow(order: orders[index]),
                ),
              ),
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = order.itemCount == 1 ? '1 item' : '${order.itemCount} items';

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailPage(order: order),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.id, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDate(order.placedAt)} · $items',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  formatPrice(order.total),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
