import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/views/product_detail_page.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:ecommerce_app/widgets/quantity_stepper.dart';
import 'package:ecommerce_app/widgets/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/pump_app.dart';

final _product = Product(
  id: 1,
  title: 'Fjallraven Foldsack No. 1 Backpack',
  price: 109.95,
  description: 'Your perfect pack for everyday use and walks in the forest. '
      'Stash your laptop in the padded sleeve, your everyday essentials in the '
      'main compartment, and a water bottle in the side pocket. Built from '
      'hard-wearing Vinylon F with a leather logo patch and a top handle.',
  image: 'https://example.test/backpack.png',
  category: "men's clothing",
  rating: 3.9,
  ratingCount: 120,
);

void main() {
  setUp(() {
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

  Future<CartProvider> pumpDetail(
    WidgetTester tester, {
    Size surface = const Size(400, 800),
    double textScale = 1.0,
  }) async {
    setViewport(tester, surface);
    final cart = CartProvider();

    await pumpApp(
      tester,
      ProductDetailPage(product: _product),
      textScale: textScale,
      providers: [ChangeNotifierProvider.value(value: cart)],
    );
    await tester.pumpAndSettle();
    return cart;
  }

  group('content', () {
    testWidgets('shows title, formatted price, rating and category',
        (tester) async {
      await pumpDetail(tester);

      expect(find.text('Fjallraven Foldsack No. 1 Backpack'), findsWidgets);
      expect(find.text('\$109.95'), findsOneWidget);
      expect(find.byType(RatingStars), findsOneWidget);
      expect(find.textContaining('120'), findsOneWidget);
      expect(find.text("men's clothing"), findsOneWidget);
    });

    testWidgets('long descriptions collapse behind a toggle', (tester) async {
      await pumpDetail(tester);

      // The toggle sits below the image header, so scroll it into view first.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsOneWidget);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      // Expanding pushes the toggle further down the page.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('does not overflow on a 320dp wide screen', (tester) async {
      await pumpDetail(tester, surface: const Size(320, 640));

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at 2.0x text scale', (tester) async {
      await pumpDetail(tester, surface: const Size(320, 640), textScale: 2.0);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the whole page scrolls, including the description',
        (tester) async {
      await pumpDetail(tester, surface: const Size(320, 500));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuantityStepper), findsOneWidget);
    });
  });

  group('quantity stepper', () {
    testWidgets('increments and decrements, never below one', (tester) async {
      await pumpDetail(tester);

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pump();
      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });

  group('add to cart', () {
    testWidgets('adds the selected quantity and offers a way to the cart',
        (tester) async {
      final cart = await pumpDetail(tester);

      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pump();
      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Add to cart'));
      await tester.pump();

      expect(cart.quantityOf(_product.id), 3);
      expect(find.textContaining('Added 3'), findsOneWidget);
      expect(find.text('View cart'), findsOneWidget);
    });
  });

  group('RatingStars', () {
    testWidgets('renders five stars and an accessible label', (tester) async {
      setViewport(tester, const Size(400, 800));
      await pumpApp(
        tester,
        const Scaffold(body: RatingStars(rating: 3.5, count: 42)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(
        tester.getSemantics(find.byType(RatingStars)).label,
        contains('3.5'),
      );
    });
  });
}
