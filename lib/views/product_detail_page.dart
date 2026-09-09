import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../state/shell_tab_controller.dart';
import '../state/wishlist_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/rating_stars.dart';

/// A single product.
///
/// The page scrolls as a whole. The previous version was an unscrollable
/// `Column` holding a full-size image and the full description, which overflowed
/// on anything smaller than a tablet.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  bool _descriptionExpanded = false;

  Product get _product => widget.product;

  void _addToCart() {
    unawaited(HapticFeedback.lightImpact());
    context.read<CartProvider>().addToCart(_product, quantity: _quantity);

    final shell = context.read<ShellTabController>();
    final navigator = Navigator.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Added $_quantity to your cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () {
              if (navigator.canPop()) navigator.pop();
              shell.goTo(ShellTabController.cartTab);
            },
          ),
        ),
      );
  }

  void _toggleFavorite() {
    unawaited(HapticFeedback.selectionClick());
    final saved = context.read<WishlistProvider>().toggle(_product.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(saved ? 'Saved for later' : 'Removed from saved'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLongDescription = _product.description.length > 180;

    return Scaffold(
      body: Center(
        // A product page pinned to the full width of a desktop window gives
        // unreadably long description lines.
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppSizes.detailContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 320,
                backgroundColor: scheme.surface,
                actions: [
                  FavoriteButton(
                    onPlate: false,
                    isFavorite:
                        context.watch<WishlistProvider>().contains(_product.id),
                    onPressed: _toggleFavorite,
                    title: _product.title,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ColoredBox(
                    // Product art is shot on white; it needs a light plate in both
                    // themes or it reads as a floating cut-out.
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Hero(
                        tag: 'product-image-${_product.id}',
                        child: ProductImage(
                          url: _product.image,
                          semanticLabel: _product.title,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList.list(
                  children: [
                    if (_product.category.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(_product.category),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(_product.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    if (_product.ratingCount > 0)
                      RatingStars(
                        rating: _product.rating,
                        count: _product.ratingCount,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      formatPrice(_product.price),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: AppSpacing.xl),
                    Text('About this item', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _product.description,
                      maxLines:
                          _descriptionExpanded || !isLongDescription ? null : 4,
                      overflow: _descriptionExpanded || !isLongDescription
                          ? null
                          : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (isLongDescription)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(
                            () => _descriptionExpanded = !_descriptionExpanded,
                          ),
                          child: Text(
                              _descriptionExpanded ? 'Show less' : 'Show more'),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _PurchaseBar(
        quantity: _quantity,
        onQuantityChanged: (value) => setState(() => _quantity = value),
        onAddToCart: _addToCart,
      ),
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          // Wrap, not Row: at 320dp with 2x text the stepper and the button do
          // not fit on one line, and a Row would overflow instead of stacking.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              QuantityStepper(value: quantity, onChanged: onQuantityChanged),
              FilledButton.icon(
                onPressed: onAddToCart,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Add to cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
