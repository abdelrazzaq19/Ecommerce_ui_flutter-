import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'api_exception.dart';

/// Thin HTTP layer over the FakeStore API.
///
/// Two things about that API shape this class:
///
/// * `?offset=` is ignored — the server always returns from the first product —
///   so paging is done client-side and no offset is ever sent.
/// * `?q=` is ignored — the server returns the entire catalog for any query —
///   so there is no search endpoint here. Search filters the loaded catalog.
///
/// Every failure leaves this class as an [ApiException]; nothing else escapes.
class ApiService {
  ApiService({
    http.Client? client,
    this.baseUrl = 'https://fakestoreapi.com',
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Requests hang forever without this; a shopper on a dead network would sit
  /// on a spinner indefinitely.
  final Duration timeout;

  /// The whole catalog. It is 20 products, so paging happens in the UI layer.
  Future<List<Product>> fetchProducts() async {
    final data = await _getJsonList('/products');
    return Product.listFromJson(data);
  }

  /// The store's category names, used by the filter chips.
  Future<List<String>> fetchCategories() async {
    final data = await _getJsonList('/products/categories');
    return data.whereType<String>().toList();
  }

  Future<List<dynamic>> _getJsonList(String path) async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse('$baseUrl$path')).timeout(timeout);
    } on TimeoutException catch (error) {
      throw ApiException.timeout().withCause(error);
    } on http.ClientException catch (error) {
      throw ApiException.network(error);
    } on Object catch (error) {
      // SocketException and friends live in dart:io, which the web build cannot
      // import, so anything left is treated as a transport failure.
      throw ApiException.network(error);
    }

    if (response.statusCode != 200) {
      throw ApiException.server(response.statusCode);
    }

    try {
      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw ApiException.decoding('expected a JSON array');
      }
      return decoded;
    } on FormatException catch (error) {
      throw ApiException.decoding(error);
    }
  }

  /// Releases the underlying connection pool.
  void dispose() => _client.close();
}

extension on ApiException {
  ApiException withCause(Object cause) => ApiException(
        kind: kind,
        message: message,
        statusCode: statusCode,
        cause: cause,
      );
}
