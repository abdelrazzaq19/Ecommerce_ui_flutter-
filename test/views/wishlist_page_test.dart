import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/shell_tab_controller.dart';
import 'package:ecommerce_app/state/wishlist_provider.dart';
import 'package:ecommerce_app/views/home_page.dart';
import 'package:ecommerce_app/views/product_detail_page.dart';
import 'package:ecommerce_app/views/wishlist_page.dart';
import 'package:ecommerce_app/widgets/app_states.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  final catalog = fakeCatalog(6);

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

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required WishlistProvider wishlist,
    CartProvider? cart,
    ShellTabController? shell,
    Size surface = const Size(420, 900),
  }) async {
    setViewport(tester, surface);

    await pumpApp(
      tester,
      screen,
      catalog: await readyCatalog(),
      providers: [
        ChangeNotifierProvider.value(value: wishlist),
        ChangeNotifierProvider.value(value: cart ?? CartProvider()),
        ChangeNotifierProvider.value(value: shell ?? ShellTabController()),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('empty wishlist', () {
    testWidgets('offers a way back to the catalog', (tester) async {
      final shell = ShellTabController();
      await pumpScreen(
        tester,
        const WishlistPage(),
        wishlist: WishlistProvider(),
        shell: shell,
      );

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsOneWidget);

      await tester.tap(find.text('Browse products'));
      await tester.pumpAndSettle();

      expect(shell.index, ShellTabController.homeTab);
    });
  });

  group('saved products', () {
    testWidgets('renders newest first with the heart already filled',
        (tester) async {
      final wishlist = WishlistProvider()
        ..add(1)
        ..add(4);

      await pumpScreen(tester, const WishlistPage(), wishlist: wishlist);

      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('2 items'), findsOneWidget);

      final first = tester.widget<ProductCard>(find.byType(ProductCard).first);
      expect(first.product.id, 4, reason: 'newest saved comes first');
      expect(first.isFavorite, isTrue);
    });

    testWidgets('the heart removes the product, with undo', (tester) async {
      final wishlist = WishlistProvider()..add(1);

      await pumpScreen(tester, const WishlistPage(), wishlist: wishlist);

      await tester.tap(find.byTooltip('Remove Product 1 from saved'));
      await tester.pumpAndSettle();

      expect(wishlist.isEmpty, isTrue);
      expect(find.byType(EmptyStateView), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(wishlist.contains(1), isTrue);
      expect(find.byType(ProductCard), findsOneWidget);
    });

    testWidgets('move to cart adds it and takes it off the wishlist',
        (tester) async {
      final wishlist = WishlistProvider()..add(2);
      final cart = CartProvider();
      final shell = ShellTabController();

      await pumpScreen(
        tester,
        const WishlistPage(),
        wishlist: wishlist,
        cart: cart,
        shell: shell,
      );

      await tester.tap(find.byTooltip('Move Product 2 to cart'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf(2), 1);
      expect(wishlist.contains(2), isFalse);
      expect(find.textContaining('moved to your cart'), findsOneWidget);

      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();

      expect(shell.index, ShellTabController.cartTab);
    });

    testWidgets('a product the catalog dropped is simply not shown',
        (tester) async {
      final wishlist = WishlistProvider()
        ..add(1)
        ..add(999);

      await pumpScreen(tester, const WishlistPage(), wishlist: wishlist);

      expect(find.byType(ProductCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('hearts elsewhere', () {
    testWidgets('the home grid toggles the wishlist', (tester) async {
      final wishlist = WishlistProvider();

      await pumpScreen(tester, const HomePage(), wishlist: wishlist);

      await tester.tap(find.byTooltip('Save Product 1 for later'));
      await tester.pumpAndSettle();

      expect(wishlist.contains(1), isTrue);
      expect(find.byTooltip('Remove Product 1 from saved'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove Product 1 from saved'));
      await tester.pumpAndSettle();

      expect(wishlist.contains(1), isFalse);
    });

    testWidgets('the detail page toggles the same wishlist', (tester) async {
      final wishlist = WishlistProvider();

      await pumpScreen(
        tester,
        ProductDetailPage(product: catalog.first),
        wishlist: wishlist,
      );

      await tester.tap(find.byTooltip('Save Product 1 for later'));
      await tester.pumpAndSettle();

      expect(wishlist.contains(1), isTrue);
      expect(find.text('Saved for later'), findsOneWidget);
    });
  });
}
