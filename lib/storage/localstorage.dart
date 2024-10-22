import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _userKey = 'users';
  static const String _groupKey = 'groups';

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final prefs = await _getPrefs();
    String? userData = prefs.getString(_userKey);

    if (userData != null) {
      Map<String, dynamic> decodedData = jsonDecode(userData);
      return decodedData[userId];
    } else {
      return null;
    }
  }

  static Future<void> saveUser (String userId, Map<String, dynamic> userData) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_userKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      decodedData[userId] = userData;
      await prefs.setString(_userKey, jsonEncode(decodedData));
    } else {
      await prefs.setString(_userKey, jsonEncode({userId: userData}));
    }
  }

  static Future<void> deleteUser(String userId) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_userKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      decodedData.remove(userId);
      await prefs.setString(_userKey, jsonEncode(decodedData));
    }
  }

  static Future<List<Map<String, dynamic>>> getGroupMembers(String groupCode) async {
    final prefs = await _getPrefs();
    String? groupData = prefs.getString(_groupKey);

    if (groupData != null) {
      Map<String, dynamic> decodedData = jsonDecode(groupData);
      return decodedData[groupCode]['members'] ?? [];
    } else {
      return [];
    }
  }

  static Future<void> saveGroupMembers(String groupCode, List<Map<String, dynamic>> members) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_groupKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      decodedData[groupCode] = {'members': members};
      await prefs.setString(_groupKey, jsonEncode(decodedData));
    } else {
      await prefs.setString(_groupKey, jsonEncode({groupCode: {'members': members}}));
    }
  }

  static Future<void> addUserToGroup(String groupCode, Map<String, dynamic> userData) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_groupKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      if (decodedData[groupCode] != null) {
        decodedData[groupCode]['members'].add(userData);
      } else {
        decodedData[groupCode] = {'members': [userData]};
      }
      await prefs.setString(_groupKey, jsonEncode(decodedData));
    } else {
      await prefs.setString(_groupKey, jsonEncode({groupCode: {'members': [userData]}}));
    }
  }

  static Future<void> removeUserFromGroup(String groupCode, String userId) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_groupKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      if (decodedData[groupCode] != null) {
        decodedData[groupCode]['members'].removeWhere((member) => member['userId'] == userId);
      }
      await prefs.setString(_groupKey, jsonEncode(decodedData));
    }
  }

  static Future<Map<String, dynamic>?> getGroup(String groupCode) async {
    final prefs = await _getPrefs();
    String? groupData = prefs.getString(_groupKey);

    if (groupData != null) {
      Map<String, dynamic> decodedData = jsonDecode(groupData);
      return decodedData[groupCode];
    } else {
      return null;
    }
  }

  static Future<void> saveGroup(String groupCode, Map<String, dynamic> groupData) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_groupKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      decodedData[groupCode] = groupData;
      await prefs.setString(_groupKey, jsonEncode(decodedData));
    } else {
      await prefs.setString(_groupKey, jsonEncode({groupCode: groupData}));
    }
  }

  static Future<void> deleteGroup(String groupCode) async {
    final prefs = await _getPrefs();
    String? existingData = prefs.getString(_groupKey);

    if (existingData != null) {
      Map<String, dynamic> decodedData = jsonDecode(existingData);
      decodedData.remove(groupCode);
      await prefs.setString(_groupKey, jsonEncode(decodedData));
    }
  }

    static Future<void> refreshLocalStorageFromDatabase() async {
    final client = Client()
      .setEndpoint(END_POINT)
      .setProject(PROJECT_ID)
      .setSelfSigned();
    final databases = Databases(client);

    try {
      // Fetch all users
      final userDocuments = await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
      );

      Map<String, dynamic> users = {};
      for (var doc in userDocuments.documents) {
        users[doc.$id] = {
          'userId': doc.$id,
          'name': doc.data['name'],
          'email': doc.data['email'],
          'groups': doc.data['groups'] ?? [],
        };
      }

      // Save all users to local storage
      final prefs = await _getPrefs();
      await prefs.setString(_userKey, jsonEncode(users));

      // Fetch all groups
      final groupDocuments = await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
      );

      Map<String, dynamic> groups = {};
      for (var doc in groupDocuments.documents) {
        groups[doc.data['groupCode']] = {
          'groupCode': doc.data['groupCode'],
          'groupName': doc.data['groupName'],
          'creatorId': doc.data['creatorId'],
          'members': doc.data['members'] ?? [],
        };
      }

      // Save all groups to local storage
      await prefs.setString(_groupKey, jsonEncode(groups));

      print("Local storage refreshed successfully from database.");
    } catch (e) {
      print("Error refreshing local storage: $e");
    }
  }
}