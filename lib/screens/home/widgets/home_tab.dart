import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/config/routes.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/cart_provider.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Header image that fades in when the asset frames are ready to avoid flashing
/// the underlying gradient while the image decodes. Uses [Image.asset]'s frameBuilder
/// to detect when the first image frame is available.
class _HeaderImage extends StatefulWidget {
  const _HeaderImage({Key? key}) : super(key: key);

  @override
  State<_HeaderImage> createState() => _HeaderImageState();
}

class _HeaderImageState extends State<_HeaderImage> with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _visible ? 1.0 : 0.0,
      child: Image.asset(
        'assets/images/backgrounds/main-bg.png',
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            // first frame is ready — reveal
            if (!_visible) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _visible = true);
              });
            }
            return child;
          }
          // not yet ready — keep hidden
          return const SizedBox.shrink();
        },
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _showRealBudget = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {

    final refLocal = ref; // for analyzer
    final isLoggedIn = ref.watch(isUserLoggedInProvider);
    final userAsync = ref.watch(firestoreUserNotifierProvider);

    final budgetAsync = isLoggedIn
        ? ref.watch(budgetNotifierProvider)
        : const AsyncValue<Budget?>.data(null);

    final pricesAsync = ref.watch(enhancedPricesProvider);

    

    // Determine loading state
    final cartAsync = ref.watch(cartNotifierProvider);
    final isLoadingBudget = budgetAsync.isLoading;
    final isLoadingCart = cartAsync.isLoading;

    // Manage debounce to avoid flicker when values rapidly change on startup
    if (!isLoadingBudget && !isLoadingCart) {
      // both ready — start debounce to show real numbers
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showRealBudget = true);
      });
    } else {
      // still loading — hide real numbers
      _debounce?.cancel();
      if (_showRealBudget) setState(() => _showRealBudget = false);
    }

    if (!_showRealBudget) {
      // show skeleton until stable
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beautiful Welcome Header with Background
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/backgrounds/main-bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? 'Welcome back, ${userAsync.value?.name ?? 'User'}!' : 'Welcome!',
                        style: AppTypography.headline1.copyWith(color: Colors.white, fontSize: 28),
                      ),
                      Text(
                        'Find the best deals for your groceries today.',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // skeleton budget
                  BaseCard(child: SizedBox(height: 92, child: Center(child: CircularProgressIndicator()))),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'My Favorites', subtitle: 'Quick access'),
                  const SizedBox(height: AppSpacing.lg),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Latest Price Updates', subtitle: 'Top 5 recent changes'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return budgetAsync.when(
      data: (budget) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Welcome Header with Background
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: _HeaderImage(),
                  ),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? 'Welcome back, ${userAsync.value?.name ?? 'User'}!' : 'Welcome!',
                          style: AppTypography.headline1.copyWith(color: Colors.white, fontSize: 28),
                        ),
                        Text(
                          'Find the best deals for your groceries today.',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BudgetCard(budget: budget),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Favorites Row ---
                    Consumer(builder: (context, ref, _) {
                      final favs = ref.watch(favoritesProvider);

                      // If no favorites, show a small prompt card
                      if (favs.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'My Favorites',
                              subtitle: 'Quick access',
                              onViewAll: () => Navigator.pushNamed(context, '/favorites'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            BaseCard(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppTheme.spacing16),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite_border, size: 28, color: Colors.pink),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('No favorites yet', style: AppTypography.labelLarge),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text('Tap the heart on products to save them here', style: AppTypography.bodySmall),
                                      ],
                                    ),
                                  ),
                                    TextButton(
                                      onPressed: () => Navigator.pushNamed(context, RoutesConfig.home, arguments: {'initialTab': 1}),
                                      child: const Text('Explore'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        );
                      }

                      final visible = favs.take(6).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'My Favorites',
                            subtitle: 'Quick access',
                            onViewAll: () => Navigator.pushNamed(context, '/favorites'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(right: AppSpacing.lg),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final pid = visible[index];
                                final product = ref.watch(productByIdProvider(pid));
                                return GestureDetector(
                                  onTap: () {
                                    if (product != null) Navigator.pushNamed(context, '/product-details', arguments: product.id);
                                  },
                                  child: SizedBox(
                                    width: 150,
                                    child: BaseCard(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryLight,
                                              borderRadius: BorderRadius.circular(AppRadius.md),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: product?.imageUrl != null && product!.imageUrl.isNotEmpty
                                                ? SmartImage(imageUrl: product.imageUrl)
                                                : const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product?.name ?? 'Product',
                                                  style: AppTypography.labelLarge.copyWith(fontSize: 12),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (product?.category != null) ...[
                                                  const SizedBox(height: AppSpacing.xs),
                                                  Text(product!.category, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      );
                    }),
                    SectionHeader(
                      title: 'Latest Price Updates',
                      subtitle: 'Top 5 recent changes',
                      onViewAll: () {
                        Navigator.pushNamed(context, '/all-prices');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    pricesAsync.when(
                      data: (prices) {
                        final topPrices = prices.take(5).toList();
                        return Column(
                          children: topPrices
                              .map((price) => _PriceCard(price: price))
                              .toList(),
                        );
                      },
                      loading: () => const Center(
                          child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      )),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading budget', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => ref.invalidate(budgetNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

// ---------- Budget Summary Card ----------

class _BudgetCard extends ConsumerWidget {
  final Budget? budget;
  const _BudgetCard({this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live cart total = "spent" amount
    final cartTotal = ref.watch(cartTotalProvider);

    final displayBudget = budget ??
        Budget(
          id: 1,
          userId: 0,
          spent: 0,
          limit: 0,
          period: 'monthly',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          history: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final spent = cartTotal + ref.watch(cartTravelCostProvider);
    final limit = displayBudget.limit;
    final isOverBudget = spent > limit && limit > 0;
    final percentage = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final statusColor = isOverBudget ? AppTheme.error : AppTheme.secondary;

    return BaseCard(
      backgroundColor: isOverBudget
          ? AppTheme.error.withValues(alpha: 0.1)
          : AppTheme.secondary.withValues(alpha: 0.05),
      borderColor: statusColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget', style: AppTypography.labelLarge),
              StatusBadge(
                label: isOverBudget ? 'Over Budget' : 'On Track',
                status: isOverBudget ? StatusType.error : StatusType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'RM${spent.toStringAsFixed(2)} / RM${limit.toStringAsFixed(2)}',
            style: AppTypography.headline2.copyWith(color: statusColor),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            displayBudget.daysRemaining > 0
                ? '${displayBudget.daysRemaining} days remaining'
                : 'Budget period ended',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------- Price Row Card ----------

class _PriceCard extends StatelessWidget {
  final Price price;
  const _PriceCard({required this.price});

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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: BaseCard(
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              clipBehavior: Clip.antiAlias,
              child: price.product?.imageUrl != null &&
                      price.product!.imageUrl.isNotEmpty
                  ? SmartImage(
                      imageUrl: price.product!.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(Icons.shopping_bag_outlined,
                          color: AppTheme.primary, size: 20),
                    )
                  : const Icon(Icons.shopping_bag_outlined,
                      color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
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
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(color: AppTheme.divider, width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SmartImage(
                          imageUrl: getRetailerLogo(
                            price.retailer?.name ?? 'Retailer',
                            price.retailer?.logoUrl,
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          errorWidget: const Icon(Icons.store_outlined, size: 12),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          price.retailer?.name ?? 'Retailer',
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Scraped ${_formatScraped(price.scrapedAt)}',
                  style: AppTypography.labelSmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
