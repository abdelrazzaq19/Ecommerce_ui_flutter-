import 'package:ecommerce_app/models/order.dart';
import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/order_provider.dart';
import 'package:ecommerce_app/state/shell_tab_controller.dart';
import 'package:ecommerce_app/views/order_detail_page.dart';
import 'package:ecommerce_app/views/order_history_page.dart';
import 'package:ecommerce_app/views/profile_page.dart';
import 'package:ecommerce_app/widgets/app_states.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
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

  const address = ShippingAddress(
    fullName: 'Ada Lovelace',
    phone: '08123456789',
    street: '12 Analytical Way',
    city: 'London',
    postalCode: '12345',
  );

  setUp(() {
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

  Future<CatalogProvider> readyCatalog([List<Product>? products]) async {
    final provider = CatalogProvider(
      repository: FakeProductRepository(
        productsResult: Success(products ?? catalog),
      ),
      autoLoad: false,
    );
    await provider.load();
    return provider;
  }

  Future<OrderProvider> withOrders({LocalStore? store}) async {
    final orders = OrderProvider(store: store);
    await orders.placeOrder(
      lines: [OrderLine.fromProduct(cheap, 2)],
      address: address,
      shipping: 4.99,
      placedAt: DateTime(2026, 1, 15, 9),
    );
    await orders.placeOrder(
      lines: [
        OrderLine.fromProduct(catalog[1], 1),
        OrderLine.fromProduct(catalog[2], 3),
      ],
      address: address,
      shipping: 0,
      placedAt: DateTime(2026, 6, 20, 18, 30),
    );
    return orders;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    OrderProvider? orders,
    CartProvider? cart,
    ShellTabController? shell,
    List<Product>? products,
    Size surface = const Size(500, 1100),
  }) async {
    setViewport(tester, surface);

    await pumpApp(
      tester,
      screen,
      catalog: await readyCatalog(products),
      providers: [
        ChangeNotifierProvider.value(value: orders ?? OrderProvider()),
        ChangeNotifierProvider.value(value: cart ?? CartProvider()),
        ChangeNotifierProvider.value(value: shell ?? ShellTabController()),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('empty history', () {
    testWidgets('says so and offers the catalog', (tester) async {
      final shell = ShellTabController();
      await pumpScreen(tester, const OrderHistoryPage(), shell: shell);

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No orders yet'), findsOneWidget);

      await tester.tap(find.text('Browse products'));
      await tester.pumpAndSettle();

      expect(shell.index, ShellTabController.homeTab);
    });
  });

  group('history list', () {
    testWidgets('lists newest first with date, item count and total',
        (tester) async {
      final orders = await withOrders();
      await pumpScreen(tester, const OrderHistoryPage(), orders: orders);

      final rows = find.byType(InkWell);
      expect(rows, findsNWidgets(2));

      // 20 Jun order first: 1 + 3 items, no delivery charge.
      expect(find.text('20 Jun 2026 · 4 items'), findsOneWidget);
      expect(find.text('15 Jan 2026 · 2 items'), findsOneWidget);

      // 2 x $5.50 + $4.99 delivery.
      expect(find.text('\$15.99'), findsOneWidget);
    });

    testWidgets('shows no invented delivery status', (tester) async {
      await pumpScreen(
        tester,
        const OrderHistoryPage(),
        orders: await withOrders(),
      );

      for (final invented in ['Shipped', 'Delivered', 'In transit']) {
        expect(find.text(invented), findsNothing, reason: 'for "$invented"');
      }
    });

    testWidgets('survives a restart', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      await withOrders(store: store);

      await pumpScreen(
        tester,
        const OrderHistoryPage(),
        orders: OrderProvider(store: store),
      );

      expect(find.byType(InkWell), findsNWidgets(2));
    });
  });

  group('order detail', () {
    testWidgets('opens from the list and shows the price paid', (tester) async {
      // The catalog now sells the same product for far more; the order must
      // still show what was actually paid.
      final repriced = [
        Product(
          id: cheap.id,
          title: cheap.title,
          price: 999,
          description: cheap.description,
          image: cheap.image,
          category: cheap.category,
          rating: cheap.rating,
          ratingCount: cheap.ratingCount,
        ),
        ...catalog.skip(1),
      ];

      await pumpScreen(
        tester,
        const OrderHistoryPage(),
        orders: await withOrders(),
        products: repriced,
      );

      await tester.tap(find.text('15 Jan 2026 · 2 items'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailPage), findsOneWidget);
      expect(find.text('2 x \$5.50'), findsOneWidget);
      expect(find.text('\$999.00'), findsNothing);
      expect(find.text('12 Analytical Way, London, 12345'), findsOneWidget);
      expect(find.text('\$4.99'), findsOneWidget);
    });
  });

  group('reorder', () {
    testWidgets('refills the cart and goes to it', (tester) async {
      final cart = CartProvider();
      final shell = ShellTabController();
      final orders = await withOrders();

      await pumpScreen(
        tester,
        OrderDetailPage(order: orders.orders.last),
        cart: cart,
        shell: shell,
      );

      await tester.tap(find.text('Order these again'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf(cheap.id), 2);
      expect(shell.index, ShellTabController.cartTab);
    });

    testWidgets('skips products the store no longer has and says how many',
        (tester) async {
      final cart = CartProvider();
      final orders = OrderProvider();
      await orders.placeOrder(
        lines: [
          OrderLine.fromProduct(cheap, 1),
          const OrderLine(
            productId: 9999,
            title: 'Discontinued thing',
            image: '',
            unitPrice: 10,
            quantity: 1,
          ),
        ],
        address: address,
        shipping: 0,
      );

      await pumpScreen(
        tester,
        OrderDetailPage(order: orders.orders.single),
        cart: cart,
      );

      await tester.tap(find.text('Order these again'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf(cheap.id), 1);
      expect(cart.distinctItemCount, 1);
      expect(find.textContaining('1 item is no longer available'),
          findsOneWidget);
    });

    testWidgets('an order of only discontinued products adds nothing',
        (tester) async {
      final cart = CartProvider();
      final shell = ShellTabController();
      final orders = OrderProvider();
      await orders.placeOrder(
        lines: [
          const OrderLine(
            productId: 9999,
            title: 'Discontinued thing',
            image: '',
            unitPrice: 10,
            quantity: 1,
          ),
        ],
        address: address,
        shipping: 0,
      );

      await pumpScreen(
        tester,
        OrderDetailPage(order: orders.orders.single),
        cart: cart,
        shell: shell,
      );

      await tester.tap(find.text('Order these again'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
      expect(
        find.text('None of these products are available any more'),
        findsOneWidget,
      );
      expect(shell.index, ShellTabController.homeTab);
    });
  });

  group('profile link', () {
    testWidgets('shows the order count', (tester) async {
      await pumpScreen(
        tester,
        const ProfilePage(),
        orders: await withOrders(),
      );

      expect(find.text('Your orders'), findsOneWidget);
      expect(find.text('2 orders on this device'), findsOneWidget);
    });

    testWidgets('reads "Nothing ordered yet" when empty', (tester) async {
      await pumpScreen(tester, const ProfilePage());

      expect(find.text('Nothing ordered yet'), findsOneWidget);
    });
  });
}
