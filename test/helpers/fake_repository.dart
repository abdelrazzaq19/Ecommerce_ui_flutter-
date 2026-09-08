import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';

import 'fake_products.dart';

/// In-memory [ProductRepository] for widget and state tests.
///
/// Defaults to serving [fakeProducts]; pass [productsResult] or
/// [categoriesResult] to drive the empty and error screens. [delay] lets a test
/// observe the loading state before the result lands.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({
    Result<List<Product>>? productsResult,
    Result<List<String>>? categoriesResult,
    this.delay = Duration.zero,
  })  : productsResult = productsResult ?? Success(fakeProducts),
        categoriesResult =
            categoriesResult ?? const Success(["men's clothing", 'jewelery']);

  final Result<List<Product>> productsResult;
  final Result<List<String>> categoriesResult;
  final Duration delay;

  /// How many times the catalog was requested — lets tests assert that a screen
  /// loads once on init, and that pull-to-refresh actually refetches.
  int fetchCount = 0;
  int categoriesFetchCount = 0;

  @override
  Future<Result<List<Product>>> fetchProducts() async {
    fetchCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return productsResult;
  }

  @override
  Future<Result<List<String>>> fetchCategories() async {
    categoriesFetchCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return categoriesResult;
  }
}
