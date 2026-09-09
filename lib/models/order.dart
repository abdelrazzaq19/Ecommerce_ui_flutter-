import 'package:flutter/foundation.dart';

import 'product.dart';

/// Where an order is going.
@immutable
class ShippingAddress {
  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.postalCode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        fullName: _string(json['fullName']),
        phone: _string(json['phone']),
        street: _string(json['street']),
        city: _string(json['city']),
        postalCode: _string(json['postalCode']),
      );

  static const ShippingAddress empty = ShippingAddress(
    fullName: '',
    phone: '',
    street: '',
    city: '',
    postalCode: '',
  );

  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String postalCode;

  bool get isEmpty =>
      fullName.isEmpty && phone.isEmpty && street.isEmpty && city.isEmpty;

  /// One-line form for a confirmation or a history row.
  String get summary =>
      [street, city, postalCode].where((part) => part.isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'city': city,
        'postalCode': postalCode,
      };

  static String _string(dynamic value) => value is String ? value : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingAddress &&
          other.fullName == fullName &&
          other.phone == phone &&
          other.street == street &&
          other.city == city &&
          other.postalCode == postalCode;

  @override
  int get hashCode => Object.hash(fullName, phone, street, city, postalCode);
}

/// One line of an order.
///
/// A snapshot, not a reference: the price and title are copied at purchase
/// time so a later price change cannot rewrite what someone already paid.
@immutable
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.title,
    required this.image,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productId: _int(json['productId']),
        title: _string(json['title']),
        image: _string(json['image']),
        unitPrice: _double(json['unitPrice']),
        quantity: _int(json['quantity']),
      );

  factory OrderLine.fromProduct(Product product, int quantity) => OrderLine(
        productId: product.id,
        title: product.title,
        image: product.image,
        unitPrice: product.price,
        quantity: quantity,
      );

  final int productId;
  final String title;
  final String image;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'image': image,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  static String _string(dynamic value) => value is String ? value : '';
  static int _int(dynamic value) => value is num ? value.toInt() : 0;
  static double _double(dynamic value) => value is num ? value.toDouble() : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLine &&
          other.productId == productId &&
          other.title == title &&
          other.image == image &&
          other.unitPrice == unitPrice &&
          other.quantity == quantity;

  @override
  int get hashCode =>
      Object.hash(productId, title, image, unitPrice, quantity);
}

/// A placed order.
///
/// Recorded on this device only. No payment is taken and no card details are
/// collected anywhere in this app.
@immutable
class Order {
  const Order({
    required this.id,
    required this.placedAt,
    required this.lines,
    required this.address,
    required this.shipping,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final rawAddress = json['address'];

    return Order(
      id: json['id'] is String ? json['id'] as String : '',
      placedAt: DateTime.tryParse('${json['placedAt']}') ?? DateTime(1970),
      lines: rawLines is List
          ? rawLines
              .whereType<Map<String, dynamic>>()
              .map(OrderLine.fromJson)
              .toList()
          : const [],
      address: rawAddress is Map<String, dynamic>
          ? ShippingAddress.fromJson(rawAddress)
          : ShippingAddress.empty,
      shipping: json['shipping'] is num
          ? (json['shipping'] as num).toDouble()
          : 0,
    );
  }

  final String id;
  final DateTime placedAt;
  final List<OrderLine> lines;
  final ShippingAddress address;
  final double shipping;

  double get subtotal =>
      lines.fold(0, (sum, line) => sum + line.lineTotal);

  double get total => subtotal + shipping;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'placedAt': placedAt.toIso8601String(),
        'lines': lines.map((line) => line.toJson()).toList(),
        'address': address.toJson(),
        'shipping': shipping,
      };
}
