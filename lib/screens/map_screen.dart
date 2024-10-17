import 'package:familygps/utils/permissions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState()  {
    super.initState();
    
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('Map Screen'),
    );
  }
}