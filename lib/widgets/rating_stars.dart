import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// A five-star rating with an optional review count.
///
/// The old detail page printed `Rating: 3.9`, which tells a shopper far less at
/// a glance than the stars they expect from every other store.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.count,
    this.size = 18,
  });

  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = theme.colorScheme.tertiary;

    return Semantics(
      label: count == null
          ? 'Rated ${rating.toStringAsFixed(1)} out of 5'
          : 'Rated ${rating.toStringAsFixed(1)} out of 5 from $count reviews',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              switch (rating - i) {
                >= 0 => Icons.star_rounded,
                >= -0.5 => Icons.star_half_rounded,
                _ => Icons.star_outline_rounded,
              },
              size: size,
              color: starColor,
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              count == null
                  ? rating.toStringAsFixed(1)
                  : '${rating.toStringAsFixed(1)} (${formatCount(count!)})',
              style: theme.textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
