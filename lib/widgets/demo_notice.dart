import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// States plainly that accounts here are local and fake.
///
/// The app has no backend. Letting someone believe they have created a real
/// account, or that their password went somewhere, would be a lie told by
/// omission.
class DemoAccountNotice extends StatelessWidget {
  const DemoAccountNotice({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.tertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message ??
                  'Demo account. Any valid email and password signs you in. '
                      'Nothing is sent anywhere and no password is stored.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
