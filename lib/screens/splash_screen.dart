import 'dart:async';
import 'package:familygps/storage/localstorage.dart';
import 'package:familygps/widgets/check_session.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _refreshGroupDataAndNavigate();
  }

  Future<void> _refreshGroupDataAndNavigate() async {
    try {
      await LocalStorage.refreshLocalStorageFromDatabase();
      // Only navigate after the refresh is complete
      if (mounted) {  // Check if the widget is still in the tree
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CheckSession())
        );
      }
    } catch (e) {
      print("Error during refresh: $e");
      // Handle error (e.g., show error message, retry option)
    }
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