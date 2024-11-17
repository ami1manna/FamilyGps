import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // For location permission handling

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  _PermissionRequestScreenState createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool locationPermissionGranted = false;
  bool backgroundPermissionGranted = false;
  bool notificationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
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
    bool notificationPermission = await Permission.notification.isGranted;
    setState(() {
      notificationPermissionGranted = notificationPermission;
    });

    // Redirect if all permissions are granted
    if (locationPermissionGranted &&
        backgroundPermissionGranted &&
        notificationPermissionGranted) {
      navigateToHomeScreen();
    }
  }

  Future<void> requestLocationPermission() async {
    LocationPermission locationPermission =
        await Geolocator.requestPermission();

    if (locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse) {
      setState(() {
        locationPermissionGranted = true;
      });
    }

    checkRedirect();
  }

  Future<void> requestBackgroundPermission() async {
    PermissionStatus status = await Permission.locationAlways.request();

    if (status.isGranted) {
      setState(() {
        backgroundPermissionGranted = true;
      });
    }

    checkRedirect();
  }

  Future<void> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      setState(() {
        notificationPermissionGranted = true;
      });
    }

    checkRedirect();
  }

  void checkRedirect() {
    if (locationPermissionGranted &&
        backgroundPermissionGranted &&
        notificationPermissionGranted) {
      navigateToHomeScreen();
    }
  }

  void navigateToHomeScreen() {
    Navigator.pushReplacementNamed(context, '/home'); // Navigate to HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permissions Required")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              'To use this app, we need the following permissions:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                locationPermissionGranted
                    ? Icons.check_circle
                    : Icons.location_on,
                color: locationPermissionGranted ? Colors.green : Colors.red,
              ),
              title: Text("Location Permission"),
              
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: locationPermissionGranted
                    ? null
                    : () {
                        requestLocationPermission();
                      },
                child: Text("Allow", style: TextStyle(fontSize: 15)),
              ),
            ),
            ListTile(
              leading: Icon(
                backgroundPermissionGranted
                    ? Icons.check_circle
                    : Icons.location_searching,
                color: backgroundPermissionGranted ? Colors.green : Colors.red,
              ),
              title: Text("Background Location Permission"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: backgroundPermissionGranted
                    ? null
                    : () {
                        requestBackgroundPermission();
                      },
               child: Text("Allow", style: TextStyle(fontSize: 15)),
              ),
            ),
            ListTile(
              leading: Icon(
                notificationPermissionGranted
                    ? Icons.check_circle
                    : Icons.notifications,
                color:
                    notificationPermissionGranted ? Colors.green : Colors.red,
              ),
              title: Text("Notification Permission"),
             trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                  
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: notificationPermissionGranted
                    ? null
                    : () {
                        requestNotificationPermission();
                      },
               child: Text( "Allow", style: TextStyle(fontSize: 15)),
              ),
            ),
            SizedBox(height: 32),
            if (locationPermissionGranted &&
                backgroundPermissionGranted &&
                notificationPermissionGranted)
              Center(
                child: ElevatedButton(
                  onPressed: navigateToHomeScreen,
                  child: Text("Continue to App"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
