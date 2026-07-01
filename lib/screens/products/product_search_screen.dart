import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/add_to_list_sheet.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';
import 'package:smartshopper_mobile/services/web_scraper_service.dart';

/// Detailed product search screen with filtering and price comparison
class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  ConsumerState<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  late TextEditingController _searchController;
  List<Product> _searchResults = [];
  String _selectedCategory = 'All';
  bool _hasSearched = false;
  bool _isScraping = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  /// Trigger live web scraping on all retailers for a search term
  Future<void> _triggerLiveScrape(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _hasSearched = true;
      _isScraping = true;
    });

    try {
      final scraperService = WebScraperService();
      
      // 1. Run live scraping locally
      final results = await scraperService.scrapeAllProducts(category: query.trim());
      
      // 2. Separate products and prices
      final localProducts = <Product>[];
      final localPrices = <Price>[];
      
      for (final (product, price) in results) {
        localProducts.add(product);
        localPrices.add(price);
      }
      
      // Update local state providers to reactively refresh the comparison list
      ref.read(localProductsProvider.notifier).state = [
        ...ref.read(localProductsProvider),
        ...localProducts,
      ];
      ref.read(localPricesProvider.notifier).state = [
        ...ref.read(localPricesProvider),
        ...localPrices,
      ];
      
      // 3. Attempt to save in Firestore in background (will succeed if admin, fail silently if regular user)
      // ignore: unawaited_futures
      scraperService.scrapeAllRetailers(
        category: query.trim(),
        storeInFirestore: true,
      ).catchError((e) => debugPrint('Firestore write bypassed: $e'));
      
      if (mounted) {
        _performSearch(query);
      }
    } catch (e) {
      debugPrint('Error during live search scraping: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScraping = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Perform search with optional category filter
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final allProducts = ref.read(groupedProductsProvider).valueOrNull ?? [];
    
    List<Product> results = allProducts
        .where((p) {
          final name = p.name.toLowerCase();
          final desc = p.description.toLowerCase();
          return queryWords.every((word) => name.contains(word) || desc.contains(word));
        })
        .toList();

    // Apply category filter if not "All"
    if (_selectedCategory != 'All') {
      results = results.where((p) => p.category == _selectedCategory).toList();
    }

    setState(() => _searchResults = results);
  }

  /// Handle category selection
  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);

    // Re-search with new category filter if search exists
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Get all unique categories from products
  List<String> _getCategories(List<String> categories) {
    return ['All', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    // Automatically update search results when Firestore stream updates products
    ref.listen<AsyncValue<List<Product>>>(groupedProductsProvider, (previous, next) {
      if (next.hasValue && _searchController.text.isNotEmpty && _hasSearched) {
        _performSearch(_searchController.text);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        centerTitle: false,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SearchField(
              controller: _searchController,
              onChanged: (val) {
                _debounceTimer?.cancel();
                
                // If search query is cleared, revert to recommendations
                if (val.trim().isEmpty) {
                  setState(() {
                    _hasSearched = false;
                    _searchResults = [];
                  });
                  return;
                }
                
                // Auto trigger live crawling 1.5 seconds after user stops typing
                _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
                  _triggerLiveScrape(val);
                });
              },
              onSubmitted: _triggerLiveScrape,
              hint: 'Search Milo, Rice, Cooking oil...',
            ),
          ),

          // Category Filter
          _buildCategoryFilter(categories),

          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  /// Build horizontal scrollable category filter
  Widget _buildCategoryFilter(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: _getCategories(categories).map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: AppTheme.primaryLight,
              backgroundColor: AppTheme.surfaceVariant,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              onSelected: (_) => _selectCategory(category),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build search results view
  Widget _buildSearchResults() {
    if (_isScraping) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text(
              'Searching stores for live prices...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      // Show recommended / popular products when user hasn't searched yet
      final allProducts = ref.watch(groupedProductsProvider).valueOrNull ?? [];
      final recommendations = allProducts.take(6).toList();
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final product = recommendations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildProductCard(product, context),
          );
        },
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Products Found',
        message: 'No products matched "${_searchController.text}" at MyDin, Lotus\'s, or AEON.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildProductCard(product, context),
        );
      },
    );
  }

  /// Build individual product card
  Widget _buildProductCard(Product product, BuildContext context) {
    final prices = ref.watch(pricesForProductProvider(product.id));

    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }

    final lowestPrice = prices.reduce((a, b) => a.price < b.price ? a : b);
    final highestPrice = prices.reduce((a, b) => a.price > b.price ? a : b);

    return BaseCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-details',
          arguments: product.id,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            product.name,
            style: AppTypography.labelLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Product Description
          Text(
            product.description,
            style: AppTypography.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),

          // Price Info
          _buildPriceInfo(prices, lowestPrice, highestPrice),
          const SizedBox(height: AppSpacing.md),

          // Retailers Count and Add to List Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${prices.length} retailers available',
                style: AppTypography.bodySmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrangeLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'SAVE RM${(highestPrice.price - lowestPrice.price).toStringAsFixed(2)}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Add to List',
            icon: Icons.add_shopping_cart,
            onPressed: () {
              final isLoggedIn = ref.read(isUserLoggedInProvider);
              if (!isLoggedIn) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Login Required'),
                    content: const Text(
                      'You need to log in to add items to your shopping list.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/firebase-auth');
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                );
              } else {
                // Use the shared AddToListSheet for consistency
                AddToListSheet.show(context, product: product);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build price comparison section
  Widget _buildPriceInfo(List<Price> prices, Price lowest, Price highest) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lowest Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lowest Price',
                style: AppTypography.labelSmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PriceDisplay(
                currentPrice: lowest.price,
                textStyle: AppTypography.labelLarge.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'at ${lowest.retailer?.name ?? 'Retailer'}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          // Divider
          Container(
            width: 1,
            height: 60,
            color: AppTheme.divider,
          ),
          // Highest Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Highest Price',
                style: AppTypography.labelSmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'RM${highest.price.toStringAsFixed(2)}',
                style: AppTypography.labelLarge.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'at ${highest.retailer?.name ?? 'Retailer'}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

