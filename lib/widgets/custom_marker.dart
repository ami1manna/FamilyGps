import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:familygps/models/users_locations.dart';

/// Method to create a custom marker with user initials and color based on the first letter
Future<BitmapDescriptor> createCustomMarker(String initials) async {
  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Define the size of the marker
  const double width = 100;
  const double height = 100;

  // Get color based on the first letter of the initials
  final color = _getColorFromInitial(initials.isNotEmpty ? initials[0] : 'A');

  // Draw a circular background
  final paint = Paint()..color = color;
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

/// Helper function to get a color based on the initial letter
Color _getColorFromInitial(String initial) {
  final colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
    Colors.amber,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.blueGrey,
    Colors.grey,
    Colors.indigoAccent,
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
  ];
  // Convert the initial to uppercase and get its ASCII value
  int asciiValue = initial.toUpperCase().codeUnitAt(0);
  
  // Use modulo to get an index within the range of our colors array
  int colorIndex = asciiValue % colors.length;
  
  return colors[colorIndex];
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