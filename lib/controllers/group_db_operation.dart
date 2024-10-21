import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/storage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familygps/constants/appwrite_config.dart';

class GroupDbOperation {
  late Client client;
  late Databases databases;

  GroupDbOperation() {
    client = Client()
        .setEndpoint(END_POINT) // Your Appwrite endpoint
        .setProject(PROJECT_ID) // Your project ID
        .setSelfSigned();
    databases = Databases(client);
  }

  // Function to create a group document with creatorId and groupNameimport 'dart:convert';  // Import for JSON encoding/decoding

Future<String> createGroup(String creatorId, String groupName) async {
  String localKey = '$creatorId-$groupName';

  // Check local storage first
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey(localKey)) {
    // Decode the stored JSON string to retrieve group data
    String storedData = prefs.getString(localKey)!;
    Map<String, dynamic> storedGroupData = jsonDecode(storedData);
    return 'Group data found in local storage: $storedGroupData';
  }

  // Check for duplicate group name
  bool isDuplicate = await isDuplicateGroupName(creatorId, groupName);
  if (isDuplicate) {
    return 'ERROR: A group with the same name already exists for this user.';
  }

  // Generate a unique group code
  String groupCode = await generateUniqueCode();

  // Group data to be saved
  Map<String, dynamic> groupData = {
    'creatorId': creatorId,
    'groupName': groupName,
    'groupCode': groupCode,
    'members': [creatorId],
  };

  try {
    // Create the document in the group_details collection
    Document result = await databases.createDocument(
      databaseId: DATABASE_ID,
      collectionId: GROUP_COLLECTION_ID,
      documentId: 'unique()', // Auto-generate document ID
      data: groupData,
    );

    // Add group code to the user's document
    await addGroupToUserDocument(creatorId, groupCode);

    // Save group data to local storage as a JSON string
    String jsonGroupData = jsonEncode(groupData);
    await prefs.setString(localKey, jsonGroupData);

    return 'Group created successfully';
  } catch (e) {
    print('ERROR: creating group: $e');
    return 'ERROR: creating group.';
  }
}

  // Function to add the group code to the user's document's groups array
  Future<void> addGroupToUserDocument(String userId, String groupCode) async {
    try {
      // Check if the user's data exists in local storage
      List<Map<String, dynamic>> users = await LocalStorage.getUsersFromLocalStorage();

      // Find the user in local storage
      Map<String, dynamic>? userDocument = users.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => {}, // Return an empty map if not found
      );

      // If user is found in local storage, update the groups list there
      if (userDocument.isNotEmpty) {
        List<dynamic> groups = userDocument['groups'] ?? [];
        if (!groups.contains(groupCode)) {
          groups.add(groupCode);

          // Update user in local storage
          await LocalStorage.updateUserInLocalStorage(userId, {
            'id': userId,
            'groups': groups,
          });

          print('Group code added to user document in local storage successfully');
        }
      } else {
        // If the user is not found in local storage, fetch from database
        Document userDocument = await databases.getDocument(
          databaseId: DATABASE_ID,
          collectionId: USERS_COLLECTION_ID,
          documentId: userId,
        );

        // Extract the existing groups array (if exists)
        List<dynamic> groups = userDocument.data['groups'] ?? [];

        // Add the new group code to the array if it doesn't already exist
        if (!groups.contains(groupCode)) {
          groups.add(groupCode);

          // Update the user's document with the new groups array in the database
          await databases.updateDocument(
            databaseId: DATABASE_ID,
            collectionId: USERS_COLLECTION_ID,
            documentId: userId,
            data: {'groups': groups},
          );

          // Now that the database has been updated, update local storage as well
          await LocalStorage.updateUserInLocalStorage(userId, {
            'id': userId,
            'groups': groups,
          });
        }
      }
    } catch (e) {
      print('ERROR updating user groups in database: $e');
    }
  }

  // Function to check for duplicate group name
  Future<bool> isDuplicateGroupName(String creatorId, String groupName) async {
    try {
      // Use a search query instead of filters
      final result = await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [
          Query.equal('creatorId', creatorId),   // Query to filter by creatorId
          Query.equal('groupName', groupName),   // Query to filter by groupName
        ],
      );

      return result.total > 0; // If there is any document matching the criteria
    } catch (e) {
      print('ERROR checking duplicate group: $e');
      return false;
    }
  }

  // Function to generate a unique 6-letter group code
  Future<String> generateUniqueCode() async {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    Random random = Random();
    String code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return code;
  }

  // Function to fetch the groups for the logged-in user
  Future<Map<String, List<String>>> fetchUserGroups(String userId) async {
    try {
      // Check local storage first
      final prefs = await SharedPreferences.getInstance();
      List<String> groupNames = [];
      List<String> groupCodes = [];

      // Fetch from local storage if available
      if (prefs.containsKey(userId)) {
        String groupsData = prefs.getString(userId)!;
        // Extract group names and codes from local data (modify as needed)
        groupNames = extractGroupNamesFromLocalData(groupsData);
        groupCodes = extractGroupCodesFromLocalData(groupsData);
      } else {
        // Fetch from the database if not found in local storage
        Document result = await databases.getDocument(
          databaseId: DATABASE_ID,
          collectionId: USERS_COLLECTION_ID,
          documentId: userId,
        );

        List<dynamic> groups = result.data['groups'] ?? [];

        for (String groupCode in groups) {
          // Fetch each group document by group code
          DocumentList groupDoc = await databases.listDocuments(
            databaseId: DATABASE_ID,
            collectionId: GROUP_COLLECTION_ID,
            queries: [
              Query.equal('groupCode', groupCode),  // Query based on the 'groupCode' field in the document
            ],
          );

          groupNames.add(groupDoc.documents.first.data['groupName']);
          groupCodes.add(groupCode);
        }

        // Store the fetched groups in local storage
        await prefs.setString(userId, groupNames.join(', '));  // Example, modify accordingly
      }

      return {'groupNames': groupNames, 'groupCodes': groupCodes};
    } catch (e) {
      print('ERROR fetching user groups: $e');
      return {'groupNames': [], 'groupCodes': []};
    }
  }

  // Helper functions for extracting data from local storage strings (modify based on format)
  List<String> extractGroupNamesFromLocalData(String data) {
    return data.split(',').toList();
  }

  List<String> extractGroupCodesFromLocalData(String data) {
    return data.split(',').toList(); // Update logic as necessary
  }
}
