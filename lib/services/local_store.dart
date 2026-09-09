import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Every piece of state the app keeps on the device.
///
/// All keys and JSON codecs live here so no provider touches
/// [SharedPreferences] directly. Reads are synchronous and total: a corrupt or
/// half-written value returns the default rather than throwing, because losing
/// a wishlist is annoying and crashing on launch is not recoverable.
///
/// Nothing secret is stored. The session holds a display profile only — this
/// app has no backend, so there is no token, and passwords are never persisted.
class LocalStore {
  LocalStore(this._prefs);

  /// Opens the store. Call once during startup and provide it to the app.
  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const String _cartKey = 'cart';
  static const String _wishlistKey = 'wishlist';
  static const String _sessionKey = 'session';
  static const String _accountsKey = 'accounts';
  static const String _themeModeKey = 'themeMode';
  static const String _searchHistoryKey = 'searchHistory';
  static const String _ordersKey = 'orders';
  static const String _addressKey = 'address';
  static const String _catalogKey = 'catalog';
  static const String _catalogCachedAtKey = 'catalogCachedAt';

  /// Recent searches beyond this are dropped; a search sheet is not an archive.
  static const int maxSearchHistory = 10;

  // ---------------------------------------------------------------- cart

  /// Cart contents as `{productId: quantity}`.
  Map<int, int> readCart() {
    final decoded = _decode(_cartKey);
    if (decoded is! Map) return {};

    final cart = <int, int>{};
    decoded.forEach((key, value) {
      final id = int.tryParse('$key');
      if (id != null && value is int && value > 0) {
        cart[id] = value;
      }
    });
    return cart;
  }

  Future<void> writeCart(Map<int, int> cart) => _prefs.setString(
        _cartKey,
        json.encode(cart.map((id, quantity) => MapEntry('$id', quantity))),
      );

  // ------------------------------------------------------------ wishlist

  /// Saved product ids, newest first.
  ///
  /// Order is kept, not a `Set`: a wishlist reads best with the most recently
  /// saved item at the top. Duplicates are dropped on read.
  List<int> readWishlist() {
    final decoded = _decode(_wishlistKey);
    if (decoded is! List) return [];

    final ids = <int>[];
    for (final id in decoded.whereType<int>()) {
      if (!ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  Future<void> writeWishlist(List<int> productIds) =>
      _prefs.setString(_wishlistKey, json.encode(productIds));

  // ------------------------------------------------------------- session

  /// The signed-in profile, or null when signed out.
  Map<String, dynamic>? readSession() {
    final decoded = _decode(_sessionKey);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> writeSession(Map<String, dynamic> session) =>
      _prefs.setString(_sessionKey, json.encode(session));

  Future<void> clearSession() => _prefs.remove(_sessionKey);

  /// Profiles that have registered on this device.
  ///
  /// Separate from the session on purpose: signing out ends a session, it does
  /// not delete the account. Passwords are not part of this — see the note at
  /// the top of the class.
  List<Map<String, dynamic>> readAccounts() {
    final decoded = _decode(_accountsKey);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> writeAccounts(List<Map<String, dynamic>> accounts) =>
      _prefs.setString(_accountsKey, json.encode(accounts));

  // --------------------------------------------------------------- theme

  ThemeMode readThemeMode() {
    final stored = _prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> writeThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeModeKey, mode.name);

  // ------------------------------------------------------ search history

  /// Recent queries, newest first.
  List<String> readSearchHistory() {
    final decoded = _decode(_searchHistoryKey);
    if (decoded is! List) return [];
    return decoded.whereType<String>().toList();
  }

  /// Records [query] as the most recent search, de-duplicated and capped.
  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final history = readSearchHistory()
      ..removeWhere((entry) => entry.toLowerCase() == trimmed.toLowerCase())
      ..insert(0, trimmed);

    await _prefs.setString(
      _searchHistoryKey,
      json.encode(history.take(maxSearchHistory).toList()),
    );
  }

  Future<void> clearSearchHistory() => _prefs.remove(_searchHistoryKey);

  // -------------------------------------------------------------- orders

  /// Placed orders as raw documents; Task 15 maps these onto an Order model.
  List<Map<String, dynamic>> readOrders() {
    final decoded = _decode(_ordersKey);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> writeOrders(List<Map<String, dynamic>> orders) =>
      _prefs.setString(_ordersKey, json.encode(orders));

  /// The last shipping address used, so checkout does not ask for it twice.
  Map<String, dynamic>? readAddress() {
    final decoded = _decode(_addressKey);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> writeAddress(Map<String, dynamic> address) =>
      _prefs.setString(_addressKey, json.encode(address));

  // ------------------------------------------------------- catalog cache

  /// The last catalog fetched, so a cold launch has something to render before
  /// the network answers. Null when nothing has been cached yet.
  List<Product>? readCachedCatalog() {
    final decoded = _decode(_catalogKey);
    if (decoded is! List) return null;
    return Product.listFromJson(decoded);
  }

  /// Both keys are written together, with no await between them: a reader that
  /// finds the catalog must also find its timestamp.
  Future<void> writeCachedCatalog(List<Product> products) => Future.wait([
        _prefs.setString(
          _catalogKey,
          json.encode(products.map((product) => product.toJson()).toList()),
        ),
        _prefs.setString(
          _catalogCachedAtKey,
          DateTime.now().toIso8601String(),
        ),
      ]);

  /// When the cache was written, used to decide whether it is worth showing.
  DateTime? readCatalogCachedAt() {
    final stored = _prefs.getString(_catalogCachedAtKey);
    return stored == null ? null : DateTime.tryParse(stored);
  }

  // --------------------------------------------------------------- reset

  /// Wipes every key this class owns. Used by a full sign-out or reset.
  Future<void> clearAll() async {
    for (final key in const [
      _cartKey,
      _wishlistKey,
      _sessionKey,
      _accountsKey,
      _themeModeKey,
      _searchHistoryKey,
      _ordersKey,
      _addressKey,
      _catalogKey,
      _catalogCachedAtKey,
    ]) {
      await _prefs.remove(key);
    }
  }

  /// Decodes a stored JSON string, treating any corruption as absence.
  Object? _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return json.decode(raw);
    } on FormatException {
      return null;
    }
  }
}
