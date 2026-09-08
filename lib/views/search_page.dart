import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/search_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_states.dart';
import '../widgets/product_card.dart';
import '../widgets/search_field.dart';
import 'product_detail_page.dart';

/// Product search.
///
/// Filters the catalog already in memory. The previous version issued a network
/// request per keystroke to an endpoint that ignores the query and returns the
/// entire catalog, so every search "succeeded" and showed all 20 products.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    context.read<SearchProvider>().submit(text);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final catalog = context.watch<CatalogProvider>();
    final results = search.filter(catalog.allProducts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: SearchField(
              controller: _controller,
              onChanged: search.queryChanged,
              onSubmitted: (text) => search.submit(text),
              onClear: () {
                _controller.clear();
                search.clear();
              },
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: _body(context, search, catalog, results),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    SearchProvider search,
    CatalogProvider catalog,
    List<Product> results,
  ) {
    if (!search.hasQuery) {
      return _IdleView(
        recent: search.recentSearches,
        catalogSize: catalog.allProducts.length,
        onSelect: _runSearch,
        onClearHistory: search.clearHistory,
      );
    }

    if (results.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No results for "${search.query}"',
        message: 'Check the spelling, or try a shorter or more general word.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppBreakpoints.columnsForWidth(constraints.maxWidth),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.74,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final product = results[index];
          return ProductCard(
            key: ValueKey(product.id),
            product: product,
            onAddToCart: () {
              context.read<CartProvider>().addToCart(product);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('${product.title} added to cart')),
                );
            },
            onTap: () {
              // Opening a result is proof the query was useful, so keep it.
              search.rememberCurrent();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailPage(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// What the screen shows before anything is typed: recent searches if there are
/// any, and otherwise a plain statement of what can be searched.
class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.recent,
    required this.catalogSize,
    required this.onSelect,
    required this.onClearHistory,
  });

  final List<String> recent;
  final int catalogSize;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recent.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_rounded,
        title: 'Search the store',
        message: catalogSize > 0
            ? 'Find any of $catalogSize products by name, category or '
                'description.'
            : 'Find products by name, category or description.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent searches', style: theme.textTheme.titleMedium),
            ),
            TextButton(
              onPressed: onClearHistory,
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final term in recent)
              ActionChip(
                avatar: const Icon(Icons.history_rounded, size: 18),
                label: Text(term),
                onPressed: () => onSelect(term),
              ),
          ],
        ),
      ],
    );
  }
}
