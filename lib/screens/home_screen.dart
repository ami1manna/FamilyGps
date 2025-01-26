import 'package:appwrite/models.dart';
import 'package:familygps/controllers/auth.dart';
import 'package:familygps/models/user_model.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/screens/group_screen.dart';
import 'package:familygps/screens/map_screen.dart';
import 'package:familygps/screens/profile_screen.dart';
import 'package:familygps/utils/background_location.dart';

import 'package:familygps/utils/store_data.dart';
import 'package:familygps/widgets/Toast.dart';
import 'package:familygps/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const MapScreen(),
    const GroupScreen(),
    // const ActivityScreen(),
    const ProfileScreen(),
  ];

   
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
     LocationService.initializeService().then((_) {
          LocationService.startBackgroundService();
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationService.stopBackgroundService();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
   
    // switch (state) {
    //   case AppLifecycleState.paused:
    //   case AppLifecycleState.inactive:
    //     // Initialize service before starting
    //     LocationService.initializeService().then((_) {
    //       LocationService.startBackgroundService();
    //     });
    //     break;
    //   case AppLifecycleState.resumed:
    //     LocationService.stopBackgroundService();
        
    //     break;
    //   default:
    //     break;
    // }
  } 
 
 
 
  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index; // Update the selected tab
    });
  }

  void _showError(String message) {
    Toast.show(context, message, ToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: Center(
                child: Text(
                  "Welcome ${user!.name[0].toUpperCase()}${user.name.substring(1).toLowerCase()}",
                  textAlign: TextAlign.center,
                ),
              ),
        elevation: 10.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
        ),
      ),
      body:    Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _pages, // Display the relevant page
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavBar(onTabChange: _onTabChange),
    );
  }
}