
import 'package:familygps/screens/activity_screen.dart';
import 'package:familygps/screens/group_detail_screen.dart';
import 'package:familygps/screens/home_screen.dart';
import 'package:familygps/screens/login_screen.dart';
import 'package:familygps/screens/per_req_screen.dart';
import 'package:familygps/screens/signup_screen.dart';
import 'package:familygps/screens/splash_screen.dart';
import 'package:familygps/utils/background_location.dart';
import 'package:familygps/widgets/check_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await LocationService.initializeService();
  
  runApp(ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'FamilyGps',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFA011F2), // Using #A011F2 as primary color

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA011F2), // AppBar background #A011F2
          foregroundColor: Colors.white, // AppBar text white
          elevation: 0,
        ),
        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // Button background white
            foregroundColor: const Color(0xFFA011F2), // Button text in #A011F2
            textStyle: const TextStyle(fontSize: 18),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
         textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
        ),

        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/check_session': (context) => const CheckSession(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/permissions': (context) => const PermissionRequestScreen(),
        '/groupDetail': (context) => GroupDetailScreen(),
        '/activity': (context) => ActivityScreen(),
      },
    );
  }
}
