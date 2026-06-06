import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:smartshopper_mobile/data/models/notification.dart' as notif;
import 'package:smartshopper_mobile/services/notification_service.dart';

/// Rich discount notification card component
class DiscountNotificationCard extends StatelessWidget {
  final notif.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const DiscountNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!NotificationService.isDiscountNotification(notification)) {
      return const SizedBox.shrink();
    }

    final discount = notification.calculatedDiscount ?? 0;
    final isValid = notification.isDiscountValid;
    final timeRemaining = notification.discountExpiresAt != null
        ? NotificationService.formatTimeRemaining(notification.discountExpiresAt!)
        : null;

    return GestureDetector(
      onTap: isValid ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
          child: Container(
            color: AppTheme.surface,
            child: Column(
              children: [
                // Header with type badge
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.9),
                        AppTheme.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isValid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing8,
                            vertical: AppTheme.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Expired',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Column(
                    children: [
                      // Product image and basic info
                      if (notification.productImage != null)
                        Row(
                          children: [
                            // Product image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: AppTheme.background,
                                child: Image.network(
                                  notification.productImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppTheme.background,
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing12),

                            // Product info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    notification.productName ?? 'Product',
                                    style: Theme.of(context).textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppTheme.spacing4),
                                  if (notification.retailer != null)
                                    Text(
                                      notification.retailer!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),

                            // Discount badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing8,
                                vertical: AppTheme.spacing6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.accentOrange,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '-$discount%',
                                style: const TextStyle(
                                  color: AppTheme.accentOrange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // Without image
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.productName ?? 'Product',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (notification.retailer != null)
                              Padding(
                                padding: const EdgeInsets.only(top: AppTheme.spacing4),
                                child: Text(
                                  notification.retailer!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: AppTheme.spacing12),

                      // Price info
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(
                                  'RM${notification.newPrice?.toStringAsFixed(2) ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (notification.oldPrice != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Was',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: AppTheme.spacing4),
                                  Text(
                                    'RM${notification.oldPrice?.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Time remaining or message
                      if (timeRemaining != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacing12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.accentYellow,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '⏰ ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  timeRemaining,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFB8860B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacing12),
                          child: Text(
                            notification.message,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Dismiss'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.divider),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      if (isValid)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.shopping_bag, size: 16),
                            label: const Text('View Deal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.textTertiary,
                            ),
                            child: const Text('Expired'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact discount notification tile (for lists)
class DiscountNotificationTile extends StatelessWidget {
  final notif.Notification notification;
  final VoidCallback? onTap;

  const DiscountNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = notification.calculatedDiscount ?? 0;
    final isValid = notification.isDiscountValid;

    return ListTile(
      onTap: isValid ? onTap : null,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: notification.productImage != null
            ? Image.network(
                notification.productImage!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.background,
                    child: const Icon(Icons.shopping_bag),
                  );
                },
              )
            : Container(
                width: 50,
                height: 50,
                color: AppTheme.background,
                child: const Icon(Icons.shopping_bag),
              ),
      ),
      title: Text(notification.productName ?? 'Product'),
      subtitle: Text(
        '${notification.retailer ?? 'Store'} • -$discount%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'RM${notification.newPrice?.toStringAsFixed(2) ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (notification.oldPrice != null)
            Text(
              'RM${notification.oldPrice?.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
        ],
      ),
      enabled: isValid,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
    );
  }
}
