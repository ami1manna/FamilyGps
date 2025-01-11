import 'package:familygps/controllers/group_detail_operation.dart';
 
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/widgets/check_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
       

      // Get the current user
      final currentUser = ref.read(userProvider);
      print('Current user: $currentUser');
      if (currentUser != null) {
        // Reload all group and user data
        await DetailGroupOperation().reloadAllUserGroupData(currentUser.userid!);
      }

      // Update state to stop loading
      setState(() {
        _isLoading = false;
      });

      // Navigate to CheckSession
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CheckSession()),
      );
    } catch (error) {
      // Handle errors if any
      print('Error initializing app: $error');
      
      // Even if there's an error, navigate to CheckSession
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CheckSession()),
      );
    }
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}