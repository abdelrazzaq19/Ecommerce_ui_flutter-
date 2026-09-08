import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/search_provider.dart';
import 'package:ecommerce_app/views/search_page.dart';
import 'package:ecommerce_app/widgets/app_states.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

Product _product(int id, String title, String category, String description) =>
    Product(
      id: id,
      title: title,
      price: id * 10,
      description: description,
      image: 'https://example.test/$id.png',
      category: category,
      rating: 4,
      ratingCount: 10,
    );

final _catalog = [
  _product(1, 'Blue Cotton Shirt', "men's clothing", 'A soft everyday shirt.'),
  _product(2, 'Gold Ring', 'jewelery', 'Solid gold band.'),
  _product(3, 'Laptop Backpack', 'bags', 'Fits a 15 inch laptop and a shirt.'),
  _product(4, 'Silver Necklace', 'jewelery', 'Fine chain.'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProductImage.debugImageBuilder = (context, url) =>
        const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
  });

  tearDown(() => ProductImage.debugImageBuilder = null);

  Future<SearchProvider> pumpSearch(
    WidgetTester tester, {
    LocalStore? store,
    Size surface = const Size(400, 900),
  }) async {
    setViewport(tester, surface);

    final catalog = CatalogProvider(
      repository: FakeProductRepository(productsResult: Success(_catalog)),
      autoLoad: false,
    );
    await catalog.load();

    final search = SearchProvider(store: store);
    await pumpApp(
      tester,
      const SearchPage(),
      catalog: catalog,
      providers: [ChangeNotifierProvider.value(value: search)],
    );
    await tester.pumpAndSettle();
    return search;
  }

  /// Types [text] and, unless [wait] is false, lets the debounce elapse.
  ///
  /// `pumpAndSettle` alone will not do: with no animation scheduled it returns
  /// without advancing the clock, so the debounce timer never fires.
  Future<void> type(
    WidgetTester tester,
    String text, {
    bool wait = true,
  }) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    if (wait) {
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    }
  }

  group('debounce', () {
    testWidgets('waits before filtering, then filters once', (tester) async {
      await pumpSearch(tester);

      await type(tester, 'shirt', wait: false);
      expect(
        find.byType(ProductCard),
        findsNothing,
        reason: 'results must not appear on the first keystroke',
      );

      await tester.pump(const Duration(milliseconds: 299));
      expect(find.byType(ProductCard), findsNothing);

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('rapid typing only runs the final query', (tester) async {
      final search = await pumpSearch(tester);

      for (final text in ['g', 'go', 'gol', 'gold']) {
        await type(tester, text, wait: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(search.query, 'gold');
      expect(find.text('Gold Ring'), findsOneWidget);
    });
  });

  group('filtering', () {
    testWidgets('returns matches only, not the whole catalog', (tester) async {
      await pumpSearch(tester);

      await type(tester, 'shirt');
      await tester.pumpAndSettle();

      // "Blue Cotton Shirt" by title, "Laptop Backpack" by description.
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('Gold Ring'), findsNothing);
    });

    testWidgets('is case-insensitive and matches partial words',
        (tester) async {
      await pumpSearch(tester);

      await type(tester, 'NECK');
      await tester.pumpAndSettle();

      expect(find.text('Silver Necklace'), findsOneWidget);
    });

    testWidgets('matches on category too', (tester) async {
      await pumpSearch(tester);

      await type(tester, 'jewelery');
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsNWidgets(2));
    });

    testWidgets('title matches rank above description-only matches',
        (tester) async {
      final search = await pumpSearch(tester);

      await type(tester, 'shirt');
      await tester.pumpAndSettle();

      expect(search.filter(_catalog).first.title, 'Blue Cotton Shirt');
    });

    testWidgets('an unmatched query shows a no-results state naming the query',
        (tester) async {
      await pumpSearch(tester);

      await type(tester, 'submarine');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.textContaining('submarine'), findsWidgets);
      expect(find.byType(ProductCard), findsNothing);
    });
  });

  group('clearing', () {
    testWidgets('the clear button empties the field and the results',
        (tester) async {
      await pumpSearch(tester);

      await type(tester, 'gold');
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
    });
  });

  group('recent searches', () {
    testWidgets('submitting remembers the query and offers it back',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      await pumpSearch(tester, store: store);

      await type(tester, 'gold', wait: false);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(store.readSearchHistory(), contains('gold'));

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      // The idle screen offers the remembered query as a chip.
      expect(find.widgetWithText(ActionChip, 'gold'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'gold'));
      await tester.pumpAndSettle();

      expect(find.text('Gold Ring'), findsOneWidget);
    });

    testWidgets('opening a result remembers the query', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      await pumpSearch(tester, store: store);

      await type(tester, 'gold');
      await tester.tap(find.byType(ProductCard).first);
      await tester.pumpAndSettle();

      expect(store.readSearchHistory(), contains('gold'));
    });

    testWidgets('history can be cleared', (tester) async {
      SharedPreferences.setMockInitialValues({
        'searchHistory': '["gold","shirt"]',
      });
      final store = await LocalStore.open();
      await pumpSearch(tester, store: store);

      expect(find.widgetWithText(ActionChip, 'gold'), findsOneWidget);

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ActionChip, 'gold'), findsNothing);
      expect(store.readSearchHistory(), isEmpty);
    });

    testWidgets('typing alone does not fill the history with prefixes',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      await pumpSearch(tester, store: store);

      await type(tester, 'gold');
      await tester.pumpAndSettle();

      expect(store.readSearchHistory(), isEmpty);
    });
  });

  group('lifecycle', () {
    testWidgets('leaving mid-typing does not throw after dispose',
        (tester) async {
      await pumpSearch(tester);

      await type(tester, 'gold', wait: false);
      // Tear the page down while the debounce timer is still pending: the old
      // page called setState after an await with no mounted guard, and never
      // disposed its controller.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
