import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/utils/store_data.dart';
import 'package:familygps/widgets/custom_marker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194);
  final Map<String, Marker> _markers = {};
  StreamSubscription<RealtimeMessage>? _subscription;
  final Client client = Client();
  late final Realtime realtime;
  bool _isLoading = true;
   late final Databases databases;

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeAppwrite() {
    client
        .setEndpoint(END_POINT)
        .setProject(PROJECT_ID)
        .setSelfSigned(status: true);
    realtime = Realtime(client);
    databases = Databases(client);
  }

  void listenToDocumentChanges(String databaseId, String collectionId, String documentId) {
    final channel = 'databases.$databaseId.collections.$collectionId.documents.$documentId';
    print("Subscribing to document changes at $channel");

    _subscription = realtime.subscribe([channel]).stream.listen(
      (response) {
        print('Received realtime update: ${response.payload}');
        double? lat = double.tryParse(response.payload['lat'].toString());
        double? long = double.tryParse(response.payload['long'].toString());

        if (lat != null && long != null) {
          print('Updating marker with new position: $lat, $long');
          _updateMarker(documentId, LatLng(lat, long),'AM');
        } else {
          print('No valid location data found for document $documentId');
        }
      },
      onError: (error) {
        print('Error occurred during real-time subscription: $error');
        _showErrorSnackBar('Failed to get location updates');
      },
    );
  }

  void _subscribeToLocationUpdates() async {
    try {
      String userId = await LocationServiceRepository.getUserId() as String;
      print("User ID: $userId");

      if (userId.isNotEmpty) {
        listenToDocumentChanges(DATABASE_ID, USERS_COLLECTION_ID, userId);
        await _fetchInitialLocation(userId);
      } else {
        print('User ID is empty or null');
        _showErrorSnackBar('Failed to get user information');
      }
    } catch (e) {
      print('Error setting up location updates: $e');
      _showErrorSnackBar('Failed to set up location tracking');
    } finally {
      setState(() {
        _isLoading = false;
      });
     }
  }

  Future<void> _fetchInitialLocation(String userId) async {
    try {
      
      final document = await databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
      );
      double? lat = double.tryParse(document.data['lat'].toString());
      double? long = double.tryParse(document.data['long'].toString());

      if (lat != null && long != null) {
        _updateMarker(userId, LatLng(lat, long),'AM');
      } else {
        print('No valid location data found for user $userId');
      }
    } catch (e) {
      print('Error fetching initial location: $e');
      _showErrorSnackBar('Failed to fetch initial location');
    }
  }

 Future<void> _updateMarker(String id, LatLng position, String initials) async {
  print('Updating marker $id to position: $position');
  
  // Generate the custom marker
  BitmapDescriptor markerIcon = await createCustomMarker(initials);

  setState(() {
    _markers[id] = Marker(
      markerId: MarkerId(id),
      position: position,
      icon: markerIcon, // Use the custom marker icon
      infoWindow: InfoWindow(title: 'User  $id'),
    );
  });

  // Smoothly move camera to the updated marker with a zoom level of 15
  _mapController?.animateCamera(
    CameraUpdate.newLatLngZoom(position, 15.0),
  );
}

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 10.0,
              ),
              markers: Set<Marker>.of(_markers.values),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: false,

            ),
    );
  }
}