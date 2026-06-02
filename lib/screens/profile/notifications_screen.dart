import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// Notifications settings screen
/// Allows users to manage their notification preferences
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _priceAlerts = true;
  bool _budgetAlerts = true;
  bool _shoppingReminders = true;
  bool _promotions = false;
  bool _weeklyDigest = true;

  @override
  Widget build(BuildContext context) {
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
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Email Notifications
            BaseCard(
              child: SwitchListTile(
                title: Text(
                  'Email Notifications',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Receive notifications via email',
                  style: AppTypography.bodySmall,
                ),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                },
                activeColor: AppTheme.primary,
              ),
            ),
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
                value: _priceAlerts,
                onChanged: (value) {
                  setState(() => _priceAlerts = value);
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
                value: _budgetAlerts,
                onChanged: (value) {
                  setState(() => _budgetAlerts = value);
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
                value: _shoppingReminders,
                onChanged: (value) {
                  setState(() => _shoppingReminders = value);
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
                value: _promotions,
                onChanged: (value) {
                  setState(() => _promotions = value);
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
                value: _weeklyDigest,
                onChanged: (value) {
                  setState(() => _weeklyDigest = value);
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
