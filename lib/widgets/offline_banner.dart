import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Tells the shopper the products on screen are the last ones we managed to
/// fetch, not today's.
///
/// Deliberately a banner and not an error screen: throwing away a working page
/// because a background refresh failed would be a worse experience than
/// slightly old prices, as long as we say so.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.cachedAt, this.onRetry});

  final DateTime? cachedAt;
  final VoidCallback? onRetry;

  /// "just now" / "12 minutes ago" / "3 days ago", plain enough to read at a
  /// glance without a date-formatting library.
  static String describeAge(DateTime? at, {DateTime? now}) {
    if (at == null) return 'last time you were online';

    final elapsed = (now ?? DateTime.now()).difference(at);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) {
      final minutes = elapsed.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (elapsed.inHours < 24) {
      final hours = elapsed.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    final days = elapsed.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Offline. Showing products saved ${describeAge(cachedAt)}.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
