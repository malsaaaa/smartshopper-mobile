import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiBaseUrl = 'https://myapi.mydin.my/magento';
  final categoryId = 1222;
  final page = 1;
  final pageSize = 48;

  final filter = {
    'category_id': {
      'eq': categoryId,
    },
  };

  final payload = [
    {
      'filter': filter,
      'pageSize': pageSize,
      'currentPage': page,
      'sort': {
        'position': 'ASC',
      },
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
  print('Requesting: $url');

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
    final items = _extractItems(decoded);
    print('Extracted items count: ${items.length}');

    final results = [];
    for (final item in items) {
      try {
        final product = _mapProduct(item);
        final price = _mapPrice(item, product['id'] as int);
        results.add({'product': product, 'price': price});
      } catch (e) {
        print('⚠️ Error parsing MyDin API product: $e');
      }
    }
    print('Successfully parsed results count: ${results.length}');
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

Map<String, dynamic> _mapProduct(Map<String, dynamic> item) {
  final id = _extractInt(item['id']) ?? DateTime.now().millisecondsSinceEpoch;
  final name = _firstNonEmptyString([
    item['custom_productname'],
    item['name'],
    _mapString(item['description'], 'html'),
  ]);
  final description = _stripHtml(
    _firstNonEmptyString([
      _mapString(item['description'], 'html'),
      item['custom_productdescription'],
    ]),
  );
  final imageUrl = _mapString(item['thumbnail'], 'url');

  return {
    'id': id,
    'name': name.isEmpty ? 'Mydin Product $id' : name,
    'description': description,
    'category': 'MyDin',
    'imageUrl': imageUrl,
  };
}

Map<String, dynamic> _mapPrice(Map<String, dynamic> item, int productId) {
  final id = DateTime.now().millisecondsSinceEpoch;
  final price = _extractPrice(item['price_range']);
  final urlKey = _firstNonEmptyString([item['url_key']]);

  return {
    'id': id,
    'productId': productId,
    'retailerId': 1,
    'price': price,
    'productUrl': urlKey.isEmpty ? 'https://mydin.my' : 'https://mydin.my/product/$urlKey',
  };
}

double _extractPrice(dynamic value) {
  try {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final candidates = [
        map['value'],
        map['final_price'],
        map['regular_price'],
        map['minimum_price'],
        map['maximum_price'],
      ];

      for (final candidate in candidates) {
        final extracted = _extractPrice(candidate);
        if (extracted > 0) {
          return extracted;
        }
      }
    }

    final text = value.toString();
    final match = RegExp(r'value\s*=\s*([\d.]+)').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }

    final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  } catch (e) {
    return 0.0;
  }
}

int? _extractInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

String _mapString(dynamic value, String key) {
  if (value is Map) {
    final map = value.cast<String, dynamic>();
    final nested = map[key];
    if (nested != null) {
      return nested.toString();
    }
  }
  return '';
}

String _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

String _stripHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
