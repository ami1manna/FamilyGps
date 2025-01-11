import 'package:familygps/controllers/auth.dart';
import 'package:familygps/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckSession extends ConsumerStatefulWidget {
  const CheckSession({super.key});

  @override
  ConsumerState<CheckSession> createState() => _CheckSessionState();
}

class _CheckSessionState extends ConsumerState<CheckSession> {
  @override
  void initState() {
    super.initState();

    // Check session and permissions
    checkSessionAndPermissions();
  }

  Future<void> checkSessionAndPermissions() async {
    try {
      bool sessionValid = await checkSession(); // Check if the session is valid
      
      if (sessionValid) {
        bool permissionGranted = await arePermissionsGranted(); // Check if all permissions are granted
        
        if (permissionGranted) {
          // Navigate to the home screen if session and permissions are valid
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Navigate to the permissions screen if permissions are not granted
          Navigator.pushReplacementNamed(context, '/permissions');
        }
      } else {
        // Navigate to the signup screen if session is not valid
        Navigator.pushReplacementNamed(context, '/signup');
      }
    } catch (error) {
      // Handle any errors during session or permission check
      print('Error checking session or permissions: $error');
      
      // Fallback to signup screen in case of any errors
      Navigator.pushReplacementNamed(context, '/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Checking Session...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}