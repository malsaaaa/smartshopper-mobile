import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/cart_provider.dart';
import 'package:smartshopper_mobile/providers/product_provider.dart';

/// Bottom sheet: choose retailer, set quantity, then tap "Add to Cart".
/// No list selection needed — goes straight to the user's single cart.
class AddToListSheet extends ConsumerStatefulWidget {
  final Product product;
  final Price? selectedPrice; // optional pre-selection hint

  const AddToListSheet({
    super.key,
    required this.product,
    this.selectedPrice,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    Price? selectedPrice,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) =>
          AddToListSheet(product: product, selectedPrice: selectedPrice),
    );
  }

  @override
  ConsumerState<AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends ConsumerState<AddToListSheet> {
  int _quantity = 1;
  Price? _selectedPrice;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addToCart(Price? selectedPrice) async {
    setState(() => _isAdding = true);
    try {
      await ref.read(cartNotifierProvider.notifier).addToCart(
            widget.product,
            selectedPrice: selectedPrice,
            quantity: _quantity,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${widget.product.name} ×$_quantity added to cart'
            '${selectedPrice?.retailer?.name != null ? ' from ${selectedPrice?.retailer?.name}' : ''}',
          ),
          backgroundColor: AppTheme.secondary,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPrices = ref.watch(pricesForProductProvider(widget.product.id));
    final selectedPrice = _selectedPrice ?? (widget.selectedPrice != null
        ? (allPrices.firstWhere(
            (p) => p.retailerId == widget.selectedPrice!.retailerId,
            orElse: () => widget.selectedPrice!,
          ))
        : (allPrices.isNotEmpty ? allPrices.first : null));

    final unitPrice = selectedPrice?.price ?? 0.0;
    final totalPrice = unitPrice * _quantity;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add to Cart', style: AppTypography.headline2),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.product.name,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (unitPrice > 0)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _PriceBadge(
                        key: ValueKey(totalPrice),
                        price: totalPrice,
                        qty: _quantity),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(height: 0),
            const SizedBox(height: AppSpacing.lg),

            // ── Section 1: Retailer picker ──────────────────────────
            Text('Choose Retailer', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('Select where to buy from',
                style: AppTypography.bodySmall
                    .copyWith(color: AppTheme.textTertiary)),
            const SizedBox(height: AppSpacing.md),

            if (allPrices.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text('No retailer data available',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppTheme.textSecondary)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: allPrices.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final price = allPrices[i];
                    final isBest = i == 0;
                    final isSelected =
                        selectedPrice?.retailerId == price.retailerId;
                    return _RetailerTile(
                      price: price,
                      isBest: isBest,
                      isSelected: isSelected,
                      onTap: () =>
                          setState(() => _selectedPrice = price),
                    );
                  },
                ),
              ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(height: 0),
            const SizedBox(height: AppSpacing.lg),

            // ── Section 2: Quantity ─────────────────────────────────
            Text('Quantity', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StepperBtn(
                  icon: Icons.remove,
                  onTap: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Center(
                    child: Text('$_quantity',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                _StepperBtn(
                    icon: Icons.add,
                    onTap: () => setState(() => _quantity++)),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  '= RM${totalPrice.toStringAsFixed(2)}',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Add to Cart button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isAdding ? null : () => _addToCart(selectedPrice),
                icon: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_shopping_cart),
                label: Text(
                  _isAdding
                      ? 'Adding...'
                      : 'Add $_quantity × ${widget.product.name}'
                          '${selectedPrice?.retailer?.name != null ? ' from ${selectedPrice?.retailer?.name}' : ''}',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════

class _PriceBadge extends StatelessWidget {
  final double price;
  final int qty;
  const _PriceBadge({super.key, required this.price, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
          color: AppTheme.accentOrangeLight,
          borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('RM${price.toStringAsFixed(2)}',
              style: AppTypography.labelLarge.copyWith(
                  color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          if (qty > 1)
            Text('×$qty items',
                style: AppTypography.labelSmall
                    .copyWith(color: AppTheme.accentOrange)),
        ],
      ),
    );
  }
}

class _RetailerTile extends StatelessWidget {
  final Price price;
  final bool isBest;
  final bool isSelected;
  final VoidCallback onTap;
  const _RetailerTile(
      {required this.price,
      required this.isBest,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : isBest
                    ? AppTheme.secondary.withValues(alpha: 0.4)
                    : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Text(price.retailer?.name ?? 'Unknown',
                      style: AppTypography.labelLarge.copyWith(
                          color: isSelected ? AppTheme.primary : null)),
                  if (isBest) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm)),
                      child: Text('BEST',
                          style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'RM${price.price.toStringAsFixed(2)}',
              style: AppTypography.labelLarge.copyWith(
                color: isBest ? AppTheme.secondary : AppTheme.accentOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppTheme.divider : AppTheme.primaryLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(icon,
              size: 20,
              color: onTap == null
                  ? AppTheme.textTertiary
                  : AppTheme.primary),
        ),
      ),
    );
  }
}
