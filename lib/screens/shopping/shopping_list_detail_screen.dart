import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/mock_data.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/firestore_shopping_list_provider.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Detailed shopping list view with item management
class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends ConsumerState<ShoppingListDetailScreen> {
  late TextEditingController _itemNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch shopping lists from Firestore
    final listsAsync = ref.watch(firestoreShoppingListsNotifierProvider);

    return listsAsync.when(
      data: (lists) {
        // Find the shopping list by ID
        final list = lists.firstWhere(
          (l) => l.effectiveId == widget.listId,
          orElse: () => lists.isNotEmpty ? lists.first : ShoppingList(
            // id fallback not needed for Firestore lists
            userId: '0',
            name: 'Unknown List',
            items: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final isBudgetExceeded =
            list.budget != null && list.totalEstimatedCost > list.budget!;

        return Scaffold(
          appBar: AppBar(
            title: Text(list.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(list),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmationDialog(list),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Section
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildSummaryCards(list, isBudgetExceeded),
                ),

                const Divider(height: 0),
                const SizedBox(height: AppSpacing.lg),

                // Items Section
                if (list.items.isNotEmpty)
                  _buildItemsList(list)
                else
                  EmptyState(
                    icon: Icons.shopping_basket_outlined,
                    title: 'No Items Yet',
                    message: 'Add items to this shopping list',
                    actionLabel: 'Add Item',
                    onAction: () {
                      _showAddItemDialog(list);
                    },
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemDialog(list),
            tooltip: 'Add Item',
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: list.items.isNotEmpty ? _buildBottomBar(list) : null,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, st) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards(ShoppingList list, bool isBudgetExceeded) {
    return Column(
      children: [
        // Progress Card
        ProgressCard(
          title: 'Shopping Progress',
          progress: list.items.isNotEmpty
              ? list.purchasedItemsCount / list.items.length
              : 0,
          subtitle:
              '${list.purchasedItemsCount}/${list.items.length} items completed',
          progressColor: isBudgetExceeded ? AppTheme.error : AppTheme.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Cost & Budget Summary
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Cost',
                'RM${list.totalEstimatedCost.toStringAsFixed(2)}',
                AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (list.budget != null)
              Expanded(
                child: _buildSummaryCard(
                  'Budget',
                  'RM${list.budget!.toStringAsFixed(2)}',
                  AppTheme.primary,
                ),
              ),
            if (list.budget != null) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildSummaryCard(
                  'Remaining',
                  '${isBudgetExceeded ? '-' : ''}RM${list.budgetRemaining?.abs().toStringAsFixed(2) ?? '0.00'}',
                  isBudgetExceeded ? AppTheme.error : AppTheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Build summary card
  Widget _buildSummaryCard(String label, String value, Color color) {
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
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build items list
  Widget _buildItemsList(ShoppingList list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items',
                  style: AppTypography.headline3,
                ),
                Text(
                  '${list.items.length} items',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          ...list.items.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildItemCard(list, item),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build individual item card
  Widget _buildItemCard(ShoppingList list, ShoppingItem item) {
    final bestPrice = MockData.getBestPriceForProduct(item.productId ?? 0);
    final estimatedCost = item.estimatedPrice * item.quantity;

    return BaseCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-details',
          arguments: item.productId,
        );
      },
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: item.isPurchased,
            onChanged: (value) {
              // Update item purchase status in Firestore
              ref.read(firestoreShoppingListsNotifierProvider.notifier).updateItem(
                list.effectiveId,
                item.effectiveId,
                isPurchased: value ?? false,
              );
            },
            activeColor: AppTheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.labelLarge.copyWith(
                    decoration: item.isPurchased
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isPurchased
                        ? AppTheme.textTertiary
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Quantity controls
                Row(
                  children: [
                    Text(
                      'Qty: ',
                      style: AppTypography.bodySmall,
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: item.quantity > 1
                                  ? () {
                                      ref
                                          .read(firestoreShoppingListsNotifierProvider
                                              .notifier)
                                          .updateItem(
                                            list.effectiveId,
                                            item.effectiveId,
                                            quantity: item.quantity - 1,
                                          );
                                    }
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                ref
                                    .read(firestoreShoppingListsNotifierProvider
                                        .notifier)
                                    .updateItem(
                                      list.effectiveId,
                                      item.effectiveId,
                                      quantity: item.quantity + 1,
                                    );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (bestPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Best: RM${bestPrice.price.toStringAsFixed(2)} at ${bestPrice.retailer?.name}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Cost & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM${estimatedCost.toStringAsFixed(2)}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    ref.read(firestoreShoppingListsNotifierProvider.notifier).deleteItem(
                      list.effectiveId,
                      item.effectiveId,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove'),
                  ),
                ],
                child: const Icon(Icons.more_vert, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build bottom navigation with recommended retailers
  Widget _buildBottomBar(ShoppingList list) {
    // Group items by retailer
    final retailerTotals = <String, double>{};

    for (final item in list.items) {
      final bestPrice = MockData.getBestPriceForProduct(item.productId ?? 0);
      final retailerName = bestPrice?.retailer?.name ?? item.retailerName ?? 'Other';
      final totalCost = item.estimatedPrice * item.quantity;
      retailerTotals[retailerName] = (retailerTotals[retailerName] ?? 0.0) + totalCost;
    }

    // Find cheapest retailer
    String? bestRetailerName;
    double minTotal = double.infinity;
    retailerTotals.forEach((retailer, total) {
      if (total < minTotal) {
        minTotal = total;
        bestRetailerName = retailer;
      }
    });

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Retailers',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            if (retailerTotals.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'No retailers - items empty: ${list.items.isEmpty}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: retailerTotals.length,
                  itemBuilder: (context, index) {
                    final retailerName = retailerTotals.keys.elementAt(index);
                    final totalAtRetailer = retailerTotals[retailerName] ?? 0.0;
                    final isBestPrice = retailerName == bestRetailerName;
                    final savings = isBestPrice ? 0.0 : (totalAtRetailer - minTotal);

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: RetailerBadge(
                        retailerName: retailerName,
                        price: totalAtRetailer,
                        isBestPrice: isBestPrice,
                        savings: savings > 0 ? savings : 0,
                        onTap: () {
                          _showRetailerCheckoutDialog(retailerName, totalAtRetailer);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show checkout dialog for selected retailer
  void _showRetailerCheckoutDialog(String retailerName, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Checkout at $retailerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Cost',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'RM${total.toStringAsFixed(2)}',
              style: AppTypography.headline3.copyWith(
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'You will be redirected to $retailerName\'s website to complete your purchase.',
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Redirecting to $retailerName...'),
                  duration: const Duration(seconds: 2),
                ),
              );
              // TODO: Implement actual URL launch to retailer website
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit shopping list
  /// Show dialog to add new item to shopping list
  void _showAddItemDialog(ShoppingList list) {
    _itemNameController.clear();
    _quantityController.text = '1';
    _priceController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item to List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Name', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Milk, Bread',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Quantity', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Estimated Price (RM)', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'RM ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _itemNameController.text.trim();
              final quantity = int.tryParse(_quantityController.text) ?? 1;
              final price = double.tryParse(_priceController.text) ?? 0.0;

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product name is required')),
                );
                return;
              }

              // Add item to Firestore
              await ref
                  .read(firestoreShoppingListsNotifierProvider.notifier)
                  .addItem(
                    list.effectiveId,
                    productId: 1,
                    name: name,
                    quantity: quantity,
                    estimatedPrice: price,
                  );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item added successfully')),
                );
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit shopping list
  void _showEditDialog(ShoppingList list) {
    String newName = list.name;
    double? newBudget = list.budget;
    
    final nameController = TextEditingController(text: list.name);
    final budgetController = TextEditingController(
      text: list.budget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Shopping List'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'List Name',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter list name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onChanged: (value) {
                    setStateDialog(() => newName = value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Budget (Optional)',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: budgetController,
                  decoration: InputDecoration(
                    prefixText: 'RM ',
                    hintText: 'No budget',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    setStateDialog(() => newBudget = parsed);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  nameController.dispose();
                  budgetController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newName.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('List name cannot be empty'),
                      ),
                    );
                    return;
                  }

                  // Update the list in Firestore
                  await ref
                      .read(firestoreShoppingListsNotifierProvider.notifier)
                      .updateList(
                        list.effectiveId,
                        name: newName,
                        budget: newBudget,
                      );

                  nameController.dispose();
                  budgetController.dispose();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('List updated successfully'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmationDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () async {
              try {
                // Delete the list from Firestore
                await ref
                    .read(firestoreShoppingListsNotifierProvider.notifier)
                    .deleteList(list.effectiveId);

                if (mounted) {
                  // Close dialog first
                  Navigator.pop(context);
                  
                  // Show snackbar in the current scaffold context (detail screen)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${list.name}" has been deleted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // Then navigate back after a short delay to ensure snackbar is visible
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting list: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

