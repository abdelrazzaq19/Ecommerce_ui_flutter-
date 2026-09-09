import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/local_store.dart';

/// Placed orders.
///
/// Orders are recorded on this device. There is no backend and no payment
/// step — the app says so on the checkout screen rather than implying a
/// purchase happened somewhere.
class OrderProvider with ChangeNotifier {
  OrderProvider({LocalStore? store, Random? random})
      : _store = store,
        _random = random ?? Random() {
    final saved = store?.readOrders();
    if (saved != null) {
      _orders.addAll(saved.map(Order.fromJson));
      _sort();
    }
  }

  final LocalStore? _store;
  final Random _random;
  final List<Order> _orders = [];

  /// Orders, newest first.
  List<Order> get orders => List.unmodifiable(_orders);

  bool get isEmpty => _orders.isEmpty;
  int get count => _orders.length;

  Order? byId(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  /// Records an order and returns it.
  Future<Order> placeOrder({
    required List<OrderLine> lines,
    required ShippingAddress address,
    required double shipping,
    DateTime? placedAt,
  }) async {
    final order = Order(
      id: _newId(placedAt ?? DateTime.now()),
      placedAt: placedAt ?? DateTime.now(),
      lines: lines,
      address: address,
      shipping: shipping,
    );

    _orders.insert(0, order);
    notifyListeners();
    await _persist();
    return order;
  }

  Future<void> clear() async {
    if (_orders.isEmpty) return;
    _orders.clear();
    notifyListeners();
    await _persist();
  }

  /// `ORD-20260909-4F2A`: readable, sortable by eye, and unique enough for a
  /// device-local record.
  String _newId(DateTime at) {
    const alphabet = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final suffix = List.generate(
      4,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();

    final date = '${at.year}'
        '${at.month.toString().padLeft(2, '0')}'
        '${at.day.toString().padLeft(2, '0')}';

    return 'ORD-$date-$suffix';
  }

  void _sort() =>
      _orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));

  Future<void> _persist() async =>
      _store?.writeOrders(_orders.map((order) => order.toJson()).toList());
}
