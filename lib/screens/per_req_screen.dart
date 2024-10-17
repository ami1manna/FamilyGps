import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // For location permission handling

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({Key? key}) : super(key: key);

  @override
  _PermissionRequestScreenState createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool locationPermissionGranted = false;
  bool backgroundPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    // Check location permission
    LocationPermission locationPermission = await Geolocator.checkPermission();
    setState(() {
      locationPermissionGranted = locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse;
    });

    // Check background permission
    bool backgroundPermission = await Permission.locationAlways.isGranted;
    setState(() {
      backgroundPermissionGranted = backgroundPermission;
    });

    // Redirect if both permissions are granted
    if (locationPermissionGranted && backgroundPermissionGranted) {
      navigateToHomeScreen();
    }
  }

  Future<void> requestLocationPermission() async {
    LocationPermission locationPermission = await Geolocator.requestPermission();

    if (locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse) {
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

  void checkRedirect() {
    if (locationPermissionGranted && backgroundPermissionGranted) {
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
                locationPermissionGranted ? Icons.check_circle : Icons.location_on,
                color: locationPermissionGranted ? Colors.green : Colors.red,
              ),
              title: Text("Location Permission"),
              subtitle: Text("Allow the app to access your location."),
              trailing: ElevatedButton(
                onPressed: locationPermissionGranted
                    ? null
                    : () {
                        requestLocationPermission();
                      },
                child: Text(locationPermissionGranted ? "Granted" : "Allow"),
              ),
            ),
            ListTile(
              leading: Icon(
                backgroundPermissionGranted ? Icons.check_circle : Icons.location_searching,
                color: backgroundPermissionGranted ? Colors.green : Colors.red,
              ),
              title: Text("Background Location Permission"),
              subtitle: Text("Allow the app to access your location in the background."),
              trailing: ElevatedButton(
                onPressed: backgroundPermissionGranted
                    ? null
                    : () {
                        requestBackgroundPermission();
                      },
                child: Text(backgroundPermissionGranted ? "Granted" : "Allow" ),
              ),
            ),
            SizedBox(height: 32),
            if (locationPermissionGranted && backgroundPermissionGranted)
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
