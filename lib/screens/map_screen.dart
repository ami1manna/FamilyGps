import 'package:familygps/widgets/google_map.dart';
import 'package:familygps/widgets/home_bottom_sheet.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMapWidget(), // Custom Google Map widget
          HomeDraggableBottomSheet(), // Draggable bottom sheet
        ],
      ),
    );
  }
}
