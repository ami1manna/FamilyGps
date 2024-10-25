
import 'package:familygps/controllers/auth.dart';
import 'package:familygps/controllers/user_operation.dart';
import 'package:familygps/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null); // Start with no user

  void setUser(UserModel user) {
    state = user; // Update the user state
    
  }

    void updateUserName(String newName) async {
    if (state != null) {
      try {
        updateUserDetails(state!.userid!, name: newName);
        
        state = UserModel(
          name: newName,
          email: state!.email,
          password: state!.password,
          userid: state!.userid,
          lat: state!.lat,
          long: state!.long,
        );
      } catch (e) {
        print('Error updating user name: $e');
        // Handle the error (e.g., show an error message to the user)
      }
    }
  }

  
  void clearUser() {
    state = null; // Clear the user state
  }

}

// Create a provider for UserNotifier
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});