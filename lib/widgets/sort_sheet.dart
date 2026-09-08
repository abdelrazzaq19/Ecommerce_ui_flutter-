import 'package:flutter/material.dart';

import '../state/catalog_provider.dart';
import '../theme/app_tokens.dart';

/// Bottom sheet for choosing a sort order.
///
/// Returns the chosen [CatalogSort], or null if dismissed.
Future<CatalogSort?> showSortSheet(
  BuildContext context, {
  required CatalogSort current,
}) {
  return showModalBottomSheet<CatalogSort>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      // Scrollable: the default sheet is capped at 9/16 of the screen, which a
      // short phone cannot fit five options into.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Sort by',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // A plain ListTile with a trailing check, rather than
            // RadioListTile: the radio's own value handling is deprecated in
            // favour of a RadioGroup ancestor, and this sheet closes on the
            // first tap anyway.
            for (final option in CatalogSort.values)
              ListTile(
                title: Text(option.label),
                trailing: option == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                selected: option == current,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    ),
  );
}
