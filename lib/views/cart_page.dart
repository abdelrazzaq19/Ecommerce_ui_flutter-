import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/shell_tab_controller.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import '../widgets/app_states.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';

/// The cart.
///
/// Two defects died here: it no longer calls a network method from inside
/// `FutureBuilder(future:)` — which re-fired on every rebuild forever — and it
/// resolves products through the catalog instead of a private ten-item cache.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final entries = cart.items.entries.toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (entries.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Clear'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: entries.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Products you add will show up here.',
              action: FilledButton.icon(
                onPressed: () => context
                    .read<ShellTabController>()
                    .goTo(ShellTabController.homeTab),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Browse products'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _FreeShippingHint(
                      remaining: cart.amountToFreeShipping(catalog.allProducts),
                    ),
                    for (final entry in entries) ...[
                      _CartRow(
                        productId: entry.key,
                        quantity: entry.value,
                        product: catalog.productById(entry.key),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _Totals(cart: cart, catalog: catalog.allProducts),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Demo store: placing an order records it on this device '
                      'only. No payment is taken.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: entries.isEmpty
          ? null
          : _CheckoutBar(total: cart.totalFor(catalog.allProducts)),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty your cart?'),
        content: const Text('This removes every product from the cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty cart'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) cart.clear();
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.productId,
    required this.quantity,
    required this.product,
  });

  final int productId;
  final int quantity;
  final Product? product;

  void _remove(BuildContext context) {
    final cart = context.read<CartProvider>();
    final removed = cart.removeFromCart(productId);
    if (removed == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(product?.title ?? 'Item removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cart.setQuantity(productId, removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();
    final item = product;

    if (item == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Product unavailable'),
          subtitle: Text('Quantity: $quantity'),
          trailing: IconButton(
            tooltip: 'Remove unavailable item',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _remove(context),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: ProductImage(
                      url: item.image,
                      semanticLabel: item.title,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove ${item.title}',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => _remove(context),
                      ),
                    ],
                  ),
                  Text(
                    '${formatPrice(item.price)} each',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Wrap so the stepper and the line total stack rather than
                  // overflow on a narrow phone at a large text scale.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      QuantityStepper(
                        value: quantity,
                        // Minus on the last unit removes the line, with Undo.
                        min: 0,
                        onChanged: (value) => value == 0
                            ? _remove(context)
                            : cart.setQuantity(productId, value),
                      ),
                      Text(
                        formatPrice(item.price * quantity),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nudges the shopper toward free delivery, or confirms they have it.
class _FreeShippingHint extends StatelessWidget {
  const _FreeShippingHint({required this.remaining});

  final double remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = remaining <= 0;
    final color = earned ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              earned
                  ? Icons.local_shipping_rounded
                  : Icons.local_shipping_outlined,
              color: color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                earned
                    ? 'Delivery is free on this order.'
                    : 'Add ${formatPrice(remaining)} more for free delivery.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.cart, required this.catalog});

  final CartProvider cart;
  final List<Product> catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = cart.subtotalFor(catalog);
    final shipping = CartProvider.shippingFor(subtotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _row(theme, 'Subtotal', formatPrice(subtotal)),
            const SizedBox(height: AppSpacing.sm),
            _row(
              theme,
              'Delivery',
              shipping == 0 ? 'Free' : formatPrice(shipping),
            ),
            const Divider(height: AppSpacing.xl),
            _row(
              theme,
              'Total',
              formatPrice(subtotal + shipping),
              emphasised: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool emphasised = false,
  }) {
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
        Text(
          value,
          style: emphasised
              ? theme.textTheme.titleLarge
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: theme.textTheme.labelMedium),
                  Text(formatPrice(total), style: theme.textTheme.headlineSmall),
                ],
              ),
              FilledButton.icon(
                // Wired up in Task 15.
                onPressed: null,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
