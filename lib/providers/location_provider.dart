import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartshopper_mobile/services/location_service.dart';

/// Provider that holds the user's current GPS position.
/// Automatically updates when the app starts.
final userLocationProvider = StateProvider<Position?>((ref) {
  // We can also set up a stream here for live updates, 
  // but for a budget calculation, a single fetch is usually enough.
  LocationService.getCurrentPosition().then((pos) {
    ref.controller.state = pos;
  });
  return null;
});
