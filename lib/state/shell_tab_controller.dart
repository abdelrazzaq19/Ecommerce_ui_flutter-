import 'package:flutter/foundation.dart';

/// Which tab the app shell is showing.
///
/// Lifted out of `AppShell` so screens pushed on top of it — a product detail
/// page, for example — can send the shopper to the cart tab after adding
/// something, instead of leaving them to find it.
class ShellTabController extends ChangeNotifier {
  ShellTabController({int initialIndex = 0}) : _index = initialIndex {
    _visited.add(initialIndex);
  }

  static const int homeTab = 0;
  static const int searchTab = 1;
  static const int wishlistTab = 2;
  static const int cartTab = 3;
  static const int profileTab = 4;

  int _index;
  int get index => _index;

  /// Tabs that have been opened at least once, so the shell can build them
  /// lazily and still keep their state afterwards.
  final Set<int> _visited = {};
  Set<int> get visited => Set.unmodifiable(_visited);

  void goTo(int index) {
    _visited.add(index);
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}
