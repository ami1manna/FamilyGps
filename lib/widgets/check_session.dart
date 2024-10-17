import 'package:appwrite/appwrite.dart';
import 'package:familygps/controllers/auth.dart';
import 'package:familygps/utils/permissions.dart';
import 'package:flutter/material.dart';

class CheckSession extends StatefulWidget {
  const CheckSession({super.key});

  @override
  State<CheckSession> createState() => _CheckSessionState();
}

class _CheckSessionState extends State<CheckSession> {
  @override
  void initState() {
    super.initState();

    // Check session and permissions
    checkSessionAndPermissions();
  }

  Future<void> checkSessionAndPermissions() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
