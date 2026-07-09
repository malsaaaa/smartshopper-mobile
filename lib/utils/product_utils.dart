/// Utility functions for products and naming standardization

// Extracts the first size token from a product name using strict word-boundary regex.
// Returns empty string if no size is found.
String _extractSizeToken(String lower) {
  // Pack multiplier: "6x200ml", "200ml x 6"
  final packRx1 = RegExp(
      r'\b([0-9]+(?:\.[0-9]+)?)\s*(kg|g|l|ml)\s*[x×*]\s*([0-9]+)\b',
      caseSensitive: false);
  final m1 = packRx1.firstMatch(lower);
  if (m1 != null) return '${m1.group(1)}${m1.group(2)!.toLowerCase()}x${m1.group(3)}';

  final packRx2 = RegExp(
      r'\b([0-9]+)\s*[x×*]\s*([0-9]+(?:\.[0-9]+)?)\s*(kg|g|l|ml)\b',
      caseSensitive: false);
  final m2 = packRx2.firstMatch(lower);
  if (m2 != null) return '${m2.group(2)}${m2.group(3)!.toLowerCase()}x${m2.group(1)}';

  // Count/serving: "18s", "30s", "100s", "25pcs", "5pack"
  final countRx = RegExp(r'\b([0-9]+)\s*(s|pcs|pack|sachets?|teabags?)\b', caseSensitive: false);
  final mc = countRx.firstMatch(lower);
  if (mc != null) return '${mc.group(1)}${mc.group(2)!.toLowerCase()}';

  // Standard weight/volume
  final singleRx = RegExp(r'\b([0-9]+(?:\.[0-9]+)?)\s*(kg|g|l|ml)\b', caseSensitive: false);
  final ms = singleRx.firstMatch(lower);
  if (ms != null) return '${ms.group(1)}${ms.group(2)!.toLowerCase()}';

  return '';
}

