import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:familygps/models/users_locations.dart';
import 'package:familygps/providers/locations_provider.dart';
import 'package:familygps/utils/store_data.dart';
import 'package:familygps/widgets/custom_marker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoogleMapWidget extends ConsumerStatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends ConsumerState<GoogleMapWidget> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Default to San Francisco
  Set<Marker> _markers = {};
  String _currentMapStyle = '';
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _loadLastKnownLocation();
  }

  Future<void> _loadMapStyles() async {
    try {
      // Load both dark and light styles
      String darkStyle = await rootBundle.loadString('assets/dark_map_style.json');
      String lightStyle = await rootBundle.loadString('assets/light_map_style.json');

      // Set the initial map style
      setState(() {
        _currentMapStyle = isDarkMode ? darkStyle : lightStyle;
      });
    } catch (e) {
      print('Error loading map styles: $e');
    }
  }

  Future<void> _loadLastKnownLocation() async {
    final lastLocation = await LocationServiceRepository.getLastLocation();
    if (lastLocation['lat'] != null && lastLocation['long'] != null) {
      setState(() {
        _initialPosition = LatLng(lastLocation['lat']!, lastLocation['long']!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMarkers(ref.read(userLocationProvider));
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateMarkers(List<UserLocation> locations) async {
    final markers = await generateMarkers(locations);
    setState(() {
      _markers = markers;
    });

    if (_mapController != null && locations.isNotEmpty) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(locations.first.latitude, locations.first.longitude),
        ),
      );
    }
  }

  void _toggleMapStyle() {
    setState(() {
      isDarkMode = !isDarkMode;
      _loadMapStyles().then((_) {
        if (_mapController != null) {
          _mapController!.setMapStyle(_currentMapStyle);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapController?.setMapStyle(_currentMapStyle);
              controller.moveCamera(
                CameraUpdate.newLatLng(_initialPosition),
              );
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15.0,
            ),
            markers: _markers,
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            tiltGesturesEnabled: true,
            trafficEnabled: true,
          ),
          
          // Location Update Listener
          Positioned(
            top: 10,
            right: 10,
            child: _buildLocationUpdateListener(),
          ),
          
          // Map Style Toggle Button
          Positioned(
            top: 70,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _toggleMapStyle,
              child: Icon(
                isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                color: isDarkMode ? Colors.orange : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUpdateListener() {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen<List<UserLocation>>(
          userLocationProvider,
          (previous, next) {
            if (next != previous) {
              _updateMarkers(next);
            }
          },
        );
        return const SizedBox.shrink();
      },
    );
  }
}