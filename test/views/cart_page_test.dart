import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/views/cart_page.dart';
import 'package:ecommerce_app/widgets/app_states.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:ecommerce_app/widgets/quantity_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  final catalog = fakeCatalog(20);
  final cheap = catalog[0]; // $5.50
  final expensive = catalog[19]; // $110.00

  setUp(() {
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

  Future<CartProvider> pumpCart(
    WidgetTester tester, {
    required CartProvider cart,
    Size surface = const Size(400, 900),
  }) async {
    setViewport(tester, surface);

    final catalogProvider = CatalogProvider(
      repository: FakeProductRepository(productsResult: Success(catalog)),
      autoLoad: false,
    );
    await catalogProvider.load();

    await pumpApp(
      tester,
      const CartPage(),
      catalog: catalogProvider,
      providers: [ChangeNotifierProvider.value(value: cart)],
    );
    await tester.pumpAndSettle();
    return cart;
  }

  group('empty cart', () {
    testWidgets('shows an empty state and a way back to the catalog',
        (tester) async {
      await pumpCart(tester, cart: CartProvider());

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Browse products'), findsOneWidget);
      expect(find.text('Checkout'), findsNothing);
    });
  });

  group('line items', () {
    testWidgets('shows the product, unit price and line total', (tester) async {
      await pumpCart(
        tester,
        cart: CartProvider()..addToCart(cheap, quantity: 2),
      );

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('\$5.50 each'), findsOneWidget);
      expect(find.text('\$11.00'), findsWidgets);
      expect(find.byType(QuantityStepper), findsOneWidget);
    });

    testWidgets('the stepper changes the quantity and the totals',
        (tester) async {
      final cart = await pumpCart(
        tester,
        cart: CartProvider()..addToCart(cheap),
      );

      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf(cheap.id), 2);
      expect(find.text('\$11.00'), findsWidgets);
    });

    testWidgets('stepping the last unit down removes the line and offers undo',
        (tester) async {
      final cart = await pumpCart(
        tester,
        cart: CartProvider()..addToCart(cheap),
      );

      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
      expect(find.byType(EmptyStateView), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf(cheap.id), 1);
      expect(find.byType(QuantityStepper), findsOneWidget);
    });

    testWidgets('the close button removes the line with undo', (tester) async {
      final cart = await pumpCart(
        tester,
        cart: CartProvider()..addToCart(cheap, quantity: 3),
      );

      await tester.tap(find.byTooltip('Remove Product 1'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(
        cart.quantityOf(cheap.id),
        3,
        reason: 'undo must restore the quantity, not just one unit',
      );
    });
  });

  group('totals', () {
    testWidgets('charges delivery below the free threshold', (tester) async {
      await pumpCart(tester, cart: CartProvider()..addToCart(cheap));

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('\$4.99'), findsOneWidget);
      expect(find.textContaining('more for free delivery'), findsOneWidget);
      expect(find.text('\$10.49'), findsWidgets); // 5.50 + 4.99
    });

    testWidgets('waives delivery once the threshold is met', (tester) async {
      await pumpCart(tester, cart: CartProvider()..addToCart(expensive));

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Delivery is free on this order.'), findsOneWidget);
      expect(find.text('\$110.00'), findsWidgets);
    });

    testWidgets('says plainly that no payment is taken', (tester) async {
      await pumpCart(tester, cart: CartProvider()..addToCart(cheap));

      expect(find.textContaining('No payment is taken'), findsOneWidget);
    });
  });

  group('clear', () {
    testWidgets('asks before emptying the cart', (tester) async {
      final cart = await pumpCart(
        tester,
        cart: CartProvider()..addToCart(cheap),
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(cart.isEmpty, isFalse);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empty cart'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
    });
  });

  group('unavailable products', () {
    testWidgets('an id the catalog does not know can still be removed',
        (tester) async {
      final cart = CartProvider();
      cart.setQuantity(9999, 2);

      await pumpCart(tester, cart: cart);

      expect(find.text('Product unavailable'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove unavailable item'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
    });
  });
}
