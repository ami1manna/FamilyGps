import 'dart:async';
import 'package:familygps/utils/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

class LocationService {
  static const double updateThreshold = 5.0; // Minimum distance in meters to trigger update
  static Timer? _foregroundTimer;
  static Position? _lastPosition; // Store last recorded position
  
  static Future<void> updateUserLocation(String userId) async {
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions denied');
          return;
        }
      }

      // Get current position
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // Check if location has changed significantly
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          currentPosition.latitude,
          currentPosition.longitude
        );

        // If distance is less than threshold, don't update
        if (distance < updateThreshold) {
          print('Location hasn\'t changed significantly. Skipping update.');
          return;
        }
      }

      // Update location in database
      await updateUserLocationInDatabase(
        currentPosition.latitude, 
        currentPosition.longitude,
        userId
      );
      
      // Store current position as last position
      print("Location updated: (${_lastPosition!.latitude}, ${_lastPosition!.longitude})");
      _lastPosition = currentPosition;
      
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  static void startForegroundUpdates(String userId) {
    stopForegroundUpdates(); // Stop any existing timer
    _foregroundTimer = Timer.periodic(Duration(seconds: 30), (_) { // Changed to 30 seconds
      updateUserLocation(userId);
    });
  }

  static void stopForegroundUpdates() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    resetLastPosition(); 
  }

  static Future<void> startBackgroundUpdates(String userId) async {
    await Workmanager().initialize(
      backLocationCallbackDispatcher,
      isInDebugMode: true
    );

    await Workmanager().registerPeriodicTask(
      "locationUpdate",
      "updateLocation",
      frequency: Duration(minutes: 15),
      inputData: {'userId': userId},
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> stopBackgroundUpdates() async {
    await Workmanager().cancelAll();
  }

  // Reset last position when needed (e.g., when service is stopped)
  static void  resetLastPosition() {
    _lastPosition = null;
  }
}

@pragma('vm:entry-point') // Important!
void backLocationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final userId = inputData?['userId'];
      if (userId != null) {
        await LocationService.updateUserLocation(userId);
        return true;
      }
      return false;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}