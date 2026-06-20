import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

// ============== BUTTONS ==============

/// Primary button with loading state and optional icon support
/// Used for main call-to-action elements
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double width;
  final EdgeInsets padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.padding =
        const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: padding,
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppTheme.borderRadiusCard),
          ),
        ),
      ),
    );
  }
}

/// Secondary button with outlined style
/// Used for secondary actions
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double width;
  final EdgeInsets padding;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width = double.infinity,
    this.padding =
        const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: padding,
          side: const BorderSide(color: AppTheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppTheme.borderRadiusCard),
          ),
        ),
      ),
    );
  }
}

/// Minimal text button with optional icon
/// Used for tertiary actions
class TextIconButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color textColor;

  const TextIconButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: textColor,
      ),
    );
  }
}

// ============== INPUT FIELDS ==============

/// Custom text field with validation and password toggle
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType keyboardType;
  final bool isPassword;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.controller,
    this.prefixIcon,
    this.obscureText = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            errorText: widget.errorText,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusInput),
            ),
          ),
        ),
      ],
    );
  }
}

/// Search field with clear button
class SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final String? hint;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    required this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.hint,
    this.controller,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Search products...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  widget.onClear?.call();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppTheme.borderRadiusInput),
        ),
      ),
    );
  }
}

// ============== CARDS & CONTAINERS ==============

/// Reusable card with customizable styling and tap handler
class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color borderColor;
  final double elevation;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTheme.spacing16),
    this.backgroundColor = AppTheme.surface,
    this.borderColor = AppTheme.divider,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
          border: Border.all(color: borderColor),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: elevation,
                    offset: Offset(0, elevation / 2),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Section header with title, subtitle, and optional "View All" button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;
  final bool showViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing4),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          if (showViewAll && onViewAll != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacing8),
                child: TextIconButton(
                  label: 'View All',
                  onPressed: onViewAll!,
                  icon: Icons.arrow_forward,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============== PRICE & PRODUCT ==============

/// Displays price with optional original price (strikethrough)
class PriceDisplay extends StatelessWidget {
  final double currentPrice;
  final double? originalPrice;
  final String currency;
  final TextStyle? textStyle;

  const PriceDisplay({
    super.key,
    required this.currentPrice,
    this.originalPrice,
    this.currency = 'RM',
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (originalPrice != null && originalPrice! > currentPrice)
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing8),
            child: Text(
              '$currency${originalPrice!.toStringAsFixed(2)}',
              style: (textStyle ?? Theme.of(context).textTheme.bodySmall)
                  ?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        Text(
          '$currency${currentPrice.toStringAsFixed(2)}',
          style: textStyle ??
              Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
        ),
      ],
    );
  }
}

/// Retailer badge showing logo, price, and best price indicator
class RetailerBadge extends StatelessWidget {
  final String retailerName;
  final double price;
  final bool isBestPrice;
  final VoidCallback? onTap;
  final String? logoUrl;
  final double? savings;
  final DateTime? scrapedAt;
  final double? distanceKm;
  final double? gasCost;
  final double? latitude;
  final double? longitude;

  const RetailerBadge({
    super.key,
    required this.retailerName,
    required this.price,
    this.isBestPrice = false,
    this.onTap,
    this.logoUrl,
    this.savings,
    this.scrapedAt,
    this.distanceKm,
    this.gasCost,
    this.latitude,
    this.longitude,
  });

