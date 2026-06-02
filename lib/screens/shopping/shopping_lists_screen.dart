import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Shopping lists management screen
class ShoppingListsScreen extends ConsumerStatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  ConsumerState<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends ConsumerState<ShoppingListsScreen> {
  late TextEditingController _listNameController;

  @override
  void initState() {
    super.initState();
    _listNameController = TextEditingController();
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(firestoreShoppingListsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateListDialog();
            },
          ),
        ],
      ),
      body: listsAsync.when(
        data: (lists) => lists.isEmpty
            ? EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'No Shopping Lists',
                message: 'Create your first shopping list to get started',
                actionLabel: 'Create New List',
                onAction: () {
                  _showCreateListDialog();
                },
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final list = lists[index];
                  return _buildListCard(list);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading lists: $error'),
        ),
      ),
    );
  }

  /// Build shopping list card
  Widget _buildListCard(ShoppingList list) {
    final isBudgetExceeded =
        list.budget != null && list.totalEstimatedCost > list.budget!;
    final progressColor = isBudgetExceeded ? AppTheme.error : AppTheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: BaseCard(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/shopping-list-detail',
            arguments: list.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: AppTypography.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${list.items.length} items • Created ${_formatDate(list.createdAt)}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildListMenu(list),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress Card
            ProgressCard(
              title: 'Items Purchased',
              progress: list.items.isNotEmpty
                  ? list.purchasedItemsCount / list.items.length
                  : 0,
              subtitle:
                  '${list.purchasedItemsCount}/${list.items.length} completed',
              progressColor: progressColor,
            ),
            const SizedBox(height: AppSpacing.md),

            // Cost Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'RM${list.totalEstimatedCost.toStringAsFixed(2)}',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
                if (list.budget != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Budget Status',
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isBudgetExceeded
                            ? 'RM${list.budgetRemaining!.abs().toStringAsFixed(2)} over'
                            : 'RM${list.budgetRemaining!.toStringAsFixed(2)} left',
                        style: AppTypography.labelLarge.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build list menu (edit, share, delete)
  Widget _buildListMenu(ShoppingList list) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteConfirmation(list);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppTheme.error),
              SizedBox(width: AppSpacing.md),
              Text('Delete', style: TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Delete the list from Firestore
              await ref
                  .read(firestoreShoppingListsNotifierProvider.notifier)
                  .deleteList(list.id.toString());

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List deleted successfully')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Show create list dialog
  void _showCreateListDialog() {
    _listNameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shopping List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List Name', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _listNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Weekly Groceries',
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
              final name = _listNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List name cannot be empty')),
                );
                return;
              }

              // Create list in Firestore
              try {
                await ref
                    .read(firestoreShoppingListsNotifierProvider.notifier)
                    .createList(
                      name: name,
                    );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('List created successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating list: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
