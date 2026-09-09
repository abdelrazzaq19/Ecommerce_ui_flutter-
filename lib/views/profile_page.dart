import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_session.dart';
import '../routes.dart';
import '../state/auth_provider.dart';
import '../state/order_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/app_info.dart';
import '../widgets/settings_cards.dart';
import '../widgets/demo_notice.dart';

/// Account and settings.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = auth.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.formWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (session == null)
                const _SignedOutCard()
              else
                _SignedInCard(session: session),
              const SizedBox(height: AppSpacing.md),
              const _OrdersTile(),
              const SizedBox(height: AppSpacing.md),
              const AppearanceCard(),
              const SizedBox(height: AppSpacing.md),
              const AboutCard(version: AppInfo.version),
              const SizedBox(height: AppSpacing.md),
              const DemoAccountNotice(
                message: 'Accounts here are local to this device. There is no '
                    'server, and no password is stored.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Link into the order history, with the count so it is worth tapping.
class _OrdersTile extends StatelessWidget {
  const _OrdersTile();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<OrderProvider>().count;
    final theme = Theme.of(context);
    final plural = count == 1 ? 'order' : 'orders';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.receipt_long_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: const Text('Your orders'),
        subtitle: Text(
          count == 0
              ? 'Nothing ordered yet'
              : '$count $plural on this device',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.orders),
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Not signed in', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in to keep your wishlist and orders.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.login),
              icon: const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.register),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.session});

  final UserSession session;

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your cart and wishlist stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    session.initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        session.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (session.phone.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      session.phone,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
