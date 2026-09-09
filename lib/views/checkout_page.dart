import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../routes.dart';
import '../services/local_store.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/order_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/app_states.dart';
import 'order_confirmation_page.dart';

/// Checkout: shipping address, order review, place order.
///
/// Signing in is required, but the page does not throw the shopper out to do
/// it — it shows the prompt in place and switches to the form once they are
/// back, so nothing in the cart is lost.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();

  bool _placing = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  /// Fills the form from the last address used, falling back to the signed-in
  /// profile. Runs once the shopper is actually signed in.
  void _prefill(AuthProvider auth) {
    if (_prefilled) return;
    _prefilled = true;

    final saved = context.read<LocalStore?>()?.readAddress();
    final address =
        saved == null ? ShippingAddress.empty : ShippingAddress.fromJson(saved);
    final session = auth.session;

    _nameController.text =
        address.fullName.isNotEmpty ? address.fullName : session?.name ?? '';
    _phoneController.text =
        address.phone.isNotEmpty ? address.phone : session?.phone ?? '';
    _streetController.text = address.street;
    _cityController.text = address.city;
    _postalController.text = address.postalCode;
  }

  Future<void> _placeOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cart = context.read<CartProvider>();
    final catalog = context.read<CatalogProvider>();
    final orders = context.read<OrderProvider>();
    final store = context.read<LocalStore?>();
    final navigator = Navigator.of(context);

    final lines = <OrderLine>[];
    for (final entry in cart.items.entries) {
      final product = catalog.productById(entry.key);
      if (product != null) {
        lines.add(OrderLine.fromProduct(product, entry.value));
      }
    }
    if (lines.isEmpty) return;

    final address = ShippingAddress(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalController.text.trim(),
    );

    setState(() => _placing = true);

    final subtotal = cart.subtotalFor(catalog.allProducts);
    final order = await orders.placeOrder(
      lines: lines,
      address: address,
      shipping: CartProvider.shippingFor(subtotal),
    );

    await store?.writeAddress(address.toJson());
    cart.clear();

    if (!mounted) return;
    setState(() => _placing = false);

    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyStateView(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to check out',
          message: 'Your cart is kept while you sign in.',
          action: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.login),
            icon: const Icon(Icons.login),
            label: const Text('Sign in'),
          ),
        ),
      );
    }

    _prefill(auth);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const EmptyStateView(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          message: 'Add something to it before checking out.',
        ),
      );
    }

    final subtotal = cart.subtotalFor(catalog.allProducts);
    final shipping = CartProvider.shippingFor(subtotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.detailContentWidth),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const _SectionTitle(number: 1, title: 'Shipping address'),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nameController,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _streetController,
                  validator: (value) => (value ?? '').trim().length < 5
                      ? 'Enter a street address'
                      : null,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Street address',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // City and postal code sit side by side only when they fit.
                // At 320dp, or at a large text scale, two labelled fields on
                // one line overflow.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final side = constraints.maxWidth >= 360 && scale < 1.3;
                    final city = TextFormField(
                      controller: _cityController,
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Enter a city' : null,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'City'),
                    );
                    final postal = TextFormField(
                      controller: _postalController,
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Enter a code' : null,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Postal code'),
                    );

                    if (!side) {
                      return Column(
                        children: [
                          city,
                          const SizedBox(height: AppSpacing.md),
                          postal,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: city),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 2, child: postal),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(number: 2, title: 'Review your order'),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        for (final entry in cart.items.entries)
                          _ReviewLine(
                            title: catalog.productById(entry.key)?.title ??
                                'Product ${entry.key}',
                            quantity: entry.value,
                            lineTotal:
                                (catalog.productById(entry.key)?.price ?? 0) *
                                    entry.value,
                          ),
                        const Divider(height: AppSpacing.lg),
                        _TotalRow(label: 'Subtotal', value: subtotal),
                        const SizedBox(height: AppSpacing.xs),
                        _TotalRow(
                          label: 'Delivery',
                          value: shipping,
                          freeWhenZero: true,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _TotalRow(
                          label: 'Total',
                          value: subtotal + shipping,
                          emphasised: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _NoPaymentNotice(),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _placing ? null : _placeOrder,
                  icon: _placing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text('Place order · ${formatPrice(subtotal + shipping)}'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '$number',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Flexible: at a large text scale the heading alone is wider than a
        // 320dp phone.
        Flexible(
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.title,
    required this.quantity,
    required this.lineTotal,
  });

  final String title;
  final int quantity;
  final double lineTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${quantity}x ', style: theme.textTheme.labelLarge),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              formatPrice(lineTotal),
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    this.freeWhenZero = false,
  });

  final String label;
  final double value;
  final bool emphasised;
  final bool freeWhenZero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasised
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        Flexible(
          child: Text(
            freeWhenZero && value == 0 ? 'Free' : formatPrice(value),
            overflow: TextOverflow.ellipsis,
            style: emphasised
                ? theme.textTheme.titleLarge
                : theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// Says outright that nothing is charged. A checkout screen that stays silent
/// about this is misleading, however obvious the demo context seems.
class _NoPaymentNotice extends StatelessWidget {
  const _NoPaymentNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.tertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Demo order. No payment is taken and no card details are asked '
              'for. The order is recorded on this device only.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
