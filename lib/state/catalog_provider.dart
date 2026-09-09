import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/api_exception.dart';
import '../services/local_store.dart';

/// What the catalog screen should be showing.
enum CatalogStatus { initial, loading, ready, empty, error }

/// Sort orders offered on the catalog.
enum CatalogSort {
  featured('Featured'),
  priceLowHigh('Price: low to high'),
  priceHighLow('Price: high to low'),
  rating('Top rated'),
  nameAZ('Name: A to Z');

  const CatalogSort(this.label);

  final String label;
}

/// Owns the product catalog and is the single source of truth for products.
///
/// The store API has no working pagination — it ignores `offset` and returns
/// all 20 products — so the whole catalog is fetched once and filtered, sorted
/// and paged in memory. That is why the old infinite scroll appended the same
/// products forever.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider({
    ProductRepository? repository,
    LocalStore? store,
    int pageSize = 8,
    bool autoLoad = true,
  })  : _repository = repository ?? ApiProductRepository(),
        _store = store,
        _pageSize = pageSize {
    _seedFromCache();
    if (autoLoad) {
      // Seeded runs are a refresh, not a first load: the shopper already has
      // products on screen and should not watch them turn back into skeletons.
      unawaited(load(refresh: _status == CatalogStatus.ready));
    }
  }

  /// Puts the last catalog on screen synchronously, before any request goes
  /// out, so a second launch opens on products instead of a spinner.
  void _seedFromCache() {
    final cached = _store?.readCachedCatalog();
    if (cached == null || cached.isEmpty) return;

    _all.addAll(cached);
    _categories = _derivedCategories();
    _status = CatalogStatus.ready;
    _isStale = true;
    _cachedAt = _store?.readCatalogCachedAt();
    _recompute(resetPaging: true);
  }

  final ProductRepository _repository;
  final LocalStore? _store;
  final int _pageSize;
  final List<Product> _all = [];
  List<Product> _filtered = const [];
  List<String> _categories = const [];

  CatalogStatus _status = CatalogStatus.initial;
  ApiException? _error;
  bool _isLoading = false;
  int _visibleCount = 0;

  String? _selectedCategory;
  CatalogSort _sort = CatalogSort.featured;

  bool _isStale = false;
  DateTime? _cachedAt;

  CatalogStatus get status => _status;
  ApiException? get error => _error;
  bool get isLoading => _isLoading;

  /// True while the products on screen came from the cache and the latest
  /// refresh has not succeeded. Drives the offline banner.
  bool get isShowingCachedData => _isStale && _all.isNotEmpty;

  /// When the cached catalog was written, for the banner's wording.
  DateTime? get cachedAt => _cachedAt;

  /// The full catalog. Cart and wishlist resolve their ids against this.
  List<Product> get allProducts => List.unmodifiable(_all);

  /// The catalog after the category filter and sort, before paging.
  List<Product> get filteredProducts => List.unmodifiable(_filtered);

  /// The slice currently rendered, grown by [loadNextPage].
  List<Product> get visibleProducts =>
      List.unmodifiable(_filtered.take(_visibleCount));

  /// How many products the current filter matches, for the result count.
  int get filteredCount => _filtered.length;

  bool get hasMore => _visibleCount < _filtered.length;

  /// Category names for the filter chips.
  List<String> get categories => List.unmodifiable(_categories);

  /// The selected category, or null for "All".
  String? get selectedCategory => _selectedCategory;

  CatalogSort get sort => _sort;

  bool get hasActiveFilters =>
      _selectedCategory != null || _sort != CatalogSort.featured;

  Product? productById(int id) {
    for (final product in _all) {
      if (product.id == id) return product;
    }
    return null;
  }

  /// Loads the catalog unless it is already loaded or loading.
  ///
  /// The home page calls this on its first build, so products appear without
  /// the user having to scroll — the defect that made the app look broken.
  Future<void> loadIfNeeded() async {
    if (_status == CatalogStatus.initial) {
      await load();
    }
  }

  Future<void> load({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    // A refresh keeps the current products on screen and lets the pull-to-
    // refresh spinner carry the feedback, instead of flashing skeletons.
    if (!refresh) {
      _status = CatalogStatus.loading;
    }
    notifyListeners();

    // Started together so the two requests overlap, awaited separately so both
    // results keep their types.
    final productsFuture = _repository.fetchProducts();
    final categoriesFuture = _repository.fetchCategories();
    final productResult = await productsFuture;
    final categoryResult = await categoriesFuture;

    switch (productResult) {
      case Success<List<Product>>(:final value):
        _all
          ..clear()
          ..addAll(value);
        _status = CatalogStatus.ready;
        _isStale = false;
        _cachedAt = DateTime.now();
        unawaited(_store?.writeCachedCatalog(value));
      case EmptyResult<List<Product>>():
        _all.clear();
        _status = CatalogStatus.empty;
        _isStale = false;
      case Failure<List<Product>>(:final error):
        _error = error;
        // Keep whatever is already on screen. Replacing a working page with an
        // error because a background refresh failed is worse than showing
        // slightly old products and saying so.
        _status = _all.isEmpty ? CatalogStatus.error : CatalogStatus.ready;
        _isStale = _all.isNotEmpty;
    }

    // Categories are a nicety: if that call fails, derive them from the
    // products we did get rather than dropping the filter row entirely.
    _categories = switch (categoryResult) {
      // Copy before sorting: the result may hold an unmodifiable list.
      Success<List<String>>(:final value) => [...value]..sort(),
      _ => _derivedCategories(),
    };

    // A category that no longer exists would filter everything away.
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    _recompute(resetPaging: true);
    _isLoading = false;
    notifyListeners();
  }

  /// Refetches and resets paging back to the first page.
  Future<void> refresh() => load(refresh: true);

  /// Reveals the next page. A no-op at the end of the list, so a scroll
  /// handler firing repeatedly at the bottom cannot duplicate anything.
  void loadNextPage() {
    if (!hasMore) return;
    _visibleCount = math.min(_visibleCount + _pageSize, _filtered.length);
    notifyListeners();
  }

  /// Filters by [category]; null means "All".
  void selectCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _recompute(resetPaging: true);
    notifyListeners();
  }

  void setSort(CatalogSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    _recompute(resetPaging: true);
    notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _selectedCategory = null;
    _sort = CatalogSort.featured;
    _recompute(resetPaging: true);
    notifyListeners();
  }

  List<String> _derivedCategories() {
    final names = _all
        .map((product) => product.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  void _recompute({bool resetPaging = false}) {
    final category = _selectedCategory;
    final list = category == null
        ? List<Product>.from(_all)
        : _all.where((product) => product.category == category).toList();

    switch (_sort) {
      case CatalogSort.featured:
        // The order the store returned; treated as the merchandiser's choice.
        break;
      case CatalogSort.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
      case CatalogSort.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
      case CatalogSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case CatalogSort.nameAZ:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }

    _filtered = list;
    if (resetPaging || _visibleCount > _filtered.length) {
      _visibleCount = math.min(_pageSize, _filtered.length);
    }
  }
}
