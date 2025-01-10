import 'package:familygps/models/hive_models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveServiceUserDetails {
  static const String _userBoxName = 'user_details';

  // Initialize Hive service with the application's directory
  Future<void> initHive() async {
    try {
      // Use path_provider to get the application documents directory
      final appDocumentDir = await getApplicationDocumentsDirectory();

      // Initialize Hive with the path
      await Hive.initFlutter(appDocumentDir.path);

      // Register adapters BEFORE opening any boxes
      _registerAdapters();

      // Open the box to ensure it's accessible before any operations
      await Hive.openBox<UserDetailModel>(_userBoxName);
    } catch (e) {
      print('Error initializing Hive: $e');
      // Optionally, you might want to delete the existing Hive database
      await Hive.deleteBoxFromDisk(_userBoxName);
      // Retry initialization
      await initHive();
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserDetailModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GroupDetailModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(StringListAdapter());
    }
  }

  // Save user details to the Hive box
  Future<void> saveUserDetails(UserDetailModel userDetails) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      await box.put(userDetails.userId, userDetails);
    } catch (e) {
      print('Error saving user details: $e');
      rethrow;
    }
  }

  // Retrieve user details from the Hive box
  UserDetailModel? getUserDetails(String userId) {
    final box = Hive.box<UserDetailModel>(_userBoxName);
    return box.get(userId);
  }

  // Delete user details from the Hive box
  Future<void> deleteUserDetails(String userId) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      await box.delete(userId);
    } catch (e) {
      print('Error deleting user details: $e');
      rethrow;
    }
  }

  // Update existing user details
  Future<void> updateUserDetails(UserDetailModel updatedUserDetails) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      await box.put(updatedUserDetails.userId, updatedUserDetails);
    } catch (e) {
      print('Error updating user details: $e');
      rethrow;
    }
  }

  // Get all users
  List<UserDetailModel> getAllUsers() {
    final box = Hive.box<UserDetailModel>(_userBoxName);
    return box.values.toList();
  }

  // Update user location
  Future<void> updateUserLocation(
      String userId, double lat, double long) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      UserDetailModel? userDetails = box.get(userId);

      if (userDetails != null) {
        userDetails.lat = lat;
        userDetails.long = long;
        userDetails.lastUpdatedLocation = DateTime.now();

        await box.put(userId, userDetails);
      }
    } catch (e) {
      print('Error updating user location: $e');
      rethrow;
    }
  }

  // Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      UserDetailModel? userDetails = box.get(userId);

      if (userDetails != null) {
        userDetails.status = status;
        await box.put(userId, userDetails);
      }
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  // Add group to user's groups
  Future<void> addGroupToUser(String userId, String groupId) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      UserDetailModel? userDetails = box.get(userId);

      if (userDetails != null) {
        if (!userDetails.groupIds!.contains(groupId)) {
          userDetails.groupIds!.add(groupId);
          await box.put(userId, userDetails);
        }
      }
    } catch (e) {
      print('Error adding group to user: $e');
      rethrow;
    }
  }

  // Remove group from user's groups
  Future<void> removeGroupFromUser(String userId, String groupId) async {
    try {
      final box = await Hive.openBox<UserDetailModel>(_userBoxName);
      UserDetailModel? userDetails = box.get(userId);

      if (userDetails != null) {
        userDetails.groupIds!.remove(groupId);
        await box.put(userId, userDetails);
      }
    } catch (e) {
      print('Error removing group from user: $e');
      rethrow;
    }
  }

  // Check if a user exists
  bool userExists(String userId) {
    final box = Hive.box<UserDetailModel>(_userBoxName);
    return box.containsKey(userId);
  }

  // Get users by group
  List<UserDetailModel> getUsersByGroup(String groupId) {
    final box = Hive.box<UserDetailModel>(_userBoxName);
    return box.values
        .where((user) => user.groupIds!.contains(groupId))
        .toList();
  }

  // Clear all user-related data
  Future<void> clearAllUserData() async {
    try {
      // Close the box if it's open
      if (Hive.isBoxOpen(_userBoxName)) {
        final box = Hive.box<UserDetailModel>(_userBoxName);
        await box.clear(); // Remove all entries
      } else {
        // Open and then clear
        final box = await Hive.openBox<UserDetailModel>(_userBoxName);
        await box.clear();
      }

      print('All user data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  // Completely delete the user details box
  Future<void> deleteUserDetailsBox() async {
    try {
      // Close the box if it's open
      if (Hive.isBoxOpen(_userBoxName)) {
        await Hive.box<UserDetailModel>(_userBoxName).close();
      }

      // Delete the box
      await Hive.deleteBoxFromDisk(_userBoxName);
      print('User details box deleted successfully');
    } catch (e) {
      print('Error deleting user details box: $e');
      rethrow;
    }
  }

  // Comprehensive logout method to clear all local data
  Future<void> performLogout() async {
    try {
      // Clear all user-specific data
      await clearAllUserData();

      // Close and delete the box
      await deleteUserDetailsBox();

      // Reinitialize Hive to ensure clean state
      await initHive();

      print('Logout and data cleanup completed successfully');
    } catch (e) {
      print('Error during logout and data cleanup: $e');
      rethrow;
    }
  }


}
