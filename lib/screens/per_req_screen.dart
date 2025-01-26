import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familygps/controllers/auth.dart';
import 'package:familygps/controllers/group_detail_operation.dart';
import 'package:familygps/models/user_model.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/utils/background_location.dart';
import 'package:familygps/utils/store_data.dart';
import 'package:familygps/utils/permissions.dart';
import 'dart:io';

class PermissionRequestScreen extends ConsumerStatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  _PermissionRequestScreenState createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends ConsumerState<PermissionRequestScreen> {
  bool locationPermissionGranted = false;
  bool backgroundPermissionGranted = false;
  bool notificationPermissionGranted = false;
  bool _isLoading = false;
  int androidSdkVersion = 0;

  @override
  void initState() {
    super.initState();
    _checkAndroidVersion();
    checkPermissions();
  }

  Future<void> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        androidSdkVersion = androidInfo.version.sdkInt;
      });
    }
  }

  Future<void> checkPermissions() async {
    try {
      // Check location permission
      LocationPermission locationPermission = await Geolocator.checkPermission();
      setState(() {
        locationPermissionGranted =
            locationPermission == LocationPermission.always ||
                locationPermission == LocationPermission.whileInUse;
      });

      // Check background permission
      bool backgroundPermission = await Permission.locationAlways.isGranted;
      setState(() {
        backgroundPermissionGranted = backgroundPermission;
      });

      // Check notification permission
      bool notificationPermission = await _checkNotificationPermission();
      setState(() {
        notificationPermissionGranted = notificationPermission;
      });

      // Redirect if all permissions are granted
      if (locationPermissionGranted &&
          backgroundPermissionGranted &&
          notificationPermissionGranted) {
        navigateToHomeScreen();
      }
    } catch (e) {
      print('Error checking permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking permissions: $e')),
      );
    }
  }

  Future<bool> _checkNotificationPermission() async {
    if (Platform.isAndroid && androidSdkVersion >= 33) {
      return await Permission.notification.isGranted;
    }
    return true; // For older Android versions
  }

  Future<void> requestLocationPermission() async {
    LocationPermission locationPermission =
        await Geolocator.requestPermission();

    if (locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse) {
      setState(() {
        locationPermissionGranted = true;
      });
    } else {
      await _showLocationPermissionRationaleDialog();
    }

    checkRedirect();
  }

  Future<void> requestBackgroundPermission() async {
    PermissionStatus status = await Permission.locationAlways.request();

    if (status.isGranted) {
      setState(() {
        backgroundPermissionGranted = true;
      });
    } else {
      await _showBackgroundPermissionRationaleDialog();
    }

    checkRedirect();
  }

  Future<void> requestNotificationPermission() async {
    if (Platform.isAndroid && androidSdkVersion >= 33) {
      // For Android 13 (SDK 33) and above
      PermissionStatus status = await Permission.notification.request();

      if (status.isGranted) {
        setState(() {
          notificationPermissionGranted = true;
        });
      } else {
        // Show a dialog explaining why the permission is needed
        await _showNotificationPermissionRationaleDialog();
      }
    } else {
      // For older Android versions
      setState(() {
        notificationPermissionGranted = true;
      });
    }

    checkRedirect();
  }

  Future<void> _showLocationPermissionRationaleDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('This app needs location permissions to:'),
                const SizedBox(height: 10),
                const Text('• Track your current location'),
                const Text('• Provide location-based services'),
                const SizedBox(height: 10),
                const Text('Please go to app settings and enable location permissions.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open App Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBackgroundPermissionRationaleDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Background Location Permission'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('This app needs background location permissions to:'),
                const SizedBox(height: 10),
                const Text('• Track your location when the app is closed'),
                const Text('• Provide continuous location updates'),
                const SizedBox(height: 10),
                const Text('Please go to app settings and enable background location.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open App Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNotificationPermissionRationaleDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification Permission'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('This app needs notification permissions to:'),
                const SizedBox(height: 10),
                const Text('• Send important location updates'),
                const Text('• Provide background tracking alerts'),
                const SizedBox(height: 10),
                const Text('Please go to app settings and enable notifications.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open App Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () { Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void checkRedirect() {
    if (locationPermissionGranted &&
        backgroundPermissionGranted &&
        notificationPermissionGranted) {
      navigateToHomeScreen();
    }
  }

  Future<void> navigateToHomeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the current user
      final fetchedUser  = await getUser ();
      
      if (fetchedUser  != null) {
        // Create UserModel
        UserModel newUser  = UserModel(
          name: fetchedUser .name,
          email: fetchedUser .email,
          password: fetchedUser .password ?? '',
          userid: fetchedUser .$id,
        );

        // Update user provider
        ref.read(userProvider.notifier).setUser (newUser );

        // Save user ID to local storage
        await LocationServiceRepository.saveUserId(fetchedUser .$id);

        // Reload all group and user data
        await DetailGroupOperation().reloadAllUserGroupData(fetchedUser .$id);

        // Start location updates
        LocationService.updateUserLocation(fetchedUser .$id);

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // If no user is found, navigate to signup
        Navigator.pushReplacementNamed(context, '/signup');
      }
    } catch (error) {
      print('Error during home screen navigation: $error');
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing user data: $error')),
      );

      setState(() {
        _isLoading = false;
      });

      // Fallback to signup in case of any error
      Navigator.pushReplacementNamed(context, '/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Permissions Required"),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'To use this app, we need the following permissions:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                locationPermissionGranted
                    ? Icons.check_circle
                    : Icons.location_on,
                color: locationPermissionGranted ? Colors.green : Colors.red,
              ),
              title: const Text("Location Permission"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: locationPermissionGranted
                    ? null
                    : () => requestLocationPermission(),
                child: const Text("Allow", style: TextStyle(fontSize: 15)),
              ),
            ),
            ListTile(
              leading: Icon(
                backgroundPermissionGranted
                    ? Icons.check_circle
                    : Icons.location_searching,
                color: backgroundPermissionGranted ? Colors.green : Colors.red,
              ),
              title: const Text("Background Location Permission"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: backgroundPermissionGranted
                    ? null
                    : () => requestBackgroundPermission(),
                child: const Text("Allow", style: TextStyle(fontSize: 15)),
              ),
            ),
            ListTile(
              leading: Icon(
                notificationPermissionGranted
                    ? Icons.check_circle
                    : Icons.notifications,
                color: notificationPermissionGranted ? Colors.green : Colors.red,
              ),
              title: Text(
                androidSdkVersion >= 33 
                  ? "Notification Permission" 
                  : "Notification Permission (Not Required)",
              ),
              trailing: androidSdkVersion >= 33 
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: notificationPermissionGranted
                        ? null
                        : () => requestNotificationPermission(),
                    child: const Text("Allow", style: TextStyle(fontSize: 15)),
                  )
                : null,
            ),
            const SizedBox(height: 32),
            if (locationPermissionGranted && backgroundPermissionGranted && notificationPermissionGranted)
              Center(
                child: ElevatedButton(
                  onPressed: () => navigateToHomeScreen(),
                  child: const Text("Continue to App"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}