/// Gemini API configuration for SmartShopper AI features.
///
/// ⚠️  SETUP REQUIRED:
///   1. Visit https://aistudio.google.com/app/apikey
///   2. Create a free API key (takes ~30 seconds)
///   3. Replace the placeholder string below with your key
///
/// The free tier is generous enough for all in-app AI features.
class GeminiConfig {
  /// Paste your Gemini API key here.
  static const String apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  /// Model to use — Gemini 3.5 Flash is the latest high-speed production model.
  static const String model = 'gemini-3.5-flash';

  /// Max tokens for recommendation replies (needs space for thinking tokens + text).
  static const int maxOutputTokens = 2048;

  /// Request timeout so the UI is never blocked for too long.
  static const Duration timeout = Duration(seconds: 12);

  /// Returns true only when a real key has been configured.
  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE';
}
