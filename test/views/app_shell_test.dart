import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/routes.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/views/app_shell.dart';
import 'package:ecommerce_app/views/cart_page.dart';
import 'package:ecommerce_app/views/home_page.dart';
import 'package:ecommerce_app/views/profile_page.dart';
import 'package:ecommerce_app/views/search_page.dart';
import 'package:ecommerce_app/views/wishlist_page.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() {
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

  Future<CartProvider> pumpShell(
    WidgetTester tester, {
    Size surface = const Size(400, 900),
    int products = 8,
  }) async {
    setViewport(tester, surface);

    final cart = CartProvider();
    await pumpApp(
      tester,
      const AppShell(),
      catalog: CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(products)),
        ),
        autoLoad: false,
      ),
      providers: [ChangeNotifierProvider.value(value: cart)],
    );
    await tester.pumpAndSettle();
    return cart;
  }

  group('destinations', () {
    testWidgets('every screen is reachable from the shell', (tester) async {
      await pumpShell(tester);

      expect(find.byType(HomePage), findsOneWidget);

      for (final destination in [
        ('Search', SearchPage),
        ('Saved', WishlistPage),
        ('Cart', CartPage),
        ('Profile', ProfilePage),
        ('Home', HomePage),
      ]) {
        await tester.tap(find.text(destination.$1).last);
        await tester.pumpAndSettle();
        expect(
          find.byType(destination.$2),
          findsOneWidget,
          reason: '${destination.$1} should be reachable',
        );
      }
    });

    testWidgets('keeps each tab on its own scroll position', (tester) async {
      await pumpShell(tester, products: 20);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsNothing);

      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Product 1'),
        findsNothing,
        reason: 'returning to a tab must not reset its scroll offset',
      );
    });
  });

  group('cart badge', () {
    testWidgets('appears and counts items as they are added', (tester) async {
      final cart = await pumpShell(tester);

      expect(find.byType(Badge), findsNothing);

      cart
        ..addToCart(fakeCatalog(2).first)
        ..addToCart(fakeCatalog(2).first)
        ..addToCart(fakeCatalog(2).last);
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('adaptive navigation', () {
    testWidgets('uses a bottom bar on a phone', (tester) async {
      await pumpShell(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('uses a side rail on a desktop window', (tester) async {
      await pumpShell(tester, surface: const Size(1200, 900));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('named routes', () {
    testWidgets('the home route resolves, so a login redirect cannot crash',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: appProviders(repository: FakeProductRepository()),
          child: MaterialApp(
            initialRoute: AppRoutes.home,
            routes: appRoutes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppShell));
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('the login route resolves', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: appProviders(repository: FakeProductRepository()),
          child: MaterialApp(
            initialRoute: AppRoutes.login,
            routes: appRoutes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sign in'), findsWidgets);
    });
  });
}
