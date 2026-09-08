/// Design tokens shared by every screen.
///
/// Screens and widgets must read spacing, radii, durations and sizes from here
/// rather than hard-coding numbers, so the app stays consistent across the six
/// platforms it targets.
library;

/// Spacing scale, anchored to a 4dp grid.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. [pill] is large enough to fully round any control height.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  /// Cards and image plates. Slightly softer than [lg], which is used for
  /// controls, so surfaces read as calmer than the things you tap.
  static const double card = 20;
}

/// Elevation steps. Material 3 leans on tonal surfaces, so these stay low.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
}

/// Motion durations. Kept short: shopping UIs feel sluggish above ~300ms.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Delay before a search query is executed, so typing does not thrash state.
  static const Duration searchDebounce = Duration(milliseconds: 300);
}

/// Fixed sizes with a reason behind them.
abstract final class AppSizes {
  /// Accessibility floor for any interactive target (Material + WCAG 2.2).
  static const double minTapTarget = 48;

  /// Product imagery is square; FakeStore art is centred on white.
  static const double productImageAspect = 1;

  /// Wide desktop windows get a centred column instead of a 4000px-wide grid.
  static const double maxContentWidth = 1200;

  /// A single product reads better in a narrower column than the grid does.
  static const double detailContentWidth = 900;

  static const double skeletonRowHeight = 220;
}

/// Material 3 window size classes, used to lay out for phone, tablet and
/// desktop windows from one codebase.
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  /// Product-grid column count for a given available width.
  ///
  /// These thresholds are the grid's own, not the M3 window classes: a 1150dp
  /// window minus a navigation rail still deserves four cards per row, and
  /// three would leave each card uncomfortably large.
  static int columnsForWidth(double width) {
    if (width < 600) return 2;
    if (width < 1000) return 3;
    return 4;
  }

  static bool isCompact(double width) => width < compact;
  static bool isExpanded(double width) => width >= expanded;
}
