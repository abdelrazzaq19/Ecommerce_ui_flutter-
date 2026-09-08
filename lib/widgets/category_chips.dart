import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Horizontal category filter. "All" is always first and always available.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;

  /// null means "All".
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: AppSizes.minTapTarget,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _chip(context, label: 'All', value: null),
          for (final category in categories)
            _chip(context, label: category, value: category),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required String? value,
  }) {
    final isSelected = selected == value;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        // Tapping the selected chip should not clear it; "All" is the way back.
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}
