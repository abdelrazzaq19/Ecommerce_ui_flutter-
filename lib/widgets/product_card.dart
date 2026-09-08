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
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

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
                    if (onAddToCart != null)
                      Positioned(
                        right: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: _AddButton(
                          onPressed: onAddToCart!,
                          title: product.title,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.title});

  final VoidCallback onPressed;
  final String title;

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
      tooltip: 'Add $title to cart',
    );
  }
}
