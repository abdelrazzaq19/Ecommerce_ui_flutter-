import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/api_exception.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/views/home_page.dart';
import 'package:ecommerce_app/widgets/app_states.dart';
import 'package:ecommerce_app/widgets/offline_banner.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = fakeCatalog(12);

  Future<LocalStore> emptyStore() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore.open();
  }

  /// A store that already holds a catalog, as a second launch would find.
  Future<LocalStore> storeWithCache() async {
    final store = await emptyStore();
    await store.writeCachedCatalog(catalog);
    return store;
  }

  group('cold start', () {
    test('a first launch has nothing to show until the network answers',
        () async {
      final store = await emptyStore();
      final provider = CatalogProvider(
        repository: FakeProductRepository(productsResult: Success(catalog)),
        store: store,
        autoLoad: false,
      );

      expect(provider.status, CatalogStatus.initial);
      expect(provider.isShowingCachedData, isFalse);
    });

    test('a successful load writes the cache', () async {
      final store = await emptyStore();
      final provider = CatalogProvider(
        repository: FakeProductRepository(productsResult: Success(catalog)),
        store: store,
        autoLoad: false,
      );

      await provider.load();

      expect(store.readCachedCatalog(), catalog);
      expect(store.readCatalogCachedAt(), isNotNull);
      expect(provider.isShowingCachedData, isFalse);
    });
  });

  group('second launch', () {
    test('renders cached products synchronously, before any response',
        () async {
      final store = await storeWithCache();
      final repository = FakeProductRepository(
        productsResult: Success(catalog),
        delay: const Duration(milliseconds: 50),
      );

      final provider = CatalogProvider(
        repository: repository,
        store: store,
        autoLoad: false,
      );

      // No await: this is the state at the moment the provider is built.
      expect(provider.status, CatalogStatus.ready);
      expect(provider.allProducts, hasLength(12));
      expect(provider.visibleProducts, isNotEmpty);
      expect(provider.isShowingCachedData, isTrue);
      expect(repository.fetchCount, 0);
    });

    test('derives categories from the cache so the filter row still works',
        () async {
      final store = await storeWithCache();

      final provider =
          CatalogProvider(repository: FakeProductRepository(), store: store, autoLoad: false);

      expect(provider.categories, isNotEmpty);
    });

    test('a background refresh replaces the cache and clears the flag',
        () async {
      final store = await storeWithCache();
      final fresher = fakeCatalog(3);
      final provider = CatalogProvider(
        repository: FakeProductRepository(productsResult: Success(fresher)),
        store: store,
        autoLoad: false,
      );
      expect(provider.isShowingCachedData, isTrue);

      await provider.load(refresh: true);

      expect(provider.isShowingCachedData, isFalse);
      expect(provider.allProducts, hasLength(3));
      expect(store.readCachedCatalog(), hasLength(3));
    });
  });

  group('offline', () {
    test('keeps cached products on screen when the refresh fails', () async {
      final store = await storeWithCache();
      final provider = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Failure(ApiException.network()),
        ),
        store: store,
        autoLoad: false,
      );

      await provider.load(refresh: true);

      expect(
        provider.status,
        CatalogStatus.ready,
        reason: 'a failed background refresh must not replace a working page',
      );
      expect(provider.allProducts, hasLength(12));
      expect(provider.isShowingCachedData, isTrue);
      expect(provider.error, isNotNull);
    });

    test('falls back to the full error state when there is no cache', () async {
      final store = await emptyStore();
      final provider = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Failure(ApiException.network()),
        ),
        store: store,
        autoLoad: false,
      );

      await provider.load();

      expect(provider.status, CatalogStatus.error);
      expect(provider.isShowingCachedData, isFalse);
      expect(provider.error!.isRetryable, isTrue);
    });

    test('an empty response clears the cache flag rather than pretending',
        () async {
      final store = await storeWithCache();
      final provider = CatalogProvider(
        repository: FakeProductRepository(productsResult: const EmptyResult()),
        store: store,
        autoLoad: false,
      );

      await provider.load(refresh: true);

      expect(provider.status, CatalogStatus.empty);
      expect(provider.isShowingCachedData, isFalse);
    });
  });

  group('OfflineBanner.describeAge', () {
    final now = DateTime(2026, 9, 9, 12);

    test('reads plainly at every scale', () {
      expect(OfflineBanner.describeAge(null), 'last time you were online');
      expect(
        OfflineBanner.describeAge(now.subtract(const Duration(seconds: 20)),
            now: now),
        'just now',
      );
      expect(
        OfflineBanner.describeAge(now.subtract(const Duration(minutes: 1)),
            now: now),
        '1 minute ago',
      );
      expect(
        OfflineBanner.describeAge(now.subtract(const Duration(minutes: 12)),
            now: now),
        '12 minutes ago',
      );
      expect(
        OfflineBanner.describeAge(now.subtract(const Duration(hours: 5)),
            now: now),
        '5 hours ago',
      );
      expect(
        OfflineBanner.describeAge(now.subtract(const Duration(days: 3)),
            now: now),
        '3 days ago',
      );
    });
  });

  group('home page', () {
    setUp(() {
      ProductImage.debugImageBuilder = (context, url) =>
          const ColoredBox(color: Color(0xFFCCCCCC), child: SizedBox.expand());
    });

    tearDown(() => ProductImage.debugImageBuilder = null);

    testWidgets('shows products and a banner when offline with a cache',
        (tester) async {
      setViewport(tester, const Size(420, 900));
      final store = await storeWithCache();
      final provider = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Failure(ApiException.network()),
        ),
        store: store,
        autoLoad: false,
      );
      await provider.load(refresh: true);

      await pumpApp(tester, const HomePage(), catalog: provider);
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.textContaining('Showing products saved'), findsOneWidget);
      expect(find.byType(ProductCard), findsWidgets);
      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('the banner disappears once a refresh succeeds',
        (tester) async {
      setViewport(tester, const Size(420, 900));
      final store = await storeWithCache();
      final provider = CatalogProvider(
        repository: FakeProductRepository(productsResult: Success(catalog)),
        store: store,
        autoLoad: false,
      );

      await pumpApp(tester, const HomePage(), catalog: provider);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('offline with no cache still shows the error and retry',
        (tester) async {
      setViewport(tester, const Size(420, 900));
      final store = await emptyStore();
      final provider = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Failure(ApiException.network()),
        ),
        store: store,
        autoLoad: false,
      );
      await provider.load();

      await pumpApp(tester, const HomePage(), catalog: provider);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
