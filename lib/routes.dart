import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'repositories/product_repository.dart';
import 'services/local_store.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/catalog_provider.dart';
import 'state/search_provider.dart';
import 'state/shell_tab_controller.dart';
import 'views/app_shell.dart';
import 'views/login_page.dart';

/// Named routes.
///
/// The app previously declared only `home:`, so `pushReplacementNamed('/')`
/// after login threw "Could not find a generator for route". Every named
/// destination the app navigates to must exist in [appRoutes].
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
}

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.home: (_) => const AppShell(),
  AppRoutes.login: (_) => LoginPage(),
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
      ChangeNotifierProvider(
        create: (_) => CatalogProvider(repository: repository),
      ),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider(store: store)),
      ChangeNotifierProvider(create: (_) => SearchProvider(store: store)),
      ChangeNotifierProvider(create: (_) => ShellTabController()),
    ];
