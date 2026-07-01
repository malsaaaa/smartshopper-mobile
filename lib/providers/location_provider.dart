import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartshopper_mobile/services/location_service.dart';

/// Provider that holds the user's current GPS position.
/// Automatically updates when the app starts.
final userLocationProvider = StateProvider<Position?>((ref) {
  // Check permission status without triggering a prompt on app startup
  Geolocator.checkPermission().then((permission) {
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      // Fetch current location if permission is already granted
      LocationService.getCurrentPosition().then((pos) {
        if (pos != null) {
          ref.controller.state = pos;
        }
      });
    } else {
      // Set to fallback location immediately without requesting permissions
      ref.controller.state = Position(
        latitude: LocationService.fallbackLat,
        longitude: LocationService.fallbackLng,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  });
  return null;
});
