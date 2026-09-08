import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/local_store.dart';

/// The shopping cart.
///
/// Stores product ids and quantities only. It used to keep a second, partial
/// copy of the catalog (the first ten products), which is why anything with a
/// higher id rendered as "Product not found". Products are now resolved through
/// `CatalogProvider`, the single source of truth.
///
/// Every mutation is written straight to [LocalStore], so a cart survives the
/// app being closed — the thing shoppers most expect and this app did not do.
class CartProvider with ChangeNotifier {
  CartProvider({LocalStore? store}) : _store = store {
    final saved = store?.readCart();
    if (saved != null) _items.addAll(saved);
  }

  /// Orders under this subtotal pay [flatShipping]; at or above it, delivery is
  /// free. A demo rule, stated plainly in the cart so it is not a surprise.
  static const double freeShippingThreshold = 50;
  static const double flatShipping = 4.99;

  final LocalStore? _store;
  final Map<int, int> _items = {};

  /// `{productId: quantity}`.
  Map<int, int> get items => Map.unmodifiable(_items);

  /// Total number of units in the cart, for the navigation badge.
  int get itemCount => _items.values.fold(0, (sum, quantity) => sum + quantity);

  /// Number of distinct products, for "3 products" style copy.
  int get distinctItemCount => _items.length;

  bool get isEmpty => _items.isEmpty;

  int quantityOf(int productId) => _items[productId] ?? 0;

  void addToCart(Product product, {int quantity = 1}) {
    if (quantity < 1) return;
    _items[product.id] = (_items[product.id] ?? 0) + quantity;
    _commit();
  }

  void increment(int productId) =>
      setQuantity(productId, quantityOf(productId) + 1);

  void decrement(int productId) =>
      setQuantity(productId, quantityOf(productId) - 1);

  /// Sets an exact quantity. Zero or less removes the line, which is what a
  /// shopper means when they tap minus on the last unit.
  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    if (_items[productId] == quantity) return;
    _items[productId] = quantity;
    _commit();
  }

  /// Removes a line and returns the quantity that was dropped, or null if the
  /// product was not in the cart. The returned quantity is what makes Undo
  /// possible.
  int? removeFromCart(int productId) {
    final removed = _items.remove(productId);
    if (removed == null) return null;
    _commit();
    return removed;
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _commit();
  }

  /// Line items priced against [catalog]. Ids the catalog does not know about
  /// contribute nothing rather than throwing.
  double subtotalFor(Iterable<Product> catalog) {
    final prices = {for (final product in catalog) product.id: product.price};
    var subtotal = 0.0;
    _items.forEach((id, quantity) {
      subtotal += (prices[id] ?? 0) * quantity;
    });
    return subtotal;
  }

  static double shippingFor(double subtotal) {
    if (subtotal <= 0 || subtotal >= freeShippingThreshold) return 0;
    return flatShipping;
  }

  double totalFor(Iterable<Product> catalog) {
    final subtotal = subtotalFor(catalog);
    return subtotal + shippingFor(subtotal);
  }

  /// How much more is needed to earn free delivery; zero once it is earned.
  double amountToFreeShipping(Iterable<Product> catalog) {
    final remaining = freeShippingThreshold - subtotalFor(catalog);
    return remaining > 0 ? remaining : 0;
  }

  void _commit() {
    // Fire and forget: the UI must not wait on disk, and shared_preferences
    // updates its in-memory cache synchronously, so a read right after a write
    // already sees the new value.
    unawaited(_store?.writeCart(_items));
    notifyListeners();
  }
}
