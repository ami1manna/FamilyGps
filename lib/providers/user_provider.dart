
import 'package:familygps/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null); // Start with no user

  void setUser(UserModel user) {
    state = user; // Update the user state
    
  }

  void clearUser() {
    state = null; // Clear the user state
  }
}

// Create a provider for UserNotifier
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});