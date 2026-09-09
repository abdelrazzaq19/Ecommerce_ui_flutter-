import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import 'product_image.dart';

/// A product tile in the catalog grid.
///
/// Replaces the single-line `ListTile` the app used to show: a shopper decides
/// from the picture, the price and the rating, and none of those were visible.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.addToCartTooltip,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  /// Shows a heart over the artwork when provided.
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  /// Overrides the add button's label, so the wishlist can say "Move to cart".
  final String? addToCartTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        // Product art is shot on white, so it needs a light
                        // plate to sit on even in dark mode.
                        child: ColoredBox(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Hero(
                              tag: 'product-image-${product.id}',
                              child: ProductImage(
                                url: product.image,
                                semanticLabel: product.title,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (product.ratingCount > 0)
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: _RatingPill(rating: product.rating),
                      ),
                    if (onFavoriteToggle != null)
                      Positioned(
                        right: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: FavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: onFavoriteToggle!,
                          title: product.title,
                        ),
                      ),
                    if (onAddToCart != null)
                      Positioned(
                        right: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: _AddButton(
                          onPressed: onAddToCart!,
                          tooltip: addToCartTooltip ??
                              'Add ${product.title} to cart',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                // Merged so a screen reader announces "title, price" as one
                // item instead of two unrelated fragments.
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.3,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formatPrice(product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rating badge floated over the artwork, so the row below stays a clean
/// title-and-price pair.
class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        // Sits on the white image plate in both themes, so this pill is styled
        // against white rather than against the surface color.
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFC857)),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Heart toggle, styled against the white image plate rather than the theme
/// surface, since that is what it sits on in both light and dark.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    required this.title,
    this.onPlate = true,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final String title;

  /// False when the button sits on a normal themed surface, such as an app bar.
  final bool onPlate;

  static const Color _saved = Color(0xFFE0245E);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      iconSize: 22,
      tooltip:
          isFavorite ? 'Remove $title from saved' : 'Save $title for later',
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite
            ? _saved
            : (onPlate ? const Color(0xFF6B6B76) : scheme.onSurfaceVariant),
      ),
      style: onPlate
          ? IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              minimumSize: const Size.square(AppSizes.minTapTarget),
            )
          : IconButton.styleFrom(
              minimumSize: const Size.square(AppSizes.minTapTarget),
            ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.square(AppSizes.minTapTarget),
      ),
      // Icon-only control: the label tells a screen reader which product.
      tooltip: tooltip,
    );
  }
}
