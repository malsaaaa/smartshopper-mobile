/// Utility functions for products and naming standardization
String standardizeProductName(String rawName) {
  final lower = rawName.toLowerCase();
  
  // 1. Buruh Cooking Oil
  if (lower.contains('buruh') && lower.contains('oil')) {
    if (lower.contains('1') && lower.contains('kg')) return 'Buruh Cooking Oil 1kg';
    if (lower.contains('2') && lower.contains('kg')) return 'Buruh Cooking Oil 2kg';
    if (lower.contains('3') && lower.contains('kg')) return 'Buruh Cooking Oil 3kg';
    if (lower.contains('5') && lower.contains('kg')) return 'Buruh Cooking Oil 5kg';
  }
  
  // 2. Knife Cooking Oil
  if (lower.contains('knife') && lower.contains('oil')) {
    if (lower.contains('1') && lower.contains('kg')) return 'Knife Cooking Oil 1kg';
    if (lower.contains('2') && lower.contains('kg')) return 'Knife Cooking Oil 2kg';
    if (lower.contains('3') && lower.contains('kg')) return 'Knife Cooking Oil 3kg';
    if (lower.contains('5') && lower.contains('kg')) return 'Knife Cooking Oil 5kg';
  }

  // 3. Red Eagle Cooking Oil
  if (lower.contains('red eagle') && lower.contains('oil')) {
    if (lower.contains('1') && lower.contains('kg')) return 'Red Eagle Cooking Oil 1kg';
    if (lower.contains('2') && lower.contains('kg')) return 'Red Eagle Cooking Oil 2kg';
    if (lower.contains('5') && lower.contains('kg')) return 'Red Eagle Cooking Oil 5kg';
  }
  
  // 4. Vesawit Cooking Oil
  if (lower.contains('vesawit') && lower.contains('oil')) {
    if (lower.contains('1') && lower.contains('kg')) return 'Vesawit Cooking Oil 1kg';
    if (lower.contains('2') && lower.contains('kg')) return 'Vesawit Cooking Oil 2kg';
    if (lower.contains('3') && lower.contains('kg')) return 'Vesawit Cooking Oil 3kg';
    if (lower.contains('5') && lower.contains('kg')) return 'Vesawit Cooking Oil 5kg';
  }

  // 5. Milo
  if (lower.contains('milo')) {
    if (lower.contains('1') && lower.contains('kg')) {
      if (lower.contains('1.8')) return 'Milo Activ-Go Powder 1.8kg';
      if (lower.contains('1.5')) return 'Milo Activ-Go Powder 1.5kg';
      return 'Milo Activ-Go Powder 1kg';
    }
    if (lower.contains('2') && lower.contains('kg')) return 'Milo Activ-Go Powder 2kg';
    if (lower.contains('400') && lower.contains('g')) return 'Milo Activ-Go Powder 400g';
    if (lower.contains('200') && lower.contains('ml')) return 'Milo UHT Chocolate Malt Drink 200ml';
    if (lower.contains('nugget')) return 'Milo Chocolate Nuggets';
  }
  
  // 6. Maggi Curry
  if (lower.contains('maggi') && lower.contains('curry')) {
    if (lower.contains('5') && (lower.contains('pack') || lower.contains('s') || lower.contains('79'))) {
      return 'Maggi 2-Minute Curry Noodles 5-Pack';
    }
  }
  
  // 7. Boh Tea
  if (lower.contains('boh') && lower.contains('tea')) {
    if (lower.contains('30') || lower.contains('teabag')) return 'Boh Cameron Highlands Tea 30s';
    if (lower.contains('100') || lower.contains('teabag')) return 'Boh Cameron Highlands Tea 100s';
  }
  
  // 8. Jati Rice
  if (lower.contains('jati') && lower.contains('rice')) {
    if (lower.contains('5') && lower.contains('kg')) return 'Jati Super Special Tempatan Rice 5kg';
    if (lower.contains('10') && lower.contains('kg')) return 'Jati Super Special Tempatan Rice 10kg';
  }
  
  // 9. Sunflower Basmathi Rice
  if (lower.contains('sunflower') && lower.contains('rice')) {
    if (lower.contains('5') && lower.contains('kg')) return 'Sunflower Basmathi Rice 5kg';
  }

  // Fallback: Clean up corporate prefixes and formatting
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
  
  // Standardize weight/size formatting: e.g. "3 kg" or "(3kg)" -> "3kg"
  clean = clean.replaceAllMapped(RegExp(r'\s*([0-9.]+)\s*(kg|g|l|ml)\b', caseSensitive: false), (match) {
    return ' ${match.group(1)}${match.group(2)}';
  });
  
  // Remove parentheses around sizes: e.g. "(1kg)" -> "1kg"
  clean = clean.replaceAllMapped(RegExp(r'\((.*?)\)'), (match) {
    return '${match.group(1)}';
  });
  
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

