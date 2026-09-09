import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/wishlist_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_states.dart';
import '../widgets/category_chips.dart';
import '../widgets/offline_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/sort_sheet.dart';
import 'product_detail_page.dart';

/// The catalog screen.
///
/// It loads itself on first build. Previously the only trigger was a scroll
/// notification, and an empty list cannot scroll, so the app opened on a
/// permanently blank page.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CatalogProvider>().loadIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Reveal the next page slightly before the end so the grid never visibly
    // runs out. Comparing pixels == maxScrollExtent, as the old code did, only
    // fires on an exact landing.
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<CatalogProvider>().loadNextPage();
    }
  }

  void _addToCart(BuildContext context, Product product) {
    // A short tap back: on a phone this is the only confirmation you get
    // without looking at the screen.
    unawaited(HapticFeedback.lightImpact());
    context.read<CartProvider>().addToCart(product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart'),
          duration: AppDurations.slow * 4,
        ),
      );
  }

  void _toggleFavorite(BuildContext context, Product product) {
    unawaited(HapticFeedback.selectionClick());
    final saved = context.read<WishlistProvider>().toggle(product.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved ? '${product.title} saved' : '${product.title} removed',
          ),
          duration: AppDurations.slow * 4,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = AppBreakpoints.columnsForWidth(constraints.maxWidth);

            return RefreshIndicator(
              onRefresh: catalog.refresh,
              child: Center(
                // Wide desktop windows get a centred column rather than a grid
                // stretched across 2000 logical pixels.
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
                  child: CustomScrollView(
                    controller: _scrollController,
                    // Always scrollable so pull-to-refresh works even when the
                    // body is an error or empty state.
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _header(),
                      if (catalog.isShowingCachedData)
                        SliverToBoxAdapter(
                          child: OfflineBanner(
                            cachedAt: catalog.cachedAt,
                            onRetry: catalog.refresh,
                          ),
                        ),
                      if (catalog.status == CatalogStatus.ready)
                        SliverToBoxAdapter(child: _filterBar(context, catalog)),
                      ..._body(context, catalog, columns),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return const SliverAppBar.large(
      pinned: true,
      title: Text('Shop'),
    );
  }

  Widget _filterBar(BuildContext context, CatalogProvider catalog) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryChips(
          categories: catalog.categories,
          selected: catalog.selectedCategory,
          onSelected: catalog.selectCategory,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          // Everything here is Flexible: on a narrow phone the count, the Reset
          // button and a long sort label ("Price: high to low") do not fit on
          // one line at their natural widths.
          child: Row(
            children: [
              Flexible(
                child: Text(
                  catalog.filteredCount == 1
                      ? '1 product'
                      : '${catalog.filteredCount} products',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              if (catalog.hasActiveFilters)
                TextButton(
                  onPressed: catalog.clearFilters,
                  child: const Text('Reset'),
                ),
              Flexible(
                child: Tooltip(
                  message: 'Sort: ${catalog.sort.label}',
                  child: TextButton.icon(
                    onPressed: () async {
                      final choice = await showSortSheet(
                        context,
                        current: catalog.sort,
                      );
                      if (choice != null) catalog.setSort(choice);
                    },
                    icon: const Icon(Icons.swap_vert_rounded, size: 20),
                    label: Text(
                      catalog.sort.label,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    CatalogProvider catalog,
    int columns,
  ) {
    switch (catalog.status) {
      case CatalogStatus.initial:
      case CatalogStatus.loading:
        return [
          SliverToBoxAdapter(
            child: ProductSkeletonGrid(columns: columns, itemCount: columns * 3),
          ),
        ];

      case CatalogStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateView(
              message:
                  catalog.error?.message ?? 'The store could not be reached.',
              onRetry:
                  (catalog.error?.isRetryable ?? true) ? catalog.load : null,
            ),
          ),
        ];

      case CatalogStatus.empty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              icon: Icons.storefront_outlined,
              title: 'No products yet',
              message: 'The store has nothing to show right now. '
                  'Pull down to check again.',
              action: FilledButton.icon(
                onPressed: catalog.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
          ),
        ];

      case CatalogStatus.ready:
        final products = catalog.visibleProducts;
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: AppBreakpoints.gridAspectRatio(
                        MediaQuery.textScalerOf(context).scale(1),
                      ),
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final wishlist = context.watch<WishlistProvider>();

                return ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  isFavorite: wishlist.contains(product.id),
                  onFavoriteToggle: () => _toggleFavorite(context, product),
                  onAddToCart: () => _addToCart(context, product),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailPage(product: product),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              child: Center(
                // Static, not a spinner: paging is instant because the catalog
                // is already in memory, and an endless animation would mean the
                // widget tree never settles.
                child: Text(
                  catalog.hasMore
                      ? 'Keep scrolling for more'
                      : 'You have seen every product',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        ];
    }
  }
}
