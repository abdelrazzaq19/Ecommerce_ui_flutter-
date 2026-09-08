import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/local_store.dart';
import '../theme/app_tokens.dart';

/// Catalog search.
///
/// The store API ignores `?q=` and returns all 20 products for any query, so
/// searching it was worse than useless — every search looked like "no filter
/// applied". Filtering happens here, over the catalog already in memory, and
/// input is debounced so a fast typist causes one pass, not one per keystroke.
class SearchProvider with ChangeNotifier {
  SearchProvider({
    LocalStore? store,
    Duration debounce = AppDurations.searchDebounce,
  })  : _store = store,
        _debounceDuration = debounce {
    _recent = store?.readSearchHistory() ?? [];
  }

  final LocalStore? _store;
  final Duration _debounceDuration;

  Timer? _debounce;
  String _query = '';
  List<String> _recent = const [];

  /// The query currently applied to the catalog.
  String get query => _query;

  bool get hasQuery => _query.trim().isNotEmpty;

  /// Previously submitted queries, newest first.
  List<String> get recentSearches => List.unmodifiable(_recent);

  /// Called on every keystroke. Applies [text] once typing pauses.
  void queryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _apply(text));
  }

  /// Applies [text] immediately — used for submit and for tapping a recent
  /// search, where waiting out the debounce would feel broken.
  ///
  /// [remember] records the query in history. Only explicit submissions are
  /// remembered; debounced keystrokes would otherwise fill the history with
  /// every prefix of every word ("g", "go", "gol", "gold").
  void submit(String text, {bool remember = true}) {
    _debounce?.cancel();
    _apply(text);
    if (remember) {
      unawaited(_remember(text));
    }
  }

  /// Records the current query in history.
  ///
  /// Called when a search demonstrably led somewhere — the shopper opened a
  /// result — as well as on submit. Plenty of people never press Enter,
  /// especially on desktop, and a history that only fills on Enter stays empty.
  void rememberCurrent() {
    if (!hasQuery) return;
    unawaited(_remember(_query));
  }

  void clear() {
    _debounce?.cancel();
    _apply('');
  }

  Future<void> clearHistory() async {
    _recent = const [];
    notifyListeners();
    await _store?.clearSearchHistory();
  }

  /// Products matching [query], title matches first.
  ///
  /// Someone searching "shirt" wants the shirt before the backpack whose
  /// description happens to mention one.
  List<Product> filter(Iterable<Product> catalog) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final titleMatches = <Product>[];
    final otherMatches = <Product>[];

    for (final product in catalog) {
      if (product.title.toLowerCase().contains(needle)) {
        titleMatches.add(product);
      } else if (product.category.toLowerCase().contains(needle) ||
          product.description.toLowerCase().contains(needle)) {
        otherMatches.add(product);
      }
    }

    return [...titleMatches, ...otherMatches];
  }

  void _apply(String text) {
    if (_query == text) return;
    _query = text;
    notifyListeners();
  }

  Future<void> _remember(String text) async {
    if (text.trim().isEmpty) return;
    await _store?.addSearch(text);
    _recent = _store?.readSearchHistory() ?? [text.trim(), ..._recent];
    notifyListeners();
  }

  @override
  void dispose() {
    // Without this a pending timer fires into a disposed notifier after the
    // user navigates away.
    _debounce?.cancel();
    super.dispose();
  }
}
