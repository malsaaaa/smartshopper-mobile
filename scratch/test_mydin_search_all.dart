import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiBaseUrl = 'https://myapi.mydin.my/magento';
  final searchTerms = ['cooking oil', 'milo', 'maggi', 'tea', 'rice'];
  final pageSize = 24; // Use 24 to keep the test quick

  print('🔍 Starting search test for all terms...');

  for (final term in searchTerms) {
    final payload = [
      {
        'search': term,
        'pageSize': pageSize,
        'currentPage': 1,
      },
      {
        'products': 'products-custom-query',
        'metadata': {
          'fields': '''
items {
  id
  name
  sku
  url_key
  custom_productname
  price_range {
    minimum_price {
      final_price {
        currency
        value
      }
    }
  }
}
''',
        },
      },
    ];

    final url = '$apiBaseUrl/products?body=${Uri.encodeComponent(jsonEncode(payload))}';
    print('\n🔄 Searching for "$term"...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'accept': 'application/json',
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('❌ MyDin API failed for "$term": ${response.statusCode}');
        continue;
      }

      final decoded = jsonDecode(response.body);
      final items = _extractItems(decoded);
      print('✅ Successfully fetched ${items.length} products for "$term"');

      if (items.isNotEmpty) {
        print('Sample items:');
        for (var i = 0; i < (items.length < 3 ? items.length : 3); i++) {
          final item = items[i];
          final name = item['custom_productname'] ?? item['name'] ?? 'Unknown';
          print(' - $name (SKU: ${item['sku']})');
        }
      }
    } catch (e) {
      print('❌ Error searching for "$term": $e');
    }

    // Polite delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
  print('\n🎉 All search terms tested!');
}

List<Map<String, dynamic>> _extractItems(dynamic decoded) {
  final items = <Map<String, dynamic>>[];

  void walk(dynamic value) {
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final maybeItems = map['items'];
      if (maybeItems is List) {
        for (final entry in maybeItems) {
          if (entry is Map) {
            items.add(entry.cast<String, dynamic>());
          }
        }
        return;
      }

      for (final nested in map.values) {
        walk(nested);
      }
    } else if (value is List) {
      for (final nested in value) {
        walk(nested);
      }
    }
  }

  walk(decoded);
  return items;
}
