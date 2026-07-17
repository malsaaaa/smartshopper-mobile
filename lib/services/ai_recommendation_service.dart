import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smartshopper_mobile/config/gemini_config.dart';

/// Alternative brand suggestion recommended by AI.
class AiBrandSwap {
  final String originalItem;
  final String suggestedAlternative;
  final String savingsReason;
  const AiBrandSwap({
    required this.originalItem,
    required this.suggestedAlternative,
    required this.savingsReason,
  });
}


/// Recipe bundle suggestions
class AiRecipeBundle {
  final String recipeName;
  final List<String> ingredients;
  const AiRecipeBundle({required this.recipeName, required this.ingredients});
}

/// Price entry passed to the AI for context.
class AiPriceEntry {
  final String retailer;
  final double price;
  const AiPriceEntry(this.retailer, this.price);
}

/// Cart item summary passed to the AI for basket-level advice.
class AiCartItem {
  final String productName;
  final int quantity;
  final List<AiPriceEntry> prices;
  const AiCartItem({
    required this.productName,
    required this.quantity,
    required this.prices,
  });
}

/// Service that calls the Gemini API to generate concise, actionable
/// shopping recommendations based on live scraped price data.
///
/// All methods return [null] silently on any error (network, auth, timeout)
/// so the UI always has a graceful fallback — the app never crashes because
/// the AI is unavailable.
class AiRecommendationService {
  static GenerativeModel? _model;

