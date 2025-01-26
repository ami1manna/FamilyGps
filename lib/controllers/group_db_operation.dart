import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
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
  
  // Function to generate a unique 8-character alphanumeric group code
  Future<String> generateUniqueCode() async {
    const chars = '0123456789';
    Random random = Random();

    while (true) {
      String groupCode =
          List.generate(6, (index) => chars[random.nextInt(chars.length)])
              .join();

      // Check if the generated code already exists in the collection
      try {
        DocumentList result = await databases.listDocuments(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          queries: [Query.equal('groupCode', groupCode)],
        );

        // If no documents with this code, return the group code
        if (result.total == 0) {
          return groupCode;
        }
      } catch (e) {
        // print('Error checking for existing code: $e');
      }
    }
  }

  // Function to check for duplicate group names created by the same user
  Future<bool> isDuplicateGroupName(String creatorId, String groupName) async {
    try {
      // Query to check if a group with the same name and creatorId exists
      DocumentList result = await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [
          Query.equal('creatorId', creatorId),
          Query.equal('groupName', groupName),
        ],
      );

      // Return true if a group with the same name exists
      return result.total > 0;
    } catch (e) {
      print('Error checking for duplicate group name: $e');
      return false;
    }
  }

  // Function to create a group document with creatorId and groupName
  Future<String> createGroup(String creatorId, String groupName ) async {
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

      return 'Group created successfully';
    } catch (e) {
      // print('ERROR: creating group: $e');
      return 'ERROR: creating group.';
    }
  }

  // Function to add the group code to the user's document's groups array
  Future<void> addGroupToUserDocument(String userId, String groupCode) async {
    try {
      // Get the user's document
      Document userDocument = await databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID, // Assuming user data is stored here
        documentId: userId,
      );

      // Extract the existing groups array (if exists)
      List<dynamic> groups = userDocument.data['groups'] ?? [];

      // Add the new group code to the array
      groups.add(groupCode);

      // Update the user's document with the new groups array
      await databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
        data: {'groups': groups},
      );

      // print('Group code added to user document successfully');
    } catch (e) {
      // print('ERROR: updating user document with group code: $e');
    }
  }

  // Function to fetch all groups a user is a member of
  Future<Map<String, dynamic>> fetchUserGroups(String userId) async {
    try {
      // Fetch the user's document which contains the group codes
      Document userDoc = await databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
      );

      // Safely extract group codes (assuming 'groups' is a List<String>)
      List<String> groupCodes = List<String>.from(userDoc.data['groups'] ?? []);

      // Fetch all group documents that match the group codes
      List<String> groupNames = [];
      for (var groupCode in groupCodes) {
        // Fetch each group document by groupCode
        DocumentList groupDoc = await databases.listDocuments(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          queries: [Query.equal('groupCode', groupCode)],
        );

        // If the group is found, add the group name to the list
        if (groupDoc.total > 0) {
          groupNames.add(groupDoc.documents[0].data['groupName']);
        } else {
          print('Group with code $groupCode not found.');
        }
      }

      // Return both group names and codes in a Map
      return {
        'groupNames': groupNames,
        'groupCodes': groupCodes,
      };
    } catch (e) {
      print('Error fetching user groups: $e');
      return {'groupNames': [], 'groupCodes': []}; // Return empty lists on error
    }
  }
}


