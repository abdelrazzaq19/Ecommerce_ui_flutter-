import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/product_provider.dart';
import 'theme/app_theme.dart';
import 'views/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The provider graph lives inside MyApp rather than main() so widget tests
    // can pump `const MyApp()` directly and get a fully wired app.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter E-Commerce',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Task 17 replaces this with the user's persisted preference.
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
