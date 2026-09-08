import 'package:ecommerce_app/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_products.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a well-formed FakeStore payload', () {
      final product = Product.fromJson(fakeProductJson);

      expect(product.id, 1);
      expect(product.title, 'Fjallraven Foldsack No. 1 Backpack');
      expect(product.price, 109.95);
      expect(product.category, "men's clothing");
      expect(product.image, 'https://example.test/backpack.png');
      expect(product.rating, 3.9);
      expect(product.ratingCount, 120);
    });

    test('survives a missing rating object', () {
      final product = Product.fromJson(const {
        'id': 7,
        'title': 'Unrated item',
        'price': 10.0,
      });

      expect(product.rating, 0);
      expect(product.ratingCount, 0);
      expect(product.title, 'Unrated item');
    });

    test('survives a null rating rate', () {
      final product = Product.fromJson(const {
        'id': 7,
        'title': 'Half-rated',
        'price': 10.0,
        'rating': {'rate': null, 'count': null},
      });

      expect(product.rating, 0);
      expect(product.ratingCount, 0);
    });

    test('accepts a rating given as a bare number', () {
      final product = Product.fromJson(const {
        'id': 8,
        'title': 'Flat rating',
        'price': 1,
        'rating': 4.5,
      });

      expect(product.rating, 4.5);
    });

    test('clamps an out-of-range rating to 0..5', () {
      expect(
        Product.fromJson(const {'id': 1, 'rating': {'rate': 9.9}}).rating,
        5,
      );
      expect(
        Product.fromJson(const {'id': 1, 'rating': {'rate': -3}}).rating,
        0,
      );
    });

    test('parses price from int, double and numeric string', () {
      expect(Product.fromJson(const {'id': 1, 'price': 12}).price, 12.0);
      expect(Product.fromJson(const {'id': 1, 'price': 12.5}).price, 12.5);
      expect(Product.fromJson(const {'id': 1, 'price': '12.5'}).price, 12.5);
    });

    test('falls back to zero for a null or unparseable price', () {
      expect(Product.fromJson(const {'id': 1, 'price': null}).price, 0);
      expect(Product.fromJson(const {'id': 1, 'price': 'free'}).price, 0);
    });

    test('parses an id delivered as a string', () {
      expect(Product.fromJson(const {'id': '42'}).id, 42);
    });

    test('defaults every missing string field to empty rather than throwing', () {
      final product = Product.fromJson(const {'id': 1});

      expect(product.title, isEmpty);
      expect(product.description, isEmpty);
      expect(product.image, isEmpty);
      expect(product.category, isEmpty);
    });
  });

  group('Product serialisation', () {
    test('toJson round-trips through fromJson', () {
      final original = Product.fromJson(fakeProductJson);
      final restored = Product.fromJson(original.toJson());

      expect(restored, original);
    });

    test('toJson keeps the nested rating shape the API uses', () {
      final json = fakeProducts.first.toJson();

      expect(json['rating'], isA<Map<String, dynamic>>());
      expect((json['rating']! as Map<String, dynamic>)['rate'], 3.9);
    });
  });

  group('Product equality', () {
    test('two products with identical fields are equal', () {
      final a = Product.fromJson(fakeProductJson);
      final b = Product.fromJson(fakeProductJson);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}.length, 1);
    });

    test('a differing price breaks equality', () {
      final a = Product.fromJson(fakeProductJson);
      final b = Product.fromJson({...fakeProductJson, 'price': 1.0});

      expect(a, isNot(b));
    });
  });

  group('Product.listFromJson', () {
    test('skips malformed entries instead of failing the whole list', () {
      final products = Product.listFromJson([
        fakeProductJson,
        'not a product',
        const {'id': 2, 'title': 'Second'},
      ]);

      expect(products, hasLength(2));
      expect(products.last.title, 'Second');
    });
  });
}
