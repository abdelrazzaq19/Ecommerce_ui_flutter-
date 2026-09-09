import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/shell_tab_controller.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';

/// Shown once an order is recorded.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.order});

  final Order order;

  void _backToShopping(BuildContext context) {
    context.read<ShellTabController>().goTo(ShellTabController.homeTab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order placed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppSizes.detailContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Thanks, your order is in',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Order ${order.id}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatDateTime(order.placedAt),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivering to', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(order.address.fullName),
                      Text(
                        order.address.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        order.address.phone,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: AppSpacing.xl),
                      Text('Items', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      for (final line in order.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${line.quantity}x ',
                                style: theme.textTheme.labelLarge,
                              ),
                              Expanded(
                                child: Text(
                                  line.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                formatPrice(line.lineTotal),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total paid',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            formatPrice(order.total),
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Demo order: nothing was charged and nothing will ship. '
                'The record lives on this device and you can find it under '
                'your profile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => _backToShopping(context),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Continue shopping'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
