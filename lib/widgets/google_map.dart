import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late GoogleMapController _mapController;

  final LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Example: San Francisco

  // Function to handle map creation and retrieve the map controller
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 10.0,
        ),
        mapType: MapType.normal, // You can change this to satellite, terrain, etc.
        myLocationEnabled: true, // Enable the user's location on the map
        zoomControlsEnabled: true, // Enable zoom controls
      ),
    );
  }
}
