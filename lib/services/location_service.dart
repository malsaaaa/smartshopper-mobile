import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../data/models/retailer.dart';

/// LocationService handles distance and fuel cost calculations
class LocationService {
  // Fuel price constants for Malaysia
  static const double fuelPricePerLiter = 3.47; // RM per liter (RON 95)
  static const double averageFuelEfficiency = 12.0; // km per liter

  // Default fallback location: Melaka
  static const double fallbackLat = 2.2365657630638127;
  static const double fallbackLng = 102.28151321103672;

  /// Find store coordinates using OpenStreetMap API
  static Future<Map<String, double>?> getStoreCoordinates(
    String storeName, {
    double? userLat,
    double? userLon,
  }) async {
    try {
      // First try: Search full name with "Malaysia"
      var coords = await _performSearch(storeName, userLat, userLon);
      if (coords != null) return coords;

      // Second try: Search just the first word (e.g., "Mydin")
      final shortName = storeName.split(' ')[0];
      if (shortName != storeName) {
        coords = await _performSearch(shortName, userLat, userLon);
        if (coords != null) return coords;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Perform API search on OpenStreetMap
  static Future<Map<String, double>?> _performSearch(String queryText, double? lat, double? lon) async {
    try {
      // Encode query and add "Malaysia" to restrict results
      final query = Uri.encodeComponent('$queryText Malaysia');
      // Create request URL returning JSON
      var url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
      
      // Add user location to bias search results
      if (lat != null && lon != null) {
        url += '&lat=$lat&lon=$lon';
      }
      
      // Send HTTP GET request with required User-Agent
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'SmartShopperApp/1.0',
      });

      // If request is successful
      if (response.statusCode == 200) {
        // Decode JSON response list
        final List results = json.decode(response.body);
        // Return coordinates from the first match
        if (results.isNotEmpty) {
          return {
            'latitude': double.parse(results[0]['lat']),
            'longitude': double.parse(results[0]['lon']),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get current user coordinates with permission handling
  static Future<Position?> getCurrentPosition() async {
    LocationPermission permission;

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if not granted
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    // Return null if permission is permanently blocked
    if (permission == LocationPermission.deniedForever) return null;

    // Check if device GPS service is turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    try {
      // Fetch coordinates with high accuracy and 5s timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance to a retailer in kilometers
  static double? calculateDistanceTo(Retailer retailer, {Position? currentPos}) {
    // Return null if store coordinates are invalid or missing
    if (retailer.latitude == null || retailer.longitude == null || 
        retailer.latitude == 0.0 || retailer.longitude == 0.0) {
      return null;
    }
    
    // Return null if user position is not loaded yet
    if (currentPos == null) {
      return null;
    }
    
    final lat1 = currentPos.latitude;
    final lon1 = currentPos.longitude;
    
    // Calculate distance using Haversine formula
    return _haversine(lat1, lon1, retailer.latitude!, retailer.longitude!);
  }

  /// Calculate estimated round-trip fuel cost
  static double calculateGasCost(double distanceKm) {
    if (distanceKm <= 0) return 0.0;
    // Double the distance for round trip
    final totalDistance = distanceKm * 2;
    // Formula: (Distance / Efficiency) * Fuel Price
    return (totalDistance / averageFuelEfficiency) * fuelPricePerLiter;
  }

  /// Haversine formula to find distance on a sphere
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    // Earth radius in kilometers
    const r = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // Convert degree to radian
  static double _toRadians(double degree) => degree * (pi / 180);
}
