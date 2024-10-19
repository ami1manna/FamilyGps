// import 'package:familygps/utils/location.dart';
// import 'package:familygps/utils/store_data.dart';
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;


// void configureBackgroundGeolocation() {
//   // Configure background location service
//   bg.BackgroundGeolocation.onLocation((bg.Location location) async {
//     print('[location] - ${location.coords.latitude}, ${location.coords.longitude}');

//     // Save the location in Appwrite and local storage
//     String? userId = await LocationServiceRepository.getUserId();
//     if (userId != null) {
//       await updateUserLocationInDatabase(location.coords.latitude, location.coords.longitude, userId);
//     }
//   });

//   // Configure settings
//   bg.BackgroundGeolocation.ready(bg.Config(
//     desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
//     distanceFilter: 10,
//     stopOnTerminate: false,
//     startOnBoot: true,
//   )).then((bg.State state) {
//     if (!state.enabled) {
//       bg.BackgroundGeolocation.start();  // Start tracking location in the background
//     }
//   });
// }
