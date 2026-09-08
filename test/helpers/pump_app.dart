import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_provider.dart';
import 'package:ecommerce_app/state/search_provider.dart';
import 'package:ecommerce_app/state/shell_tab_controller.dart';
import 'package:ecommerce_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_repository.dart';

/// Sets the logical window size for a test.
///
/// `setSurfaceSize` does not reliably reach `MediaQuery` in this Flutter
/// version, and the app's layout is width-driven on six platforms, so tests
/// override the view directly at a 1:1 pixel ratio.
void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps [child] inside the app's provider graph, themed like the real app.
///
/// Pass [catalog] to control the catalog a screen sees; the default is backed
/// by [FakeProductRepository], so no test reaches the network. Extra
/// [providers] are appended last, so they win over the defaults.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  CatalogProvider? catalog,
  List<SingleChildWidget> providers = const [],
  ThemeData? theme,
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              catalog ??
              CatalogProvider(
                repository: FakeProductRepository(),
                autoLoad: false,
              ),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ShellTabController()),
        ...providers,
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: child,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: widget!,
        ),
      ),
    ),
  );
}
