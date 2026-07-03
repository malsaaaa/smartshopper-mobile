import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/app_strings.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/screens/support/contact_us_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  final AppStrings s;
  const HelpCenterScreen({super.key, required this.s});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedIndex;

  static const _faqs = [
    {
      'q': 'What is SmartShopper?',
      'a': 'SmartShopper is a price comparison app that helps you find the best grocery deals across major Malaysian supermarkets like Lotus\'s, Aeon, and more.',
    },
    {
      'q': 'How do I search for a product?',
      'a': 'Tap the Search tab at the bottom of the screen and type the product name. You can also use the quick suggestion cards to explore popular items.',
    },
    {
      'q': 'How do I add items to my shopping list?',
      'a': 'On any product page, tap "Add to List". You can view and manage your list from the Shopping tab.',
    },
    {
      'q': 'How does the budget planner work?',
      'a': 'Go to the Budget tab, set your monthly spending limit, and track your expenses by category. SmartShopper will alert you when you\'re close to your limit.',
    },
    {
      'q': 'Are the prices real-time?',
      'a': 'Prices are updated regularly from our data sources. While we strive for accuracy, always confirm the final price at checkout.',
    },
    {
      'q': 'How do I change my language?',
      'a': 'Go to Profile → Preferences → Language and select either English or Bahasa Malaysia.',
    },
    {
      'q': 'Can I delete my account?',
      'a': 'Yes. Go to Profile → Account Settings and select "Delete Account". This action is permanent and cannot be undone.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text(s.helpCenter),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Hero banner ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              children: [
                const Icon(Icons.help_outline_rounded, size: 48, color: Colors.white),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.helpCenter,
                  style: AppTypography.headline2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Find answers to common questions below',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── FAQ label ────────────────────────────────────────────────
          Text(
            s.faq,
            style: AppTypography.labelLarge.copyWith(
              color: AppTheme.textTertiary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── FAQ accordion ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(_faqs.length, (i) {
                final faq = _faqs[i];
                final isOpen = _expandedIndex == i;
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 0, indent: 16, endIndent: 16),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: isOpen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        title: Text(
                          faq['q']!,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(Icons.expand_more, color: AppTheme.textTertiary),
                        onTap: () => setState(() => _expandedIndex = i),
                      ),
                      secondChild: InkWell(
                        onTap: () => setState(() => _expandedIndex = null),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq['q']!,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.expand_less, color: AppTheme.primary),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                faq['a']!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Still need help? ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, size: 36, color: AppTheme.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Still need help?',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Our support team is ready to assist you.',
                  style: AppTypography.bodySmall.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ContactUsScreen(s: s)),
                  ),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(s.contactUs),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
