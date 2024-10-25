import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:familygps/models/users_locations.dart';

/// Method to create a custom marker with user initials
Future<BitmapDescriptor> createCustomMarker(String initials) async {
  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Define the size of the marker
  const double width = 100;
  const double height = 100;

  // Draw a circular background
  final paint = Paint()..color = Colors.blue;
  canvas.drawCircle(Offset(width / 2, height / 2), width / 2, paint);

  // Draw the initials
  final textPainter = TextPainter(
    text: TextSpan(
      text: initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: ui.TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
  );

  // Convert the canvas to an image
  final picture = recorder.endRecording();
  final img = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Create a BitmapDescriptor from the image
  return BitmapDescriptor.fromBytes(pngBytes);
}

/// Function to generate markers with custom icons for each location
Future<Set<Marker>> generateMarkers(List<UserLocation> locations) async {
  final Set<Marker> markers = {};
  
  for (var location in locations) {
    // Extract initials from the name
    String initials = _getInitials(location.name);

    // Create the custom marker icon with initials
    BitmapDescriptor customIcon = await createCustomMarker(initials);

    // Add the marker with the custom icon
    markers.add(
      Marker(
        markerId: MarkerId(location.userId),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: location.name),
        icon: customIcon, // Set the custom icon here
      ),
    );
  }

  return markers;
}

/// Helper function to get the initials from the user's name
String _getInitials(String name) {
  List<String> words = name.split(' ');
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'; // First letter of first and last name
  } else if (words.isNotEmpty) {
    return words[0][0].toUpperCase(); // If only one name part, take first letter
  }
  return ''; // Return empty string if no valid name
}
