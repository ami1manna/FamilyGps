import 'dart:async';
import 'package:familygps/utils/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:familygps/utils/store_data.dart'; // Ensure this import matches your project structure

class LocationService {
  static const double _movementThreshold = 1.0; // Movement threshold in meters
  static const double _updateRadius = 10.0; // Update radius in meters
  static Timer? _timer;
  static DateTime _lastUpdateTime = DateTime.now();
  static bool _isUpdating = false;
static Future<void> startLocationTracking() async {
  accelerometerEvents.listen((AccelerometerEvent event) async {
    if (_isMoving(event)) {
      if (_timer == null || !_timer!.isActive) {
        _timer = Timer(Duration(seconds: 1), () async {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await _saveLocation(position.latitude, position.longitude);
        });
      }
    } else {
      // Cancel the timer if there's no movement detected
      if (_timer != null && _timer!.isActive) {
        _timer!.cancel();
        _timer = null; // Reset the timer to indicate it's not active
      }
    }
  });
}

  static bool _isMoving(AccelerometerEvent event) {
    return event.x.abs() > _movementThreshold || 
           event.y.abs() > _movementThreshold || 
           event.z.abs() > _movementThreshold;
  }
static Future<void> _saveLocation(double lat, double long) async {
  // Prevent multiple simultaneous calls to this function
  if (_isUpdating) return;
  _isUpdating = true; // Set the flag to true

  // Retrieve last known location using the LocationServiceRepository
  Map<String, double?> lastLocation = await LocationServiceRepository.getLastLocation();
  double lastLat = lastLocation['lat'] ?? lat;
  double lastLong = lastLocation['long'] ?? long;

  // Calculate the distance from the last known location
  double distance = Geolocator.distanceBetween(lastLat, lastLong, lat, long);
  

  DateTime now = DateTime.now();
  Duration timeSinceLastUpdate = now.difference(_lastUpdateTime);

  

  // Only update if the distance is greater than the update radius and time limit
  if (distance > _updateRadius && timeSinceLastUpdate >= Duration(seconds: 30)) {
    // Save the new location using LocationServiceRepository
    await LocationServiceRepository.saveLastLocation(lat, long);

    String? userId = await LocationServiceRepository.getUserId();

    if (userId != null) {
      try {
        // Here you would call your method to update the user's location in the database
        await updateUserLocationInDatabase(lat, long, userId);
        
        // Update the last update time only after a successful update
        _lastUpdateTime = now;
        // print('Location updated to: $lat, $long');
      } catch (e) {
        // print('Failed to update user location: $e');
      }
    } else {
      print('User ID is null. Unable to update location.');
    }
  }
  // else {
  //   if (distance <= _updateRadius) {
  //     print('Location update skipped: within $_updateRadius meter radius.');
  //   } else {
  //     print('Location update skipped due to rate limiting.');
  //   }
  // }

  _isUpdating = false; // Reset the flag at the end
}
}