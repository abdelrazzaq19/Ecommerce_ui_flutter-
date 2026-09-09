import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/product_repository.dart';
import 'routes.dart';
import 'services/local_store.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

/// The application root: provider graph, themes and routing table.
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository, this.store});

  /// Overridden by tests so a widget test never reaches the live store API.
  final ProductRepository? repository;

  /// On-device persistence. Null in tests that do not care about it.
  final LocalStore? store;

  @override
  Widget build(BuildContext context) {
    // The provider graph lives inside MyApp rather than main() so widget tests
    // can pump `const MyApp()` directly and get a fully wired app.
    return MultiProvider(
      providers: appProviders(repository: repository, store: store),
      // Only the theme preference is watched here, so changing a cart quantity
      // does not rebuild the entire app.
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Flutter E-Commerce',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          initialRoute: AppRoutes.home,
          routes: appRoutes,
        ),
      ),
    );
  }
}
