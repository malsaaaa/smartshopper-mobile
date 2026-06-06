# Web Scraping Quick Start

## 1️⃣ Install Dependencies

Run in terminal:
```bash
flutter pub get
```

This installs the new `html: ^0.15.4` package for HTML parsing.

## 2️⃣ Basic Usage - Scrape All Retailers

### Option A: Using Riverpod (Recommended)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/providers/web_scraper_provider.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Scrape all retailers and store in Firestore
        final results = await ref.read(scrapeAllRetailersProvider(true).future);
        
        print('MyDin: ${results['mydin']} products');
        print('Giant: ${results['giant']} products');
        print('Lotus: ${results['lotus']} products');
      },
      child: Text('Start Scraping'),
    );
  }
}
```

### Option B: Direct Service Usage

```dart
import 'package:smartshopper_mobile/services/web_scraper_service.dart';

void scrapeData() async {
  final service = WebScraperService();
  
  // Scrape all retailers
  final results = await service.scrapeAllRetailers(storeInFirestore: true);
  
  for (final entry in results.entries) {
    print('${entry.key}: ${entry.value} products');
  }
}
```

## 3️⃣ Scrape Individual Retailers

```dart
final service = WebScraperService();

// Scrape MyDin only
int mydinCount = await service.scrapeRetailer('mydin', storeInFirestore: true);
print('Scraped $mydinCount MyDin products');

// Scrape Giant only
int giantCount = await service.scrapeRetailer('giant', storeInFirestore: true);
print('Scraped $giantCount Giant products');

// Scrape Lotus only
int lotusCount = await service.scrapeRetailer('lotus', storeInFirestore: true);
print('Scraped $lotusCount Lotus products');
```

## 4️⃣ Get Scraped Products

```dart
final service = WebScraperService();

// Get all MyDin products from Firestore
final mydinProducts = await service.getProductsByRetailer('mydin');
print('Found ${mydinProducts.length} MyDin products');

// Display them
for (final product in mydinProducts) {
  print('${product.name} - RM${product.price}');
}
```

## 5️⃣ Check Scraping Statistics

```dart
final service = WebScraperService();

final stats = await service.getScrapingStats();
print('Total retailers: ${stats['retailers']}');
print('Total products: ${stats['products']}');
print('Total prices: ${stats['prices']}');
print('Last update: ${stats['lastUpdate']}');
```

## 6️⃣ Add Control Screen to Your App

### Step 1: Update Routes

Open `lib/config/routes.dart`:
```dart
import 'package:smartshopper_mobile/screens/admin/web_scraper_control_screen.dart';

final routes = {
  // ... existing routes
  '/admin/scraper': (context) => const WebScraperControlScreen(),
};
```

### Step 2: Add Navigation Link

Add a button or menu item:
```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/admin/scraper'),
  child: const Text('Web Scraper Control'),
)
```

### Step 3: Navigate and Test

1. Run the app: `flutter run`
2. Click the Web Scraper Control button
3. Click "Scrape All Retailers"
4. Monitor console output for progress
5. Check Firestore Console to see scraped data

## 7️⃣ Console Output Examples

When scraping starts, you'll see:
```
🔍 Starting scrape of all retailers...
🔄 Scraping mydin...
✅ MyDin: Scraped 145 products
✅ Stored retailer: MyDin
✅ Stored 145 products
🔄 Scraping giant...
✅ Giant: Scraped 203 products
✅ Stored retailer: Giant
✅ Stored 203 products
🔄 Scraping lotus...
✅ Lotus: Scraped 178 products
✅ Stored retailer: Lotus
✅ Stored 178 products
✅ Scraping complete: {'mydin': 145, 'giant': 203, 'lotus': 178}
```

## 🔧 Troubleshooting

### Problem: "No products found" in console

**Cause**: HTML selectors don't match the actual website structure

**Solution**: 
1. Visit retailer website
2. Open DevTools (F12)
3. Inspect product elements
4. Update CSS selectors in scraper files:
   - `lib/services/scrapers/mydin_scraper.dart`
   - `lib/services/scrapers/giant_scraper.dart`
   - `lib/services/scrapers/lotus_scraper.dart`

Example update:
```dart
// OLD - Generic selector
final productElements = document.querySelectorAll('.product-card');

// NEW - Actual website selector
final productElements = document.querySelectorAll('.mydin-product-item[data-id]');
```

### Problem: "Timeout" error

**Cause**: Website is slow or not responding

**Solution**: Increase timeout in scraper (line with `.timeout(Duration(seconds: 30))`)
```dart
// Change to 60 seconds
.timeout(const Duration(seconds: 60))
```

### Problem: Prices showing as 0.0

**Cause**: Price text format is different than expected

**Solution**: Update `_extractPrice()` method to handle your retailer's format:
```dart
// Example if prices are "RM 9.99"
final cleaned = text
    .replaceAll('RM', '')
    .replaceAll(RegExp(r'[^\d.]'), '')
    .trim();
```

## 📊 Checking Results in Firestore

1. Open Firebase Console
2. Go to Firestore Database
3. Check these collections:
   - `retailers` - Should have 3 docs (MyDin, Giant, Lotus)
   - `products` - Should have hundreds of products
   - `prices` - Should have entries for each product × retailer

## 🎯 Next: Customize for Real Websites

See [WEB_SCRAPING_GUIDE.md](WEB_SCRAPING_GUIDE.md) for detailed instructions on:
- Inspecting website HTML structure
- Finding correct CSS selectors
- Handling JavaScript-rendered content
- Performance optimization
- Rate limiting best practices

## 💡 Tips

- **Test one retailer first**: Start with MyDin, verify it works
- **Check Firestore in real-time**: Open Firebase Console while scraping
- **Use DevTools Network tab**: See actual HTTP responses
- **Add logging**: Use `print()` statements to debug selectors
- **Respect rate limits**: Add delays between requests in production

## 🚀 You're Ready!

Your web scraping system is set up and ready to use. Just customize the HTML selectors for each retailer and start scraping! 🎉
