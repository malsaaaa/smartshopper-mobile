/// Configuration settings for Google Maps integration in SmartShopper.
///
/// ⚠️  SETUP REQUIRED (For highest store mapping accuracy):
///   1. Go to https://console.cloud.google.com/
///   2. Enable the **Geocoding API** for your project.
///   3. Create an API Key and paste it below.
///
/// If no API key is provided here, the application will automatically 
/// fall back to OpenStreetMap (Nominatim), so it remains fully functional.
class GoogleMapsConfig {
  /// Paste your Google Maps API Key here.
  static const String apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';

  /// Returns true only when a real key has been configured.
  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
}
