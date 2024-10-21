import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _userKey = 'users';
  static const String _groupKey = 'groups';

  // Method to get shared preferences instance
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Method to fetch all users
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final prefs = await _getPrefs();
    String? userData = prefs.getString(_userKey);

    if (userData != null) {
      List<dynamic> decodedData = jsonDecode(userData);
      return decodedData
          .map<Map<String, dynamic>>((user) => Map<String, dynamic>.from(user))
          .toList();
    } else {
      return []; // Return an empty list if no data exists
    }
  }

  // Method to fetch all groups
  // Method to fetch all groups
static Future<List<Map<String, dynamic>>> fetchAllGroups() async {
  final prefs = await _getPrefs();
  String? groupData = prefs.getString(_groupKey);

  if (groupData != null) {
    try {
      List<dynamic> decodedData = jsonDecode(groupData);
      // Debugging: print the fetched group data to check its structure
      print("Fetched groups: $decodedData");

      return decodedData.map<Map<String, dynamic>>((group) => Map<String, dynamic>.from(group)).toList();
    } catch (e) {
      print("Error decoding groups: $e");
      return []; // Return an empty list if data cannot be decoded
    }
  } else {
    return []; // Return an empty list if no data exists
  }
}

// Fetch group members from local storage
static Future<List<Map<String, dynamic>>> getGroupMembersFromLocalStorage(String groupCode) async {
  final prefs = await _getPrefs();
  // Get the stored data as JSON
  String? storedData = prefs.getString(_groupKey);

  if (storedData != null) {
    try {
      List<dynamic> groupList = jsonDecode(storedData);
      // Debugging: print the stored groups to check the structure
      print("Stored group list: $groupList");

      // Find the relevant group by groupCode
      for (var group in groupList) {
        if (group['code'] == groupCode) {
          // Debugging: print the found group and its members
          print("Found group: $group");
          return List<Map<String, dynamic>>.from(group['members']);
        }
      }
    } catch (e) {
      print("Error decoding group members: $e");
    }
  }

  return []; // Return an empty list if no data found or error occurs
}


  // Method to store user data
  static Future<void> storeUserData(Map<String, dynamic> userMap) async {
    final prefs = await _getPrefs();
    String existingData = prefs.getString(_userKey) ??
        '[]'; // Start with an empty list if no data exists
    List<Map<String, dynamic>> currentData =
        List<Map<String, dynamic>>.from(jsonDecode(existingData));

    // Add or update user data in the list
    currentData
        .add(userMap); // You may need logic to check if user already exists

    // Store updated list in shared preferences
    await prefs.setString(_userKey, jsonEncode(currentData));
  }

  // Method to store group data
  static Future<void> storeGroupData(Map<String, dynamic> groupMap) async {
    final prefs = await _getPrefs();
    String existingData = prefs.getString(_groupKey) ??
        '[]'; // Start with an empty list if no data exists
    List<Map<String, dynamic>> currentData =
        List<Map<String, dynamic>>.from(jsonDecode(existingData));

    // Add or update group data in the list
    currentData
        .add(groupMap); // You may need logic to check if group already exists

    // Store updated list in shared preferences
    await prefs.setString(_groupKey, jsonEncode(currentData));
  }

  // Method to delete user by userId
  static Future<void> deleteUser(String userId) async {
    final prefs = await _getPrefs();
    String existingData = prefs.getString(_userKey) ??
        '[]'; // Start with an empty list if no data exists
    List<Map<String, dynamic>> currentData =
        List<Map<String, dynamic>>.from(jsonDecode(existingData));

    // Remove the user by userId
    currentData.removeWhere((user) => user['id'] == userId);

    // Update shared preferences
    await prefs.setString(_userKey, jsonEncode(currentData));
  }

  // Method to delete group by groupCode
  static Future<void> deleteGroup(String groupCode) async {
    final prefs = await _getPrefs();
    String existingData = prefs.getString(_groupKey) ??
        '[]'; // Start with an empty list if no data exists
    List<Map<String, dynamic>> currentData =
        List<Map<String, dynamic>>.from(jsonDecode(existingData));

    // Remove the group by groupCode
    currentData.removeWhere((group) => group['code'] == groupCode);

    // Update shared preferences
    await prefs.setString(_groupKey, jsonEncode(currentData));
  }

  // Fetch all users from local storage
  static Future<List<Map<String, dynamic>>> getUsersFromLocalStorage() async {
    return await fetchAllUsers(); // You can reuse the above method
  }

  // Update a specific user in local storage
  static Future<void> updateUserInLocalStorage(
      String userId, Map<String, dynamic> updatedUserData) async {
    List<Map<String, dynamic>> users = await getUsersFromLocalStorage();

    // Find the user in the list and update it
    for (int i = 0; i < users.length; i++) {
      if (users[i]['id'] == userId) {
        // Update the user data
        users[i] = updatedUserData;
        break;
      }
    }

    // Save the updated list of users back to local storage
    final prefs = await _getPrefs();
    await prefs.setString(_userKey, jsonEncode(users));
  }

  // Add a new user to local storage
  static Future<void> addUserToLocalStorage(
      Map<String, dynamic> userData) async {
    final prefs = await _getPrefs();
    List<Map<String, dynamic>> users = await getUsersFromLocalStorage();

    // Add the new user to the list
    users.add(userData);

    // Save the updated list of users back to local storage
    await prefs.setString(_userKey, jsonEncode(users));
  }



  // Save group members to local storage
  static Future<void> saveGroupMembersToLocalStorage(
      String groupCode, List<Map<String, dynamic>> members) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch existing data
    String? storedData = prefs.getString(_groupKey);
    List<dynamic> groupList = storedData != null ? json.decode(storedData) : [];

    // Find and update the group if it exists, otherwise add a new group
    bool groupFound = false;
    for (var group in groupList) {
      if (group['groupCode'] == groupCode) {
        group['members'] = members;
        groupFound = true;
        break;
      }
    }

    if (!groupFound) {
      // Add a new group entry if it doesn't exist
      groupList.add({
        'groupCode': groupCode,
        'members': members,
      });
    }

    // Save the updated data back to local storage
    await prefs.setString(_groupKey, json.encode(groupList));
  }

