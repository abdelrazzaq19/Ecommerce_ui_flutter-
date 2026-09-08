import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/api_exception.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/search_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repository.dart';

Product _product(
  int id,
  String title,
  String category,
  double price,
  double rating,
) =>
    Product(
      id: id,
      title: title,
      price: price,
      description: '$title description',
      image: '',
      category: category,
      rating: rating,
      ratingCount: 10,
    );

/// Deliberately out of order in every dimension, so a sort that does nothing
/// cannot pass by accident.
final _catalog = [
  _product(1, 'Denim Jacket', 'clothing', 89.50, 4.1),
  _product(2, 'Gold Ring', 'jewelery', 695.00, 4.6),
  _product(3, 'Apple Watch', 'electronics', 199.99, 3.2),
  _product(4, 'Cotton Shirt', 'clothing', 22.30, 4.8),
  _product(5, 'Silver Chain', 'jewelery', 168.00, 3.9),
  _product(6, 'Zephyr Laptop', 'electronics', 1099.00, 2.1),
];

Future<CatalogProvider> readyCatalog({
  Result<List<String>>? categories,
  int pageSize = 20,
}) async {
  final catalog = CatalogProvider(
    repository: FakeProductRepository(
      productsResult: Success(_catalog),
      categoriesResult: categories ??
          const Success(['jewelery', 'electronics', 'clothing']),
    ),
    pageSize: pageSize,
    autoLoad: false,
  );
  await catalog.load();
  return catalog;
}

List<String> _titles(List<Product> products) =>
    products.map((product) => product.title).toList();

void main() {
  group('categories', () {
    test('come from the API, sorted', () async {
      final catalog = await readyCatalog();

      expect(catalog.categories, ['clothing', 'electronics', 'jewelery']);
    });

    test('fall back to the catalog when the category call fails', () async {
      final catalog = await readyCatalog(
        categories: Failure(ApiException.timeout()),
      );

      expect(catalog.categories, ['clothing', 'electronics', 'jewelery']);
      expect(
        catalog.status,
        CatalogStatus.ready,
        reason: 'a failed category call must not fail the whole screen',
      );
    });
  });

  group('category filter', () {
    test('narrows the list and the count', () async {
      final catalog = await readyCatalog();
      expect(catalog.filteredCount, 6);

      catalog.selectCategory('jewelery');

      expect(catalog.filteredCount, 2);
      expect(_titles(catalog.filteredProducts), ['Gold Ring', 'Silver Chain']);
    });

    test('All restores everything', () async {
      final catalog = await readyCatalog()
        ..selectCategory('jewelery');

      catalog.selectCategory(null);

      expect(catalog.filteredCount, 6);
    });

    test('leaves the full catalog available to the cart', () async {
      final catalog = await readyCatalog()..selectCategory('jewelery');

      expect(catalog.allProducts, hasLength(6));
      expect(catalog.productById(1), isNotNull);
    });

    test('a category that vanishes on refresh is dropped', () async {
      final catalog = await readyCatalog()..selectCategory('jewelery');

      final narrowed = CatalogProvider(
        repository: FakeProductRepository(
          productsResult: Success(_catalog),
          categoriesResult: const Success(['clothing']),
        ),
        autoLoad: false,
      )..selectCategory('jewelery');
      await narrowed.load();

      expect(narrowed.selectedCategory, isNull);
      expect(narrowed.filteredCount, 6);
      expect(catalog.selectedCategory, 'jewelery');
    });
  });

  group('sort', () {
    test('featured keeps the order the store returned', () async {
      final catalog = await readyCatalog();

      expect(_titles(catalog.filteredProducts), _titles(_catalog));
    });

    test('price low to high', () async {
      final catalog = await readyCatalog()..setSort(CatalogSort.priceLowHigh);

      expect(
        catalog.filteredProducts.map((p) => p.price).toList(),
        [22.30, 89.50, 168.00, 199.99, 695.00, 1099.00],
      );
    });

    test('price high to low', () async {
      final catalog = await readyCatalog()..setSort(CatalogSort.priceHighLow);

      expect(catalog.filteredProducts.first.title, 'Zephyr Laptop');
      expect(catalog.filteredProducts.last.title, 'Cotton Shirt');
    });

    test('top rated', () async {
      final catalog = await readyCatalog()..setSort(CatalogSort.rating);

      expect(
        catalog.filteredProducts.map((p) => p.rating).toList(),
        [4.8, 4.6, 4.1, 3.9, 3.2, 2.1],
      );
    });

    test('name A to Z, case-insensitively', () async {
      final catalog = await readyCatalog()..setSort(CatalogSort.nameAZ);

      expect(_titles(catalog.filteredProducts), [
        'Apple Watch',
        'Cotton Shirt',
        'Denim Jacket',
        'Gold Ring',
        'Silver Chain',
        'Zephyr Laptop',
      ]);
    });
  });

  group('filter and sort compose', () {
    test('sorting applies within the selected category', () async {
      final catalog = await readyCatalog()
        ..selectCategory('clothing')
        ..setSort(CatalogSort.priceLowHigh);

      expect(_titles(catalog.filteredProducts), ['Cotton Shirt', 'Denim Jacket']);
    });

    test('search composes on top of the filtered list', () async {
      final catalog = await readyCatalog()..selectCategory('jewelery');
      final search = SearchProvider()..submit('chain', remember: false);

      expect(
        _titles(search.filter(catalog.filteredProducts)),
        ['Silver Chain'],
      );
      expect(
        _titles(search.filter(catalog.allProducts)),
        ['Silver Chain'],
        reason: 'the search screen deliberately spans the whole catalog',
      );
    });

    test('reset clears both the category and the sort', () async {
      final catalog = await readyCatalog()
        ..selectCategory('clothing')
        ..setSort(CatalogSort.priceHighLow);
      expect(catalog.hasActiveFilters, isTrue);

      catalog.clearFilters();

      expect(catalog.hasActiveFilters, isFalse);
      expect(catalog.selectedCategory, isNull);
      expect(catalog.sort, CatalogSort.featured);
      expect(_titles(catalog.filteredProducts), _titles(_catalog));
    });
  });

  group('paging interaction', () {
    test('changing the category resets to the first page', () async {
      final catalog = await readyCatalog(pageSize: 2);
      catalog.loadNextPage();
      expect(catalog.visibleProducts, hasLength(4));

      catalog.selectCategory('clothing');

      expect(catalog.visibleProducts, hasLength(2));
      expect(catalog.hasMore, isFalse);
    });

    test('changing the sort resets to the first page', () async {
      final catalog = await readyCatalog(pageSize: 2);
      catalog.loadNextPage();

      catalog.setSort(CatalogSort.nameAZ);

      expect(catalog.visibleProducts, hasLength(2));
      expect(_titles(catalog.visibleProducts), ['Apple Watch', 'Cotton Shirt']);
    });

    test('paging never exceeds the filtered list', () async {
      final catalog = await readyCatalog(pageSize: 2)
        ..selectCategory('jewelery');

      catalog
        ..loadNextPage()
        ..loadNextPage();

      expect(catalog.visibleProducts, hasLength(2));
      expect(catalog.hasMore, isFalse);
    });
  });
}
