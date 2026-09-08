import 'dart:convert';

import 'package:ecommerce_app/services/api_exception.dart';
import 'package:ecommerce_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fake_products.dart';

/// Builds a service whose HTTP layer is fully under the test's control.
///
/// [onRequest] receives every request, so tests can assert on the URI as well
/// as choose the response. The timeout is short so the timeout path is cheap
/// to exercise.
ApiService serviceReturning(
  Future<http.Response> Function(http.Request request) onRequest, {
  Duration timeout = const Duration(milliseconds: 100),
}) {
  return ApiService(client: MockClient(onRequest), timeout: timeout);
}

http.Response jsonResponse(Object? body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json; charset=utf-8',
    });

void main() {
  group('ApiService.fetchProducts', () {
    test('requests the plain products endpoint with no offset or q', () async {
      Uri? captured;
      final service = serviceReturning((request) async {
        captured = request.url;
        return jsonResponse([fakeProductJson]);
      });

      await service.fetchProducts();

      expect(captured!.path, '/products');
      expect(
        captured!.queryParameters.keys,
        isNot(contains('offset')),
        reason: 'the API silently ignores offset, so sending it is a lie',
      );
      expect(captured!.queryParameters.keys, isNot(contains('q')));
      expect(captured!.queryParameters, isEmpty);
    });

    test('parses a successful payload', () async {
      final service = serviceReturning(
        (_) async => jsonResponse([fakeProductJson]),
      );

      final products = await service.fetchProducts();

      expect(products, hasLength(1));
      expect(products.single.title, 'Fjallraven Foldsack No. 1 Backpack');
    });

    test('drops malformed rows but keeps the rest', () async {
      final service = serviceReturning(
        (_) async => jsonResponse([fakeProductJson, 'junk']),
      );

      expect(await service.fetchProducts(), hasLength(1));
    });

    test('throws a server ApiException on a non-200 response', () async {
      final service = serviceReturning((_) async => jsonResponse([], status: 500));

      await expectLater(
        service.fetchProducts(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server)
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('500')),
        ),
      );
    });

    test('throws a decoding ApiException on a body that is not a JSON list',
        () async {
      final service = serviceReturning(
        (_) async => http.Response('<html>nope</html>', 200),
      );

      await expectLater(
        service.fetchProducts(),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.decoding),
        ),
      );
    });

    test('throws a timeout ApiException when the server is too slow', () async {
      final service = serviceReturning(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          return jsonResponse([fakeProductJson]);
        },
        timeout: const Duration(milliseconds: 40),
      );

      await expectLater(
        service.fetchProducts(),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.timeout),
        ),
      );
    });

    test('throws a network ApiException when the socket fails', () async {
      final service = serviceReturning(
        (_) async => throw http.ClientException('connection refused'),
      );

      await expectLater(
        service.fetchProducts(),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network),
        ),
      );
    });
  });

  group('ApiService.fetchCategories', () {
    test('returns the category list', () async {
      final service = serviceReturning(
        (request) async {
          expect(request.url.path, '/products/categories');
          return jsonResponse(
            ['electronics', 'jewelery', "men's clothing", "women's clothing"],
          );
        },
      );

      expect(await service.fetchCategories(), hasLength(4));
    });

    test('ignores non-string entries', () async {
      final service = serviceReturning(
        (_) async => jsonResponse(['electronics', 42, null]),
      );

      expect(await service.fetchCategories(), ['electronics']);
    });

    test('throws a server ApiException on failure', () async {
      final service = serviceReturning((_) async => jsonResponse([], status: 404));

      await expectLater(
        service.fetchCategories(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ApiException', () {
    test('every kind carries a distinct human-readable message', () {
      final messages = {
        ApiException.timeout().message,
        ApiException.server(500).message,
        ApiException.decoding().message,
        ApiException.network('boom').message,
      };

      expect(messages, hasLength(4));
      for (final message in messages) {
        expect(message, isNotEmpty);
        expect(message.length, greaterThan(20));
      }
    });
  });
}
