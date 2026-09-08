import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_products.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = fakeCatalog(20);
  final first = catalog[0]; // $5.50
  final second = catalog[1]; // $11.00
  final expensive = catalog[19]; // $110.00

  Future<LocalStore> emptyStore() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore.open();
  }

  group('quantities', () {
    test('adding the same product twice increases its quantity', () {
      final cart = CartProvider()
        ..addToCart(first)
        ..addToCart(first);

      expect(cart.quantityOf(first.id), 2);
      expect(cart.itemCount, 2);
      expect(cart.distinctItemCount, 1);
    });

    test('adds a chosen quantity in one go', () {
      final cart = CartProvider()..addToCart(first, quantity: 3);

      expect(cart.quantityOf(first.id), 3);
    });

    test('increment and decrement move by one', () {
      final cart = CartProvider()..addToCart(first, quantity: 2);

      cart.increment(first.id);
      expect(cart.quantityOf(first.id), 3);

      cart.decrement(first.id);
      expect(cart.quantityOf(first.id), 2);
    });

    test('decrementing the last unit removes the line', () {
      final cart = CartProvider()..addToCart(first);

      cart.decrement(first.id);

      expect(cart.quantityOf(first.id), 0);
      expect(cart.isEmpty, isTrue);
    });

    test('setQuantity to zero or less removes the line', () {
      final cart = CartProvider()..addToCart(first, quantity: 5);

      cart.setQuantity(first.id, 0);

      expect(cart.isEmpty, isTrue);
    });

    test('remove returns the quantity it dropped, so it can be undone', () {
      final cart = CartProvider()..addToCart(first, quantity: 4);

      final removed = cart.removeFromCart(first.id);
      expect(removed, 4);
      expect(cart.isEmpty, isTrue);

      cart.setQuantity(first.id, removed!);
      expect(cart.quantityOf(first.id), 4);
    });

    test('removing something absent returns null and changes nothing', () {
      final cart = CartProvider();

      expect(cart.removeFromCart(999), isNull);
      expect(cart.isEmpty, isTrue);
    });

    test('clear empties the cart', () {
      final cart = CartProvider()
        ..addToCart(first)
        ..addToCart(second)
        ..clear();

      expect(cart.isEmpty, isTrue);
    });
  });

  group('pricing', () {
    test('subtotal multiplies price by quantity', () {
      final cart = CartProvider()
        ..addToCart(first, quantity: 2) // 11.00
        ..addToCart(second); // 11.00

      expect(cart.subtotalFor(catalog), closeTo(22.0, 0.001));
    });

    test('ids the catalog does not know about contribute nothing', () {
      final cart = CartProvider()..addToCart(first);

      expect(cart.subtotalFor(const []), 0);
    });

    test('shipping is charged below the free threshold and waived above it',
        () {
      expect(CartProvider.shippingFor(0), 0);
      expect(CartProvider.shippingFor(10), CartProvider.flatShipping);
      expect(
        CartProvider.shippingFor(CartProvider.freeShippingThreshold),
        0,
      );
    });

    test('total is subtotal plus shipping', () {
      final cheap = CartProvider()..addToCart(first); // 5.50
      expect(
        cheap.totalFor(catalog),
        closeTo(5.50 + CartProvider.flatShipping, 0.001),
      );

      final big = CartProvider()..addToCart(expensive); // 110.00
      expect(big.totalFor(catalog), closeTo(110.0, 0.001));
    });

    test('reports how much more is needed for free shipping', () {
      final cart = CartProvider()..addToCart(first); // 5.50

      expect(
        cart.amountToFreeShipping(catalog),
        closeTo(CartProvider.freeShippingThreshold - 5.50, 0.001),
      );

      cart.addToCart(expensive);
      expect(cart.amountToFreeShipping(catalog), 0);
    });
  });

  group('persistence', () {
    test('restores the cart written by a previous session', () async {
      final store = await emptyStore();

      CartProvider(store: store)
        ..addToCart(first, quantity: 2)
        ..addToCart(second);

      final restored = CartProvider(store: store);

      expect(restored.quantityOf(first.id), 2);
      expect(restored.quantityOf(second.id), 1);
    });

    test('persists removals and clears', () async {
      final store = await emptyStore();
      final cart = CartProvider(store: store)
        ..addToCart(first)
        ..addToCart(second);

      cart.removeFromCart(first.id);
      expect(CartProvider(store: store).quantityOf(first.id), 0);

      cart.clear();
      expect(CartProvider(store: store).isEmpty, isTrue);
    });

    test('works without a store, for tests and previews', () {
      final cart = CartProvider()..addToCart(first);

      expect(cart.quantityOf(first.id), 1);
    });
  });

  group('notifications', () {
    test('every mutation notifies listeners exactly once', () {
      var notifications = 0;
      final cart = CartProvider()..addListener(() => notifications++);

      cart
        ..addToCart(first)
        ..increment(first.id)
        ..decrement(first.id)
        ..removeFromCart(first.id);

      expect(notifications, 4);
    });

    test('a no-op does not notify', () {
      var notifications = 0;
      final cart = CartProvider()..addListener(() => notifications++);

      cart
        ..removeFromCart(999)
        ..clear()
        ..addToCart(first, quantity: 0);

      expect(notifications, 0);
    });
  });
}
