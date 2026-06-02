import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/mock_data.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Screen displaying all price updates
class AllPricesScreen extends StatefulWidget {
  const AllPricesScreen({super.key});

  @override
  State<AllPricesScreen> createState() => _AllPricesScreenState();
}

class _AllPricesScreenState extends State<AllPricesScreen> {
  late TextEditingController _searchController;
  List<Price> _filteredPrices = [];
  String _sortBy = 'recent'; // recent, price_low, price_high

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredPrices = MockData.prices;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAndSort(String query) {
    List<Price> filtered = MockData.prices;

    // Filter by search query
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

    setState(() => _filteredPrices = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Price Updates'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SearchField(
              controller: _searchController,
              onChanged: _filterAndSort,
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
          if (_filteredPrices.isEmpty)
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
                itemCount: _filteredPrices.length,
                itemBuilder: (context, index) {
                  final price = _filteredPrices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPriceCard(context, price),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Build a price card
  Widget _buildPriceCard(BuildContext context, Price price) {
    return BaseCard(
      onTap: () {
        if (price.product != null) {
          Navigator.pushNamed(
            context,
            '/product-details',
            arguments: price.product!.id,
          );
        }
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
        _filterAndSort(_searchController.text);
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
