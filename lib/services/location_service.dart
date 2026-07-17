import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../data/models/retailer.dart';
import '../config/google_maps_config.dart';

/// LocationService handles distance and fuel cost calculations
class LocationService {
  // Fuel price constants for Malaysia
  static const double fuelPricePerLiter = 3.47; // RM per liter (RON 95)
  static const double averageFuelEfficiency = 12.0; // km per liter

  // Default fallback location: Melaka
  static const double fallbackLat = 2.2365657630638127;
  static const double fallbackLng = 102.28151321103672;

  // Cache to store resolved coordinates to avoid redundant API queries.
  // Key format: "retailerName_userLat_userLon" (user coords rounded to 2 decimals)
  static final Map<String, Map<String, double>> _coordsCache = {};

  // Timestamp of the last OpenStreetMap request to enforce rate limits
  static DateTime _lastOsmRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Find store coordinates using Google Maps (with OpenStreetMap fallback)
  static Future<Map<String, double>?> getStoreCoordinates(
    String storeName, {
    double? userLat,
    double? userLon,
  }) async {
    try {
      // Normalize online-only retailer names like "myAEON2go" to "AEON"
      // so we can resolve physical outlets.
      String queryName = storeName;
      if (storeName.toLowerCase().contains('aeon')) {
        queryName = 'AEON';
      }

      // Check cache first (using user coords rounded to 2 decimal places to capture minor moves)
      String? cacheKey;
      if (userLat != null && userLon != null) {
        final latKey = userLat.toStringAsFixed(2);
        final lonKey = userLon.toStringAsFixed(2);
        cacheKey = '${queryName}_${latKey}_$lonKey';
        if (_coordsCache.containsKey(cacheKey)) {
          print('📦 [LocationService] Cache hit for $queryName at ($latKey, $lonKey): ${_coordsCache[cacheKey]}');
          return _coordsCache[cacheKey];
        }
      }

      Map<String, double>? coords;

      // ── 1. Google Maps Geocoding API (Primary, highly accurate POIs) ─────
      if (GoogleMapsConfig.isConfigured) {
        coords = await _performGoogleSearch(queryName, userLat, userLon);
        if (coords == null) {
          // Try searching by the first word (e.g. just "Mydin" or "Lotus's")
          final shortName = queryName.split(' ')[0];
          if (shortName != queryName) {
            coords = await _performGoogleSearch(shortName, userLat, userLon);
          }
        }
      }

      // ── 2. OpenStreetMap Nominatim API (Fallback) ────────────────────────
      if (coords == null) {
        coords = await _performSearch(queryName, userLat, userLon);
        if (coords == null) {
          final shortName = queryName.split(' ')[0];
          if (shortName != queryName) {
            coords = await _performSearch(shortName, userLat, userLon);
          }
        }
      }

      // Save to cache if resolved
      if (coords != null && cacheKey != null) {
        _coordsCache[cacheKey] = coords;
      }

      return coords;
    } catch (e) {
      return null;
    }
  }

