import 'dart:async';
import 'package:flutter/material.dart';
import 'package:familygps/utils/location.dart';
import 'package:familygps/utils/store_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationService {
  static const double updateThreshold = 5.0; // Meters
  static Position? _lastPosition;
  static Timer? _locationUpdateTimer;

  // Background Service and Notification Plugins
  static final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification Channel Configuration
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'location_tracking_channel',
    'Location Tracking',
    description: 'Continuous location tracking service',
    importance: Importance.high,
  );

  // Initialize Location Service
  static Future<void> initializeService() async {
    // Notification Initialization
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification Tapped: ${details.payload}');
      },
    );

    // Create Notification Channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Configure Background Service
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channel.id,
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking is active',
        foregroundServiceNotificationId: 888,
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

  // iOS Background Handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  // Background Service Start Method
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Ensure Foreground Service on Android
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();

      // Persistent Notification Configuration
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
      );

      final NotificationDetails notificationDetails = 
          NotificationDetails(android: androidNotificationDetails);

      // Set Foreground Notification
      await service.setForegroundNotificationInfo(
        title: 'Location Tracking Active',
        content: 'Tracking your location continuously',
      );

      // Show Persistent Notification
      await _flutterLocalNotificationsPlugin.show(
        888,
        'Location Tracking Active',
        'Your location is being tracked',
        notificationDetails,
      );

      // Stop Service Listener
      service.on('stopService').listen((event) {
        _flutterLocalNotificationsPlugin.cancel(888);
        service.stopSelf();
      });
    }

    // Periodic Location Update
    _startPeriodicLocationUpdate(service);
  }

  // Start Periodic Location Update
  static void _startPeriodicLocationUpdate(ServiceInstance service) {
    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 5), 
      (timer) async {
        try {
          // Check User and Permissions
          final userId = await LocationServiceRepository.getUserId();
          if (userId == null) {
            debugPrint('No user ID found. Stopping location updates.');
            return;
          }

          // Check Location Permissions
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            debugPrint('Location permissions denied');
            return;
          }

          // Get Current Position
          Position currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Check Location Change Significance
          if (_isLocationSignificantlyChanged(currentPosition)) {
            // Update Location in Database
            await _updateLocationInDatabase(currentPosition, userId);
          }
        } catch (e) {
          debugPrint('Location Update Error: $e');
        }
      },
    );
  }

  // Check if Location has Changed Significantly
  static bool _isLocationSignificantlyChanged(Position currentPosition) {
    if (_lastPosition == null) return true;

    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    return distance >= updateThreshold;
  }

  // Update Location in Database
  static Future<void> _updateLocationInDatabase(
    Position currentPosition, 
    String userId
  ) async {
    try {
      // Save to Local Storage
      await LocationServiceRepository.saveLastLocation(
        currentPosition.latitude, 
        currentPosition.longitude
      );

      // Update in Database
      await updateUserLocationInDatabase(
        currentPosition.latitude, 
        currentPosition.longitude, 
        userId
      );

      // Update Last Position
      _lastPosition = currentPosition;

      debugPrint(
        'Location Updated: (${currentPosition.latitude}, ${currentPosition.longitude})'
      );
    } catch (e) {
      debugPrint('Database Location Update Error: $e');
    }
  }

  // Manual Location Update Method
  static Future<void> updateUserLocation(String userId) async {
    try {
      // Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return;
        }
      }

      // Get Current Position
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update Location
      await _updateLocationInDatabase(currentPosition, userId);
    } catch (e) {
      debugPrint('Manual Location Update Error: $e');
    }
  }

  // Start Background Service
  static Future<void> startBackgroundService() async {
    await initializeService();
    final isRunning = await _backgroundService.isRunning();
    if (!isRunning) {
      await _backgroundService.startService();
    }
  }

  // Stop Background Service
  static Future<void> stopBackgroundService() async {
    if (await _backgroundService.isRunning()) {
      _backgroundService.invoke('stopService');
      _locationUpdateTimer?.cancel();
      await _flutterLocalNotificationsPlugin.cancel(888);
    }
  }

  // Check if Service is Running
  static Future<bool> isServiceRunning() async {
    return await _backgroundService.isRunning();
  }
}