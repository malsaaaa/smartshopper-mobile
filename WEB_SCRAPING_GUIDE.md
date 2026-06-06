# Web Scraping Setup Guide

This guide explains how to use and customize the web scraping system for MyDin, Giant, and Lotus retailers.

## Architecture Overview

The scraping system is built with a modular, extensible architecture:

```
WebScraperService (coordinator)
├── MyDinScraper (implements BaseScraper)
├── GiantScraper (implements BaseScraper)
└── LotusScraper (implements BaseScraper)
```

### Key Components

1. **BaseScraper**: Abstract base class defining the scraper interface
2. **RetailerScrapers**: Individual scrapers for each retailer (MyDin, Giant, Lotus)
3. **WebScraperService**: Central service that coordinates all scrapers and manages Firestore storage
4. **web_scraper_provider.dart**: Riverpod providers for easy integration

## File Structure

```
lib/
├── services/
│   ├── web_scraper_service.dart          # Main orchestrator
│   ├── scrapers/
│   │   ├── base_scraper.dart             # Abstract base class
│   │   ├── mydin_scraper.dart            # MyDin scraper
│   │   ├── giant_scraper.dart            # Giant scraper
│   │   ├── lotus_scraper.dart            # Lotus scraper
│   │   └── index.dart                    # Scraper exports
│   └── index.dart                        # Service exports
├── providers/
│   └── web_scraper_provider.dart         # Riverpod providers
└── ...
```

## Usage Examples

### 1. Scrape All Retailers

```dart
import 'package:smartshopper_mobile/services/web_scraper_service.dart';

// Initialize service
final service = WebScraperService();

// Scrape all retailers and store in Firestore
final results = await service.scrapeAllRetailers(
  storeInFirestore: true,
  pageNumber: 1,
);

// Results: {'mydin': 145, 'giant': 203, 'lotus': 178}
```

### 2. Scrape a Single Retailer

```dart
final count = await service.scrapeRetailer(
  'mydin',
  storeInFirestore: true,
  pageNumber: 1,
  category: 'Groceries',
);

print('Scraped $count products from MyDin');
```

### 3. Using Riverpod Providers

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/providers/web_scraper_provider.dart';

class ScrapingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrapingStats = ref.watch(scrapingStatsProvider);

    return scrapingStats.when(
      data: (stats) => Text('Scraped ${stats['products']} products'),
      loading: () => CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }

  void scrapeAllRetailers(WidgetRef ref) async {
    await ref.read(scrapeAllRetailersProvider(true).future);
  }
}
```

### 4. Get Products by Retailer

```dart
final mydinProducts = await service.getProductsByRetailer('mydin');
print('Found ${mydinProducts.length} MyDin products');

