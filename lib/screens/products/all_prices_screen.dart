import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Screen displaying all price updates
class AllPricesScreen extends ConsumerStatefulWidget {
  const AllPricesScreen({super.key});

  @override
  ConsumerState<AllPricesScreen> createState() => _AllPricesScreenState();
}

class _AllPricesScreenState extends ConsumerState<AllPricesScreen> {
  late TextEditingController _searchController;
  String _sortBy = 'recent'; // recent, price_low, price_high

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

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(enhancedPricesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Price Updates'),
        elevation: 1,
      ),
      body: pricesAsync.when(
        data: (allPrices) {
          // Filter by search query
          List<Price> filtered = List.from(allPrices);
          final query = _searchController.text.trim();
          if (query.isNotEmpty) {
            filtered = filtered.where((price) {
              final productName = price.product?.name.toLowerCase() ?? '';
              final retailerName = price.retailer?.name.toLowerCase() ?? '';
              final searchQuery = query.toLowerCase();
              return productName.contains(searchQuery) ||
                  retailerName.contains(searchQuery);
            }).toList();
          }

          // Sort
          switch (_sortBy) {
            case 'price_low':
              filtered.sort((a, b) => a.price.compareTo(b.price));
              break;
            case 'price_high':
              filtered.sort((a, b) => b.price.compareTo(a.price));
              break;
            case 'recent':
            default:
              filtered.sort((a, b) => b.scrapedAt.compareTo(a.scrapedAt));
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SearchField(
                  controller: _searchController,
                  onChanged: (q) => setState(() {}),
                  hint: 'Search products or retailers...',
                ),
              ),

              // Sort options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortButton('Recent', 'recent'),
                            const SizedBox(width: AppSpacing.sm),
                            _buildSortButton('Price Low', 'price_low'),
                            const SizedBox(width: AppSpacing.sm),
                            _buildSortButton('Price High', 'price_high'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Price list
              if (filtered.isEmpty)
                Expanded(
                  child: EmptyState(
                    icon: Icons.trending_down,
                    title: 'No Prices Found',
                    message: 'No prices match your search criteria',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final price = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildPriceCard(context, price),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  /// Build a price card
  Widget _buildPriceCard(BuildContext context, Price price) {
    return BaseCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-details',
          arguments: price.productId,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.product?.name ?? 'Product',
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  price.retailer?.name ?? 'Retailer',
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Updated ${_formatDate(price.scrapedAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceDisplay(
                currentPrice: price.price,
                textStyle: AppTypography.labelLarge.copyWith(
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build sort button
  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _sortBy = value);
      },
      backgroundColor: AppTheme.surface,
      selectedColor: AppTheme.primary,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
