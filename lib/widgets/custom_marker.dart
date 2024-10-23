import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Method to create a custom marker
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
      style: TextStyle(
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