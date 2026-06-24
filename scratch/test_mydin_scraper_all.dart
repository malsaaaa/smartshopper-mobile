import 'package:smartshopper_mobile/services/scrapers/mydin_scraper.dart';

void main() async {
  print('=== MyDin Scraper Test for All Search Terms ===');
  
  final scraper = MyDinScraper();
  print('Scraper initialized.');
  
  print('Running scrapeProducts()...');
  final stopwatch = Stopwatch()..start();
  
  final products = await scraper.scrapeProducts();
  stopwatch.stop();
  
  print('\n=== Scraping Completed in ${stopwatch.elapsed.inSeconds} seconds ===');
  print('Total products scraped: ${products.length}');
  
  if (products.isNotEmpty) {
    print('\nFirst 15 Scraped Products:');
    for (var i = 0; i < (products.length < 15 ? products.length : 15); i++) {
      final pair = products[i];
      final product = pair.$1;
      final price = pair.$2;
      print(' ${i + 1}. [ID: ${product.id}] ${product.name} | RM ${price.price} | URL: ${price.productUrl}');
    }
  } else {
    print('❌ Failed to scrape any products!');
  }
}
