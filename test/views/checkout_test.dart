import 'dart:math';

import 'package:ecommerce_app/models/order.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/order_provider.dart';
import 'package:ecommerce_app/views/checkout_page.dart';
import 'package:ecommerce_app/views/order_confirmation_page.dart';
import 'package:ecommerce_app/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = fakeCatalog(6);
  final cheap = catalog[0]; // $5.50
  final expensive = catalog[5]; // $33.00

  Future<LocalStore> emptyStore() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore.open();
  }

  Future<CatalogProvider> readyCatalog() async {
    final provider = CatalogProvider(
      repository: FakeProductRepository(productsResult: Success(catalog)),
      autoLoad: false,
    );
    await provider.load();
    return provider;
  }

  Future<AuthProvider> signedIn() async {
    final auth = AuthProvider(latency: Duration.zero);
    await auth.register(
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      phone: '08123456789',
      password: 'letters123',
    );
    return auth;
  }

  Future<void> pumpCheckout(
    WidgetTester tester, {
    required CartProvider cart,
    AuthProvider? auth,
    OrderProvider? orders,
    LocalStore? store,
    Size surface = const Size(500, 1400),
  }) async {
    setViewport(tester, surface);

    await pumpApp(
      tester,
      const CheckoutPage(),
      catalog: await readyCatalog(),
      providers: [
        Provider<LocalStore?>.value(value: store),
        ChangeNotifierProvider.value(
          value: auth ?? AuthProvider(latency: Duration.zero),
        ),
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider.value(value: orders ?? OrderProvider()),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAddress(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ada Lovelace');
    await tester.enterText(fields.at(1), '08123456789');
    await tester.enterText(fields.at(2), '12 Analytical Way');
    await tester.enterText(fields.at(3), 'London');
    await tester.enterText(fields.at(4), '12345');
    await tester.pumpAndSettle();
  }

  group('auth guard', () {
    testWidgets('signed out asks for sign-in instead of the form',
        (tester) async {
      await pumpCheckout(tester, cart: CartProvider()..addToCart(cheap));

      expect(find.text('Sign in to check out'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Place order · \$10.49'), findsNothing);
    });

    testWidgets('the form appears as soon as the session exists',
        (tester) async {
      final auth = AuthProvider(latency: Duration.zero);
      await pumpCheckout(
        tester,
        cart: CartProvider()..addToCart(cheap),
        auth: auth,
      );

      expect(find.byType(EmptyStateView), findsOneWidget);

      // Signing in happens on a pushed page; the checkout rebuilds when the
      // provider notifies, so the cart is never lost on the way.
      await auth.login(email: 'ada@example.com', password: 'letters123');
      await tester.pumpAndSettle();

      expect(find.text('Shipping address'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
    });
  });

  group('empty cart', () {
    testWidgets('cannot be checked out', (tester) async {
      await pumpCheckout(
        tester,
        cart: CartProvider(),
        auth: await signedIn(),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  });

  group('address form', () {
    testWidgets('prefills from the signed-in profile', (tester) async {
      await pumpCheckout(
        tester,
        cart: CartProvider()..addToCart(cheap),
        auth: await signedIn(),
      );

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('08123456789'), findsOneWidget);
    });

    testWidgets('prefills from the last address used', (tester) async {
      final store = await emptyStore();
      await store.writeAddress(const ShippingAddress(
        fullName: 'Grace Hopper',
        phone: '08199999999',
        street: '1 Compiler Road',
        city: 'Arlington',
        postalCode: '22202',
      ).toJson());

      await pumpCheckout(
        tester,
        cart: CartProvider()..addToCart(cheap),
        auth: await signedIn(),
        store: store,
      );

      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('1 Compiler Road'), findsOneWidget);
      expect(find.text('Arlington'), findsOneWidget);
    });

    testWidgets('blocks the order with an error per empty field',
        (tester) async {
      final orders = OrderProvider();
      final cart = CartProvider()..addToCart(cheap);
      final auth = AuthProvider(latency: Duration.zero);
      await auth.login(email: 'ada@example.com', password: 'letters123');

      await pumpCheckout(tester, cart: cart, auth: auth, orders: orders);
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '');
      await tester.enterText(fields.at(1), '');
      await tester.enterText(fields.at(2), 'abc');
      await tester.enterText(fields.at(3), '');
      await tester.enterText(fields.at(4), '');
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Place order'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter your phone number'), findsOneWidget);
      expect(find.text('Enter a street address'), findsOneWidget);
      expect(find.text('Enter a city'), findsOneWidget);
      expect(find.text('Enter a code'), findsOneWidget);

      expect(orders.isEmpty, isTrue);
      expect(cart.isEmpty, isFalse, reason: 'a blocked order keeps the cart');
    });
  });

  group('placing an order', () {
    testWidgets('records it, clears the cart and confirms', (tester) async {
      final store = await emptyStore();
      final orders = OrderProvider(store: store);
      final cart = CartProvider()
        ..addToCart(cheap, quantity: 2)
        ..addToCart(expensive);

      await pumpCheckout(
        tester,
        cart: cart,
        auth: await signedIn(),
        orders: orders,
        store: store,
      );

      await fillAddress(tester);
      await tester.tap(find.textContaining('Place order'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderConfirmationPage), findsOneWidget);
      expect(cart.isEmpty, isTrue);
      expect(orders.count, 1);

      final order = orders.orders.single;
      expect(order.id, matches(RegExp(r'^ORD-\d{8}-[0-9A-Z]{4}$')));
      expect(order.lines, hasLength(2));
      expect(order.itemCount, 3);
      expect(order.subtotal, closeTo(5.50 * 2 + 33.0, 0.001));
      expect(order.address.city, 'London');

      expect(find.text('Order ${order.id}'), findsOneWidget);
      expect(find.text('12 Analytical Way, London, 12345'), findsOneWidget);
    });

    testWidgets('survives a restart and remembers the address', (tester) async {
      final store = await emptyStore();
      final cart = CartProvider()..addToCart(cheap);

      await pumpCheckout(
        tester,
        cart: cart,
        auth: await signedIn(),
        orders: OrderProvider(store: store),
        store: store,
      );

      await fillAddress(tester);
      await tester.tap(find.textContaining('Place order'));
      await tester.pumpAndSettle();

      final restored = OrderProvider(store: store);
      expect(restored.count, 1);
      expect(restored.orders.single.lines.single.title, cheap.title);
      expect(store.readAddress()!['city'], 'London');
    });

    testWidgets('says plainly that nothing was charged', (tester) async {
      await pumpCheckout(
        tester,
        cart: CartProvider()..addToCart(cheap),
        auth: await signedIn(),
      );

      expect(find.textContaining('No payment is taken'), findsOneWidget);
      expect(find.textContaining('no card details'), findsOneWidget);
    });
  });

  group('OrderProvider', () {
    test('ids are unique, dated and readable', () async {
      final orders = OrderProvider(random: Random(7));
      final at = DateTime(2026, 9, 9, 14, 5);

      final first = await orders.placeOrder(
        lines: [OrderLine.fromProduct(cheap, 1)],
        address: ShippingAddress.empty,
        shipping: 4.99,
        placedAt: at,
      );

      expect(first.id, startsWith('ORD-20260909-'));
      expect(first.total, closeTo(5.50 + 4.99, 0.001));
    });

    test('newest first, and findable by id', () async {
      final orders = OrderProvider();

      final older = await orders.placeOrder(
        lines: [OrderLine.fromProduct(cheap, 1)],
        address: ShippingAddress.empty,
        shipping: 0,
        placedAt: DateTime(2026, 1, 1),
      );
      final newer = await orders.placeOrder(
        lines: [OrderLine.fromProduct(expensive, 1)],
        address: ShippingAddress.empty,
        shipping: 0,
        placedAt: DateTime(2026, 6, 1),
      );

      expect(orders.orders.first.id, newer.id);
      expect(orders.byId(older.id), isNotNull);
      expect(orders.byId('nope'), isNull);
    });

    test('a line keeps the price it was bought at', () {
      final line = OrderLine.fromProduct(cheap, 3);

      expect(line.unitPrice, cheap.price);
      expect(line.lineTotal, closeTo(cheap.price * 3, 0.001));
    });

    test('orders round-trip through JSON', () async {
      final orders = OrderProvider();
      final order = await orders.placeOrder(
        lines: [OrderLine.fromProduct(cheap, 2)],
        address: const ShippingAddress(
          fullName: 'Ada',
          phone: '0812',
          street: '12 Analytical Way',
          city: 'London',
          postalCode: '12345',
        ),
        shipping: 4.99,
        placedAt: DateTime(2026, 9, 9),
      );

      final restored = Order.fromJson(order.toJson());

      expect(restored.id, order.id);
      expect(restored.placedAt, order.placedAt);
      expect(restored.lines, order.lines);
      expect(restored.address, order.address);
      expect(restored.total, order.total);
    });

    test('a corrupt stored order does not take the history down', () async {
      SharedPreferences.setMockInitialValues({
        'orders': '[{"id": "ORD-1", "lines": "junk"}]',
      });
      final store = await LocalStore.open();

      final orders = OrderProvider(store: store);

      expect(orders.count, 1);
      expect(orders.orders.single.lines, isEmpty);
      expect(orders.orders.single.total, 0);
    });
  });
}
