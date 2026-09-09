import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'repositories/product_repository.dart';
import 'services/local_store.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/catalog_provider.dart';
import 'state/order_provider.dart';
import 'state/search_provider.dart';
import 'state/settings_provider.dart';
import 'state/shell_tab_controller.dart';
import 'state/wishlist_provider.dart';
import 'views/app_shell.dart';
import 'views/checkout_page.dart';
import 'views/login_page.dart';
import 'views/order_history_page.dart';
import 'views/register_page.dart';

/// Named routes.
///
/// The app previously declared only `home:`, so `pushReplacementNamed('/')`
/// after login threw "Could not find a generator for route". Every named
/// destination the app navigates to must exist in [appRoutes].
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
}

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.home: (_) => const AppShell(),
  AppRoutes.login: (_) => const LoginPage(),
  AppRoutes.register: (_) => const RegisterPage(),
  AppRoutes.checkout: (_) => const CheckoutPage(),
  AppRoutes.orders: (_) => const OrderHistoryPage(),
};

/// The app's provider graph.
///
/// Lives here so both the running app and route-level tests wire up the same
/// state. [repository] is injected by tests to keep them off the network, and
/// [store] carries the persisted cart, wishlist and settings.
List<SingleChildWidget> appProviders({
  ProductRepository? repository,
  LocalStore? store,
}) =>
    [
      // The store itself is provided so screens that read or write a single key
      // — checkout saving an address, for instance — do not each need a
      // provider of their own.
      Provider<LocalStore?>.value(value: store),
      ChangeNotifierProvider(
        create: (_) => CatalogProvider(repository: repository, store: store),
      ),
      ChangeNotifierProvider(create: (_) => AuthProvider(store: store)),
      ChangeNotifierProvider(create: (_) => CartProvider(store: store)),
      ChangeNotifierProvider(create: (_) => SearchProvider(store: store)),
      ChangeNotifierProvider(create: (_) => WishlistProvider(store: store)),
      ChangeNotifierProvider(create: (_) => OrderProvider(store: store)),
      ChangeNotifierProvider(create: (_) => SettingsProvider(store: store)),
      ChangeNotifierProvider(create: (_) => ShellTabController()),
    ];
