import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartshopper_mobile/services/location_service.dart';

/// Provider that holds the user's current GPS position.
/// Automatically updates when the app starts.
final userLocationProvider = StateProvider<Position?>((ref) {
  // We can also set up a stream here for live updates, 
  // but for a budget calculation, a single fetch is usually enough.
  LocationService.getCurrentPosition().then((pos) {
    if (pos != null) {
      ref.controller.state = pos;
    } else {
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
