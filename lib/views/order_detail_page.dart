import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/shell_tab_controller.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import '../widgets/product_image.dart';

/// One past order.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.order});

  final Order order;

  /// Puts the order's products back in the cart and goes there.
  ///
  /// Products the store no longer sells are skipped and counted, rather than
  /// silently dropped or added as broken rows.
  void _reorder(BuildContext context) {
    final cart = context.read<CartProvider>();
    final catalog = context.read<CatalogProvider>();
    final shell = context.read<ShellTabController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    var added = 0;
    var missing = 0;
    for (final line in order.lines) {
      final product = catalog.productById(line.productId);
      if (product == null) {
        missing++;
      } else {
        cart.addToCart(product, quantity: line.quantity);
        added++;
      }
    }

    if (added == 0) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('None of these products are available any more'),
          ),
        );
      return;
    }

    final plural = missing == 1 ? 'item is' : 'items are';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            missing == 0
                ? 'Added back to your cart'
                : 'Added back to your cart. $missing $plural no longer available.',
          ),
        ),
      );

    shell.goTo(ShellTabController.cartTab);
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppSizes.detailContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                formatDateTime(order.placedAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      for (final line in order.lines) _LineRow(line: line),
                      const Divider(height: AppSpacing.lg),
                      _AmountRow(label: 'Subtotal', value: order.subtotal),
                      const SizedBox(height: AppSpacing.xs),
                      _AmountRow(
                        label: 'Delivery',
                        value: order.shipping,
                        freeWhenZero: true,
                      ),
                      const Divider(height: AppSpacing.lg),
                      _AmountRow(
                        label: 'Total',
                        value: order.total,
                        emphasised: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivered to', style: theme.textTheme.titleSmall),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => _reorder(context),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Order these again'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Prices shown are what you paid at the time.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 48,
              height: 48,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ProductImage(
                    url: line.image,
                    semanticLabel: line.title,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${line.quantity} x ${formatPrice(line.unitPrice)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              formatPrice(line.lineTotal),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    this.freeWhenZero = false,
  });

  final String label;
  final double value;
  final bool emphasised;
  final bool freeWhenZero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasised
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        Flexible(
          child: Text(
            freeWhenZero && value == 0 ? 'Free' : formatPrice(value),
            overflow: TextOverflow.ellipsis,
            style: emphasised
                ? theme.textTheme.titleLarge
                : theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
