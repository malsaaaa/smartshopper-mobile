import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/cart_provider.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/smart_recommendations.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';
import 'package:smartshopper_mobile/data/models/index.dart';

class BudgetTab extends ConsumerWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isUserLoggedInProvider);

    if (!isLoggedIn) {
      return _LoginPrompt(
        message: 'Sign in to view and manage your budget',
      );
    }

    final budgetAsync = ref.watch(budgetNotifierProvider);
    // Live cart total = "spent" amount
    final cartTotal = ref.watch(cartTotalProvider);
    final categoryBreakdown = ref.watch(cartCategoryBreakdownProvider);

    return budgetAsync.when(
      data: (budget) {
        if (budget == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Travel costs (Gas)
        final travelCost = ref.watch(cartTravelCostProvider);
        
        // Total spent includes both products and transportation
        final spent = cartTotal + travelCost;
        final limit = budget.limit;
        final remaining = (limit - spent).clamp(0.0, double.infinity);
        final percentage = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
        final isExceeded = spent > limit;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Budget Planning', style: AppTypography.headline1),
              const SizedBox(height: AppSpacing.xxl),

              // Main budget card
              BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Top Row: Limit | Circular progress | Spent ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'MONTHLY LIMIT',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  GestureDetector(
                                    onTap: () => _showEditLimitDialog(context, ref, limit),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'RM ${limit.toStringAsFixed(2)}',
                                    style: AppTypography.headline1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: percentage,
                                strokeWidth: 6,
                                backgroundColor: AppTheme.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isExceeded
                                      ? AppTheme.error
                                      : AppTheme.secondary,
                                ),
                              ),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: AppTypography.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL SPENT',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'RM ${spent.toStringAsFixed(2)}',
                                    style: AppTypography.headline2.copyWith(
                                      color: isExceeded ? AppTheme.error : AppTheme.accentOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ---- Spent / Remaining summary ----
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _LegendDot(
                          color: AppTheme.secondary,
                          label: 'GROCERIES: RM${cartTotal.toStringAsFixed(2)}',
                        ),
                        _LegendDot(
                          color: AppTheme.accentOrange,
                          label: 'GAS COST: RM${travelCost.toStringAsFixed(2)}',
                        ),
                        _LegendDot(
                          color: AppTheme.primary,
                          label: 'REMAINING: RM${remaining.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ---- Category breakdown ----
                    Text(
                      'SPENDING BY CATEGORY',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Real Pie Chart ---
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(100, 100),
                                painter: _PieChartPainter(
                                  categoryBreakdown: categoryBreakdown,
                                  total: spent,
                                ),
                              ),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Column(
                            children: [
                              if (categoryBreakdown.isEmpty && travelCost <= 0)
                                Text('No items in cart',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: AppTheme.textTertiary))
                              else ...[
                                ...categoryBreakdown.entries.map((entry) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: _LegendDot(
                                              color: _getCategoryColor(entry.key),
                                              label: entry.key,
                                            ),
                                          ),
                                          Text(
                                            'RM${entry.value.toStringAsFixed(2)}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                    fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    )),
                                // Add Travel Cost to the list if it exists
                                if (travelCost > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _LegendDot(
                                            color: AppTheme.accentOrange,
                                            label: 'Travel Cost',
                                          ),
                                        ),
                                        Text(
                                          'RM${travelCost.toStringAsFixed(2)}',
                                          style: AppTypography.bodySmall
                                              .copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],   // end BaseCard Column children
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _BudgetHistorySection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── Smart Shopping Recommendations ──────────────────────────
              const SmartRecommendations(),
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
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Beverages':
      case 'Drinks':
        return Colors.lightBlue;
      case 'Cooking Ingredients':
        return Colors.purple;
      case 'Instant Noodles': return Colors.amber;
      case 'Rice & Grains': return Colors.green;
      case 'Coffee': return Colors.brown;
      case 'Dairy': return Colors.teal;
      case 'Bread': return Colors.orange;
      case 'Eggs': return Colors.deepOrange;
      case 'Travel Cost': return AppTheme.accentOrange;
      default: return Colors.deepPurpleAccent;
    }
  }

  void _showEditLimitDialog(BuildContext context, WidgetRef ref, double currentLimit) {
    showDialog(
      context: context,
      builder: (context) {
        double limitVal = currentLimit > 0 ? currentLimit : 500.0;
        if (limitVal > 2000) limitVal = 2000;
        final textController = TextEditingController(text: limitVal.toStringAsFixed(0));

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Monthly Limit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Limit: RM ${limitVal.toStringAsFixed(0)}', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Slider(
                      value: limitVal,
                      min: 100,
                      max: 2000,
                      divisions: 19, // steps of 100
                      activeColor: AppTheme.primary,
                      inactiveColor: AppTheme.divider,
                      onChanged: (val) {
                        setState(() {
                          limitVal = val;
                          textController.text = val.toStringAsFixed(0);
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Quick Presets', style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [200, 500, 1000, 1500].map((preset) {
                        final isSelected = limitVal.round() == preset;
                        return ChoiceChip(
                          label: Text('RM $preset'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                limitVal = preset.toDouble();
                                textController.text = preset.toString();
                              });
                            }
                          },
                          selectedColor: AppTheme.primaryLight,
                          checkmarkColor: AppTheme.primaryDark,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: textController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Custom Limit (RM)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 100 && parsed <= 2000) {
                          setState(() {
                            limitVal = parsed;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newLimitText = textController.text.trim();
                    final newLimit = double.tryParse(newLimitText);
                    if (newLimit == null || newLimit <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid positive limit')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    
                    try {
                      await ref.read(budgetNotifierProvider.notifier).updateBudgetLimit(newLimit);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Budget limit updated successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating budget limit: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> categoryBreakdown;
  final double total;

  _PieChartPainter({required this.categoryBreakdown, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    double startAngle = -1.57; // Start at top

    categoryBreakdown.forEach((category, amount) {
      final sweepAngle = (amount / total) * 6.28;
      if (sweepAngle > 0) {
        paint.color = _getColorFor(category);
        canvas.drawArc(
          Rect.fromLTWH(0, 0, size.width, size.height),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
        startAngle += sweepAngle;
      }
    });

    // Handle travel cost (remainder of total spent - category sum)
    double catSum = categoryBreakdown.values.fold(0.0, (s, v) => s + v);
    if (total > catSum + 0.01) {
      final sweepAngle = ((total - catSum) / total) * 6.28;
      paint.color = AppTheme.accentOrange; 
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  Color _getColorFor(String category) {
    switch (category) {
      case 'Beverages':
      case 'Drinks':
        return Colors.lightBlue;
      case 'Cooking Ingredients':
        return Colors.purple;
      case 'Instant Noodles': return Colors.amber;
      case 'Rice & Grains': return Colors.green;
      case 'Coffee': return Colors.brown;
      case 'Dairy': return Colors.teal;
      case 'Bread': return Colors.orange;
      case 'Eggs': return Colors.deepOrange;
      default: return Colors.deepPurpleAccent;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------- Reusable widgets ----------

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Generic "login required" prompt used by Budget and Profile tabs.
class _LoginPrompt extends StatelessWidget {
  final String message;
  const _LoginPrompt({required this.message});

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(
                Icons.lock_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Login Required',
              style: AppTypography.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Sign In',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/firebase-auth');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetHistorySection extends ConsumerWidget {
  const _BudgetHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(budgetHistoryProvider);

    return historyAsync.when(
      data: (budgets) {
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final pastBudgets = budgets.where((b) {
          return b.startDate.isBefore(currentMonthStart);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget History',
              style: AppTypography.headline2.copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Track your past monthly limits and overall spending',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (pastBudgets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 40,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No budget history available',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your past monthly budgets will be listed here.',
                      style: AppTypography.bodySmall.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: pastBudgets.map((b) => _PastBudgetCard(budget: b)).toList(),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            'Error loading budget history',
            style: AppTypography.bodyMedium.copyWith(color: AppTheme.error),
          ),
        ),
      ),
    );
  }
}

class _PastBudgetCard extends StatelessWidget {
  final Budget budget;

  const _PastBudgetCard({required this.budget});

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (date.month >= 1 && date.month <= 12) {
      return '${months[date.month - 1]} ${date.year}';
    }
    return '${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isExceeded = budget.isExceeded;
    final statusColor = isExceeded ? AppTheme.error : AppTheme.primary;
    final statusText = isExceeded ? 'Exceeded' : 'Within Limit';
    final percentage = budget.percentageUsed;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Month/Year and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMonthYear(budget.startDate),
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Row with Limit and Spent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTHLY LIMIT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'RM ${budget.limit.toStringAsFixed(2)}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'RM ${budget.spent.toStringAsFixed(2)}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isExceeded ? AppTheme.error : AppTheme.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? AppTheme.error : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // Percentage used text
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percentage * 100).toStringAsFixed(0)}% used',
                style: AppTypography.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