  String _formatScraped(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final hhmm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Today $hhmm';
    if (diff.inDays == 1) return 'Yesterday $hhmm';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        if (await canLaunchUrl(geoUrl)) {
          await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Last resort: try to open the web URL directly
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      backgroundColor:
          isBestPrice ? AppTheme.bestPriceLight : AppTheme.surface,
      borderColor: isBestPrice ? AppTheme.bestPrice : AppTheme.divider,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (true) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SmartImage(
                    imageUrl: getRetailerLogo(retailerName, logoUrl),
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorWidget: const Icon(Icons.store_outlined, size: 14),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  retailerName,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isBestPrice)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bestPrice,
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusInput),
                  ),
                  child: Text(
                    'BEST',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'RM${price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isBestPrice ? AppTheme.bestPrice : AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (savings != null && savings! > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing8),
              child: Text(
                'Save RM${savings!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          if (distanceKm != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded,
                      size: 11, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${distanceKm!.toStringAsFixed(1)}km away',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          if (gasCost != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.local_gas_station_rounded,
                      size: 11, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Fuel cost RM${gasCost!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          if (distanceKm == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentOrange),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Finding nearest store...',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.accentOrange,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          if (savings != null && gasCost != null)
            Builder(builder: (context) {
              final net = savings! - gasCost!;
              final isProfit = net > 0;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isProfit
                        ? 'Net Save: RM${net.toStringAsFixed(2)}'
                        : 'Loss: RM${net.abs().toStringAsFixed(2)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: isProfit ? AppTheme.primary : AppTheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            }),
          if (latitude != null && longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing8),
              child: SizedBox(
                height: 28,
                child: OutlinedButton.icon(
                  onPressed: () => _launchMaps(latitude!, longitude!),
                  icon: const Icon(Icons.directions_outlined, size: 14),
                  label: const Text('Get Directions', style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: AppTheme.primary, width: 0.5),
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ),
            ),
          if (scrapedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.update_rounded, size: 11, color: AppTheme.textTertiary),
                  const SizedBox(width: 3),
                  Text(
                    'Scraped: ${_formatScraped(scrapedAt!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============== PROGRESS & STATUS ==============

/// Progress card with title and progress bar
class ProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final String? subtitle;
  final Color progressColor;

  const ProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.subtitle,
    this.progressColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing4),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: AppTheme.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge with different states (success, warning, error, info)
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType status;
  final double? width;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = StatusType.info,
    this.width,
  });

  Color get _backgroundColor {
    switch (status) {
      case StatusType.success:
        return AppTheme.secondaryLight;
      case StatusType.warning:
        return Color(0xFFFFE8B5);
      case StatusType.error:
        return Color(0xFFFFEBEE);
      case StatusType.info:
        return AppTheme.primaryLight;
    }
  }

  Color get _textColor {
    switch (status) {
      case StatusType.success:
        return AppTheme.secondary;
      case StatusType.warning:
        return Color(0xFFE65100);
      case StatusType.error:
        return AppTheme.error;
      case StatusType.info:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

enum StatusType { success, warning, error, info }

// ============== LIST ITEMS ==============

/// List item tile with leading, title, subtitle, and trailing widgets
class ListItemTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ListItemTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.divider),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppTheme.spacing12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacing4),
                      child: Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppTheme.spacing12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============== STATES ==============

/// Empty state with icon, title, message, and optional action button
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                child: Icon(
                  icon,
                  size: 64,
                  color: AppTheme.textTertiary,
                ),
              ),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacing16),
                child: PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction!,
                  width: 200,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Error state with message and retry button
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              child: Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacing16),
                child: PrimaryButton(
                  label: retryLabel ?? 'Retry',
                  onPressed: onRetry!,
                  width: 150,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading state with spinner and optional message
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing16),
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

// ============== UTILITIES ==============

/// Divider with centered text
class DividerWithText extends StatelessWidget {
  final String text;
  final Color dividerColor;

  const DividerWithText({
    super.key,
    required this.text,
    this.dividerColor = AppTheme.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: dividerColor),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Divider(color: dividerColor),
        ),
      ],
    );
  }
}

/// Helper widget for handling AsyncSnapshot UI building
class SnapshotBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext)? emptyBuilder;

  const SnapshotBuilder({
    super.key,
    required this.snapshot,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingBuilder?.call(context) ?? const LoadingState();
    }

    if (snapshot.hasError) {
      final errorMessage = snapshot.error.toString();
      return errorBuilder?.call(context, errorMessage) ??
          ErrorState(message: errorMessage);
    }

    if (!snapshot.hasData) {
      return emptyBuilder?.call(context) ??
          const EmptyState(
            title: 'No data',
            message: 'No data available at the moment',
          );
    }

    return builder(context, snapshot.data as T);
  }
}
// ============== UTILITIES ==============

/// Intelligent image widget that handles both Network and Asset images
/// with error handling and consistent fit.
class SmartImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Center(child: Icon(Icons.image_not_supported_outlined));
    }

    final bool isNetwork = imageUrl.startsWith('http') || imageUrl.startsWith('https');

    if (isNetwork) {
      // Use a reliable image proxy on Web to prevent CORS blocking
      final displayUrl = kIsWeb 
          ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(imageUrl)}' 
          : imageUrl;

      return Image.network(
        displayUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? const Center(child: Icon(Icons.broken_image_outlined)),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? const Center(child: Icon(Icons.image_not_supported_outlined)),
      );
    }
  }
}

/// Helper function to resolve retailer logo with fallback
String getRetailerLogo(String name, String? currentUrl) {
  final normalized = name.toLowerCase();
  final fallback = normalized.contains('myaeon2go')
    ? 'assets/images/retailers/aeon.png'
      : normalized.contains('mydin')
          ? 'assets/images/retailers/mydin.png'
          : normalized.contains('lotus')
              ? 'assets/images/retailers/lotuss.png'
              : normalized.contains('aeon')
                  ? 'assets/images/retailers/aeon.png'
                  : normalized.contains('econsave')
                      ? 'assets/images/retailers/econsave.png'
                      : '';

  if (fallback.isNotEmpty) {
    if (currentUrl == null || currentUrl.isEmpty) return fallback;
    if (currentUrl.startsWith('assets/') || currentUrl.startsWith('package:')) {
      return currentUrl;
    }
    return fallback;
  }

  return currentUrl ?? '';
}
