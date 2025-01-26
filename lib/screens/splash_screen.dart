import 'package:appwrite/models.dart';
import 'package:familygps/controllers/auth.dart';
import 'package:familygps/controllers/group_detail_operation.dart';
import 'package:familygps/models/user_model.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/utils/background_location.dart';
import 'package:familygps/utils/permissions.dart';
import 'package:familygps/utils/store_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Update loading message
      setState(() {
        _loadingMessage = 'Checking session...';
      });

      // Check session validity
      bool sessionValid = await checkSession();
      
      if (!sessionValid) {
        // Navigate to signup if session is invalid
        _navigateTo('/signup');
        return;
      }

      // Update loading message
      setState(() {
        _loadingMessage = 'Checking permissions...';
      });

      // Check permissions
      bool permissionGranted = await arePermissionsGranted();
      
      if (!permissionGranted) {
        // Navigate to permissions screen
        _navigateTo('/permissions');
        return;
      }

      // Update loading message
      setState(() {
        _loadingMessage = 'Fetching user data...';
      });

      // Fetch user
      final fetchedUser = await getUser();
      
      if (fetchedUser != null) {
        // Create UserModel
        UserModel newUser = UserModel(
          name: fetchedUser.name,
          email: fetchedUser.email,
          password: fetchedUser.password,
          userid: fetchedUser.$id,
        );

        // Update user provider
        ref.read(userProvider.notifier).setUser(newUser);

        // Save user ID to local storage
        await LocationServiceRepository.saveUserId(fetchedUser.$id);

        // Update loading message
        setState(() {
          _loadingMessage = 'Loading user data...';
        });

        // Reload all group and user data
        await DetailGroupOperation().reloadAllUserGroupData(fetchedUser.$id);

        // Start location updates
        LocationService.updateUserLocation(fetchedUser.$id);
      }

      // Navigate to home screen
      _navigateTo('/home');

    } catch (error) {
      // Handle errors
      print('Error during app initialization: $error');
      
      // Navigate to signup as fallback
      _navigateTo('/signup');
    }
  }

  void _navigateTo(String routeName) {
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}