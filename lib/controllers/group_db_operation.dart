import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';

class GroupDbOperation {
  late Client client; // If you are using a self-signed certificate
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
        print('Error checking for existing code: $e');
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
  Future<String> createGroup(String creatorId, String groupName) async {
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
      'members': [creatorId], // Add creator as the first member
    };

    try {
      // Create the document in the group_details collection
      Document result = await databases.createDocument(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        documentId: 'unique()', // Auto-generate document ID
        data: groupData,
      );

      return 'Group created successfully}';
    } catch (e) {
      print('ERROR: creating group: $e');
      return 'ERROR: creating group.';
    }
  }
}
