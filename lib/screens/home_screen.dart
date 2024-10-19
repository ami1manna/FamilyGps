import 'package:appwrite/models.dart';
import 'package:familygps/controllers/auth.dart';
import 'package:familygps/models/user_model.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/screens/map_screen.dart';
import 'package:familygps/utils/sensors.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const MapScreen(),
    const MapScreen(),
    const MapScreen(),
    const MapScreen(),
  ];

  bool isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final user = await getUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          isLoading = false;
          setUserState();
        });

        // Save user ID to local storage
        print(user.$id);
        await LocationServiceRepository.saveUserId(_currentUser!.$id);
        await LocationService.startLocationTracking(); // Start location tracking

      } else {
        setState(() {
          isLoading = false;
        });
        _showError("Failed to fetch user data");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showError("Error occurred: $error");
    }
  }

  void setUserState() {
    UserModel newUser = UserModel(
      name: _currentUser!.name,
      email: _currentUser!.email,
      password: _currentUser!.password,
      userid: _currentUser!.$id,
    );

    // Update the user state
    ref.read(userProvider.notifier).setUser(newUser);
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
        title: isLoading
            ? const Text('Loading...')
            : Center(
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('No user found'))
              : Column(
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
