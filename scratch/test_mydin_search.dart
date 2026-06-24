import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiBaseUrl = 'https://myapi.mydin.my/magento';
  final searchTerm = 'cooking oil';
  final page = 1;
  final pageSize = 48;

  // In Magento GraphQL/REST, the payload can take 'search' instead of 'filter'
  final payload = [
    {
      'search': searchTerm,
      'pageSize': pageSize,
      'currentPage': page,
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
  description {
    html
  }
  thumbnail {
    url
    label
  }
  price_range {
    minimum_price {
      final_price {
        currency
        value
      }
      regular_price {
        currency
        value
      }
    }
  }
  salable_quantity
  quantity
  categories {
    name
  }
}
page_info {
  current_page
  page_size
  total_pages
}
total_count
''',
      },
    },
  ];

  final url = '$apiBaseUrl/products?body=${Uri.encodeComponent(jsonEncode(payload))}';
  print('Requesting search for "$searchTerm": $url');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'accept': 'application/json',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
      },
    );

    print('Status Code: ${response.statusCode}');
    
    final decoded = jsonDecode(response.body);
    
    // Check if errors exist in response
    if (decoded is Map && decoded['errors'] != null) {
      print('Errors returned: ${decoded['errors']}');
      return;
    }

    final items = _extractItems(decoded);
    print('Extracted items count: ${items.length}');
    
    if (items.isNotEmpty) {
      print('Sample items:');
      for (var i = 0; i < (items.length < 5 ? items.length : 5); i++) {
        print(' - ${items[i]['name']} (SKU: ${items[i]['sku']})');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
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
