import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/providers/notifications_provider.dart';
import 'package:smartshopper_mobile/widgets/discount_notification_widget.dart';

/// Example: How to use the new discount notification system
/// 
/// USAGE EXAMPLES:
/// 
/// 1. Price Drop Notification:
///    ref.read(notificationsProvider.notifier).addDiscountNotification(
///      type: 'price_drop',
///      userId: 1,
///      productId: 'milo-001',
///      productName: 'Milo Activ-Go',
///      productImage: 'assets/images/products/milo.png',
///      oldPrice: 15.50,
///      newPrice: 12.50,
///      retailer: 'Mydin',
///    );
///
/// 2. New Discount Notification:
///    ref.read(notificationsProvider.notifier).addDiscountNotification(
///      type: 'new_discount',
///      userId: 1,
///      productId: 'cola-001',
///      productName: 'Coca Cola 2L',
///      oldPrice: 8.90,
///      newPrice: 6.99,
///      retailer: 'Giant',
///      expiresAt: DateTime.now().add(Duration(hours: 24)),
///    );
///
/// 3. Time-Limited Deal:
///    ref.read(notificationsProvider.notifier).addTimeLimitedDealNotification(
///      userId: 1,
///      productId: 'bread-001',
///      productName: 'Gardenia Bread',
///      originalPrice: 5.50,
///      dealPrice: 3.99,
///      retailer: 'Tesco',
///      expiresAt: DateTime.now().add(Duration(hours: 2)),
///    );
///
/// 4. Flash Sale:
///    ref.read(notificationsProvider.notifier).addFlashSaleNotification(
///      userId: 1,
///      productId: 'milk-001',
///      productName: 'Dutch Lady Milk',
///      salePrice: 4.99,
///      retailer: 'Aeon',
///      endsAt: DateTime.now().add(Duration(minutes: 30)),
///    );

/// Discount Notifications Demo Screen
class DiscountNotificationsDemoScreen extends ConsumerWidget {
  const DiscountNotificationsDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountNotifications = ref.watch(discountNotificationsProvider);
    final allNotifications = ref.watch(notificationsProvider);
    final frequency = ref.watch(notificationFrequencyProvider);
    final enabled = ref.watch(discountNotificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Center(
              child: Text(
                '${allNotifications.length}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Settings Section
            Container(
              color: AppTheme.primaryLight,
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing12),

                  // Enable/Disable toggle
                  SwitchListTile(
                    title: const Text('Enable Discount Notifications'),
                    value: enabled,
                    onChanged: (value) {
                      ref.read(discountNotificationsEnabledProvider.notifier).state =
                          value;
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppTheme.spacing12),

                  // Frequency selector
                  Text(
                    'Notification Frequency',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'real-time',
                        label: Text('Real-time'),
                      ),
                      ButtonSegment(
                        value: 'daily',
                        label: Text('Daily'),
                      ),
                      ButtonSegment(
                        value: 'weekly',
                        label: Text('Weekly'),
                      ),
                    ],
                    selected: {frequency},
                    onSelectionChanged: (newSelection) {
                      ref.read(notificationFrequencyProvider.notifier).state =
                          newSelection.first;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing16),

            // Demo Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Notifications',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing12),

                  // Price Drop Demo
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier)
                          .addDiscountNotification(
                        type: 'price_drop',
                        userId: 1,
                        productId: 'milo-001',
                        productName: 'Milo Activ-Go 400g',
                        productImage:
                            'https://via.placeholder.com/80?text=Milo',
                        oldPrice: 15.50,
                        newPrice: 12.50,
                        retailer: 'Mydin',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Price Drop Notification Added')),
                      );
                    },
                    icon: const Icon(Icons.trending_down),
                    label: const Text('Add Price Drop'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),

                  // New Discount Demo
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier)
                          .addDiscountNotification(
                        type: 'new_discount',
                        userId: 1,
                        productId: 'cola-001',
                        productName: 'Coca Cola 2L',
                        oldPrice: 8.90,
                        newPrice: 6.99,
                        retailer: 'Giant',
                        expiresAt: DateTime.now()
                            .add(const Duration(hours: 24)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New Discount Notification Added')),
                      );
                    },
                    icon: const Icon(Icons.local_offer),
                    label: const Text('Add New Discount'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),

                  // Time-Limited Deal Demo
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier)
                          .addTimeLimitedDealNotification(
                        userId: 1,
                        productId: 'bread-001',
                        productName: 'Gardenia Bread',
                        originalPrice: 5.50,
                        dealPrice: 3.99,
                        retailer: 'Tesco',
                        expiresAt:
                            DateTime.now().add(const Duration(hours: 2)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Time-Limited Deal Added')),
                      );
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Add Time-Limited Deal'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),

                  // Flash Sale Demo
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier)
                          .addFlashSaleNotification(
                        userId: 1,
                        productId: 'milk-001',
                        productName: 'Dutch Lady Milk 1L',
                        salePrice: 4.99,
                        retailer: 'Aeon',
                        endsAt: DateTime.now()
                            .add(const Duration(minutes: 30)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flash Sale Notification Added')),
                      );
                    },
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Add Flash Sale'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),

                  // Clear all
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).clearReadNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cleared notifications')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Read Notifications'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Notifications List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount Notifications (${discountNotifications.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                ],
              ),
            ),

            if (discountNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        'No discount notifications yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Test notifications using buttons above',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: discountNotifications.length,
                itemBuilder: (context, index) {
                  final notification = discountNotifications[index];
                  return DiscountNotificationCard(
                    notification: notification,
                    onTap: () {
                      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                      // Navigate to product details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Viewing: ${notification.productName}',
                          ),
                        ),
                      );
                    },
                    onDismiss: () {
                      ref
                          .read(notificationsProvider.notifier)
                          .deleteNotification(notification.id);
                    },
                  );
                },
              ),

            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
}