/// Normalizes a raw product name from any retailer into a canonical,
/// human-readable display name for cross-retailer comparison.
String standardizeProductName(String rawName) {
  final lower = rawName.toLowerCase().trim();
  final size = _extractSizeToken(lower);

  // ── 1. Buruh Cooking Oil ──────────────────────────────────────────────────
  if (lower.contains('buruh') && lower.contains('oil')) {
    return size.isNotEmpty ? 'Buruh Cooking Oil $size' : 'Buruh Cooking Oil';
  }

  // ── 2. Knife Cooking Oil ──────────────────────────────────────────────────
  if (lower.contains('knife') && lower.contains('oil')) {
    return size.isNotEmpty ? 'Knife Cooking Oil $size' : 'Knife Cooking Oil';
  }

  // ── 3. Red Eagle Cooking Oil ──────────────────────────────────────────────
  if (lower.contains('red eagle') && lower.contains('oil')) {
    return size.isNotEmpty ? 'Red Eagle Cooking Oil $size' : 'Red Eagle Cooking Oil';
  }

  // ── 4. Vesawit Cooking Oil ────────────────────────────────────────────────
  if (lower.contains('vesawit') && lower.contains('oil')) {
    return size.isNotEmpty ? 'Vesawit Cooking Oil $size' : 'Vesawit Cooking Oil';
  }

  // ── 5. Naturel Cooking Oil ────────────────────────────────────────────────
  if (lower.contains('naturel') && lower.contains('oil')) {
    return size.isNotEmpty ? 'Naturel Cooking Oil $size' : 'Naturel Cooking Oil';
  }

  // ── 6. Alif Cooking Oil ───────────────────────────────────────────────────
  if (lower.contains('alif') && lower.contains('oil')) {
    return size.isNotEmpty ? 'Alif Cooking Oil $size' : 'Alif Cooking Oil';
  }

  // ── 7. Generic Cooking Oil ────────────────────────────────────────────────
  if (lower.contains('cooking oil') && !lower.contains('buruh') &&
      !lower.contains('knife') && !lower.contains('red eagle') &&
      !lower.contains('vesawit') && !lower.contains('naturel') &&
      !lower.contains('alif')) {
    return size.isNotEmpty ? 'Cooking Oil $size' : 'Cooking Oil';
  }

  // ── 8. Milo ───────────────────────────────────────────────────────────────
  if (lower.contains('milo')) {
    // UHT/RTD carton
    if (lower.contains('uht') || lower.contains('rtd') ||
        lower.contains('ready to drink')) {
      return size.isNotEmpty ? 'Milo UHT Chocolate Malt Drink $size' : 'Milo UHT';
    }
    // 3-in-1 sachets
    if (lower.contains('3in1') || lower.contains('3 in 1')) {
      return size.isNotEmpty ? 'Milo 3-in-1 $size' : 'Milo 3-in-1';
    }
    // Fuze
    if (lower.contains('fuze') || lower.contains('fuse')) {
      return size.isNotEmpty ? 'Milo Fuze $size' : 'Milo Fuze';
    }
    // Soft pack / refill pouch — distinct from regular tin
    if (lower.contains('soft pack') || lower.contains('softpack') ||
        lower.contains('refill')) {
      return size.isNotEmpty ? 'Milo Activ-Go Soft Pack $size' : 'Milo Activ-Go Soft Pack';
    }
    // Nuggets
    if (lower.contains('nugget')) return 'Milo Chocolate Nuggets';
    // Cereal bar
    if (lower.contains('cereal bar')) {
      return size.isNotEmpty ? 'Milo Cereal Bar $size' : 'Milo Cereal Bar';
    }
    // Cereal
    if (lower.contains('cereal')) {
      return size.isNotEmpty ? 'Milo Cereal $size' : 'Milo Cereal';
    }
    // Biscuit
    if (lower.contains('biscuit')) {
      return size.isNotEmpty ? 'Milo Biscuit $size' : 'Milo Biscuit';
    }
    // Chocobar / ice cream
    if (lower.contains('chocobar') || lower.contains('choco bar')) {
      return size.isNotEmpty ? 'Milo Chocobar $size' : 'Milo Chocobar';
    }
    if (lower.contains('ice cream') || lower.contains('kaw ice cream')) {
      return size.isNotEmpty ? 'Milo Kaw Ice Cream $size' : 'Milo Kaw Ice Cream';
    }
    // Default: powder (tin)
    return size.isNotEmpty ? 'Milo Activ-Go Powder $size' : 'Milo Activ-Go Powder';
  }

  // ── 9. Maggi Curry ────────────────────────────────────────────────────────
  if (lower.contains('maggi') && lower.contains('curry')) {
    return size.isNotEmpty ? 'Maggi 2-Minute Curry Noodles $size' : 'Maggi Curry Noodles';
  }
  if (lower.contains('maggi') && lower.contains('chicken')) {
    return size.isNotEmpty ? 'Maggi 2-Minute Chicken Noodles $size' : 'Maggi Chicken Noodles';
  }

  // ── 10. Boh Tea ───────────────────────────────────────────────────────────
  if (lower.contains('boh') && lower.contains('tea')) {
    if (lower.contains('green')) {
      return size.isNotEmpty ? 'Boh Green Tea $size' : 'Boh Green Tea';
    }
    return size.isNotEmpty ? 'Boh Cameron Highlands Tea $size' : 'Boh Cameron Highlands Tea';
  }

  // ── 11. Jati Rice ─────────────────────────────────────────────────────────
  if (lower.contains('jati') && lower.contains('rice')) {
    return size.isNotEmpty ? 'Jati Super Special Tempatan Rice $size' : 'Jati Rice';
  }

  // ── 12. Sunflower Rice ────────────────────────────────────────────────────
  if (lower.contains('sunflower') && lower.contains('rice')) {
    return size.isNotEmpty ? 'Sunflower Basmathi Rice $size' : 'Sunflower Basmathi Rice';
  }

  // ── Fallback: clean up corporate prefixes and normalize formatting ─────────
  String clean = rawName.trim();

  // Remove common corporate prefixes
  final corporatePrefixes = [
    RegExp(r'^nestle\s+', caseSensitive: false),
    RegExp(r'^standard\s+', caseSensitive: false),
    RegExp(r'^ahmad\s+tea\s+', caseSensitive: false),
  ];
  for (final rx in corporatePrefixes) {
    clean = clean.replaceFirst(rx, '');
  }

  // Normalize weight/size formatting: "3 kg" or "(3kg)" → "3kg"
  clean = clean.replaceAllMapped(
      RegExp(r'\s*([0-9.]+)\s*(kg|g|l|ml)\b', caseSensitive: false),
      (match) => ' ${match.group(1)}${match.group(2)}');

  // Remove parentheses around sizes: "(1kg)" → "1kg"
  clean = clean.replaceAllMapped(RegExp(r'\((.*?)\)'), (match) => '${match.group(1)}');

  // Remove duplicate spaces
  clean = clean.replaceAll(RegExp(r'\s+'), ' ');

  return clean.trim();
}