// Add a user to a specific group's members list in local storage
  static Future<void> addUserToGroupLocalStorage(
      String groupCode, Map<String, dynamic> user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch existing data
    String? storedData = prefs.getString(_groupKey);
    List<dynamic> groupList = storedData != null ? json.decode(storedData) : [];

    bool groupFound = false;

    // Find the relevant group and update its members list
    for (var group in groupList) {
      if (group['groupCode'] == groupCode) {
        List<Map<String, dynamic>> members =
            List<Map<String, dynamic>>.from(group['members']);

        // Check if the user already exists in the group
        if (!members.any((member) => member['userId'] == user['userId'])) {
          members.add(user); // Add user if not already in the list
          group['members'] = members;
          groupFound = true;
        } else {
          print("User is already in the group.");
        }
        break;
      }
    }

    if (!groupFound) {
      // Add a new group entry if it doesn't exist
      groupList.add({
        'groupCode': groupCode,
        'members': [user],
      });
    }

    // Save the updated data back to local storage
    await prefs.setString(_groupKey, json.encode(groupList));
  }

// Remove a user from a specific group's members list in local storage
  static Future<void> removeUserFromGroupLocalStorage(
      String groupCode, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch existing data
    String? storedData = prefs.getString(_groupKey);
    List<dynamic> groupList = storedData != null ? json.decode(storedData) : [];

    bool groupFound = false;

    // Find the relevant group and update its members list
    for (var group in groupList) {
      if (group['groupCode'] == groupCode) {
        List<Map<String, dynamic>> members =
            List<Map<String, dynamic>>.from(group['members']);

        // Remove the user by userId
        members.removeWhere((member) => member['userId'] == userId);
        group['members'] = members;
        groupFound = true;
        break;
      }
    }

    if (groupFound) {
      // Save the updated list back to local storage
      await prefs.setString(_groupKey, json.encode(groupList));
    } else {
      print("Group not found.");
    }
  }
}
