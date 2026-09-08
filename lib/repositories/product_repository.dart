import '../models/product.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

/// The outcome of a repository call.
///
/// Three variants, not two: "the request worked and there is nothing to show"
/// and "the request failed" need different screens, and collapsing them into an
/// empty list is how the old code ended up rendering a blank page on a network
/// error. Being sealed, a `switch` over this is checked for exhaustiveness.
sealed class Result<T> {
  const Result();

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        _ => null,
      };

  ApiException? get errorOrNull => switch (this) {
        Failure<T>(:final error) => error,
        _ => null,
      };
}

/// The call succeeded and returned data.
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// The call succeeded but the store returned nothing.
final class EmptyResult<T> extends Result<T> {
  const EmptyResult();
}

/// The call failed. [error] carries a message that is safe to show the user.
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final ApiException error;
}

/// Source of catalog data for the state layer.
///
/// The state layer depends on this interface rather than [ApiService] so tests
/// can swap in a fake and never touch the live FakeStore API.
abstract interface class ProductRepository {
  Future<Result<List<Product>>> fetchProducts();

  Future<Result<List<String>>> fetchCategories();
}

/// [ProductRepository] backed by the live API.
class ApiProductRepository implements ProductRepository {
  ApiProductRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<Result<List<Product>>> fetchProducts() => _guard(_api.fetchProducts);

  @override
  Future<Result<List<String>>> fetchCategories() => _guard(_api.fetchCategories);

  /// Turns thrown failures into [Failure] values so callers never need a
  /// try/catch — the old empty `catch (e)` block is what hid network errors
  /// from the user in the first place.
  Future<Result<List<T>>> _guard<T>(Future<List<T>> Function() call) async {
    try {
      final items = await call();
      return items.isEmpty ? EmptyResult<List<T>>() : Success(items);
    } on ApiException catch (error) {
      return Failure(error);
    } on Object catch (error) {
      return Failure(ApiException.decoding(error));
    }
  }
}
