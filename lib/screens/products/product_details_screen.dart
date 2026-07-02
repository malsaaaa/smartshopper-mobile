import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/config/routes.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/add_to_list_sheet.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';
import 'package:smartshopper_mobile/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Product details screen showing full product info and all retailer prices
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  String _sortBy = 'price'; // 'price' or 'retailer'
  bool _ascending = true;
  Position? _userPosition;
  final Map<int, Map<String, double>> _autoCoords = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    var pos = await LocationService.getCurrentPosition();
    pos ??= Position(
      latitude: LocationService.fallbackLat,
      longitude: LocationService.fallbackLng,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    if (mounted) {
      setState(() {
        _userPosition = pos;
      });
      // Update global location provider with resolved position
      ref.read(userLocationProvider.notifier).state = pos;
    }
  }

  Future<void> _findMissingCoords(List<Price> prices) async {
    for (var price in prices) {
      final r = price.retailer;
      if (r != null && (r.latitude == null || r.latitude == 0.0) && !_autoCoords.containsKey(r.id)) {
        // Automatically search for store location nearest to the user
        final coords = await LocationService.getStoreCoordinates(
          r.name,
          userLat: _userPosition?.latitude,
          userLon: _userPosition?.longitude,
        );
        if (coords != null && mounted) {
          setState(() {
            _autoCoords[r.id] = coords;
          });

          // Save to Firestore automatically for everyone else!
          ref.read(firestoreProductServiceProvider).updateRetailerLocation(
                r.id,
                coords['latitude']!,
                coords['longitude']!,
              );
        }
      }
    }
  }

  /// Sort prices based on selected criteria
  List<Price> _getSortedPrices(List<Price> prices) {
    final sorted = List<Price>.from(prices);
    if (_sortBy == 'price') {
      sorted.sort((a, b) => _ascending
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price));
    } else {
      sorted.sort((a, b) => _ascending
          ? (a.retailer?.name ?? '').compareTo(b.retailer?.name ?? '')
          : (b.retailer?.name ?? '').compareTo(a.retailer?.name ?? ''));
    }
    return sorted;
  }

  /// Calculate price statistics
  Map<String, double> _calculateStats(List<Price> prices) {
    if (prices.isEmpty) return {};

    final allPrices = prices.map((p) => p.price).toList();
    final lowest = allPrices.reduce((a, b) => a < b ? a : b);
    final highest = allPrices.reduce((a, b) => a > b ? a : b);
    final average = allPrices.reduce((a, b) => a + b) / allPrices.length;

    return {
      'lowest': lowest,
      'highest': highest,
      'average': average,
      'range': highest - lowest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productByIdProvider(widget.productId));
    final rawPrices = ref.watch(pricesForProductProvider(widget.productId));
    
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final prices = _getSortedPrices(rawPrices);
    final stats = _calculateStats(prices);

    // Trigger auto-discovery for missing coordinates
    _findMissingCoords(prices);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final favs = ref.watch(favoritesProvider);
              final isFav = favs.contains(product.id);
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                color: isFav ? AppTheme.error : null,
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(product.id);
                },
              );
            },
          ),
        ],
      ),
      body: prices.isEmpty
          ? const EmptyState(
              icon: Icons.info_outline,
              title: 'No Price Data',
              message:
                  'Price information is not available for this product yet',
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header
                  _buildProductHeader(product, stats),

                  const SizedBox(height: AppSpacing.lg),

                  // Price Statistics
                  _buildPriceStats(stats),

                  const SizedBox(height: AppSpacing.lg),

                  // Sort Options
                  _buildSortOptions(),

                  const SizedBox(height: AppSpacing.md),

                  // Retailer Price List
                  _buildRetailerPrices(product, prices),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
      bottomNavigationBar: prices.isNotEmpty
          ? _buildBottomBar(product, prices)
          : null,
    );
  }

  /// Build product header with info
  Widget _buildProductHeader(Product product, Map<String, double> stats) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: BaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.imageUrl.isNotEmpty
                      ? SmartImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.shopping_bag_outlined,
                              color: AppTheme.primary, size: 40),
                        )
                      : const Icon(Icons.shopping_bag_outlined,
                          color: AppTheme.primary, size: 40),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      StatusBadge(
                        label: product.category,
                        status: StatusType.info,
                        width: null,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Product Name
                      Text(
                        product.name,
                        style: AppTypography.headline3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(height: AppSpacing.sm),

            // Product Description
            Text(
              product.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Best Price Highlight
            if (stats.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrangeLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Best Price',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'RM${stats['lowest']?.toStringAsFixed(2) ?? '0.00'}',
                          style: AppTypography.headline3.copyWith(
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Save Up To',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'RM${stats['range']?.toStringAsFixed(2) ?? '0.00'}',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
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
    );
  }

  /// Build price statistics cards
  Widget _buildPriceStats(Map<String, double> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Lowest',
              'RM${stats['lowest']?.toStringAsFixed(2) ?? '0.00'}',
              AppTheme.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Highest',
              'RM${stats['highest']?.toStringAsFixed(2) ?? '0.00'}',
              AppTheme.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Average',
              'RM${stats['average']?.toStringAsFixed(2) ?? '0.00'}',
              AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// Build sort options
  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Sort By', style: AppTypography.labelLarge),
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'price',
                child: Text('Price'),
              ),
              const PopupMenuItem(
                value: 'retailer',
                child: Text('Retailer Name'),
              ),
            ],
            child: Row(
              children: [
                Text(
                  _sortBy == 'price' ? 'Price' : 'Retailer',
                  style: AppTypography.bodySmall,
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
            ),
            onPressed: () {
              setState(() => _ascending = !_ascending);
            },
          ),
        ],
      ),
    );
  }

  /// Build retailer price list
  Widget _buildRetailerPrices(Product product, List<Price> prices) {
    // Find the highest price to calculate savings against
    final maxPrice = prices.isEmpty 
        ? 0.0 
        : prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);

    // Watch all retailers to find missing ones (out of stock)
    final retailersAsync = ref.watch(retailersStreamProvider);
    final allRetailers = retailersAsync.value ?? [];
    
    final pricesRetailerIds = prices.map((p) => p.retailerId).toSet();
    final missingRetailers = allRetailers.where((r) => !pricesRetailerIds.contains(r.id)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // 1. In-stock Retailers
          ...prices.asMap().entries.map((entry) {
            final index = entry.key;
            final price = entry.value;
            final isBestPrice = index == 0 && _sortBy == 'price';
            final savings = maxPrice - price.price;

            // Handle auto-discovered coordinates
            var r = price.retailer;
            if (r != null && (r.latitude == null || r.latitude == 0.0) && _autoCoords.containsKey(r.id)) {
              final coords = _autoCoords[r.id]!;
              r = Retailer(
                id: r.id,
                name: r.name,
                logoUrl: r.logoUrl,
                website: r.website,
                latitude: coords['latitude'],
                longitude: coords['longitude'],
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              );
            }

            final distance = r != null 
                ? LocationService.calculateDistanceTo(r, currentPos: _userPosition) 
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RetailerBadge(
                retailerName: r?.name ?? 'Unknown',
                logoUrl: r?.logoUrl,
                price: price.price,
                isBestPrice: isBestPrice,
                savings: savings > 0.01 ? savings : null,
                scrapedAt: price.scrapedAt,
                distanceKm: distance,
                gasCost: distance != null 
                    ? LocationService.calculateGasCost(distance) 
                    : null,
                latitude: r?.latitude,
                longitude: r?.longitude,
                // Tap a specific retailer → open sheet pre-set to that retailer's price
                onTap: () => AddToListSheet.show(
                  context,
                  product: product,
                  selectedPrice: price,
                ),
              ),
            );
          }),

          // 2. Out-of-stock Retailers
          ...missingRetailers.map((r) {
            // Apply auto coords if available
            var resolvedRetailer = r;
            if ((r.latitude == null || r.latitude == 0.0) && _autoCoords.containsKey(r.id)) {
              final coords = _autoCoords[r.id]!;
              resolvedRetailer = Retailer(
                id: r.id,
                name: r.name,
                logoUrl: r.logoUrl,
                website: r.website,
                latitude: coords['latitude'],
                longitude: coords['longitude'],
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RetailerBadge(
                retailerName: resolvedRetailer.name,
                logoUrl: resolvedRetailer.logoUrl,
                price: 0.0,
                isOutOfStock: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Handle add to list button press
  void _handleAddToList(Product product, List<Price> prices) {
    final isLoggedIn = ref.read(isUserLoggedInProvider);

    if (!isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
            'You need to log in to add items to your shopping lists.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RoutesConfig.login);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    final bestPrice = prices.first;
    AddToListSheet.show(
      context,
      product: product,
      selectedPrice: bestPrice,
    );
  }

  /// Launch store URL externally
  Future<void> _launchStoreUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open store link: $urlString')),
          );
        }
      }
    }
  }

  /// Show store link selector bottom sheet
  void _showStoreLinkSelector(BuildContext context, List<Price> prices) {
    // Filter prices that have valid URLs
    final validPrices = prices.where((p) => p.productUrl.isNotEmpty).toList();

    if (validPrices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No store links available for this product.')),
      );
      return;
    }

    if (validPrices.length == 1) {
      _launchStoreUrl(context, validPrices.first.productUrl);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Select Retailer Store',
                  style: AppTypography.headline3,
                ),
              ),
              const Divider(height: 1),
              ...validPrices.map((price) {
                final storeName = price.retailer?.name ?? 'Unknown Store';
                final formattedPrice = 'RM ${price.price.toStringAsFixed(2)}';
                
                return ListTile(
                  leading: Builder(builder: (context) {
                    final resolvedLogo = getRetailerLogo(storeName, price.retailer?.logoUrl);
                    if (resolvedLogo.startsWith('assets/')) {
                      return Image.asset(resolvedLogo, width: 32, height: 32);
                    } else if (resolvedLogo.startsWith('http://') || resolvedLogo.startsWith('https://')) {
                      return Image.network(
                        resolvedLogo,
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store),
                      );
                    }
                    return const Icon(Icons.store);
                  }),
                  title: Text(storeName, style: AppTypography.bodyLarge),
                  subtitle: Text(formattedPrice, style: AppTypography.bodySmall.copyWith(color: AppTheme.primary)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    _launchStoreUrl(context, price.productUrl);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Build bottom action bar
  Widget _buildBottomBar(Product product, List<Price> prices) {
    final bestPrice = prices.first;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.divider),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Buy from ${bestPrice.retailer?.name ?? 'Best'}',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Add to List',
                    onPressed: () => _handleAddToList(product, prices),
                    icon: Icons.add_shopping_cart,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'View Store',
                    onPressed: () => _showStoreLinkSelector(context, prices),
                    icon: Icons.open_in_new,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
