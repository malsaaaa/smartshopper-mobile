import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/cart_provider.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

class ShoppingTab extends ConsumerWidget {
  const ShoppingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isUserLoggedInProvider);
    if (!isLoggedIn) return const _LoginPrompt();
    return const _CartView();
  }
}

// ════════════════════════════════════════════════════════════════
// Cart View
// ════════════════════════════════════════════════════════════════

class _CartView extends ConsumerWidget {
  const _CartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);

    return cartAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load cart', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                e.toString(),
                style:
                    AppTypography.bodySmall.copyWith(color: AppTheme.textTertiary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: () => ref.invalidate(cartNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (cart) {
        final items = cart?.items ?? [];
        if (items.isEmpty) return const _EmptyCart();
        return _CartList(items: items);
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Cart list + sticky bottom bar
// ════════════════════════════════════════════════════════════════

class _CartList extends ConsumerWidget {
  final List<ShoppingItem> items;
  const _CartList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartTotalProvider);

    // Group by retailer
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in items) {
      final key = item.retailerName ?? 'Other';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Column(
      children: [
        // ── Header row ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.list_alt, size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('Shopping List (${items.length} items)',
                  style: AppTypography.bodyMedium),
              const Spacer(),
              TextButton(
                onPressed: () => _confirmClear(context, ref),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error, padding: EdgeInsets.zero),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: 0),

        // ── Items list ──────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(cartNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                for (final entry in grouped.entries) ...[
                  _RetailerHeader(
                    name: entry.key,
                    logoUrl: entry.value
                        .firstWhere((i) => i.retailerLogoUrl != null,
                            orElse: () => entry.value.first)
                        .retailerLogoUrl,
                  ),
                  ...entry.value.map((item) => _CartItemRow(item: item)),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom bar ─────────────────────────────────────────────
        _BottomBar(
          total: total,
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Clear All')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(cartNotifierProvider.notifier).clearCart();
    }
  }
}

// ── Retailer section header ─────────────────────────────────────

class _RetailerHeader extends StatelessWidget {
  final String name;
  final String? logoUrl;
  const _RetailerHeader({required this.name, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final resolvedLogoUrl = getRetailerLogo(name, logoUrl);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      color: AppTheme.primaryLight,
      child: Row(
        children: [
          if (resolvedLogoUrl.isNotEmpty) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              clipBehavior: Clip.antiAlias,
              child: SmartImage(
                imageUrl: resolvedLogoUrl,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorWidget: const Icon(Icons.store_outlined, size: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else ...[
            const Icon(Icons.store_outlined,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(name,
              style: AppTypography.labelLarge
                  .copyWith(color: AppTheme.primary)),
        ],
      ),
    );
  }
}

// ── Single cart item row ────────────────────────────────────────

class _CartItemRow extends ConsumerWidget {
  final ShoppingItem item;
  const _CartItemRow({required this.item});

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
    final notifier = ref.read(cartNotifierProvider.notifier);

    return Dismissible(
      key: Key(item.effectiveId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => notifier.removeFromCart(item.effectiveId),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
              bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: AppSpacing.sm),

            // Opaque, clickable area wrapping product image and details
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (item.productId != null) {
                    Navigator.pushNamed(
                      context,
                      '/product-details',
                      arguments: item.productId,
                    );
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product image
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? SmartImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(Icons.shopping_bag_outlined,
                                  color: AppTheme.primary, size: 28),
                            )
                          : const Icon(Icons.shopping_bag_outlined,
                              color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Name + price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.labelLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'RM${item.estimatedPrice.toStringAsFixed(2)} each',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'RM${(item.estimatedPrice * item.quantity).toStringAsFixed(2)}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.update_rounded,
                                  size: 10, color: AppTheme.textTertiary),
                              const SizedBox(width: 3),
                              Text(
                                'Price updated ${_formatScraped(item.updatedAt)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppTheme.textTertiary,
                                  fontSize: 9,
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
            const SizedBox(width: AppSpacing.md),

            // Quantity stepper
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Delete icon
                GestureDetector(
                  onTap: () => notifier.removeFromCart(item.effectiveId),
                  child: const Icon(Icons.close,
                      size: 18, color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.sm),
                _QtyStepper(
                  quantity: item.quantity,
                  onDecrement: () => notifier.updateQuantity(
                      item.effectiveId, item.quantity - 1),
                  onIncrement: () => notifier.updateQuantity(
                      item.effectiveId, item.quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quantity stepper chip ───────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              quantity.toString(),
              style: AppTypography.labelLarge,
            ),
          ),
          _Btn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, size: 16, color: AppTheme.primary),
      ),
    );
  }
}

// ── Bottom checkout bar ─────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final double total;

  const _BottomBar({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Estimated Price',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RM${total.toStringAsFixed(2)}',
                    style: AppTypography.headline2.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Informational badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Shopping List',
                style: AppTypography.labelLarge.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Empty cart
// ════════════════════════════════════════════════════════════════

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.primaryLight),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 50, color: AppTheme.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Your cart is empty', style: AppTypography.headline2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Go to Search and tap "Add to Cart" on any product',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Login prompt
// ════════════════════════════════════════════════════════════════

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.primaryLight),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Sign In to View Cart',
                style: AppTypography.headline2,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sign in to add products to your cart',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Sign In',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/firebase-auth'),
            ),
          ],
        ),
      ),
    );
  }
}
