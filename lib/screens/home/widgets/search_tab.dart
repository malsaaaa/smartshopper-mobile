import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/services/ai_recommendation_service.dart';
import 'package:smartshopper_mobile/widgets/add_to_list_sheet.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';
import 'package:smartshopper_mobile/services/web_scraper_service.dart';

// ─── Brand category metadata ───────────────────────────────────────────────────

class _BrandMeta {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _BrandMeta(this.name, this.icon, this.color, this.bgColor);
}

const _brandMeta = <String, _BrandMeta>{
  'Nestlé': _BrandMeta('Nestlé', Icons.emoji_food_beverage_rounded, Color(0xFF1B5E20), Color(0xFFE8F5E9)),
  'Aik Cheong': _BrandMeta('Aik Cheong', Icons.local_cafe_rounded, Color(0xFF6D4C41), Color(0xFFEFEBE9)),
  'Faiza': _BrandMeta('Faiza', Icons.grain_rounded, Color(0xFFF57F17), Color(0xFFFFFDE7)),
  'Unilever': _BrandMeta('Unilever', Icons.soap_rounded, Color(0xFF1565C0), Color(0xFFE3F2FD)),
};

_BrandMeta _brandMetaFor(String cat) =>
    _brandMeta[cat] ??
    const _BrandMeta('Other', Icons.category_rounded, Color(0xFF546E7A), Color(0xFFECEFF1));

// ─── Product-type category metadata ───────────────────────────────────────────

class _TypeMeta {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _TypeMeta(this.name, this.icon, this.color, this.bgColor);
}

const _typeMeta = <String, _TypeMeta>{
  'Drinks': _TypeMeta('Drinks', Icons.local_drink_rounded, Color(0xFF0277BD), Color(0xFFE1F5FE)),
  'Instant Noodles': _TypeMeta('Instant Noodles', Icons.ramen_dining_rounded, Color(0xFFE65100), Color(0xFFFFF3E0)),
  'Rice & Grains': _TypeMeta('Rice & Grains', Icons.grain_rounded, Color(0xFF558B2F), Color(0xFFF1F8E9)),
  'Household Cleaning': _TypeMeta('Household Cleaning', Icons.cleaning_services_rounded, Color(0xFF4527A0), Color(0xFFEDE7F6)),
};

_TypeMeta _typeMetaFor(String type) =>
    _typeMeta[type] ??
    const _TypeMeta('Other', Icons.category_rounded, Color(0xFF546E7A), Color(0xFFECEFF1));

