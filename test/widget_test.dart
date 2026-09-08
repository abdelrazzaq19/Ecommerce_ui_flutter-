import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_products.dart';
import 'helpers/fake_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  group('app boot', () {
    testWidgets('MyApp builds and lands on the home page', (tester) async {
      await tester.pumpWidget(MyApp(repository: FakeProductRepository()));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('test harness', () {
    testWidgets('pumpApp renders a child inside the provider graph',
        (tester) async {
      await pumpApp(tester, const Scaffold(body: Text('harness ok')));

      expect(find.text('harness ok'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('product fixtures are available and distinct', () {
      expect(fakeProducts, isNotEmpty);
      expect(
        fakeProducts.map((p) => p.id).toSet().length,
        fakeProducts.length,
        reason: 'fixture ids must be unique so cart/wishlist tests can key on them',
      );
    });
  });
}
