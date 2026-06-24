import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/providers/index.dart';
import 'package:smartshopper_mobile/widgets/ui_components.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);

    if (favs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const EmptyState(
          icon: Icons.favorite_border,
          title: 'No favorites yet',
          message: 'Tap the heart on a product to save it here.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: favs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final productId = favs[index];
          final product = ref.watch(productByIdProvider(productId));

          if (product == null) {
            return BaseCard(
              child: ListTile(
                title: Text('Product #$productId (Unavailable)'),
                subtitle: const Text('This product is no longer available'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                  onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(productId),
                ),
              ),
            );
          }

          return BaseCard(
            child: ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                clipBehavior: Clip.antiAlias,
                child: SmartImage(imageUrl: product.imageUrl),
              ),
              title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(product.category),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: AppTheme.error),
                onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(productId),
              ),
              onTap: () => Navigator.pushNamed(context, '/product-details', arguments: product.id),
            ),
          );
        },
      ),
    );
  }
}
