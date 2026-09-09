import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/models/order.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/order_provider.dart';
import 'package:ecommerce_app/state/search_provider.dart';
import 'package:ecommerce_app/state/settings_provider.dart';
import 'package:ecommerce_app/state/wishlist_provider.dart';
import 'package:ecommerce_app/views/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_products.dart';
import '../helpers/fake_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = fakeCatalog(4);

  Future<LocalStore> openStore([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return LocalStore.open();
  }

  group('SettingsProvider', () {
    test('defaults to following the device', () {
      final settings = SettingsProvider();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.followsSystem, isTrue);
    });

    test('restores a saved choice', () async {
      final store = await openStore({'themeMode': 'dark'});

      expect(SettingsProvider(store: store).themeMode, ThemeMode.dark);
    });

    test('persists a new choice', () async {
      final store = await openStore();

      SettingsProvider(store: store).setThemeMode(ThemeMode.light);

      expect(store.readThemeMode(), ThemeMode.light);
      expect(SettingsProvider(store: store).themeMode, ThemeMode.light);
    });

    test('notifies once per real change', () {
      var notifications = 0;
      final settings = SettingsProvider()..addListener(() => notifications++);

      settings
        ..setThemeMode(ThemeMode.dark)
        ..setThemeMode(ThemeMode.dark)
        ..setThemeMode(ThemeMode.system);

      expect(notifications, 2);
    });

    test('labels every mode', () {
      for (final mode in ThemeMode.values) {
        expect(SettingsProvider.labelFor(mode), isNotEmpty);
      }
      expect(SettingsProvider.labelFor(ThemeMode.system), 'System');
    });
  });

  group('appearance picker', () {
    testWidgets('offers System, Light and Dark, and switches between them',
        (tester) async {
      setViewport(tester, const Size(500, 1100));
      final settings = SettingsProvider();

      await pumpApp(
        tester,
        const ProfilePage(),
        providers: [ChangeNotifierProvider.value(value: settings)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Following your device setting.'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      expect(find.textContaining('Always dark'), findsOneWidget);

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.system);
    });

    testWidgets('shows the app version', (tester) async {
      setViewport(tester, const Size(500, 1100));
      await pumpApp(tester, const ProfilePage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Version 1.0.0'), findsOneWidget);
    });
  });

  group('theme applies to the whole app', () {
    testWidgets('choosing Dark repaints immediately and survives a restart',
        (tester) async {
      setViewport(tester, const Size(500, 1100));
      final store = await openStore();

      await tester.pumpWidget(
        MyApp(repository: FakeProductRepository(), store: store),
      );
      await tester.pumpAndSettle();

      ThemeMode? currentThemeMode() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;

      expect(currentThemeMode(), ThemeMode.system);

      // Drive the provider directly: reaching the picker means walking the
      // shell, which this test is not about.
      final settings = Provider.of<SettingsProvider>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      settings.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(currentThemeMode(), ThemeMode.dark);
      expect(store.readThemeMode(), ThemeMode.dark);

      // A fresh app on the same device comes back dark.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MyApp(repository: FakeProductRepository(), store: store),
      );
      await tester.pumpAndSettle();

      expect(currentThemeMode(), ThemeMode.dark);
    });
  });

  group('erase local data', () {
    testWidgets('asks first, then clears everything the app keeps',
        (tester) async {
      setViewport(tester, const Size(500, 1200));

      final auth = AuthProvider(latency: Duration.zero);
      await auth.login(email: 'ada@example.com', password: 'letters123');
      final cart = CartProvider()..addToCart(catalog.first);
      final wishlist = WishlistProvider()..add(2);
      final orders = OrderProvider();
      await orders.placeOrder(
        lines: [OrderLine.fromProduct(catalog.first, 1)],
        address: ShippingAddress.empty,
        shipping: 0,
      );
      final search = SearchProvider();
      search.submit('shoes');

      await pumpApp(
        tester,
        const ProfilePage(),
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider.value(value: wishlist),
          ChangeNotifierProvider.value(value: orders),
          ChangeNotifierProvider.value(value: search),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erase local data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cart.isEmpty, isFalse, reason: 'cancelling must change nothing');
      expect(auth.isAuthenticated, isTrue);

      await tester.tap(find.text('Erase local data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erase everything'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
      expect(wishlist.isEmpty, isTrue);
      expect(orders.isEmpty, isTrue);
      expect(search.recentSearches, isEmpty);
      expect(auth.isAuthenticated, isFalse);
      expect(find.text('Local data erased'), findsOneWidget);
    });
  });

  group('signed-out profile', () {
    testWidgets('offers sign in and register rather than blank fields',
        (tester) async {
      setViewport(tester, const Size(500, 1100));
      await pumpApp(tester, const ProfilePage());
      await tester.pumpAndSettle();

      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
    });
  });
}