// ─── Main widget ──────────────────────────────────────────────────────────────

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  late TextEditingController _searchController;

  /// Raw user query (drives skeleton display and counter text).
  String _query = '';

  /// Frozen snapshot of search results — captured ONLY after BOTH
  /// scrapeAllProducts AND scrapeAllRetailers finish.
  List<Product>? _frozenResults;


  /// AI-generated recipe bundle suggestion.
  AiRecipeBundle? _recipeBundle;
  bool _recipeBundleLoading = false;

  String? _selectedCategory;
  String? _selectedBrand;
  bool _isScraping = false;
  Timer? _debounceTimer;
  List<Product>? _shuffledFeaturedProducts;
  int _lastProductCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounceTimer?.cancel();

    if (q.trim().isEmpty) {
      setState(() {
        _query = '';
        _frozenResults = null;
        _recipeBundle = null;
        _recipeBundleLoading = false;
      });
      return;
    }

    setState(() {
      _query = q.trim();
      _frozenResults = null;  // clear old results — skeleton shows immediately
      _recipeBundle = null;
      _recipeBundleLoading = false;
      _isScraping = true;
    });

    _triggerLiveScrape(q.trim());
  }

  Future<void> _triggerLiveScrape(String query) async {
    if (query.trim().isEmpty) return;

    // Ensure skeleton is shown before any async work begins.
    if (mounted) {
      setState(() {
        _isScraping = true;
        _frozenResults = null;
      });
    }

    try {
      final scraperService = WebScraperService();

      // ── Step 1: Fast in-memory scrape (parallel) ─────────────────────────
      // Collects raw product+price pairs from all retailers concurrently.
      final inMemoryResults = await scraperService.scrapeAllProducts(category: query);

      // ── Step 2: Persist in-memory results for price comparison ─────────────
      if (mounted) {
        final products = <Product>[];
        final prices   = <Price>[];
        for (final (p, pr) in inMemoryResults) {
          products.add(p);
          prices.add(pr);
        }

        // Atomic write — one Riverpod notification, zero intermediate rebuilds.
        ref.read(localProductsProvider.notifier).state = [
          ...ref.read(localProductsProvider),
          ...products,
        ];
        ref.read(localPricesProvider.notifier).state = [
          ...ref.read(localPricesProvider),
          ...prices,
        ];
      }

      // ── Step 3: Save results to Firestore in the background (non-blocking) ──
      // ignore: unawaited_futures
      scraperService.storeScrapedProducts(inMemoryResults).catchError((e) {
        debugPrint('Firestore background write bypassed: $e');
      });

      // ── Step 4: Capture frozen snapshot & kick off AI in parallel ──────────
      if (mounted) {
        final snapshot = ref.read(productSearchProvider(query));
        setState(() {
          _frozenResults = snapshot;
          _isScraping = false;
          _recipeBundleLoading = true;
        });

        // Call Recipe Suggestions
        AiRecommendationService.getRecipeBundle(
          query: query,
        ).then((bundle) {
          if (mounted) {
            setState(() {
              _recipeBundle = bundle;
              _recipeBundleLoading = false;
            });
          }
        });
      }

    } catch (e) {
      debugPrint('Error during live search scraping: $e');
      if (mounted) {
        // Even on error show whatever we have
        final fallback = ref.read(productSearchProvider(query));
        setState(() {
          _frozenResults = fallback;
          _isScraping = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(groupedProductsProvider);
    final recentSearches = ref.watch(recentSearchesProvider);
    final popularSearches = ref.watch(popularSearchesProvider);

    // We are in search mode if the user has typed something — regardless of
    // whether scraping is still running or has completed.
    final showingSearch = _query.isNotEmpty;

    return productsAsync.when(
      data: (allProducts) {
        if (_shuffledFeaturedProducts == null || allProducts.length != _lastProductCount) {
          _shuffledFeaturedProducts = List<Product>.from(allProducts)..shuffle();
          _lastProductCount = allProducts.length;
        }

        final excludedBrands = {
          'CAROTINO',
          'CPALIF',
          'CP4_ALIF',
          'ECOSAFA',
          'LOTUSS',
          'LOTUS\'S',
          'LOTUS',
          'SAFOLI'
        };
        final allBrands = allProducts
            .map((p) => p.category)
            .toSet()
            .where((brand) => !excludedBrands.contains(brand.toUpperCase().trim()))
            .toList()
          ..sort();
        final allTypes = allProducts.map((p) => p.productType).toSet().toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: SearchField(
                controller: _searchController,
                onChanged: (val) {
                  _debounceTimer?.cancel();

                  if (val.trim().isEmpty) {
                    setState(() {
                      _query = '';
                      _frozenResults = null;
                      _isScraping = false;
                    });
                    return;
                  }

                  // Update query immediately but do NOT show skeleton yet —
                  // the user may still be typing. Skeleton appears only when
                  // _triggerLiveScrape is actually called.
                  setState(() {
                    _query = val.trim();
                  });

                  // Auto trigger live crawling 1.5 seconds after user stops typing
                  _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
                    _triggerLiveScrape(val);
                  });
                },
                onSubmitted: (q) {
                  _debounceTimer?.cancel();
                  ref.read(recentSearchesProvider.notifier).addSearch(q);
                  _triggerLiveScrape(q);
                },
                hint: 'Search Milo, Drinks, Noodles…',
              ),
            ),

            if (showingSearch || _selectedCategory != null || _selectedBrand != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  _isScraping
                      ? 'Searching for \'$_query\'…'
                      : _frozenResults != null
                          ? '${_frozenResults!.length} results for \'$_query\''
                          : '${allProducts.where((p) => (_selectedCategory != null && p.productType == _selectedCategory) || (_selectedBrand != null && p.category == _selectedBrand)).length} results for \'${_selectedCategory ?? _selectedBrand}\'',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: _isScraping
                    ? const _SearchResultsSkeleton()
                    : _frozenResults != null
                        // Frozen snapshot — never re-renders from stream updates
                        ? Column(
                            key: ValueKey('results_${_query}_${_frozenResults!.length}'),
                            children: [

                              // AI Recipe Suggestions Card
                              _AiRecipeBundleCard(
                                bundle: _recipeBundle,
                                isLoading: _recipeBundleLoading,
                                onIngredientTap: (ingredient) {
                                  _searchController.text = ingredient;
                                  _onSearch(ingredient);
                                },
                              ),

                              Expanded(
                                child: _SearchResults(
                                  results: _frozenResults!,
                                  query: _query,
                                ),
                              ),
                            ],
                          )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          children: [
                        // ── Recent Searches (if any) ────────────────────────
                        if (_selectedCategory == null && _selectedBrand == null && recentSearches.isNotEmpty) ...[
                          Text('Recent Searches', style: AppTypography.labelLarge.copyWith(color: AppTheme.textSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: recentSearches.map((s) => Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: ActionChip(
                                  label: Text(s),
                                  onPressed: () {
                                    _searchController.text = s;
                                    _onSearch(s);
                                  },
                                  backgroundColor: AppTheme.background,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                                  labelStyle: AppTypography.labelSmall,
                                ),
                              )).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // ── Popular Searches ────────────────────────────────
                        if (_selectedCategory == null && _selectedBrand == null) ...[
                          Text('Popular Searches', style: AppTypography.labelLarge.copyWith(color: AppTheme.textSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: popularSearches.map((s) => Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: ActionChip(
                                  label: Text(s),
                                  onPressed: () {
                                    _searchController.text = s;
                                    _onSearch(s);
                                  },
                                  backgroundColor: AppTheme.background,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                                  labelStyle: AppTypography.labelSmall.copyWith(color: AppTheme.primary),
                                ),
                              )).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],



                        // ── Categories (Chips) ────────────────
                        Text('By Category', style: AppTypography.labelLarge.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...allTypes.map((type) {
                                final isSelected = _selectedCategory == type;
                                final meta = _typeMetaFor(type);
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                                  child: FilterChip(
                                    avatar: Icon(meta.icon, size: 14, color: isSelected ? AppTheme.primary : AppTheme.textTertiary),
                                    label: Text(type),
                                    selected: isSelected,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedCategory = val ? type : null;
                                        if (val) _selectedBrand = null;
                                      });
                                    },
                                    backgroundColor: AppTheme.background,
                                    selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                                    labelStyle: AppTypography.labelSmall.copyWith(
                                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ── Brands (Chips) ────────────────
                        Text('By Brand', style: AppTypography.labelLarge.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...allBrands.map((brand) {
                                final isSelected = _selectedBrand == brand;
                                final meta = _brandMetaFor(brand);
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                                  child: FilterChip(
                                    avatar: Icon(meta.icon, size: 14, color: isSelected ? meta.color : AppTheme.textTertiary),
                                    label: Text(brand),
                                    selected: isSelected,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedBrand = val ? brand : null;
                                        if (val) _selectedCategory = null;
                                      });
                                    },
                                    backgroundColor: AppTheme.background,
                                    selectedColor: meta.color.withValues(alpha: 0.1),
                                    labelStyle: AppTypography.labelSmall.copyWith(
                                      color: isSelected ? meta.color : AppTheme.textSecondary,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        // ── Content ───────────────────────────────────────────
                        if (_selectedCategory != null || _selectedBrand != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text('Products in ', style: AppTypography.labelLarge.copyWith(color: AppTheme.textSecondary)),
                                  Text(
                                    _selectedCategory ?? _selectedBrand!,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: _selectedCategory != null ? AppTheme.primary : _brandMetaFor(_selectedBrand!).color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selectedCategory = null;
                                  _selectedBrand = null;
                                }),
                                child: const Text('Clear', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...allProducts
                              .where((p) => 
                                (_selectedCategory != null && p.productType == _selectedCategory) ||
                                (_selectedBrand != null && p.category == _selectedBrand)
                              )
                              .map((p) => _BrandCard(product: p)),
                        ] else ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text('Featured Products', style: AppTypography.labelLarge.copyWith(color: AppTheme.textSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: (_shuffledFeaturedProducts ?? allProducts).length.clamp(0, 10),
                              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final p = (_shuffledFeaturedProducts ?? allProducts)[index];
                                return _CompactProductCard(product: p);
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                ),
            ),
          ],
        );
      },
      loading: () => const _SearchResultsSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// ─── Search results view ───────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final List<Product> results;
  final String query;

  const _SearchResults({required this.results, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: AppSpacing.md),
            Text('No products found for "$query"', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('Try a different search term', style: AppTypography.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: results.length,
      itemBuilder: (context, index) => _BrandCard(product: results[index]),
    );
  }
}

// ─── Individual product card ──────────────────────────────────────────────────

class _BrandCard extends ConsumerWidget {
  final Product product;
  const _BrandCard({required this.product});

  String _formatScraped(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final hhmm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Today $hhmm';
    if (diff.inDays == 1) return 'Yesterday $hhmm';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestPrice = ref.watch(bestPriceForProductProvider(product.id));
    final allPrices = ref.watch(pricesForProductProvider(product.id));

    // Sort by price ascending to find cheapest
    final sortedPrices = [...allPrices]..sort((a, b) => a.price.compareTo(b.price));
    final cheapestRetailerId = sortedPrices.isNotEmpty ? sortedPrices.first.retailerId : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-details',
            arguments: product.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: product.imageUrl.isNotEmpty
                    ? (product.imageUrl.startsWith('assets/')
                        ? Image.asset(product.imageUrl, fit: BoxFit.contain)
                        : Image.network(
                            product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, _, __) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ))
                    : const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
              ),
              const SizedBox(width: AppSpacing.md),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: AppTypography.bodySmall.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // ── Retailer Price Badges Row ─────────────────────────────
                    if (sortedPrices.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sortedPrices.map((p) {
                            final isCheapest = p.retailerId == cheapestRetailerId;
                            final retailerName = p.retailer?.name ?? 'Store';
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCheapest
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isCheapest
                                      ? AppTheme.primary.withValues(alpha: 0.4)
                                      : AppTheme.divider,
                                  width: isCheapest ? 1.2 : 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCheapest)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 3),
                                      child: Icon(Icons.local_offer_rounded, size: 9, color: AppTheme.primary),
                                    ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        retailerName,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 8,
                                          color: isCheapest ? AppTheme.primaryDark : AppTheme.textSecondary,
                                          fontWeight: isCheapest ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        'RM ${p.price.toStringAsFixed(2)}',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 10,
                                          color: isCheapest ? AppTheme.primary : AppTheme.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else if (bestPrice != null)
                      Text(
                        'RM ${bestPrice.price.toStringAsFixed(2)}',
                        style: AppTypography.labelLarge.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      )
                    else
                      const Text('Price unavailable', style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    if (bestPrice != null)
                      Row(
                        children: [
                          Icon(Icons.update_rounded, size: 10, color: AppTheme.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            'Updated ${_formatScraped(bestPrice.scrapedAt)}',
                            style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Add to cart button
              IconButton.filledTonal(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => AddToListSheet(product: product),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactProductCard extends ConsumerWidget {
  final Product product;
  const _CompactProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestPrice = ref.watch(bestPriceForProductProvider(product.id));

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-details',
          arguments: product.id,
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: product.imageUrl.isNotEmpty
                      ? (product.imageUrl.startsWith('assets/')
                          ? Image.asset(product.imageUrl, fit: BoxFit.contain)
                          : Image.network(
                              product.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, _, __) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ))
                      : const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 24,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.name,
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.category,
              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (bestPrice != null)
              Text(
                'Cheapest RM ${bestPrice.price.toStringAsFixed(2)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              )
            else
              Text(
                'No prices',
                style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Search results skeleton loader ─────────────────────────────────────────────
class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Skeleton(width: 80, height: 80),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 140, height: 16),
                      const SizedBox(height: 8),
                      const Skeleton(width: 100, height: 12),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Skeleton(width: 54, height: 22, borderRadius: BorderRadius.circular(11)),
                          const SizedBox(width: 8),
                          Skeleton(width: 54, height: 22, borderRadius: BorderRadius.circular(11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ── AI Recipe Suggestions Card ────────────────────────────────────────────────
class _AiRecipeBundleCard extends StatelessWidget {
  final AiRecipeBundle? bundle;
  final bool isLoading;
  final ValueChanged<String> onIngredientTap;

  const _AiRecipeBundleCard({
    required this.bundle,
    required this.isLoading,
    required this.onIngredientTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && (bundle == null || bundle!.recipeName.isEmpty)) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isLoading ? _buildLoadingCard() : _buildBundleCard(context, bundle!),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      key: const ValueKey('recipe-loading'),
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D9488).withValues(alpha: 0.08),
            const Color(0xFF14B8A6).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 150, height: 11, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                Skeleton(width: 180, height: 10, borderRadius: BorderRadius.circular(6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleCard(BuildContext context, AiRecipeBundle recipeData) {
    return Container(
      key: const ValueKey('recipe-analysis'),
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D9488).withValues(alpha: 0.08),
            const Color(0xFF14B8A6).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu_rounded, size: 16, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Recipe Planner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recipeData.recipeName,
                        style: const TextStyle(fontSize: 8, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Making ${recipeData.recipeName}? Get matching ingredients:',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: recipeData.ingredients.map((ingredient) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.search_rounded, size: 12, color: Color(0xFF0F766E)),
                          label: Text(ingredient),
                          onPressed: () => onIngredientTap(ingredient),
                          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            side: BorderSide(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                          ),
                          labelStyle: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




