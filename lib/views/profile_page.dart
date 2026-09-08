import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../state/auth_provider.dart';
import '../theme/app_tokens.dart';

/// Account screen.
///
/// Orders (Task 16) and the theme selector (Task 17) land here later. For now
/// it shows the real sign-in state rather than pretending to hold data.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    auth.isAuthenticated
                        ? Icons.account_circle
                        : Icons.person_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    auth.isAuthenticated ? 'Signed in' : 'Not signed in',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    auth.isAuthenticated
                        ? 'This is a local demo account. No data leaves this device.'
                        : 'Sign in to save a wishlist and keep your orders.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (auth.isAuthenticated)
                    OutlinedButton.icon(
                      onPressed: auth.logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.login),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
