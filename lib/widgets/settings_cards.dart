import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../state/order_provider.dart';
import '../state/search_provider.dart';
import '../state/settings_provider.dart';
import '../state/wishlist_provider.dart';
import '../theme/app_tokens.dart';

/// Theme picker.
///
/// Three options, not a switch: "System" has to be reachable, or someone who
/// tries Dark can never hand the choice back to their device.
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            // Three segments of icon + label do not fit a narrow phone at a
            // large text scale, and a segmented button cannot wrap. Stack the
            // options into rows instead of letting them overflow.
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                if (constraints.maxWidth < 320 || scale > 1.3) {
                  // ListTile with a trailing check rather than RadioListTile:
                  // the radio's own value handling is deprecated in favour of
                  // a RadioGroup ancestor.
                  return Column(
                    children: [
                      for (final mode in ThemeMode.values)
                        ListTile(
                          leading: Icon(SettingsProvider.iconFor(mode)),
                          title: Text(SettingsProvider.labelFor(mode)),
                          trailing: settings.themeMode == mode
                              ? Icon(
                                  Icons.check_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          selected: settings.themeMode == mode,
                          contentPadding: EdgeInsets.zero,
                          onTap: () => settings.setThemeMode(mode),
                        ),
                    ],
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      for (final mode in ThemeMode.values)
                        ButtonSegment<ThemeMode>(
                          value: mode,
                          icon: Icon(SettingsProvider.iconFor(mode)),
                          label: Text(SettingsProvider.labelFor(mode)),
                          tooltip: '${SettingsProvider.labelFor(mode)} theme',
                        ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) =>
                        settings.setThemeMode(selection.first),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              settings.followsSystem
                  ? 'Following your device setting.'
                  : 'Always ${SettingsProvider.labelFor(settings.themeMode).toLowerCase()}, whatever the device does.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// App version, and a way to wipe everything this app keeps on the device.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key, required this.version});

  final String version;

  Future<void> _confirmReset(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final orders = context.read<OrderProvider>();
    final search = context.read<SearchProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase local data?'),
        content: const Text(
          'This removes your cart, saved products, order history, search '
          'history and account from this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false)) return;

    // Cleared through the providers rather than the store directly, so memory
    // and disk cannot disagree afterwards.
    cart.clear();
    wishlist.clear();
    await orders.clear();
    await search.clearHistory();
    await auth.logout();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Local data erased')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Version $version',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Erase local data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