  /// Get address components for reverse geocoding from Google Geocoding API
  static Future<List<dynamic>> _getGoogleAddressComponents(double lat, double lon) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=${GoogleMapsConfig.apiKey}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (results.isNotEmpty) {
          return results[0]['address_components'] as List? ?? [];
        }
      }
    } catch (_) {}
    return [];
  }

  /// Extract localized suburb, town, neighborhood, or locality names
  static List<String> _extractLocalKeywords(List<dynamic> components) {
    final List<String> keywords = [];
    final targetTypes = {
      'neighborhood',
      'sublocality_level_1',
      'sublocality',
      'locality',
      'administrative_area_level_2'
    };

    final excludeWords = {
      'taman', 'jalan', 'jln', 'lorong', 'desa', 'persiaran', 'lebuh', 'lebuhraya',
      'malaysia', 'melaka', 'malacca', 'selangor', 'johor', 'penang', 'perak', 
      'kedah', 'pahang', 'terengganu', 'kelantan', 'perlis', 'sabah', 'sarawak',
      'kuala', 'lumpur', 'putrajaya', 'labuan', 'negeri', 'sembilan', 'bandar',
      'utama', 'jaya', 'permai', 'indah', 'sentral', 'center', 'centre', 'plaza',
      'mall', 'hypermarket', 'supermarket', 'mart', 'wholesale', 'store', 'outlet',
      'kampung', 'kg', 'flat', 'apartment', 'condo', 'residence', 'residences',
      'block', 'blok', 'no', 'lot', 'tingkat', 'level', 'floor', 'road', 'street'
    };

    for (final comp in components) {
      final types = comp['types'] as List?;
      if (types != null && types.any((t) => targetTypes.contains(t))) {
        final name = comp['long_name'] as String? ?? '';
        
        // Clean prefix phrases (e.g. "Taman Desa Duyong" -> "Duyong")
        var cleaned = name;
        final prefixes = [
          RegExp(r'^taman\s+desa\s+', caseSensitive: false),
          RegExp(r'^taman\s+iks\s+', caseSensitive: false),
          RegExp(r'^taman\s+', caseSensitive: false),
          RegExp(r'^jalan\s+', caseSensitive: false),
          RegExp(r'^lorong\s+', caseSensitive: false),
          RegExp(r'^persiaran\s+', caseSensitive: false),
          RegExp(r'^bandar\s+', caseSensitive: false),
        ];
        for (final pattern in prefixes) {
          cleaned = cleaned.replaceFirst(pattern, '');
        }
        cleaned = cleaned.trim();
        
        if (cleaned.length > 2 && !excludeWords.contains(cleaned.toLowerCase())) {
          if (!keywords.contains(cleaned)) {
            keywords.add(cleaned);
          }
        }
      }
    }
    return keywords;
  }

  /// Perform Google Maps Geocoding API lookup
  static Future<Map<String, double>?> _performGoogleSearch(String queryText, double? lat, double? lon) async {
    try {
      if (lat != null && lon != null) {
        // 1. Reverse geocode user position to extract local area keywords
        final components = await _getGoogleAddressComponents(lat, lon);
        final keywords = _extractLocalKeywords(components);
        
        // 2. Try queries using local keywords (e.g. "Lotus's, Duyong, Malaysia")
        for (final keyword in keywords) {
          final addressQuery = '$queryText, $keyword, Malaysia';
          final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(addressQuery)}&key=${GoogleMapsConfig.apiKey}';
          
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final List results = data['results'] ?? [];
            
            if (results.isNotEmpty) {
              final first = results[0];
              final types = first['types'] as List?;
              final isPOI = types != null && (
                types.contains('establishment') || 
                types.contains('point_of_interest') || 
                types.contains('store') ||
                types.contains('shopping_mall')
              );
              
              if (isPOI) {
                final geom = first['geometry'] as Map<String, dynamic>?;
                final loc = geom?['location'] as Map<String, dynamic>?;
                final itemLat = (loc?['lat'] as num?)?.toDouble();
                final itemLon = (loc?['lng'] as num?)?.toDouble();
                
                if (itemLat != null && itemLon != null) {
                  // Ensure it's not the generic center point of Malaysia (4.21, 101.97)
                  final distToMY = (itemLat - 4.210484).abs() + (itemLon - 101.975766).abs();
                  if (distToMY > 0.5) {
                    print('📍 [Google Maps] Dynamic Query: "$addressQuery" -> Resolved POI: ${first['formatted_address']} ($itemLat, $itemLon)');
                    return {
                      'latitude': itemLat,
                      'longitude': itemLon,
                    };
                  }
                }
              }
            }
          }
        }
      }

      // 3. Fallback: Generic search with bounds biasing
      final query = Uri.encodeComponent('$queryText Malaysia');
      var url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=${GoogleMapsConfig.apiKey}';
      if (lat != null && lon != null) {
        final bounds = '${lat - 0.35},${lon - 0.35}|${lat + 0.35},${lon + 0.35}';
        url += '&bounds=$bounds';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (results.isNotEmpty) {
          final first = results[0];
          final types = first['types'] as List?;
          final isPOI = types != null && (
            types.contains('establishment') || 
            types.contains('point_of_interest') || 
            types.contains('store') ||
            types.contains('shopping_mall')
          );
          
          if (isPOI) {
            final geom = first['geometry'] as Map<String, dynamic>?;
            final loc = geom?['location'] as Map<String, dynamic>?;
            if (loc != null) {
              final itemLat = (loc['lat'] as num).toDouble();
              final itemLon = (loc['lng'] as num).toDouble();
              
              // Check that the returned point is not the generic national center of Malaysia
              final distToMY = (itemLat - 4.210484).abs() + (itemLon - 101.975766).abs();
              if (distToMY > 0.5) {
                return {
                  'latitude': itemLat,
                  'longitude': itemLon,
                };
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Perform API search on OpenStreetMap
  static Future<Map<String, double>?> _performSearch(String queryText, double? lat, double? lon) async {
    try {
      final query = Uri.encodeComponent('$queryText Malaysia');
      
      // 1. Try a bounded search first (within ~40km radius of the user)
      if (lat != null && lon != null) {
        const double offset = 0.35; // ~40km bounding box radius
        final left = lon - offset;
        final right = lon + offset;
        final top = lat + offset;
        final bottom = lat - offset;
        
        final boundedUrl = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=25&viewbox=$left,$top,$right,$bottom&bounded=1';
        final coords = await _fetchAndFindClosest(boundedUrl, lat, lon, queryText);
        if (coords != null) return coords;
      }
      
      // 2. Fallback: Unbounded search (anywhere in Malaysia)
      final fallbackUrl = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=25';
      return await _fetchAndFindClosest(fallbackUrl, lat, lon, queryText);
    } catch (_) {}
    return null;
  }

  /// Helper to fetch Nominatim results and resolve the closest coordinates
  static Future<Map<String, double>?> _fetchAndFindClosest(
    String url,
    double? userLat,
    double? userLon,
    String queryText,
  ) async {
    try {
      // Enforce rate limit (1.2 seconds between sequential Nominatim calls to prevent blocks)
      final now = DateTime.now();
      final difference = now.difference(_lastOsmRequestTime);
      if (difference.inMilliseconds < 1200) {
        final waitTime = 1200 - difference.inMilliseconds;
        print('⏱️ [Nominatim] Rate limit protection: waiting ${waitTime}ms...');
        await Future.delayed(Duration(milliseconds: waitTime));
      }
      _lastOsmRequestTime = DateTime.now();

      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'SmartShopperApp/1.0',
      });

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          if (userLat != null && userLon != null) {
            double minDistance = double.infinity;
            Map<String, double>? closestCoords;
            
            for (final item in results) {
              final itemLat = double.tryParse(item['lat'] ?? '');
              final itemLon = double.tryParse(item['lon'] ?? '');
              if (itemLat != null && itemLon != null) {
                final dist = _haversine(userLat, userLon, itemLat, itemLon);
                if (dist < minDistance) {
                  minDistance = dist;
                  closestCoords = {
                    'latitude': itemLat,
                    'longitude': itemLon,
                  };
                }
              }
            }
            if (closestCoords != null) {
              print('📍 User coordinates: ($userLat, $userLon) | Closest $queryText: (${closestCoords['latitude']}, ${closestCoords['longitude']}) - Distance: ${minDistance.toStringAsFixed(2)}km');
              return closestCoords;
            }
          }
          
          // Fallback to first result if user location is null
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
      // 1. Try to get last known position first (instantaneous, high success rate)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      // 2. Fetch active coordinates with medium accuracy (cell/WiFi)
      // which resolves instantly without waiting for a hardware GPS lock.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
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

  /// Get city/town name from coordinates using Nominatim reverse geocoding API
  static Future<String> getCityName(double lat, double lon) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'SmartShopperApp/1.0',
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? 'Unknown Location';
          return city.toString();
        }
      }
    } catch (_) {}
    return 'Unknown Location';
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
