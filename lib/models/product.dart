import 'package:flutter/foundation.dart';

/// A catalog product.
///
/// Parsing is deliberately defensive: the app reads a third-party API it does
/// not control, and one malformed field must never blank the whole product
/// list. Missing values fall back to a harmless default instead of throwing.
@immutable
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.image,
    required this.rating,
    this.category = '',
    this.ratingCount = 0,
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String image;
  final String category;

  /// Average rating, clamped to the 0..5 range the UI renders as stars.
  final double rating;

  /// Number of ratings behind [rating].
  final int ratingCount;

  factory Product.fromJson(Map<String, dynamic> json) {
    final ratingField = json['rating'];
    final Map<String, dynamic> ratingMap =
        ratingField is Map<String, dynamic> ? ratingField : const {};

    // FakeStore nests rating as {rate, count}, but tolerate a bare number too.
    final rawRate = ratingField is Map ? ratingMap['rate'] : ratingField;

    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      price: _asDouble(json['price']),
      description: _asString(json['description']),
      image: _asString(json['image']),
      category: _asString(json['category']),
      rating: _asDouble(rawRate).clamp(0, 5),
      ratingCount: _asInt(ratingMap['count']),
    );
  }

  /// Parses a decoded JSON array, skipping entries that are not objects.
  ///
  /// One bad row costs that row, not the request.
  static List<Product> listFromJson(List<dynamic> data) {
    final products = <Product>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        products.add(Product.fromJson(item));
      }
    }
    return products;
  }

  /// Serialises back into the API's own shape, so the offline cache written in
  /// Task 18 can be read by [Product.fromJson] without a second codec.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'image': image,
        'category': category,
        'rating': {'rate': rating, 'count': ratingCount},
      };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String _asString(dynamic value) => value is String ? value : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          other.id == id &&
          other.title == title &&
          other.price == price &&
          other.description == description &&
          other.image == image &&
          other.category == category &&
          other.rating == rating &&
          other.ratingCount == ratingCount;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        price,
        description,
        image,
        category,
        rating,
        ratingCount,
      );

  @override
  String toString() => 'Product(id: $id, title: $title, price: $price)';
}
