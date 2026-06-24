import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../data/models/retailer.dart';

/// LocationService handles distance and fuel cost calculations
class LocationService {
  // Constants for Malaysia (approximate)
  static const double fuelPricePerLiter = 3.47; // RM (RON 95)
  static const double averageFuelEfficiency = 12.0; // km per liter

  // Fallback Location: Melaka (biased to user's local testing area)
  static const double fallbackLat = 2.2365657630638127;
  static const double fallbackLng = 102.28151321103672;

  /// Automatically find store coordinates using OpenStreetMap (Free)
  /// Uses [userLat] and [userLon] to bias results to the nearest branch
  static Future<Map<String, double>?> getStoreCoordinates(
    String storeName, {
    double? userLat,
    double? userLon,
  }) async {
    try {
      // First try: Full Name + Malaysia
      var coords = await _performSearch(storeName, userLat, userLon);
      if (coords != null) return coords;

      // Second try: Just the first word (e.g. "Mydin" instead of "Mydin USJ")
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

  static Future<Map<String, double>?> _performSearch(String queryText, double? lat, double? lon) async {
    try {
      final query = Uri.encodeComponent('$queryText Malaysia');
      var url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
      if (lat != null && lon != null) {
        url += '&lat=$lat&lon=$lon';
      }
      
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'SmartShopperApp/1.0',
      });

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
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

  /// Get current user position, with fallback
  static Future<Position?> getCurrentPosition() async {
    LocationPermission permission;

    // Check permission first to trigger the popup
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    // Now check if GPS is actually turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // You could prompt the user to turn on GPS here
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between user and a retailer in kilometers
  static double? calculateDistanceTo(Retailer retailer, {Position? currentPos}) {
    // Treat 0.0 or null as invalid/missing
    if (retailer.latitude == null || retailer.longitude == null || 
        retailer.latitude == 0.0 || retailer.longitude == 0.0) {
      return null;
    }
    
    if (currentPos == null) {
      return null; // Return null if position is still loading
    }
    
    final lat1 = currentPos.latitude;
    final lon1 = currentPos.longitude;
    
    return _haversine(lat1, lon1, retailer.latitude!, retailer.longitude!);
  }

  /// Calculate estimated fuel cost for a round trip to a retailer
  static double calculateGasCost(double distanceKm) {
    if (distanceKm <= 0) return 0.0;
    final totalDistance = distanceKm * 2;
    return (totalDistance / averageFuelEfficiency) * fuelPricePerLiter;
  }

  /// Haversine formula
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRadians(double degree) => degree * (pi / 180);
}
