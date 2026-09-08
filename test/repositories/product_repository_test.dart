import 'dart:convert';

import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/services/api_exception.dart';
import 'package:ecommerce_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';

ApiProductRepository repositoryReturning(
  Future<http.Response> Function(http.Request) onRequest,
) {
  return ApiProductRepository(
    api: ApiService(
      client: MockClient(onRequest),
      timeout: const Duration(milliseconds: 100),
    ),
  );
}

void main() {
  group('ApiProductRepository', () {
    test('returns Success with the parsed products', () async {
      final repository = repositoryReturning(
        (_) async => http.Response(jsonEncode([fakeProductJson]), 200),
      );

      final result = await repository.fetchProducts();

      expect(result, isA<Success<List<Product>>>());
      expect((result as Success<List<Product>>).value, hasLength(1));
    });

    test('returns EmptyResult when the store has nothing to show', () async {
      final repository = repositoryReturning(
        (_) async => http.Response('[]', 200),
      );

      expect(await repository.fetchProducts(), isA<EmptyResult<List<Product>>>());
    });

    test('returns Failure carrying the ApiException instead of throwing',
        () async {
      final repository = repositoryReturning(
        (_) async => http.Response('[]', 500),
      );

      final result = await repository.fetchProducts();

      expect(result, isA<Failure<List<Product>>>());
      final failure = result as Failure<List<Product>>;
      expect(failure.error.kind, ApiErrorKind.server);
      expect(failure.error.message, contains('500'));
    });

    test('maps an unexpected error to a Failure rather than escaping', () async {
      final repository = repositoryReturning(
        (_) async => throw StateError('unexpected'),
      );

      expect(await repository.fetchProducts(), isA<Failure<List<Product>>>());
    });

    test('fetchCategories follows the same result contract', () async {
      final repository = repositoryReturning(
        (_) async => http.Response(jsonEncode(['electronics']), 200),
      );

      final result = await repository.fetchCategories();

      expect((result as Success<List<String>>).value, ['electronics']);
    });
  });

  group('Result helpers', () {
    test('valueOrNull exposes data only on Success', () {
      expect(const Success<int>(1).valueOrNull, 1);
      expect(const EmptyResult<int>().valueOrNull, isNull);
      expect(Failure<int>(ApiException.timeout()).valueOrNull, isNull);
    });

    test('errorOrNull exposes the exception only on Failure', () {
      expect(const Success<int>(1).errorOrNull, isNull);
      expect(Failure<int>(ApiException.timeout()).errorOrNull, isNotNull);
    });
  });

  group('FakeProductRepository', () {
    test('serves the fixtures without touching the network', () async {
      final repository = FakeProductRepository();

      final result = await repository.fetchProducts();

      expect((result as Success<List<Product>>).value, fakeProducts);
      expect(repository.fetchCount, 1);
    });

    test('can be told to fail, for error-state tests', () async {
      final repository = FakeProductRepository(
        productsResult: Failure(ApiException.timeout()),
      );

      expect(await repository.fetchProducts(), isA<Failure<List<Product>>>());
    });

    test('can be told to return nothing, for empty-state tests', () async {
      final repository = FakeProductRepository(
        productsResult: const EmptyResult(),
      );

      expect(await repository.fetchProducts(), isA<EmptyResult<List<Product>>>());
    });
  });
}
