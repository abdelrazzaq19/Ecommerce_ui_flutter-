import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_products.dart';

Future<LocalStore> openStore([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return LocalStore.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first launch defaults', () {
    test('every key returns a usable empty value', () async {
      final store = await openStore();

      expect(store.readCart(), isEmpty);
      expect(store.readWishlist(), isEmpty);
      expect(store.readSession(), isNull);
      expect(store.readThemeMode(), ThemeMode.system);
      expect(store.readSearchHistory(), isEmpty);
      expect(store.readOrders(), isEmpty);
      expect(store.readCachedCatalog(), isNull);
      expect(store.readCatalogCachedAt(), isNull);
    });
  });

  group('cart', () {
    test('round-trips product quantities', () async {
      final store = await openStore();

      await store.writeCart({1: 2, 3: 1});

      expect(store.readCart(), {1: 2, 3: 1});
    });

    test('drops entries with unparseable keys or non-integer quantities',
        () async {
      final store = await openStore({
        'cart': '{"1": 2, "abc": 3, "4": "many"}',
      });

      expect(store.readCart(), {1: 2});
    });

    test('returns an empty cart when the stored value is not JSON', () async {
      final store = await openStore({'cart': 'not json at all'});

      expect(store.readCart(), isEmpty);
    });

    test('returns an empty cart when the stored JSON is the wrong shape',
        () async {
      final store = await openStore({'cart': '[1, 2, 3]'});

      expect(store.readCart(), isEmpty);
    });
  });

  group('wishlist', () {
    test('round-trips product ids', () async {
      final store = await openStore();

      await store.writeWishlist([3, 1]);

      expect(store.readWishlist(), [3, 1]);
    });

    test('drops duplicates but keeps the saved order', () async {
      final store = await openStore({'wishlist': '[5, 2, 5, 9]'});

      expect(store.readWishlist(), [5, 2, 9]);
    });

    test('ignores non-integer entries in a corrupt list', () async {
      final store = await openStore({'wishlist': '[1, "two", null, 3]'});

      expect(store.readWishlist(), [1, 3]);
    });
  });

  group('session', () {
    test('round-trips the signed-in profile', () async {
      final store = await openStore();

      await store.writeSession(const {
        'name': 'Ada',
        'email': 'ada@example.test',
        'phone': '0800000000',
      });

      expect(store.readSession()!['email'], 'ada@example.test');
    });

    test('clearSession removes the session and leaves other keys alone',
        () async {
      final store = await openStore();
      await store.writeSession(const {'email': 'ada@example.test'});
      await store.writeWishlist([7]);

      await store.clearSession();

      expect(store.readSession(), isNull);
      expect(store.readWishlist(), [7]);
    });

    test('a corrupt session reads as signed out rather than throwing',
        () async {
      final store = await openStore({'session': '{{{'});

      expect(store.readSession(), isNull);
    });
  });

  group('theme mode', () {
    test('round-trips each mode', () async {
      final store = await openStore();

      for (final mode in ThemeMode.values) {
        await store.writeThemeMode(mode);
        expect(store.readThemeMode(), mode);
      }
    });

    test('falls back to system for an unknown stored value', () async {
      final store = await openStore({'themeMode': 'purple'});

      expect(store.readThemeMode(), ThemeMode.system);
    });
  });

  group('search history', () {
    test('records the newest query first and de-duplicates', () async {
      final store = await openStore();

      await store.addSearch('shoes');
      await store.addSearch('bag');
      await store.addSearch('shoes');

      expect(store.readSearchHistory(), ['shoes', 'bag']);
    });

    test('ignores blank queries', () async {
      final store = await openStore();

      await store.addSearch('   ');
      await store.addSearch('');

      expect(store.readSearchHistory(), isEmpty);
    });

    test('keeps at most ${LocalStore.maxSearchHistory} entries', () async {
      final store = await openStore();

      for (var i = 0; i < LocalStore.maxSearchHistory + 5; i++) {
        await store.addSearch('query $i');
      }

      expect(store.readSearchHistory(), hasLength(LocalStore.maxSearchHistory));
      expect(store.readSearchHistory().first, 'query 14');
    });

    test('clears on request', () async {
      final store = await openStore();
      await store.addSearch('shoes');

      await store.clearSearchHistory();

      expect(store.readSearchHistory(), isEmpty);
    });
  });

  group('orders', () {
    test('round-trips a list of order documents', () async {
      final store = await openStore();

      await store.writeOrders([
        {'id': 'ORD-1', 'total': 12.5},
      ]);

      expect(store.readOrders().single['id'], 'ORD-1');
    });

    test('a corrupt orders blob reads as no orders', () async {
      final store = await openStore({'orders': '[1, 2]'});

      expect(store.readOrders(), isEmpty);
    });
  });

  group('catalog cache', () {
    test('round-trips products and records when they were cached', () async {
      final store = await openStore();
      final before = DateTime.now().subtract(const Duration(seconds: 1));

      await store.writeCachedCatalog(fakeProducts);

      expect(store.readCachedCatalog(), fakeProducts);
      expect(store.readCatalogCachedAt()!.isAfter(before), isTrue);
    });

    test('a corrupt cache reads as no cache', () async {
      final store = await openStore({'catalog': 'not json'});

      expect(store.readCachedCatalog(), isNull);
    });

    test('skips malformed products inside an otherwise valid cache', () async {
      final store = await openStore({
        'catalog': '[{"id": 1, "title": "Kept"}, "junk"]',
      });

      final cached = store.readCachedCatalog();
      expect(cached, hasLength(1));
      expect(cached!.single.title, 'Kept');
    });
  });

  group('clearAll', () {
    test('wipes every key the app owns', () async {
      final store = await openStore();
      await store.writeCart({1: 1});
      await store.writeWishlist([2]);
      await store.writeSession(const {'email': 'ada@example.test'});
      await store.addSearch('shoes');
      await store.writeCachedCatalog(<Product>[fakeProducts.first]);

      await store.clearAll();

      expect(store.readCart(), isEmpty);
      expect(store.readWishlist(), isEmpty);
      expect(store.readSession(), isNull);
      expect(store.readSearchHistory(), isEmpty);
      expect(store.readCachedCatalog(), isNull);
    });
  });
}
