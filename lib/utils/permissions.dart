import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> arePermissionsGranted() async {
  // Check if location permission is granted (either always or while in use)
  LocationPermission locationPermission = await Geolocator.checkPermission();
  bool isLocationPermissionGranted = locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse;

  // Check if background location permission is granted
  bool isBackgroundPermissionGranted = await Permission.locationAlways.isGranted;

  // Return true only if both permissions are granted
  return isLocationPermissionGranted && isBackgroundPermissionGranted;
}
