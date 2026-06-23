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

  final fields = '''
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
  product_labels
}
''';

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
        'fields': fields,
      },
    },
  ];

  final url = '$apiBaseUrl/products?body=${Uri.encodeComponent(jsonEncode(payload))}';
  
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
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
