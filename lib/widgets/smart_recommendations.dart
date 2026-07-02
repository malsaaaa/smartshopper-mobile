import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/cart_provider.dart';
import 'package:smartshopper_mobile/providers/product_provider.dart';

// ─── Data classes ────────────────────────────────────────────────────────────

class _RetailerSummary {
  final String name;
  final String? logoUrl;
  double total;
  int itemCount;
  _RetailerSummary({required this.name, this.logoUrl, this.total = 0, this.itemCount = 0});
}

class _ItemAnalysis {
  final ShoppingItem cartItem;
  final Map<String, double> priceByRetailer; // retailerName → price each
  final String cheapestRetailer;
  final double cheapestPrice;
  _ItemAnalysis({
    required this.cartItem,
    required this.priceByRetailer,
    required this.cheapestRetailer,
    required this.cheapestPrice,
  });
}

// ─── Main widget ─────────────────────────────────────────────────────────────

/// Smart Shopping Recommendations section.
/// Compares cart total across all retailers and highlights the best deal.
class SmartRecommendations extends ConsumerStatefulWidget {
  const SmartRecommendations({super.key});

  @override
  ConsumerState<SmartRecommendations> createState() =>
      _SmartRecommendationsState();
}

// Normalize product name for matching (removes spaces, casing, and special chars)
String _getProductMatchKey(String name) {
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _SmartRecommendationsState extends ConsumerState<SmartRecommendations> {
  String? _selectedRetailer; // Selected retailer for visual breakdown

  @override
  Widget build(BuildContext context) {
    // Get cart items and watch streams
    final cart = ref.watch(cartNotifierProvider).valueOrNull;
    final items = cart?.items ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    final enhancedPricesAsync = ref.watch(enhancedPricesProvider);
    final retailersAsync = ref.watch(retailersStreamProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return enhancedPricesAsync.when(
      data: (allPrices) => retailersAsync.when(
        data: (allRetailers) => productsAsync.when(
          data: (allProducts) {
            // ── Analyze each shopping list item ──
            final analyses = <_ItemAnalysis>[];
            for (final item in items) {
              if (item.productId == null) continue;

              // Find current product in catalog
              final targetProduct = allProducts.cast<Product?>().firstWhere(
                (p) => p?.id == item.productId,
                orElse: () => null,
              );
              if (targetProduct == null) continue;

              // Find all product IDs with same normalized name
              final targetKey = _getProductMatchKey(targetProduct.name);
              final sameNameProductIds = allProducts
                  .where((p) => _getProductMatchKey(p.name) == targetKey)
                  .map((p) => p.id)
                  .toSet();

              // Get all prices associated with these product IDs
              final prices = allPrices
                  .where((p) => sameNameProductIds.contains(p.productId))
                  .toList();

              if (prices.isEmpty) continue;

              // Map price values by retailer name
              final priceByRetailer = <String, double>{};
              for (final p in prices) {
                final name = p.retailer?.name ?? 'Unknown';
                priceByRetailer[name] = p.price;
              }

              // Identify cheapest retailer/price option
              final cheapest = prices.reduce((a, b) => a.price < b.price ? a : b);
              analyses.add(_ItemAnalysis(
                cartItem: item,
                priceByRetailer: priceByRetailer,
                cheapestRetailer: cheapest.retailer?.name ?? 'Unknown',
                cheapestPrice: cheapest.price,
              ));
            }
            if (analyses.isEmpty) return const SizedBox.shrink();

            // ── Compute basket totals for each retailer ──
            final Map<String, _RetailerSummary> summaries = {};
            for (final retailer in allRetailers) {
              double total = 0.0;
              int count = 0;

              for (final a in analyses) {
                final price = a.priceByRetailer[retailer.name];
                if (price != null) {
                  total += price * a.cartItem.quantity;
                  count++;
                }
              }

              // Create summary if retailer sells at least one item
              if (count > 0) {
                summaries[retailer.name] = _RetailerSummary(
                  name: retailer.name,
                  logoUrl: retailer.logoUrl,
                  total: total,
                  itemCount: count,
                );
              }
            }

            // Sort retailers from cheapest to most expensive
            final sorted = summaries.values.toList()
              ..sort((a, b) => a.total.compareTo(b.total));
            if (sorted.isEmpty) return const SizedBox.shrink();

            final best = sorted.first;
            final worst = sorted.last;
            final maxSavings = worst.total - best.total;

            // Compute ideal total (cheapest price per item across all stores)
            final alternativeTotal = analyses.fold<double>(
                0, (s, a) => s + a.cheapestPrice * a.cartItem.quantity);

            // Default breakdown to cheapest retailer
            _selectedRetailer ??= best.name;
            final selectedSummary =
                summaries[_selectedRetailer] ?? summaries[best.name]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // ── Header ───────────────────────────────────────────────────────
                Row(children: [
                  const Text('💰', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Smart Shopping Recommendations',
                        style: AppTypography.headline2),
                  ),
                ]),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Compare total cost of your entire shopping list across retailers',
                  style:
                      AppTypography.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Retailer comparison cards ─────────────────────────────────────
                _RetailerCards(
                  sorted: sorted,
                  best: best,
                  selected: _selectedRetailer!,
                  onSelect: (name) => setState(() => _selectedRetailer = name),
                  totalItems: items.length,
                ),

                // ── Maximum savings banner ────────────────────────────────────────
                if (maxSavings > 0.005) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SavingsBanner(
                    savings: maxSavings,
                    bestName: best.name,
                    worstName: worst.name,
                  ),
                ],

                // ── Item breakdown table ──────────────────────────────────────────
                const SizedBox(height: AppSpacing.lg),
                _ItemBreakdownTable(
                  analyses: analyses,
                  retailerName: _selectedRetailer!,
                  selectedTotal: selectedSummary.total,
                  alternativeTotal: alternativeTotal,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Retailer cards row ───────────────────────────────────────────────────────

class _RetailerCards extends StatelessWidget {
  final List<_RetailerSummary> sorted;
  final _RetailerSummary best;
  final String selected;
  final void Function(String) onSelect;
  final int totalItems;

  const _RetailerCards({
    required this.sorted,
    required this.best,
    required this.selected,
    required this.onSelect,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    if (sorted.length == 1) {
      // Only one retailer — show single full-width card
      return _RetailerCard(
        summary: sorted.first,
        isBest: true,
        savings: 0,
        isSelected: true,
        onTap: () {},
        totalItems: totalItems,
      );
    }

    final others = sorted.skip(1).toList();
    final worstTotal = sorted.last.total;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none, // Allow badge to overflow
      child: Padding(
        padding: const EdgeInsets.only(top: 12), // Room for the badge
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Best value card (always first, always wider)
            SizedBox(
              width: 200,
              child: _RetailerCard(
                summary: best,
                isBest: true,
                savings: worstTotal - best.total,
                isSelected: selected == best.name,
                onTap: () => onSelect(best.name),
                totalItems: totalItems,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Other retailer cards
            ...others.map((s) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: SizedBox(
                    width: 180,
                    child: _RetailerCard(
                      summary: s,
                      isBest: false,
                      savings: 0,
                      isSelected: selected == s.name,
                      onTap: () => onSelect(s.name),
                      totalItems: totalItems,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _RetailerCard extends StatelessWidget {
  final _RetailerSummary summary;
  final bool isBest;
  final double savings;
  final bool isSelected;
  final VoidCallback onTap;
  final int totalItems;

  const _RetailerCard({
    required this.summary,
    required this.isBest,
    required this.savings,
    required this.isSelected,
    required this.onTap,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              // Always white — ensures dark text is readable
              color: Colors.white,
              border: Border.all(
                color: isBest ? AppTheme.secondary : AppTheme.divider,
                width: isBest ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: isBest
                  ? [
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Retailer name ──────────────────────────────────
                Row(children: [
                  if (summary.logoUrl != null)
                    Image.asset(
                      summary.logoUrl!,
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => const Text('🏪', style: TextStyle(fontSize: 16)),
                    )
                  else
                    const Text('🏪', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      summary.name,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),

                // ── Total cost ──────────────────────────────────────
                Text(
                  'TOTAL COST:',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.grey.shade600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${summary.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isBest ? 26 : 22,
                    fontWeight: FontWeight.w800,
                    // Dark for non-best (readable), deep green for best
                    color: isBest
                        ? const Color(0xFF0F7B50)
                        : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary.itemCount == totalItems
                      ? '${summary.itemCount} items in your list'
                      : '${summary.itemCount} of $totalItems items stocked',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),

                // ── YOU SAVE box (best card only) ──────────────────
                if (isBest && savings > 0.005) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      // Solid green bg → white text = max contrast
                      color: const Color(0xFF0F7B50),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOU SAVE:',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'RM ${savings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // ── Action button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: isBest
                      ? FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F7B50),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text(
                            isSelected
                                ? '✓ SHOP AT ${summary.name.toUpperCase()}'
                                : 'VIEW PRICES',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text(
                            isSelected ? '✓ SELECTED' : 'COMPARE',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // ── BEST VALUE badge ─────────────────────────────────────
        if (isBest)
          Positioned(
            top: -11,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7B50),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 9)),
                  SizedBox(width: 4),
                  Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Savings banner ───────────────────────────────────────────────────────────

class _SavingsBanner extends StatelessWidget {
  final double savings;
  final String bestName;
  final String worstName;

  const _SavingsBanner({
    required this.savings,
    required this.bestName,
    required this.worstName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        border: Border.all(
            color: AppTheme.secondary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💚', style: TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'MAXIMUM SAVINGS POTENTIAL',
                style: AppTypography.labelSmall.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'RM ${savings.toStringAsFixed(2)}',
            style: AppTypography.headline1.copyWith(
                color: AppTheme.secondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'by shopping at $bestName instead of $worstName',
            style: AppTypography.bodySmall
                .copyWith(color: AppTheme.secondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Item breakdown table ─────────────────────────────────────────────────────

class _ItemBreakdownTable extends StatelessWidget {
  final List<_ItemAnalysis> analyses;
  final String retailerName;
  final double selectedTotal;
  final double alternativeTotal;

  const _ItemBreakdownTable({
    required this.analyses,
    required this.retailerName,
    required this.selectedTotal,
    required this.alternativeTotal,
  });

  @override
  Widget build(BuildContext context) {
    final savings = selectedTotal - alternativeTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(children: [
          const Text('📋', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Text('Best Prices at $retailerName',
              style: AppTypography.labelLarge),
        ]),
        const SizedBox(height: AppSpacing.md),

        // Table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 480, // Minimum width to ensure all columns fit
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.divider),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                // Header row
                _TableHeader(),
                const Divider(height: 0),
                // Item rows
                ...analyses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  final isLast = i == analyses.length - 1;
                  return _TableRow(
                    analysis: a,
                    retailerName: retailerName,
                    isLast: isLast,
                  );
                }),
                // Total row
                Container(
                  color: AppTheme.primaryLight,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      const Expanded(
                          flex: 5,
                          child: SizedBox()),
                      Expanded(
                        flex: 1,
                        child: Text('TOTAL',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppTheme.textSecondary, fontSize: 10)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'RM ${selectedTotal.toStringAsFixed(2)}',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppTheme.accentOrange),
                        ),
                      ),
                      const Expanded(flex: 3, child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Alternative total footer — always visible
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: savings > 0.005
                ? AppTheme.accentOrange.withValues(alpha: 0.07)
                : const Color(0xFF0F7B50).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: savings > 0.005
                  ? AppTheme.accentOrange.withValues(alpha: 0.25)
                  : const Color(0xFF0F7B50).withValues(alpha: 0.25),
            ),
          ),
          child: savings > 0.005
              // ── Has savings: show orange fire ──
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALTERNATIVE TOTAL (BEST PRICES)',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Mix cheapest prices across all retailers',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppTheme.accentOrange.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${alternativeTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Save RM ${savings.toStringAsFixed(2)}',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppTheme.accentOrange),
                        ),
                      ],
                    ),
                  ],
                )
              // ── Already optimal: show green tick ──
              : Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALTERNATIVE TOTAL (BEST PRICES)',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF0F7B50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Already the best price combination!',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF0F7B50).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RM ${alternativeTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF0F7B50),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppTheme.primaryLight,
      child: Row(
        children: [
          Expanded(
              flex: 5,
              child: Text('ITEM',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppTheme.textTertiary, fontSize: 10))),
          Expanded(
              flex: 1,
              child: Text('QTY',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppTheme.textTertiary, fontSize: 10))),
          Expanded(
              flex: 2,
              child: Text('PRICE',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppTheme.textTertiary, fontSize: 10))),
          Expanded(
              flex: 2,
              child: Text('TOTAL',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppTheme.textTertiary, fontSize: 10))),
          Expanded(
              flex: 4,
              child: Text('SAVINGS POTENTIAL',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppTheme.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final _ItemAnalysis analysis;
  final String retailerName;
  final bool isLast;

  const _TableRow({
    required this.analysis,
    required this.retailerName,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final item = analysis.cartItem;
    final isAvailable = analysis.priceByRetailer[retailerName] != null;
    final priceHere = analysis.priceByRetailer[retailerName] ??
        analysis.cheapestPrice;
    final subtotal = priceHere * item.quantity;
    final isBestHere = (priceHere - analysis.cheapestPrice).abs() < 0.001;

    // Find cheapest OTHER retailer
    String? cheaperRetailer;
    double cheaperSaving = 0;
    if (!isBestHere && isAvailable) {
      cheaperRetailer = analysis.cheapestRetailer;
      cheaperSaving = priceHere - analysis.cheapestPrice;
    }

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name
          Expanded(
            flex: 5,
            child: Text(
              item.name,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Qty
          Expanded(
            flex: 1,
            child: Text(
              '${item.quantity}',
              style: AppTypography.bodySmall,
            ),
          ),
          // Unit price
          Expanded(
            flex: 2,
            child: Text(
              isAvailable ? 'RM${priceHere.toStringAsFixed(2)}' : 'N/A',
              style: AppTypography.bodySmall.copyWith(
                color: isAvailable ? AppTheme.secondary : AppTheme.textTertiary,
              ),
            ),
          ),
          // Subtotal
          Expanded(
            flex: 2,
            child: Text(
              isAvailable ? 'RM${subtotal.toStringAsFixed(2)}' : 'N/A',
              style: AppTypography.bodySmall.copyWith(
                color: isAvailable ? AppTheme.textPrimary : AppTheme.textTertiary,
              ),
            ),
          ),
          // Cheaper alternative
          Expanded(
            flex: 4,
            child: !isAvailable
                ? Text(
                    'N/A',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppTheme.textTertiary, fontSize: 11),
                  )
                : isBestHere
                    ? Text(
                        'Best price ✓',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppTheme.textTertiary, fontSize: 11),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color:
                                  AppTheme.accentOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '🔥 Save RM${cheaperSaving.toStringAsFixed(2)} at $cheaperRetailer',
                          style: AppTypography.labelSmall.copyWith(
                              color: AppTheme.accentOrange, fontSize: 9),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
