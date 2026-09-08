import 'package:flutter/material.dart';

import '../widgets/app_states.dart';

/// Saved products.
///
/// Task 14 fills this in with the persisted wishlist; the empty state below is
/// what a shopper sees until they save something either way.
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: const EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'Nothing saved yet',
        message: 'Tap the heart on a product to keep it here for later.',
      ),
    );
  }
}
