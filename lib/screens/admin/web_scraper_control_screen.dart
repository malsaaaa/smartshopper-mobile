import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/providers/web_scraper_provider.dart';

/// Screen for testing and managing web scraping
/// This is a utility screen for development/admin purposes
class WebScraperControlScreen extends ConsumerStatefulWidget {
  const WebScraperControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WebScraperControlScreen> createState() => _WebScraperControlScreenState();
}

class _WebScraperControlScreenState extends ConsumerState<WebScraperControlScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, int> _scrapingResults = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Scraper Control'),
        backgroundColor: const Color(0xFF00D084),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Scraping Statistics
          _buildStatisticsCard(context, ref),
          const SizedBox(height: 16),

          // Scrape All Retailers Button
          _buildScrapeAllButton(context),
          const SizedBox(height: 16),

          // Individual Retailer Buttons
          _buildRetailerButton('MyDin', context),
          const SizedBox(height: 8),
          _buildRetailerButton('myAEON2go', context),
          const SizedBox(height: 8),
          _buildRetailerButton('Lotus', context),
          const SizedBox(height: 16),

          // Results Section
          if (_scrapingResults.isNotEmpty) ...[
            _buildResultsCard(),
            const SizedBox(height: 16),
          ],

          // Status Message
          if (_statusMessage.isNotEmpty)
            Card(
              color: _statusMessage.contains('✅') ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('✅') ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ),
            ),

          // Clear Data Button (danger zone)
          const SizedBox(height: 24),
          _buildDangerZoneSection(context),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(scrapingStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scraping Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Retailers', stats['retailers']?.toString() ?? '0'),
                  _buildStatRow('Products', stats['products']?.toString() ?? '0'),
                  _buildStatRow('Prices', stats['prices']?.toString() ?? '0'),
                  _buildStatRow('Last Update', _formatTime(stats['lastUpdate'])),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(
                'Error loading stats: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrapeAllButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _scrapeAllRetailers(),
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.cloud_download),
      label: Text(_isLoading ? 'Scraping...' : 'Scrape All Retailers'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D084),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildRetailerButton(String retailerName, BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _scrapeRetailer(retailerName.toLowerCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00D084),
        side: const BorderSide(color: Color(0xFF00D084)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text('Scrape $retailerName'),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Scraping Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._scrapingResults.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${entry.value} products',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _showClearDataDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All Scraped Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _scrapeAllRetailers() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '⏳ Scraping all retailers...';
    });

    try {
      final results = await ref.read(scrapeAllRetailersProvider(true).future);
      setState(() {
        _scrapingResults = results;
        _statusMessage = '✅ Scraping complete: ${results.values.fold<int>(0, (a, b) => a + b)} products scraped';
        _isLoading = false;
      });

      // Refresh statistics
      ref.refresh(scrapingStatsProvider);
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scrapeRetailer(String retailerName) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '⏳ Scraping $retailerName...';
    });

    try {
      final count = await ref.read(scrapeRetailerProvider(retailerName).future);
      setState(() {
        _scrapingResults[retailerName] = count;
        _statusMessage = '✅ Scraped $count products from $retailerName';
        _isLoading = false;
      });

      // Refresh statistics
      ref.refresh(scrapingStatsProvider);
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error scraping $retailerName: $e';
        _isLoading = false;
      });
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Scraped Data?'),
        content: const Text(
          'This will delete all products, prices, and retailer data from Firestore. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearScrapedData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearScrapedData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '⏳ Clearing all data...';
    });

    try {
      await ref.read(webScraperServiceProvider).clearScrapedData();
      setState(() {
        _statusMessage = '✅ All scraped data cleared';
        _scrapingResults.clear();
        _isLoading = false;
      });

      // Refresh statistics
      ref.refresh(scrapingStatsProvider);
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error clearing data: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return 'Never';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
    } catch (e) {
      return 'Invalid';
    }
  }
}
