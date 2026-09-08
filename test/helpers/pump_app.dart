import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Pumps [child] inside the app's provider graph and a `MaterialApp`.
///
/// Pass [providers] to override any of the defaults with a test double; the
/// overrides are appended last, so they win over the defaults.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<SingleChildWidget> providers = const [],
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ...providers,
      ],
      child: MaterialApp(
        theme: theme,
        home: child,
      ),
    ),
  );
}
