import 'dart:async';
import 'package:familygps/providers/name_email_provider.dart';
import 'package:familygps/widgets/check_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Call the function to set the users list from the provider
    ref.read(nameEmailProvider.notifier).setUsersList().then((_) {
      // After fetching the users, navigate to the CheckSession screen
      Timer(const Duration(seconds: 3), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CheckSession()),
        );
      });
    }).catchError((error) {
      // Handle errors if any
      print('Error fetching user data: $error');
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CheckSession()),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 250,
          height: 250,
        ),
      ),
    );
  }
}
