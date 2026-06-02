import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/shopping_list.dart';
import 'package:smartshopper_mobile/providers/firestore_shopping_list_provider.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Active Shopping List Screen
/// Shows the first active shopping list belonging to the current user.
class ActiveShoppingListScreen extends ConsumerStatefulWidget {
  const ActiveShoppingListScreen({super.key});

  @override
  ConsumerState<ActiveShoppingListScreen> createState() =>
      _ActiveShoppingListScreenState();
}

class _ActiveShoppingListScreenState
    extends ConsumerState<ActiveShoppingListScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddItemDialog(ShoppingList activeList) {
    _itemNameController.clear();
    _quantityController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Estimated Price (RM)',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_itemNameController.text.isEmpty ||
                  _quantityController.text.isEmpty ||
                  _priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final quantity = int.tryParse(_quantityController.text) ?? 1;
              final price = double.tryParse(_priceController.text) ?? 0.0;
              final listId =
                  activeList.effectiveId;

              try {
                await ref
                    .read(firestoreShoppingListsNotifierProvider.notifier)
                    .addItem(
                      listId,
                      productId: 0,
                      name: _itemNameController.text.trim(),
                      quantity: quantity,
                      estimatedPrice: price,
                    );

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isUserLoggedInProvider);

    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight,
                ),
                child: const Icon(Icons.lock_outlined,
                    size: 40, color: AppTheme.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Login Required',
                  style: AppTypography.headline2, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sign in to manage your shopping list',
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

    final listsAsync = ref.watch(firestoreShoppingListsNotifierProvider);

    return listsAsync.when(
      data: (lists) {
        final ShoppingList? activeList = lists.isEmpty
            ? null
            : lists.firstWhere(
                (l) => l.isActive,
                orElse: () => lists.first,
              );

        if (activeList == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.divider),
                    child: const Icon(Icons.shopping_cart_outlined,
                        size: 40, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('No shopping lists yet',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Go to Shopping Lists to create one',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final pendingItems =
            activeList.items.where((item) => !item.isPurchased).toList();
        final purchasedItems =
            activeList.items.where((item) => item.isPurchased).toList();
        final totalCost = activeList.items.fold<double>(
          0.0,
          (sum, item) => sum + (item.estimatedPrice * item.quantity),
        );
        final listId = activeList.effectiveId;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeList.name, style: AppTypography.headline1),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${activeList.items.length} items',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (purchasedItems.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            for (final item in purchasedItems) {
                              if (item.documentId != null) {
                                await ref
                                    .read(firestoreShoppingListsNotifierProvider
                                        .notifier)
                                    .deleteItem(listId, item.documentId!);
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Clear'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Item',
                        onPressed: () => _showAddItemDialog(activeList),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Summary Card
              if (activeList.items.isNotEmpty)
                BaseCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryCell(
                          label: 'Total Cost',
                          value: 'RM${totalCost.toStringAsFixed(2)}',
                          valueColor: AppTheme.primary),
                      _SummaryCell(
                          label: 'Pending',
                          value: '${pendingItems.length}'),
                      _SummaryCell(
                          label: 'Purchased',
                          value: '${purchasedItems.length}',
                          valueColor: AppTheme.secondary),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              if (pendingItems.isNotEmpty)
                _ItemSection(
                    title: 'PENDING ITEMS',
                    items: pendingItems,
                    listId: listId),

              if (purchasedItems.isNotEmpty)
                _ItemSection(
                    title: 'PURCHASED ITEMS',
                    items: purchasedItems,
                    listId: listId),

              if (activeList.items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.divider),
                          child: const Icon(Icons.shopping_cart_outlined,
                              size: 40, color: AppTheme.textTertiary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('No items yet',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading shopping list',
                style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(firestoreShoppingListsNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Sub-widgets ----------

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryCell(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                AppTypography.labelSmall.copyWith(color: AppTheme.textTertiary)),
        const SizedBox(height: AppSpacing.sm),
        Text(value,
            style: AppTypography.headline2.copyWith(color: valueColor)),
      ],
    );
  }
}

class _ItemSection extends ConsumerWidget {
  final String title;
  final List<ShoppingItem> items;
  final String listId;
  const _ItemSection(
      {required this.title, required this.items, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.labelSmall
                .copyWith(color: AppTheme.textTertiary)),
        const SizedBox(height: AppSpacing.md),
        ...items.map((item) => _ItemCard(item: item, listId: listId)),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final ShoppingItem item;
  final String listId;
  const _ItemCard({required this.item, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: BaseCard(
        child: Row(
          children: [
            Checkbox(
              value: item.isPurchased,
              onChanged: (value) async {
                if (item.documentId == null) return;
                await ref
                    .read(firestoreShoppingListsNotifierProvider.notifier)
                    .updateItem(listId, item.documentId!,
                        isPurchased: value ?? false);
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.bodyMedium.copyWith(
                      decoration: item.isPurchased
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text('Qty: ${item.quantity}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppTheme.textSecondary)),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'RM${(item.estimatedPrice * item.quantity).toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                if (item.documentId == null) return;
                await ref
                    .read(firestoreShoppingListsNotifierProvider.notifier)
                    .deleteItem(listId, item.documentId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item removed')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
