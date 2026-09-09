import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/local_store.dart';

/// Saved products.
///
/// Stores ids only and resolves them through `CatalogProvider`, the same way
/// the cart does, so there is one copy of the catalog in the app. Newest saved
/// first: a wishlist is a list of recent intentions, not a filing cabinet.
class WishlistProvider with ChangeNotifier {
  WishlistProvider({LocalStore? store}) : _store = store {
    final saved = store?.readWishlist();
    if (saved != null) _ids.addAll(saved);
  }

  final LocalStore? _store;
  final List<int> _ids = [];

  /// Saved product ids, newest first.
  List<int> get productIds => List.unmodifiable(_ids);

  int get count => _ids.length;
  bool get isEmpty => _ids.isEmpty;

  bool contains(int productId) => _ids.contains(productId);

  /// Adds or removes [productId] and returns whether it is now saved.
  bool toggle(int productId) {
    final nowSaved = !contains(productId);
    if (nowSaved) {
      add(productId);
    } else {
      remove(productId);
    }
    return nowSaved;
  }

  void add(int productId) {
    if (_ids.contains(productId)) return;
    _ids.insert(0, productId);
    _commit();
  }

  void remove(int productId) {
    if (!_ids.remove(productId)) return;
    _commit();
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    _commit();
  }

  /// The saved products, in saved order.
  ///
  /// Ids the catalog does not know about are skipped rather than rendered as a
  /// broken row — a wishlist can outlive a product.
  List<Product> resolve(Iterable<Product> catalog) {
    final byId = {for (final product in catalog) product.id: product};
    return [
      for (final id in _ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  void _commit() {
    unawaited(_store?.writeWishlist(_ids));
    notifyListeners();
  }
}
