import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/wishlist_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_products.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = fakeCatalog(6);

  Future<LocalStore> emptyStore() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore.open();
  }

  group('toggling', () {
    test('starts empty', () {
      final wishlist = WishlistProvider();

      expect(wishlist.isEmpty, isTrue);
      expect(wishlist.count, 0);
      expect(wishlist.contains(1), isFalse);
    });

    test('toggle reports the state it moved to', () {
      final wishlist = WishlistProvider();

      expect(wishlist.toggle(1), isTrue);
      expect(wishlist.contains(1), isTrue);

      expect(wishlist.toggle(1), isFalse);
      expect(wishlist.contains(1), isFalse);
    });

    test('adding twice is not a duplicate', () {
      final wishlist = WishlistProvider()
        ..add(1)
        ..add(1);

      expect(wishlist.count, 1);
    });

    test('removing something absent changes nothing', () {
      var notifications = 0;
      final wishlist = WishlistProvider()..addListener(() => notifications++);

      wishlist.remove(99);

      expect(wishlist.isEmpty, isTrue);
      expect(notifications, 0);
    });

    test('clear empties it', () {
      final wishlist = WishlistProvider()
        ..add(1)
        ..add(2)
        ..clear();

      expect(wishlist.isEmpty, isTrue);
    });
  });

  group('order', () {
    test('newest saved comes first', () {
      final wishlist = WishlistProvider()
        ..add(1)
        ..add(2)
        ..add(3);

      expect(wishlist.productIds, [3, 2, 1]);
    });

    test('resolve returns products in saved order', () {
      final wishlist = WishlistProvider()
        ..add(4)
        ..add(1);

      expect(
        wishlist.resolve(catalog).map((product) => product.id).toList(),
        [1, 4],
      );
    });

    test('resolve skips ids the catalog no longer has', () {
      final wishlist = WishlistProvider()
        ..add(2)
        ..add(999);

      expect(wishlist.resolve(catalog), hasLength(1));
      expect(
        wishlist.count,
        2,
        reason: 'the saved id stays; only the rendering skips it',
      );
    });

    test('resolve on an empty catalog yields nothing rather than throwing', () {
      final wishlist = WishlistProvider()..add(1);

      expect(wishlist.resolve(const []), isEmpty);
    });
  });

  group('persistence', () {
    test('restores what a previous session saved, in order', () async {
      final store = await emptyStore();

      WishlistProvider(store: store)
        ..add(3)
        ..add(7);

      final restored = WishlistProvider(store: store);

      expect(restored.productIds, [7, 3]);
    });

    test('persists removals and clears', () async {
      final store = await emptyStore();
      final wishlist = WishlistProvider(store: store)
        ..add(1)
        ..add(2);

      wishlist.remove(1);
      expect(WishlistProvider(store: store).productIds, [2]);

      wishlist.clear();
      expect(WishlistProvider(store: store).isEmpty, isTrue);
    });

    test('works without a store', () {
      final wishlist = WishlistProvider()..add(1);

      expect(wishlist.contains(1), isTrue);
    });
  });

  group('notifications', () {
    test('each real change notifies once', () {
      var notifications = 0;
      final wishlist = WishlistProvider()..addListener(() => notifications++);

      wishlist
        ..add(1)
        ..add(1) // no-op
        ..toggle(1)
        ..clear(); // already empty, no-op

      expect(notifications, 2);
    });
  });
}
