import 'dart:async';
import 'package:familygps/models/users_locations.dart';
import 'package:familygps/providers/locations_provider.dart';
import 'package:familygps/widgets/Toast.dart';
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
  final LatLng _initialPosition =
      const LatLng(37.7749, -122.4194); // San Francisco
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              controller.moveCamera(
                CameraUpdate.newLatLngZoom(_initialPosition, 10.0),
              );
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 10.0,
            ),
            markers: _markers,
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            tiltGesturesEnabled: true,
            trafficEnabled: true,
            
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _buildLocationUpdateListener(),
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
        return const SizedBox
            .shrink(); // This widget doesn't render anything visible
      },
    );
  }
}