/// Extract product brand in all caps from product name.
String extractBrand(String productName) {
  final lower = productName.toLowerCase();
  
  if (lower.contains('milo') || 
      lower.contains('nescafe') || 
      lower.contains('nescafé') || 
      lower.contains('nestle') || 
      lower.contains('nestlé')) {
    return 'NESTLE';
  }
  if (lower.contains('buruh')) return 'BURUH';
  if (lower.contains('faiza')) return 'FAIZA';
  if (lower.contains('knife')) return 'KNIFE';
  if (lower.contains('vesawit')) return 'VESAWIT';
  if (lower.contains('naturel')) return 'NATUREL';
  if (lower.contains('csr')) return 'CSR';
  if (lower.contains('maggi')) return 'MAGGI';
  if (lower.contains('boh')) return 'BOH';
  if (lower.contains('jati')) return 'JATI';
  if (lower.contains('aik cheong')) return 'AIK CHEONG';
  if (lower.contains('red eagle')) return 'RED EAGLE';
  if (lower.contains('sumo')) return 'SUMO';
  if (lower.contains('oyoshi')) return 'OYOSHI';
  if (lower.contains('royal gold')) return 'ROYAL GOLD';
  if (lower.contains('sunlight')) return 'SUNLIGHT';
  if (lower.contains('sunflower')) return 'SUNFLOWER';
  
  // Fallback: extract the first word in uppercase if it is long enough, else other
  final words = productName.trim().split(RegExp(r'\s+'));
  if (words.isNotEmpty) {
    final first = words[0].replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (first.length >= 3) return first;
  }
  
  return 'OTHER';
}

/// Extract product category (Beverages, Cooking Ingredients, Food) from name.
String extractCategory(String productName) {
  final lower = productName.toLowerCase();
  
  // 1. Beverages
  if (lower.contains('milo') ||
      lower.contains('tea') ||
      lower.contains('teabag') ||
      lower.contains('coffee') ||
      lower.contains('nescafe') ||
      lower.contains('nescafé') ||
      lower.contains('oyoshi') ||
      lower.contains('drink') ||
      lower.contains('beverage') ||
      lower.contains('aik cheong') ||
      lower.contains('teh') ||
      lower.contains('juice') ||
      lower.contains('jus') ||
      lower.contains('water') ||
      lower.contains('soda') ||
      lower.contains('carbonated')) {
    return 'Beverages';
  }
  
  // 2. Cooking Ingredients
  if (lower.contains('oil') ||
      lower.contains('cooking oil') ||
      lower.contains('sauce') ||
      lower.contains('ketchup') ||
      lower.contains('oyster') ||
      lower.contains('seasoning') ||
      lower.contains('salt') ||
      lower.contains('sugar') ||
      lower.contains('sweetener') ||
      lower.contains('cukup rasa') ||
      lower.contains('sambal') ||
      lower.contains('tumis') ||
      lower.contains('cube') ||
      lower.contains('kicap') ||
      lower.contains('margarine') ||
      lower.contains('butter') ||
      lower.contains('rempah') ||
      lower.contains('tomato sauce') ||
      lower.contains('tomato paste') ||
      lower.contains('chili') ||
      lower.contains('chilli') ||
      lower.contains('dishwashing') ||
      lower.contains('liquid')) {
    return 'Cooking Ingredients';
  }
  
  // 3. Food
  if (lower.contains('rice') ||
      lower.contains('basmathi') ||
      lower.contains('basmati') ||
      lower.contains('grain') ||
      lower.contains('noodle') ||
      lower.contains('instant noodle') ||
      lower.contains('maggi') ||
      lower.contains('curry') ||
      lower.contains('chicken stock') ||
      lower.contains('ayam') ||
      lower.contains('stock cube') ||
      lower.contains('vermicelli') ||
      lower.contains('pasta') ||
      lower.contains('spaghetti') ||
      lower.contains('macaroni') ||
      lower.contains('bread') ||
      lower.contains('biscuit') ||
      lower.contains('flour') ||
      lower.contains('sunflower basmathi') ||
      lower.contains('sumo')) {
    return 'Food';
  }
  
  return 'Food'; // Fallback
}

/// Parses a document ID or string into a stable 32-bit positive integer.
/// If the string is already a valid integer, it is parsed directly.
/// Otherwise, it uses a stable polynomial rolling hash (DJB2) to generate a
/// consistent positive 31-bit integer.
int parseStableId(String idStr) {
  final clean = idStr.trim();
  final parsed = int.tryParse(clean);
  if (parsed != null) return parsed;
  
  int hash = 5381;
  for (int i = 0; i < clean.length; i++) {
    hash = ((hash << 5) + hash) + clean.codeUnitAt(i);
    hash = hash & 0x7FFFFFFF; // Keep it as a positive 31-bit integer
  }
  return hash;
}