for (final product in mydinProducts) {
  print('${product.name}: RM${product.price}');
}
```

## Customizing Scrapers for Actual Websites

Each retailer scraper needs to be customized to match the actual HTML structure of their website. Here's how:

### Step 1: Inspect Target Website

Use your browser's developer tools to inspect the HTML structure:

```
1. Open retailer website (e.g., https://www.mydin.com.my)
2. Right-click on a product → "Inspect Element"
3. Find CSS selectors for:
   - Product container
   - Product name
   - Product price
   - Product image
   - Product link
   - Pagination elements
```

### Step 2: Update HTML Selectors

In each scraper (e.g., `mydin_scraper.dart`), update the selectors:

```dart
// Example: MyDin products are in <div class="product-card">
final productElements = document.querySelectorAll('.product-card');

// Find actual selectors and update:
final name = element.querySelector('.product-title')?.text ?? '';
final price = element.querySelector('.price-now')?.text ?? '';
final image = element.querySelector('img.product-image')?.attributes['src'] ?? '';
```

### Step 3: Test Scraper

```dart
final scraper = MyDinScraper();
final products = await scraper.scrapeProducts();

// Check results
if (products.isEmpty) {
  print('⚠️ No products found - CSS selectors may be incorrect');
} else {
  print('✅ Found ${products.length} products');
  print('First product: ${products.first.$1.name}');
}
```

### Common Selector Patterns

```dart
// Product containers
.product-card
.product-item
[data-product]
.item-card

// Product names
.product-name
.title
h2
.name

// Prices
.price
[data-price]
.product-price
.price-now

// Images
img
img[data-src]
img.product-image

// Links
a[href*=product]
.product-link
```

## Handling Dynamic Content (JavaScript-Rendered)

If a retailer uses JavaScript to load products dynamically:

1. **Option 1**: Find the API endpoint the site uses to fetch products
   - Open DevTools → Network tab
   - Look for XHR/Fetch requests
   - Use the API URL directly with proper headers

```dart
final response = await http.get(
  Uri.parse('https://api.retailer.com/products?page=1'),
  headers: {
    'User-Agent': 'Mozilla/5.0...',
    'Accept': 'application/json',
  },
);

final json = jsonDecode(response.body);
// Parse JSON directly instead of HTML
```

2. **Option 2**: Use headless browser (more complex, slower)
   - Consider using `webdriver` or similar for complex sites
   - Only if simple scraping doesn't work

## Data Storage in Firestore

Scraped data is automatically stored in Firestore with this structure:

### Retailers Collection

```
retailers/
├── 1/
│   ├── id: 1
│   ├── name: "MyDin"
│   ├── website: "https://www.mydin.com.my"
│   ├── logoUrl: "..."
│   └── updatedAt: (server timestamp)
├── 2/
│   ├── name: "Giant"
│   └── ...
└── 3/
    ├── name: "Lotus"
    └── ...
```

### Products Collection

```
products/
├── 12345/
│   ├── id: 12345
│   ├── name: "Product Name"
│   ├── category: "Groceries"
│   ├── description: "..."
│   ├── imageUrl: "..."
│   └── updatedAt: (server timestamp)
└── ...
```

### Prices Collection

```
prices/
├── 1_12345/  # Format: {retailerId}_{productId}
│   ├── productId: "12345"
│   ├── retailerId: "1"
│   ├── price: 9.99
│   ├── productUrl: "https://..."
│   └── updatedAt: (server timestamp)
└── ...
```

## Error Handling

The system includes built-in error handling:

```dart
try {
  final results = await service.scrapeAllRetailers();
  // Check individual results
  if (results['mydin'] == 0) {
    print('⚠️ MyDin scraping failed or returned no products');
  }
} on SocketException catch (e) {
  print('❌ Network error: $e');
} on TimeoutException catch (e) {
  print('❌ Request timeout: $e');
} catch (e) {
  print('❌ Unexpected error: $e');
}
```

## Rate Limiting & Best Practices

### Respect Retailers' Servers

1. **Add delays between requests**:
   ```dart
   await Future.delayed(Duration(seconds: 2));
   ```

2. **Use appropriate User-Agent**:
   ```dart
   headers: {
     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
   }
   ```

3. **Check robots.txt**:
   - Visit `https://retailer.com/robots.txt`
   - Respect disallowed paths

4. **Limit concurrent requests**:
   ```dart
   // Scrape one retailer at a time, not all in parallel
   for (final retailer in ['mydin', 'giant', 'lotus']) {
     await service.scrapeRetailer(retailer);
     await Future.delayed(Duration(seconds: 5));
   }
   ```

## Troubleshooting

### No Products Found

1. **Check selectors**:
   ```dart
   print('Found ${document.querySelectorAll('.product-card').length} elements');
   ```

2. **Check if site requires login**:
   - Some retailers require authentication
   - May need to add login flow to scraper

3. **Check if site loads content with JavaScript**:
   - View page source (Ctrl+U)
   - If product HTML not in source, site loads dynamically

### Network Errors

1. **Timeout**:
   ```dart
   // Increase timeout
   timeout: Duration(seconds: 60)
   ```

2. **403 Forbidden**:
   - Add proper User-Agent header
   - Some sites block scrapers

3. **Temporary failures**:
   - Add retry logic with exponential backoff
   - Implement fallback data sources

### Data Quality Issues

1. **Missing images**:
   - Resolve relative URLs: `$baseUrl$relativeUrl`

2. **Incorrect prices**:
   - Check currency symbols in `_extractPrice()`
   - Handle promotional prices differently

3. **Duplicate products**:
   - Use product name + retailer as unique key
   - Implement deduplication logic

## Performance Optimization

### Current Configuration

- **Timeout**: 30 seconds per request
- **Batch size**: All products at once
- **Storage**: Direct Firestore write with batch

### Optimization Tips

1. **Pagination**:
   ```dart
   for (int page = 1; page <= 10; page++) {
     final products = await scraper.scrapeProducts(pageNumber: page);
     await service._storeProducts(products);
   }
   ```

2. **Caching**:
   ```dart
   // Store last scrape time per retailer
   // Only scrape if > 24 hours old
   ```

3. **Background Worker**:
   ```dart
   // Schedule daily scraping using work_manager or similar
   // Run scraping in background without blocking UI
   ```

## Next Steps

1. **Update HTML selectors** for each retailer based on actual website structure
2. **Test scraping** with `flutter run` and check console output
3. **Monitor Firestore** to verify data is being stored correctly
4. **Set up automatic scraping** with scheduled tasks
5. **Add product deduplication** to handle duplicate entries across updates

## Files to Modify

- [mydin_scraper.dart](../../services/scrapers/mydin_scraper.dart) - Update selectors for MyDin website
- [giant_scraper.dart](../../services/scrapers/giant_scraper.dart) - Update selectors for Giant website
- [lotus_scraper.dart](../../services/scrapers/lotus_scraper.dart) - Update selectors for Lotus website

Good luck with your scraping setup! 🚀
