import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Notifications settings screen
/// Allows users to manage their notification preferences
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Types Section
            Text(
              'Notification Types',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Push Notifications
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Push Notifications',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Receive notifications on your phone',
                  style: AppTypography.bodySmall,
                ),
                value: preferences.pushNotifications,
                onChanged: (value) {
                  ref.read(notificationPreferencesProvider.notifier).setPushNotifications(value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            const SizedBox(height: AppSpacing.xxl),

            // Alert Preferences Section
            Text(
              'Alert Preferences',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Price Alerts
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Price Drop Alerts',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Get notified when prices drop',
                  style: AppTypography.bodySmall,
                ),
                value: preferences.priceAlerts,
                onChanged: (value) {
                  ref.read(notificationPreferencesProvider.notifier).setPriceAlerts(value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Budget Alerts
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Budget Alerts',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Notify when budget limit reached',
                  style: AppTypography.bodySmall,
                ),
                value: preferences.budgetAlerts,
                onChanged: (value) {
                  ref.read(notificationPreferencesProvider.notifier).setBudgetAlerts(value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Shopping Reminders
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Shopping Reminders',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Remind me about pending shopping lists',
                  style: AppTypography.bodySmall,
                ),
                value: preferences.shoppingReminders,
                onChanged: (value) {
                  ref.read(notificationPreferencesProvider.notifier).setShoppingReminders(value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Promotional Section
            Text(
              'Marketing & Promotions',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Promotions
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Promotional Offers',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Receive special deals and promotions',
                  style: AppTypography.bodySmall,
                ),
                value: preferences.promotions,
                onChanged: (value) {
                  ref.read(notificationPreferencesProvider.notifier).setPromotions(value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Weekly Digest
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Weekly Digest',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Weekly summary of prices and savings',
                  style: AppTypography.bodySmall,
                ),
                value: preferences.weeklyDigest,
                onChanged: (value) {
                  ref.read(notificationPreferencesProvider.notifier).setWeeklyDigest(value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Auto-save Notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Your preferences are saved automatically',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
