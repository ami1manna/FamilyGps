import 'dart:async';
import 'package:familygps/utils/location.dart';
import 'package:familygps/utils/store_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationService {
  static const double updateThreshold = 5.0;
  static Position? _lastPosition;
  static final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();

  static Future<void> initializeService() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_service',
    'Location Service',
    description: 'Keeps track of your location',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await _backgroundService.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_service',
      initialNotificationTitle: 'Location Service',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
      // Update foreground service types to match manifest
      foregroundServiceTypes: [
        AndroidForegroundType.location,
        AndroidForegroundType.dataSync,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

@pragma('vm:entry-point')
static void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Location Service Active",
      content: "Tracking your location",
    );
  }

  // Initialize last position from stored location
  final storedLocation = await LocationServiceRepository.getLastLocation();
  if (storedLocation != null) {
   _lastPosition = Position(
    headingAccuracy: 0,
  latitude: storedLocation['lat'] as double,
  longitude: storedLocation['long'] as double,
  timestamp: DateTime.now(),
  accuracy: 0,
  altitude: 0,
  altitudeAccuracy: 0, // Add this line
  heading: 0,
  speed: 0,
  speedAccuracy: 0,
);
  }

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      final userId = await LocationServiceRepository.getUserId();
      if (userId != null) {
        try {
          Position currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

          if (_lastPosition != null) {
            double distance = Geolocator.distanceBetween(
                _lastPosition!.latitude,
                _lastPosition!.longitude,
                currentPosition.latitude,
                currentPosition.longitude);

            if (distance < updateThreshold) {
              print('Background: Location hasn\'t changed significantly. Skipping update.');
              return;
            }
          }

          // Only update if location has changed significantly
          await LocationServiceRepository.saveLastLocation(
              currentPosition.latitude, currentPosition.longitude);
          await updateUserLocationInDatabase(
              currentPosition.latitude, currentPosition.longitude, userId);
          _lastPosition = currentPosition;
          
          print("Background: Location updated: (${currentPosition.latitude}, ${currentPosition.longitude})");
        } catch (e) {
          print('Background: Error updating location: $e');
        }
      }
    }
  });
}
  static Future<void> updateUserLocation(String userId) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions denied');
          return;
        }
      }

      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            currentPosition.latitude,
            currentPosition.longitude);

        if (distance < updateThreshold) {
          print('Location hasn\'t changed significantly. Skipping update.');
          return;
        }
      }

      // Save location to local storage
      await LocationServiceRepository.saveLastLocation(
          currentPosition.latitude, currentPosition.longitude);

      await updateUserLocationInDatabase(
          currentPosition.latitude, currentPosition.longitude, userId);

      print(
          "Location updated: (${currentPosition.latitude}, ${currentPosition.longitude})");
      _lastPosition = currentPosition;
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  static Future<void> startBackgroundService() async {
    final isRunning = await _backgroundService.isRunning();
    if (!isRunning) {
      await _backgroundService.startService();
    }
  }

  static Future<void> stopBackgroundService() async {
    if (await _backgroundService.isRunning()) {
      _backgroundService.invoke('stopService');
    }
  }

  static Future<bool> isServiceRunning() async {
    return await _backgroundService.isRunning();
  }
}
