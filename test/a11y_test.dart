import 'package:ecommerce_app/models/order.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/order_provider.dart';
import 'package:ecommerce_app/state/wishlist_provider.dart';
import 'package:ecommerce_app/views/app_shell.dart';
import 'package:ecommerce_app/views/cart_page.dart';
import 'package:ecommerce_app/views/checkout_page.dart';
import 'package:ecommerce_app/views/home_page.dart';
import 'package:ecommerce_app/views/login_page.dart';
import 'package:ecommerce_app/views/order_confirmation_page.dart';
import 'package:ecommerce_app/views/order_detail_page.dart';
import 'package:ecommerce_app/views/order_history_page.dart';
import 'package:ecommerce_app/views/product_detail_page.dart';
import 'package:ecommerce_app/views/profile_page.dart';
import 'package:ecommerce_app/views/register_page.dart';
import 'package:ecommerce_app/views/search_page.dart';
import 'package:ecommerce_app/views/wishlist_page.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_products.dart';
import 'helpers/fake_repository.dart';
import 'helpers/pump_app.dart';

/// The smallest width the app claims to support, and the largest text scale a
/// platform accessibility setting will hand it.
const Size _narrow = Size(320, 640);
const double _largeText = 2.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = fakeCatalog(6);
  final product = catalog.first;

  setUp(() {
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

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

  Future<Order> anOrder() async {
    final orders = OrderProvider();
    return orders.placeOrder(
      lines: [
        OrderLine.fromProduct(product, 2),
        OrderLine.fromProduct(catalog[1], 1),
      ],
      address: const ShippingAddress(
        fullName: 'Ada Lovelace',
        phone: '08123456789',
        street: '12 Analytical Way',
        city: 'London',
        postalCode: '12345',
      ),
      shipping: 4.99,
      placedAt: DateTime(2026, 9, 9, 10, 5),
    );
  }

  /// Builds every screen with enough state to be worth looking at.
  Future<void> pumpScreen(
    WidgetTester tester,
    String name, {
    required double textScale,
  }) async {
    setViewport(tester, _narrow);

    final orders = OrderProvider();
    await orders.placeOrder(
      lines: [OrderLine.fromProduct(product, 2)],
      address: const ShippingAddress(
        fullName: 'Ada Lovelace',
        phone: '08123456789',
        street: '12 Analytical Way',
        city: 'London',
        postalCode: '12345',
      ),
      shipping: 4.99,
    );

    final Widget screen = switch (name) {
      'home' => const HomePage(),
      'search' => const SearchPage(),
      'wishlist' => const WishlistPage(),
      'cart' => const CartPage(),
      'profile' => const ProfilePage(),
      'detail' => ProductDetailPage(product: product),
      'login' => const LoginPage(),
      'register' => const RegisterPage(),
      'checkout' => const CheckoutPage(),
      'confirmation' => OrderConfirmationPage(order: await anOrder()),
      'orders' => const OrderHistoryPage(),
      'orderDetail' => OrderDetailPage(order: await anOrder()),
      _ => const AppShell(),
    };

    await pumpApp(
      tester,
      screen,
      catalog: await readyCatalog(),
      textScale: textScale,
      providers: [
        ChangeNotifierProvider.value(value: await signedIn()),
        ChangeNotifierProvider.value(
          value: CartProvider()
            ..addToCart(product, quantity: 2)
            ..addToCart(catalog[1]),
        ),
        ChangeNotifierProvider.value(
          value: WishlistProvider()
            ..add(product.id)
            ..add(catalog[2].id),
        ),
        ChangeNotifierProvider.value(value: orders),
      ],
    );
    await tester.pumpAndSettle();
  }

  const screens = [
    'home',
    'search',
    'wishlist',
    'cart',
    'profile',
    'detail',
    'login',
    'register',
    'checkout',
    'confirmation',
    'orders',
    'orderDetail',
    'shell',
  ];

  group('no overflow at 320dp', () {
    for (final screen in screens) {
      testWidgets(screen, (tester) async {
        await pumpScreen(tester, screen, textScale: 1.0);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('no overflow at 2.0x text scale', () {
    for (final screen in screens) {
      testWidgets(screen, (tester) async {
        await pumpScreen(tester, screen, textScale: _largeText);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('icon-only controls are labelled', () {
    testWidgets('every IconButton on every screen has a tooltip',
        (tester) async {
      for (final screen in screens) {
        await pumpScreen(tester, screen, textScale: 1.0);

        for (final button in tester.widgetList<IconButton>(
          find.byType(IconButton, skipOffstage: false),
        )) {
          expect(
            button.tooltip,
            isNotNull,
            reason: 'an unlabelled IconButton on "$screen" tells a screen '
                'reader nothing',
          );
          expect(button.tooltip, isNotEmpty);
        }
      }
    });
  });

  group('tap targets', () {
    testWidgets('interactive controls are at least 48dp', (tester) async {
      for (final screen in screens) {
        await pumpScreen(tester, screen, textScale: 1.0);

        final finders = [
          find.byType(IconButton),
          find.byType(FilledButton),
          find.byType(OutlinedButton),
        ];

        for (final finder in finders) {
          for (final element in finder.evaluate()) {
            final size = tester.getSize(find.byWidget(element.widget).first);
            expect(
              size.height,
              greaterThanOrEqualTo(48.0),
              reason: '${element.widget.runtimeType} on "$screen" is '
                  '${size.height}dp tall',
            );
          }
        }
      }
    });
  });
}
