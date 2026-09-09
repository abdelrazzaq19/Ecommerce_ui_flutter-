import 'package:ecommerce_app/theme/app_theme.dart';
import 'package:ecommerce_app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative-contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme', () {
    test('exposes Material 3 light and dark themes', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });

    test('both themes are seeded from the brand color', () {
      expect(AppTheme.brandSeed, const Color(0xFF3D5AFE));
      // A seeded scheme never returns the raw seed, but it must stay in the
      // same hue family rather than falling back to Flutter's default blue.
      for (final scheme in [AppTheme.light.colorScheme, AppTheme.dark.colorScheme]) {
        final hue = HSLColor.fromColor(scheme.primary).hue;
        expect(
          (hue - HSLColor.fromColor(AppTheme.brandSeed).hue).abs(),
          lessThan(30),
          reason: 'primary should stay within the brand hue family',
        );
      }
    });

    test('foreground pairs meet WCAG AA contrast in both themes', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final scheme = theme.colorScheme;
        expect(_contrast(scheme.primary, scheme.onPrimary), greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.surface, scheme.onSurface), greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.error, scheme.onError), greaterThanOrEqualTo(4.5));
      }
    });

    test('the pairs the app actually paints also clear AA', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final scheme = theme.colorScheme;
        final pairs = <String, List<Color>>{
          // Secondary text: product titles, hints, timestamps.
          'onSurfaceVariant on surface': [
            scheme.surface,
            scheme.onSurfaceVariant,
          ],
          // The same text inside a card, which is a different surface tone.
          'onSurfaceVariant on card': [
            scheme.surfaceContainerLow,
            scheme.onSurfaceVariant,
          ],
          'onSurface on card': [scheme.surfaceContainerLow, scheme.onSurface],
          // Filter chips and the navigation indicator.
          'onSecondaryContainer on secondaryContainer': [
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
          ],
          // Avatars and the checkout step numbers.
          'onPrimaryContainer on primaryContainer': [
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          ],
          // Inputs and the quantity stepper.
          'onSurface on surfaceContainerHighest': [
            scheme.surfaceContainerHighest,
            scheme.onSurface,
          ],
          // Bottom bars: cart totals, the purchase bar.
          'onSurface on surfaceContainer': [
            scheme.surfaceContainer,
            scheme.onSurface,
          ],
        };

        pairs.forEach((name, colors) {
          expect(
            _contrast(colors[0], colors[1]),
            greaterThanOrEqualTo(4.5),
            reason: '$name in ${theme.brightness.name}',
          );
        });
      }
    });

    test('the colors painted on the white product plate clear AA', () {
      // The rating pill and the heart sit on product art, which is always on a
      // white plate, so they are styled against white rather than the theme.
      const white = Color(0xFFFFFFFF);
      const pillBackground = Color(0xFF474747); // black at 72% over white
      const pillText = Color(0xFFFFFFFF);
      const heartInactive = Color(0xFF6B6B76);
      const plateFill = Color(0xFFEDEDF0);
      const plateInk = Color(0xFF6E6E7A);

      expect(_contrast(pillBackground, pillText), greaterThanOrEqualTo(4.5));
      expect(_contrast(white, heartInactive), greaterThanOrEqualTo(3.0),
          reason: 'an icon is a non-text element; AA asks 3:1');
      expect(_contrast(plateFill, plateInk), greaterThanOrEqualTo(3.0),
          reason: 'the fallback image glyph is non-text');
    });

    testWidgets('dark theme paints a dark scaffold', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Text('dark')),
        ),
      );

      final context = tester.element(find.text('dark'));
      expect(Theme.of(context).colorScheme.brightness, Brightness.dark);
      expect(Theme.of(context).scaffoldBackgroundColor.computeLuminance(), lessThan(0.2));
    });
  });

  group('AppTokens', () {
    test('spacing scale is monotonic and 4dp-based', () {
      final scale = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
      for (final step in scale) {
        expect(step % 4, 0, reason: 'spacing steps must sit on the 4dp grid');
      }
      expect(AppSpacing.md, 16.0);
    });

    test('breakpoints cover the six supported platforms', () {
      expect(AppBreakpoints.compact, lessThan(AppBreakpoints.medium));
      expect(AppBreakpoints.medium, lessThan(AppBreakpoints.expanded));

      expect(AppBreakpoints.columnsForWidth(360), 2); // phone
      expect(AppBreakpoints.columnsForWidth(800), 3); // tablet / small window
      expect(AppBreakpoints.columnsForWidth(1400), 4); // desktop
    });

    test('minimum tap target meets the accessibility floor', () {
      expect(AppSizes.minTapTarget, greaterThanOrEqualTo(48.0));
    });
  });
}
