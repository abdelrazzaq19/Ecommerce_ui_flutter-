import 'package:flutter/material.dart';

import 'app.dart';
import 'services/local_store.dart';

Future<void> main() async {
  // The store is opened before the first frame so the cart, wishlist and
  // settings are already on screen at launch instead of popping in a moment
  // later.
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();

  runApp(MyApp(store: store));
}
