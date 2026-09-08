import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/api_exception.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/views/home_page.dart';
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
  setUp(() {
    // Product imagery is network-backed; widget tests render a stand-in so no
    // test depends on an HTTP client or an image cache plugin.
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

  Future<void> pumpHome(
    WidgetTester tester, {
    required FakeProductRepository repository,
    int pageSize = 8,
    Size surface = const Size(400, 900),
  }) async {
    setViewport(tester, surface);

    await pumpApp(
      tester,
      const HomePage(),
      catalog: CatalogProvider(
        repository: repository,
        pageSize: pageSize,
        autoLoad: false,
      ),
    );
  }

  group('loading', () {
    testWidgets('shows skeletons first, then products, with no interaction',
        (tester) async {
      final repository = FakeProductRepository(
        productsResult: Success(fakeCatalog(20)),
        delay: const Duration(milliseconds: 50),
      );
      await pumpHome(tester, repository: repository);

      await tester.pump();
      expect(find.byType(ProductSkeletonGrid), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(ProductSkeletonGrid), findsNothing);
      expect(find.byType(ProductCard), findsWidgets);
      expect(repository.fetchCount, 1,
          reason: 'the home page must load itself on first build');
    });
  });

  group('error state', () {
    testWidgets('renders the message and a working retry', (tester) async {
      final repository = FakeProductRepository(
        productsResult: Failure(ApiException.timeout()),
      );
      await pumpHome(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.textContaining('took too long'), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.fetchCount, 2);
    });
  });

  group('empty state', () {
    testWidgets('says the store is empty rather than showing a blank page',
        (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(productsResult: const EmptyResult()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });
  });

  group('content', () {
    testWidgets('renders a card per product with title and price',
        (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(4)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('\$5.50'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(4));
    });

    testWidgets('lays out more columns as the window grows', (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(8)),
        ),
        surface: const Size(1400, 1000),
      );
      await tester.pumpAndSettle();

      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });
  });

  group('add to cart', () {
    testWidgets('the card button adds the product and confirms it',
        (tester) async {
      final cart = CartProvider();
      setViewport(tester, const Size(400, 900));
      await pumpApp(
        tester,
        const HomePage(),
        catalog: CatalogProvider(
          repository: FakeProductRepository(
            productsResult: Success(fakeCatalog(2)),
          ),
          autoLoad: false,
        ),
        providers: [ChangeNotifierProvider.value(value: cart)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add Product 1 to cart'));
      await tester.pump();

      expect(cart.itemCount, 1);
      expect(find.textContaining('added to cart'), findsOneWidget);
    });
  });

  group('filter and sort bar', () {
    testWidgets('category chips narrow the grid and update the count',
        (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(6)),
          categoriesResult: const Success(['electronics', 'jewelery']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('6 products'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'jewelery'));
      await tester.pumpAndSettle();

      // fakeCatalog alternates categories, so half the products match.
      expect(find.text('3 products'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(3));
    });

    testWidgets('the sort sheet reorders the grid and Reset restores it',
        (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(4)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Featured'), findsOneWidget);

      await tester.tap(find.text('Featured'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low'));
      await tester.pumpAndSettle();

      expect(find.text('Price: high to low'), findsOneWidget);
      // fakeCatalog prices ascend with id, so product 4 is dearest.
      final firstCard = tester.widget<ProductCard>(
        find.byType(ProductCard).first,
      );
      expect(firstCard.product.title, 'Product 4');

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Featured'), findsOneWidget);
      expect(
        tester
            .widget<ProductCard>(find.byType(ProductCard).first)
            .product
            .title,
        'Product 1',
      );
    });
  });

  group('narrow screens', () {
    testWidgets('the filter bar does not overflow at 320dp with a long sort '
        'label', (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(6)),
          categoriesResult: const Success(['electronics', 'jewelery']),
        ),
        surface: const Size(320, 640),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Featured'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'jewelery'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('paging', () {
    testWidgets('appends the next page on scroll and stops at the end',
        (tester) async {
      await pumpHome(
        tester,
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(20)),
        ),
        pageSize: 8,
      );
      await tester.pumpAndSettle();

      // Only the first page exists: product 9 belongs to page two.
      expect(find.text('Product 9', skipOffstage: false), findsNothing);
      expect(find.text('Keep scrolling for more', skipOffstage: false),
          findsOneWidget);

      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
      }

      expect(find.text('Product 20', skipOffstage: false), findsOneWidget);
      expect(find.text('You have seen every product', skipOffstage: false),
          findsOneWidget);
    });
  });

  group('pull to refresh', () {
    testWidgets('refetches the catalog', (tester) async {
      final repository = FakeProductRepository(
        productsResult: Success(fakeCatalog(20)),
      );
      await pumpHome(tester, repository: repository);
      await tester.pumpAndSettle();

      await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repository.fetchCount, 2);
    });
  });
}
