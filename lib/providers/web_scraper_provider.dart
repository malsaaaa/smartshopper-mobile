import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/services/web_scraper_service.dart';

/// Provider for WebScraperService singleton
final webScraperServiceProvider = Provider<WebScraperService>((ref) {
  return WebScraperService();
});

/// Provider to manage the remote scraper listener in the background
final webScraperListenerProvider = Provider<WebScraperListener>((ref) {
  final service = ref.watch(webScraperServiceProvider);
  final listener = WebScraperListener(service);
  listener.start();
  ref.onDispose(() {
    listener.stop();
  });
  return listener;
});

class WebScraperListener {
  final WebScraperService _service;
  StreamSubscription? _subscription;
  bool _isProcessing = false;

  WebScraperListener(this._service);

  void start() {
    if (_subscription != null) return;

    print('📡 Background Scraper Listener starting...');

    _subscription = FirebaseFirestore.instance
        .collection('scraper_jobs')
        .snapshots()
        .listen((snapshot) async {
      if (_isProcessing) return;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString();

        if (status == 'pending') {
          _isProcessing = true;
          final retailerName = data['retailerName']?.toString();

          if (retailerName == null) {
            _isProcessing = false;
            continue;
          }

          try {
            print('⚙️ Processing remote scraper job for $retailerName...');
            
            // 1. Update status to running
            await doc.reference.update({
              'status': 'running',
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // 2. Execute scraping
            final count = await _service.scrapeRetailer(retailerName);

            // 3. Update status to success
            await doc.reference.update({
              'status': 'success',
              'lastRun': DateTime.now().toIso8601String(),
              'itemsScraped': count,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('✅ Remote scraper job completed for $retailerName ($count items)');
          } catch (e) {
            print('❌ Remote scraper job failed for $retailerName: $e');
            // Update status to error
            await doc.reference.update({
              'status': 'error',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } finally {
            _isProcessing = false;
          }
          break; // Process one job at a time
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}

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

