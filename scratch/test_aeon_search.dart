import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final term = 'cooking oil';
  final url = 'https://myaeon2go.com/products/search/${Uri.encodeComponent(term)}';
  print('Fetching search results for "$term" from: $url');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'referer': 'https://myaeon2go.com/',
        'accept-language': 'en-US,en;q=0.9',
      },
    );

    print('Status Code: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Failed to load page. Body: ${response.body.substring(0, 200)}');
      return;
    }

    final html = response.body;
    print('HTML loaded, length: ${html.length}');

    // Extract PhoenixAppState
    const startKeyword = "let PhoenixAppState = '";
    final startIndex = html.indexOf(startKeyword);
    if (startIndex == -1) {
      print('Error: let PhoenixAppState not found in HTML!');
      return;
    }

    final valueStart = startIndex + startKeyword.length;
    final valueEnd = html.indexOf("';", valueStart);
    if (valueEnd == -1) {
      print('Error: End of PhoenixAppState string not found!');
      return;
    }

    final base64Str = html.substring(valueStart, valueEnd);
    print('Extracted base64 string length: ${base64Str.length}');

    final decodedBytes = base64.decode(base64Str);
    final decodedStr = utf8.decode(decodedBytes);
    print('Decoded string length: ${decodedStr.length}');

    final decoded = jsonDecode(decodedStr);
    print('Successfully parsed as JSON!');

    final items = _extractVariantList(decoded);
    print('Total products extracted: ${items.length}');

    if (items.isNotEmpty) {
      print('\nSample Products:');
      for (var i = 0; i < (items.length < 5 ? items.length : 5); i++) {
        final item = items[i];
        final name = item['nameText'] ?? item['name'] ?? item['extendedName'] ?? 'Unknown';
        final price = item['salePrice'] ?? item['price'] ?? 0.0;
        print(' - $name (Price: RM $price)');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}

List<Map<String, dynamic>> _extractVariantList(dynamic decoded) {
  final items = <Map<String, dynamic>>[];

  void walk(dynamic value) {
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      
      // Look for variant map
      final variant = map['variant'];
      if (variant is Map && variant.containsKey('nameText')) {
        items.add(variant.cast<String, dynamic>());
        return;
      }

      // Keep walking
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
