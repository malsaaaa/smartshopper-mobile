import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/services/web_scraper_service.dart';

/// Provider for WebScraperService singleton
final webScraperServiceProvider = Provider<WebScraperService>((ref) {
  return WebScraperService();
});

/// Provider to scrape all retailers
final scrapeAllRetailersProvider =
    FutureProvider.family<Map<String, int>, bool>((ref, storeInFirestore) async {
  final service = ref.watch(webScraperServiceProvider);
  return await service.scrapeAllRetailers(storeInFirestore: storeInFirestore);
});

/// Provider to scrape a specific retailer
final scrapeRetailerProvider = FutureProvider.family<int, String>((ref, retailerName) async {
  final service = ref.watch(webScraperServiceProvider);
  return await service.scrapeRetailer(retailerName, storeInFirestore: true);
});

/// Provider to get products by retailer
final productsByRetailerProvider = FutureProvider.family<List, String>((ref, retailerName) async {
  final service = ref.watch(webScraperServiceProvider);
  return await service.getProductsByRetailer(retailerName);
});

/// Provider to get scraping statistics
final scrapingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(webScraperServiceProvider);
  return await service.getScrapingStats();
});
