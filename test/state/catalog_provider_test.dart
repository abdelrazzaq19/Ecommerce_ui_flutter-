import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/api_exception.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';

void main() {
  group('CatalogProvider.load', () {
    test('starts idle and reaches ready after loading', () async {
      final repository = FakeProductRepository(
        productsResult: Success(fakeCatalog(20)),
      );
      final catalog = CatalogProvider(repository: repository, autoLoad: false);

      expect(catalog.status, CatalogStatus.initial);

      await catalog.load();

      expect(catalog.status, CatalogStatus.ready);
      expect(catalog.allProducts, hasLength(20));
      expect(repository.fetchCount, 1);
    });

    test('reports empty separately from failure', () async {
      final catalog = CatalogProvider(
        repository: FakeProductRepository(productsResult: const EmptyResult()),
        autoLoad: false,
      );

      await catalog.load();

      expect(catalog.status, CatalogStatus.empty);
      expect(catalog.error, isNull);
    });

    test('keeps the failure so the UI can offer a retry', () async {
      final catalog = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Failure(ApiException.timeout()),
        ),
        autoLoad: false,
      );

      await catalog.load();

      expect(catalog.status, CatalogStatus.error);
      expect(catalog.error!.kind, ApiErrorKind.timeout);
      expect(catalog.error!.isRetryable, isTrue);
    });

    test('ignores a second load while one is already running', () async {
      final repository = FakeProductRepository(
        productsResult: Success(fakeCatalog(20)),
        delay: const Duration(milliseconds: 30),
      );
      final catalog = CatalogProvider(repository: repository, autoLoad: false);

      await Future.wait([catalog.load(), catalog.load()]);

      expect(repository.fetchCount, 1);
    });

    test('autoLoad fetches without any user interaction', () async {
      final repository = FakeProductRepository(
        productsResult: Success(fakeCatalog(3)),
      );

      CatalogProvider(repository: repository);
      await Future<void>.delayed(Duration.zero);

      expect(repository.fetchCount, 1);
    });
  });

  group('client-side paging', () {
    Future<CatalogProvider> readyCatalog({int total = 20, int pageSize = 8}) async {
      final catalog = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Success(fakeCatalog(total)),
        ),
        pageSize: pageSize,
        autoLoad: false,
      );
      await catalog.load();
      return catalog;
    }

    test('shows only the first page initially', () async {
      final catalog = await readyCatalog();

      expect(catalog.visibleProducts, hasLength(8));
      expect(catalog.hasMore, isTrue);
    });

    test('appends one page at a time and then stops', () async {
      final catalog = await readyCatalog();

      catalog.loadNextPage();
      expect(catalog.visibleProducts, hasLength(16));

      catalog.loadNextPage();
      expect(catalog.visibleProducts, hasLength(20));
      expect(catalog.hasMore, isFalse);

      // The old scroll handler kept firing at the end of the list; paging past
      // the end must be a no-op, not a duplicate append.
      catalog.loadNextPage();
      expect(catalog.visibleProducts, hasLength(20));
    });

    test('never yields a duplicate product', () async {
      final catalog = await readyCatalog();
      catalog
        ..loadNextPage()
        ..loadNextPage()
        ..loadNextPage();

      final ids = catalog.visibleProducts.map((product) => product.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('a catalog smaller than one page has nothing more to load', () async {
      final catalog = await readyCatalog(total: 3);

      expect(catalog.visibleProducts, hasLength(3));
      expect(catalog.hasMore, isFalse);
    });
  });

  group('refresh', () {
    test('refetches and replaces the list, resetting paging', () async {
      final repository = FakeProductRepository(
        productsResult: Success(fakeCatalog(20)),
      );
      final catalog = CatalogProvider(
        repository: repository,
        pageSize: 8,
        autoLoad: false,
      );
      await catalog.load();
      catalog.loadNextPage();
      expect(catalog.visibleProducts, hasLength(16));

      await catalog.refresh();

      expect(repository.fetchCount, 2);
      expect(catalog.allProducts, hasLength(20));
      expect(catalog.visibleProducts, hasLength(8));
    });

    test('a failed refresh surfaces the error', () async {
      final catalog = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Failure(ApiException.network()),
        ),
        autoLoad: false,
      );

      await catalog.refresh();

      expect(catalog.status, CatalogStatus.error);
    });
  });
}
