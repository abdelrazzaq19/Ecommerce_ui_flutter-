import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/shell_tab_controller.dart';
import '../state/wishlist_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_states.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

/// Saved products, newest first.
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  void _moveToCart(BuildContext context, Product product) {
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final shell = context.read<ShellTabController>();

    cart.addToCart(product);
    wishlist.remove(product.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.title} moved to your cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => shell.goTo(ShellTabController.cartTab),
          ),
        ),
      );
  }

  void _remove(BuildContext context, Product product) {
    final wishlist = context.read<WishlistProvider>();
    wishlist.remove(product.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.title} removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => wishlist.add(product.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final catalog = context.watch<CatalogProvider>();
    final products = wishlist.resolve(catalog.allProducts);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        actions: [
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  products.length == 1 ? '1 item' : '${products.length} items',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: products.isEmpty
          ? EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'Nothing saved yet',
              message: 'Tap the heart on a product to keep it here for later.',
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
                child: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          AppBreakpoints.columnsForWidth(constraints.maxWidth),
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: AppBreakpoints.gridAspectRatio(
                        MediaQuery.textScalerOf(context).scale(1),
                      ),
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        isFavorite: true,
                        onFavoriteToggle: () => _remove(context, product),
                        onAddToCart: () => _moveToCart(context, product),
                        addToCartTooltip: 'Move ${product.title} to cart',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProductDetailPage(product: product),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
