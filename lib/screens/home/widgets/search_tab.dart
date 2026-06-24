import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/add_to_list_sheet.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

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
  String _query = '';
  String? _selectedCategory;
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(groupedProductsProvider);
    final searchResults = ref.watch(productSearchProvider(_query));
    final recentSearches = ref.watch(recentSearchesProvider);
    final popularSearches = ref.watch(popularSearchesProvider);
    
    final showingSearch = _query.isNotEmpty;

    return productsAsync.when(
      data: (allProducts) {
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
                onChanged: _onSearch,
                onSubmitted: (q) => ref.read(recentSearchesProvider.notifier).addSearch(q),
                hint: 'Search Milo, Drinks, Noodles…',
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: showingSearch
                  ? _SearchResults(results: searchResults, query: _query)
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
                          ...allProducts.take(10).map((p) => _BrandCard(product: p)),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (bestPrice != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BEST PRICE', style: AppTypography.labelSmall.copyWith(fontSize: 8, color: AppTheme.textTertiary)),
                              Text(
                                'RM ${bestPrice.price.toStringAsFixed(2)}',
                                style: AppTypography.labelLarge.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.update_rounded, size: 10, color: AppTheme.textTertiary),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Scraped ${_formatScraped(bestPrice.scrapedAt)}',
                                    style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppTheme.textTertiary),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          const Text('Price unavailable', style: AppTypography.bodySmall),
                        
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
