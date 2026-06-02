import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';

/// About SmartShopper screen
/// Displays information about the app
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About SmartShopper'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight,
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      size: 50,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'SmartShopper',
                    style: AppTypography.headline1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Version 1.0.0',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Description Section
            Text(
              'About',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'SmartShopper is your intelligent shopping companion designed to help you save money and time while shopping. Compare prices across retailers, manage your budget, and keep track of your shopping lists all in one place.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Key Features Section
            Text(
              'Key Features',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureItem(
              icon: Icons.trending_down,
              title: 'Price Comparison',
              description: 'Compare prices across multiple retailers',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureItem(
              icon: Icons.shopping_cart,
              title: 'Shopping Lists',
              description: 'Create and manage shopping lists easily',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureItem(
              icon: Icons.wallet,
              title: 'Budget Tracking',
              description: 'Set and monitor your spending budget',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureItem(
              icon: Icons.notifications,
              title: 'Smart Alerts',
              description: 'Get notified about price drops and deals',
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Support Section
            Text(
              'Support & Contact',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: 'support@smartshopper.com',
                  ),
                  const Divider(height: 20),
                  _buildContactItem(
                    icon: Icons.language,
                    title: 'Website',
                    value: 'www.smartshopper.com',
                  ),
                  const Divider(height: 20),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: '+1 (555) 123-4567',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Legal Section
            Text(
              'Legal',
              style: AppTypography.headline3,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLegalLink('Privacy Policy'),
            const SizedBox(height: AppSpacing.md),
            _buildLegalLink('Terms of Service'),
            const SizedBox(height: AppSpacing.md),
            _buildLegalLink('Licenses'),
            const SizedBox(height: AppSpacing.xxl),

            // Copyright
            Center(
              child: Text(
                '© 2024 SmartShopper. All rights reserved.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Build a feature item
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryLight,
          ),
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a contact item
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primary,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a legal link
  Widget _buildLegalLink(String text) {
    return BaseCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTypography.labelLarge,
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