/// Safely parses a dynamic field into a DateTime.
/// Supports both Firestore Timestamp (via dynamic toDate() call) and ISO 8601 strings.
DateTime parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  
  // Try calling toDate() dynamically (for Firestore Timestamp)
  try {
    return val.toDate();
  } catch (_) {
    try {
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    } catch (_) {}
  }
  
  return DateTime.now();
}

/// Public, shared product match-key function used for cross-retailer deduplication
/// and grouping throughout the app (product_provider, smart_recommendations, etc.)
///
/// Two products that should be compared side-by-side MUST produce the same key.
/// The key encodes: brand + product variant type + exact size.
String getProductMatchKey(String name) {
  final lower = name.toLowerCase().trim();

  // Size helper (strict word-boundary)
  String sz(String text) => _extractSizeToken(text);

  // ── Milo ──────────────────────────────────────────────────────────────────
  if (lower.contains('milo')) {
    final size = sz(lower);
    String variant;
    if (lower.contains('3in1') || lower.contains('3 in 1') || lower.contains('three in one')) {
      variant = '3in1';
    } else if (lower.contains('fuze') || lower.contains('fuse')) {
      variant = 'fuze';
    } else if (lower.contains('nugget')) {
      variant = 'nuggets';
    } else if (lower.contains('cereal bar') || lower.contains('cereal_bar')) {
      variant = 'cerealbar';
    } else if (lower.contains('cereal')) {
      variant = 'cereal';
    } else if (lower.contains('biscuit')) {
      variant = 'biscuit';
    } else if (lower.contains('chocobar') || lower.contains('choco bar')) {
      variant = 'chocobar';
    } else if (lower.contains('ice cream') || lower.contains('kaw')) {
      variant = 'icecream';
    } else if (lower.contains('uht') || lower.contains('rtd') ||
        lower.contains('ready to drink') ||
        (lower.contains('drink') && !lower.contains('powder'))) {
      variant = 'uht';
    } else if (lower.contains('soft pack') || lower.contains('softpack') ||
        lower.contains('refill')) {
      variant = 'softpack';
    } else {
      variant = 'powder';
    }
    return 'milo_${variant}_$size';
  }

  // ── Cooking Oils (branded) ────────────────────────────────────────────────
  final oilBrands = [
    'buruh', 'knife', 'red eagle', 'vesawit', 'alif',
    'naturel', 'saji', 'tropical', 'rasaku', 'topvalu',
  ];
  for (final brand in oilBrands) {
    if (lower.contains(brand) && lower.contains('oil')) {
      return '${brand.replaceAll(' ', '')}_oil_${sz(lower)}';
    }
  }
  if (lower.contains('cooking oil')) return 'cookingoil_${sz(lower)}';

  // ── Maggi ─────────────────────────────────────────────────────────────────
  if (lower.contains('maggi')) {
    final size = sz(lower);
    String flavour;
    if (lower.contains('asam laksa') || lower.contains('laksa')) {
      flavour = 'laksa';
    } else if (lower.contains('tomyam') || lower.contains('tom yam')) {
      flavour = 'tomyam';
    } else if (lower.contains('chicken') || lower.contains('ayam')) {
      flavour = 'chicken';
    } else if (lower.contains('kari') || lower.contains('curry')) {
      flavour = 'curry';
    } else if (lower.contains('anchovies') || lower.contains('ikan bilis')) {
      flavour = 'anchovies';
    } else if (lower.contains('sambal')) {
      flavour = 'sambal';
    } else if (lower.contains('cube') || lower.contains('stock')) {
      flavour = 'stock';
    } else {
      flavour = 'other';
    }
    return 'maggi_${flavour}_$size';
  }

  // ── Boh Tea ───────────────────────────────────────────────────────────────
  if (lower.contains('boh')) {
    final size = sz(lower);
    String type = 'regular';
    if (lower.contains('green')) type = 'green';
    else if (lower.contains('earl grey')) type = 'earlgrey';
    return 'boh_${type}_$size';
  }

  // ── Rice (branded) ────────────────────────────────────────────────────────
  final riceBrands = ['jati', 'sunflower', 'seri murni', 'faiza', 'royal gold'];
  for (final brand in riceBrands) {
    if (lower.contains(brand) && lower.contains('rice')) {
      return '${brand.replaceAll(' ', '')}_rice_${sz(lower)}';
    }
  }

  // ── Aik Cheong / Nescafé ─────────────────────────────────────────────────
  if (lower.contains('aik cheong') || lower.contains('aik_cheong')) {
    return 'aikcheong_${sz(lower)}';
  }
  if (lower.contains('nescafe') || lower.contains('nescafé')) {
    return 'nescafe_${sz(lower)}';
  }

  // ── Fallback (preserves size in key) ─────────────────────────────────────
  return lower
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
}
