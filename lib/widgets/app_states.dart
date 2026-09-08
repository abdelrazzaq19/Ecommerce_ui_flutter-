import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Shown when a request failed.
///
/// The old code caught errors into an empty block and rendered nothing, so a
/// dropped connection was indistinguishable from an empty store. This states
/// what happened and offers the one action that can help.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CenteredState(
      children: [
        _StateIcon(icon: icon, color: theme.colorScheme.error),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Something went wrong',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ],
    );
  }
}

/// Shown when a request succeeded but there is nothing to display.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CenteredState(
      children: [
        _StateIcon(icon: icon, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: AppSpacing.lg),
          action!,
        ],
      ],
    );
  }
}

/// Placeholder grid shown while the catalog loads.
///
/// Deliberately static rather than animated: a repeating shimmer never settles,
/// which would hang every `pumpAndSettle` in the test suite.
class ProductSkeletonGrid extends StatelessWidget {
  const ProductSkeletonGrid({
    super.key,
    required this.columns,
    this.itemCount = 6,
  });

  final int columns;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.74,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}

/// The icon in a soft tinted disc, rather than a bare glyph floating in space.
class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 44, color: color),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
