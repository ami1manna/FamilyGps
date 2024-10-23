import 'package:familygps/controllers/user_operation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Create a state notifier for handling user data
class NameEmailNotifier extends StateNotifier<List<String>> {
  final UsersDatabaseOperations usersDatabaseOperations;

  NameEmailNotifier(this.usersDatabaseOperations) : super([]);

  // Function to set user data
  Future<void> setUsersList() async {
    final users = await usersDatabaseOperations.fetchUsersList();
    state = users; // Updates the provider state with the list of users
    print("FROM NOTIFIER${state[1]}");
  }

  // Function to get the user list
  List<String> getUsersList() {
    return state;
  }


}

// Riverpod provider to handle users' data fetching and storing
final nameEmailProvider = StateNotifierProvider<NameEmailNotifier, List<String>>((ref) {
  final usersDatabaseOperations = UsersDatabaseOperations();
  return NameEmailNotifier(usersDatabaseOperations);
});
