import 'package:smartshopper_mobile/services/scrapers/myaeon2go_scraper.dart';

void main() async {
  final scraper = MyAeon2GoScraper();
  
  for (final term in MyAeon2GoScraper.searchTerms) {
    print('🔄 Testing search term: "$term"...');
    final products = await scraper.scrapeProducts(category: term);
    print('➡️ Result for "$term": ${products.length} products found.');
    if (products.isNotEmpty) {
      print('  Example: ${products.first.$1.name} (RM ${products.first.$2.price})');
    }
    print('-----------------------------------------');
    await Future.delayed(Duration(milliseconds: 1000));
  }
}
