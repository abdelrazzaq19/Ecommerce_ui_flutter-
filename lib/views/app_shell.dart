import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/cart_provider.dart';
import '../state/shell_tab_controller.dart';
import '../theme/app_tokens.dart';
import 'cart_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'wishlist_page.dart';

/// Top-level navigation.
///
/// Before this existed, the home page had no way to reach the cart, search or
/// login, so three of the five screens were unreachable dead code.
///
/// Adapts to the window: a bottom bar on phones, a side rail from the medium
/// breakpoint up, since this app also ships to web, Windows, macOS and Linux.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<_Destination> _destinations = [
    _Destination('Home', Icons.storefront_outlined, Icons.storefront),
    _Destination('Search', Icons.search_outlined, Icons.search),
    _Destination('Saved', Icons.favorite_border_rounded, Icons.favorite),
    _Destination(
        'Cart', Icons.shopping_cart_outlined, Icons.shopping_cart_rounded),
    _Destination('Profile', Icons.person_outline, Icons.person),
  ];

  Widget _pageAt(int index) => switch (index) {
        0 => const HomePage(),
        1 => const SearchPage(),
        2 => const WishlistPage(),
        3 => const CartPage(),
        _ => const ProfilePage(),
      };

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellTabController>();
    final index = shell.index;
    final cartCount = context.select<CartProvider, int>((cart) => cart.itemCount);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppBreakpoints.medium;

    // Tabs are built on first visit and kept alive afterwards, so switching
    // back preserves scroll position without building all five at launch.
    final body = IndexedStack(
      index: index,
      children: [
        for (var i = 0; i < _destinations.length; i++)
          if (shell.visited.contains(i)) _pageAt(i) else const SizedBox.shrink(),
      ],
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: shell.goTo,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: _badged(destination.icon, destination, cartCount),
                    selectedIcon:
                        _badged(destination.selectedIcon, destination, cartCount),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: shell.goTo,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: _badged(destination.icon, destination, cartCount),
              selectedIcon:
                  _badged(destination.selectedIcon, destination, cartCount),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  /// Wraps the cart icon in a live item-count badge; every other icon is
  /// returned untouched.
  Widget _badged(IconData icon, _Destination destination, int cartCount) {
    final child = Icon(icon);
    if (destination.label != 'Cart' || cartCount == 0) return child;

    return Badge.count(
      count: cartCount,
      child: child,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