  /// Lazily initialise the Gemini model on first call.
  static GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: GeminiConfig.model,
      apiKey: GeminiConfig.apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: GeminiConfig.maxOutputTokens,
        temperature: 0.4, // lower = more factual, less creative
      ),
    );
    return _model!;
  }

  // ── Search tab ──────────────────────────────────────────────────────────────

  /// Generate a short deal tip for a search query given the live scraped prices.
  ///
  /// [query]  — what the user searched for (e.g. "Milo", "Cooking Oil")
  /// [prices] — list of (retailer, price) pairs from the scrape results
  ///
  /// Returns a 1–3 sentence tip, or null on failure.
  static Future<String?> getSearchRecommendation({
    required String query,
    required List<AiPriceEntry> prices,
  }) async {
    if (!GeminiConfig.isConfigured) return null;
    if (prices.isEmpty) return null;

    try {
      final priceLines = prices
          .map((e) => '  - ${e.retailer}: RM ${e.price.toStringAsFixed(2)}')
          .join('\n');

      final prompt = '''
You are a Malaysian grocery price comparison assistant for the SmartShopper app.
A user searched for "$query". Here are the live prices scraped from Malaysian retailers today:

$priceLines

Write a helpful, friendly 1–3 sentence recommendation in English. Mention:
- Which retailer has the best price and by how much
- Whether the price difference is significant enough to change stores
- One quick tip if relevant (e.g. bulk-buying, brand alternatives)

Be concise. Use RM for currency. Do not invent prices — only use the data above.
''';

      final response = await _getModel()
          .generateContent([Content.text(prompt)])
          .timeout(GeminiConfig.timeout);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (e) {
      // Silent failure — AI is a nice-to-have, not critical
      return null;
    }
  }

  // ── Shopping / cart tab ─────────────────────────────────────────────────────

  /// Generate a basket-level insight for items currently in the user's cart.
  ///
  /// [items]         — cart items with per-retailer prices
  /// [monthlyBudget] — user's set budget in RM, or null if not configured
  ///
  /// Returns a 2–4 sentence tip, or null on failure.
  static Future<String?> getCartRecommendation({
    required List<AiCartItem> items,
    double? monthlyBudget,
  }) async {
    if (!GeminiConfig.isConfigured) return null;
    if (items.isEmpty) return null;

    try {
      final itemLines = items.map((item) {
        final prices = item.prices
            .map((p) => '${p.retailer} RM ${p.price.toStringAsFixed(2)}')
            .join(', ');
        return '  - ${item.productName} ×${item.quantity} → $prices';
      }).join('\n');

      final budgetLine = monthlyBudget != null
          ? 'The user has a monthly grocery budget of RM ${monthlyBudget.toStringAsFixed(0)}.'
          : 'The user has not set a budget.';

      final prompt = '''
You are a Malaysian grocery shopping assistant for the SmartShopper app.
$budgetLine

The user's shopping cart contains:
$itemLines

Write a helpful 2–4 sentence basket recommendation in English. Cover:
- Which retailer gives the cheapest total basket
- How much money the user saves by choosing the best store
- A quick budget or planning tip if relevant

Be concise and friendly. Use RM for currency. Only reference the prices listed above.
''';

      final response = await _getModel()
          .generateContent([Content.text(prompt)])
          .timeout(GeminiConfig.timeout);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (e) {
      return null;
    }
  }

  /// Generate a list of recommended cheaper brand swaps for items in the user's cart.
  ///
  /// Returns a list of [AiBrandSwap] objects, or null on failure.
  static Future<List<AiBrandSwap>?> getAlternativeBrandSuggestions({
    required List<AiCartItem> items,
  }) async {
    if (!GeminiConfig.isConfigured) return null;
    if (items.isEmpty) return null;

    try {
      final itemLines = items.map((item) {
        return '  - ${item.productName}';
      }).join('\n');

      final prompt = '''
You are a Malaysian grocery brand comparison assistant for the SmartShopper app.
The user's shopping cart contains the following items:
$itemLines

Your task is to review this shopping list and suggest cheaper local brand alternatives (like swapping premium imported brands for local Malaysian brands, or swapping major brand names for high-quality retailer house brands such as Lotus's House Brand or Mydin Choice).

Output ONLY a JSON array of objects representing recommended brand swaps. Do not include any introductory or concluding text, and do not wrap the response in any markdown code block markers.

Each object in the array MUST contain exactly these keys:
- "originalItem": The name of the original product in the cart
- "suggestedAlternative": The name of the recommended cheaper brand alternative
- "savingsReason": A short, friendly 1-sentence explanation of why they save money (mentioning the approximate price saving range if you know it)

If there are no clear cheaper brand alternatives for any items in the list, return an empty array [].
''';

      final response = await _getModel()
          .generateContent([Content.text(prompt)])
          .timeout(GeminiConfig.timeout);

      var responseText = response.text?.trim();
      if (responseText == null || responseText.isEmpty) return null;

      // Clean markdown code block formatting if returned by the model
      if (responseText.startsWith('```')) {
        final lines = responseText.split('\n');
        if (lines.isNotEmpty && lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        responseText = lines.join('\n').trim();
      }

      final decoded = json.decode(responseText);
      if (decoded is List) {
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          return AiBrandSwap(
            originalItem: map['originalItem'] as String? ?? '',
            suggestedAlternative: map['suggestedAlternative'] as String? ?? '',
            savingsReason: map['savingsReason'] as String? ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return null;
    }
  }


  /// Generate a recipe bundle suggestion based on search query.
  static Future<AiRecipeBundle?> getRecipeBundle({
    required String query,
  }) async {
    if (!GeminiConfig.isConfigured) return null;
    if (query.trim().isEmpty) return null;

    try {
      final prompt = '''
You are a Malaysian recipe assistant for the SmartShopper app.
The user is searching for "$query". If this is a cooking ingredient (e.g. chicken, fish, potato, rice, flour, onion, garlic), suggest one popular Malaysian dish they might be cooking (e.g. Nasi Lemak, Chicken Curry, Roti Canai, Char Kway Teow).
Then suggest 2 to 3 other ingredients (specific grocery items, e.g. "Coconut Milk", "Curry Powder") needed to complete that recipe.

Output ONLY a JSON object. Do not include any introductory or concluding text, and do not wrap the response in any markdown code block markers.

The JSON object MUST contain exactly these keys:
- "recipeName": The name of the suggested Malaysian dish (e.g., "Chicken Curry").
- "ingredients": A JSON list of 2 to 3 ingredients needed for the recipe. Keep the ingredient names simple (1-3 words max, e.g., "Coconut Milk").

If the query is clearly not a cooking ingredient (e.g., laundry detergent, diapers, shampoo, Milo), return a JSON object with empty values: {"recipeName": "", "ingredients": []}.
''';

      final response = await _getModel()
          .generateContent([Content.text(prompt)])
          .timeout(GeminiConfig.timeout);

      var responseText = response.text?.trim();
      if (responseText == null || responseText.isEmpty) return null;

      // Resilient JSON substring extraction
      final startIndex = responseText.indexOf('{');
      final endIndex = responseText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        responseText = responseText.substring(startIndex, endIndex + 1);
      } else {
        if (responseText.startsWith('```')) {
          final lines = responseText.split('\n');
          if (lines.isNotEmpty && lines.first.startsWith('```')) {
            lines.removeAt(0);
          }
          if (lines.isNotEmpty && lines.last.startsWith('```')) {
            lines.removeLast();
          }
          responseText = lines.join('\n').trim();
        }
      }

      final decoded = json.decode(responseText);
      if (decoded is Map<String, dynamic>) {
        final recipe = decoded['recipeName'] as String? ?? '';
        final ingList = decoded['ingredients'] as List? ?? [];
        if (recipe.isEmpty || ingList.isEmpty) return null;
        return AiRecipeBundle(
          recipeName: recipe,
          ingredients: ingList.map((e) => e.toString()).toList(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
