import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';

class DetailGroupOperation {
  late Client client;
  late Databases _databases;

  DetailGroupOperation() {
    client = Client()
        .setEndpoint(END_POINT) // Your Appwrite endpoint
        .setProject(PROJECT_ID) // Your project ID
        .setSelfSigned();
    _databases = Databases(client);
  }

  // Fetch all members of a group
// Fetch all members of a group, displaying their names instead of userId
// Fetch all members of a group, displaying their names and emails
Future<List<Map<String, String>>> fetchGroupMembers(String groupCode) async {
  try {
    // Fetch group details by group code
    DocumentList groupDoc = await _databases.listDocuments(
      databaseId: DATABASE_ID,
      collectionId: GROUP_COLLECTION_ID,
      queries: [Query.equal('groupCode', groupCode)],
    );

    if (groupDoc.total > 0) {
      List<dynamic> members = groupDoc.documents[0].data['members'] ?? [];

      // Create a list to store user details (name and email) instead of userIds
      List<Map<String, String>> memberDetails = [];

      // Fetch each user's document by their userId and retrieve their name and email
      for (String userId in members) {
        try {
          // Fetch the user's document by their userId (document ID)
          Document userDoc = await _databases.getDocument(
            databaseId: DATABASE_ID,
            collectionId: USERS_COLLECTION_ID,
            documentId: userId,
          );

          // Get the user's name and email
          String userName = userDoc.data['name'] ?? 'Unknown';
          String userEmail = userDoc.data['email'] ?? 'Unknown';

          // Add the user's name and email to the list
          memberDetails.add({
            'userId': userId,
            'name': userName,
            'email': userEmail,
          });
        } catch (e) {
          print('Error fetching user document for $userId: $e');
        }
      }

      return memberDetails; // Return the list of user names and emails
    }

    return [];
  } catch (e) {
    print('Error fetching group members: $e');
    return [];
  }
}


  // Add a user to a group
  Future<String> addUserToGroup(String groupCode, String userId) async {
    try {
      // Fetch the group document by group code
      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        // Add the user to the group's members list
        List<dynamic> members = groupDoc.documents[0].data['members'] ?? [];
        if (!members.contains(userId)) {
          members.add(userId);

          // Update the group with new member
          await _databases.updateDocument(
            databaseId: DATABASE_ID,
            collectionId: GROUP_COLLECTION_ID,
            documentId: groupDoc.documents[0].$id,
            data: {'members': members},
          );
          return 'User added successfully';
        } else {
          return 'User is already a member';
        }
      } else {
        return 'Group not found';
      }
    } catch (e) {
      print('Error adding user to group: $e');
      return 'Failed to add user';
    }
  }

  // Delete a user from a group
  // Delete a user from a group and also remove the group code from the user's document
Future<String> deleteUserFromGroup(String groupCode, String userId) async {
  try {
    // Fetch the group document by group code
    DocumentList groupDoc = await _databases.listDocuments(
      databaseId: DATABASE_ID,
      collectionId: GROUP_COLLECTION_ID,
      queries: [Query.equal('groupCode', groupCode)],
    );

    if (groupDoc.total > 0) {
      // Get the group document ID
      String groupId = groupDoc.documents[0].$id;

      // Fetch the current members of the group
      List<dynamic> members = groupDoc.documents[0].data['members'] ?? [];

      // Check if the user is part of the group
      if (members.contains(userId)) {
        // Remove the user from the group's members list
        members.remove(userId);

        // Update the group document to remove the user
        await _databases.updateDocument(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          documentId: groupId,
          data: {'members': members},
        );

        // Fetch the user's document by their userId (document ID)
        Document userDoc = await _databases.getDocument(
          databaseId: DATABASE_ID,
          collectionId: USERS_COLLECTION_ID, // Assuming users are stored by userId as document ID
          documentId: userId,
        );

        // Get the user's current list of groups
        List<dynamic> userGroups = userDoc.data['groups'] ?? [];

        // Remove the group code from the user's groups list
        userGroups.remove(groupCode);

        // Update the user's document with the modified groups list
        await _databases.updateDocument(
          databaseId: DATABASE_ID,
          collectionId: USERS_COLLECTION_ID,
          documentId: userId,
          data: {'groups': userGroups},
        );

        return 'User deleted successfully';
      } else {
        return 'User is not a member of this group';
      }
    } else {
      return 'Group not found';
    }
  } catch (e) {
    print('Error deleting user from group: $e');
    return 'Failed to delete user from group';
  }
}

  // Delete a group
Future<String> deleteGroup(String groupCode) async {
  try {
    // Fetch the group document by group code
    DocumentList groupDoc = await _databases.listDocuments(
      databaseId: DATABASE_ID,
      collectionId: GROUP_COLLECTION_ID,
      queries: [Query.equal('groupCode', groupCode)],
    );

    if (groupDoc.total > 0) {
      // Get the group document ID
      String groupId = groupDoc.documents[0].$id;

      // Delete the group document
      await _databases.deleteDocument(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        documentId: groupId,
      );

      // Fetch all users who are part of this group
      List<String> members = List<String>.from(groupDoc.documents[0].data['members'] ?? []);
      
      // Iterate through each member and remove this group code from their 'groups' list
      for (String userId in members) {
        try {
          // Fetch the user's document by their userId (document ID)
          Document userDoc = await _databases.getDocument(
            databaseId: DATABASE_ID,
            collectionId: USERS_COLLECTION_ID, // Assuming users are stored by userId as document ID
            documentId: userId,
          );

          // Get the user's current list of groups
          List<dynamic> userGroups = userDoc.data['groups'] ?? [];

          // Remove the group code from the list
          userGroups.remove(groupCode);

          // Update the user's document with the modified groups list
          await _databases.updateDocument(
            databaseId: DATABASE_ID,
            collectionId: USERS_COLLECTION_ID,
            documentId: userId,
            data: {'groups': userGroups},
          );
        } catch (e) {
          print('Error fetching user document for $userId: $e');
        }
      }

      return 'Group deleted successfully';
    } else {
      return 'Group not found';
    }
  } catch (e) {
    print('Error deleting group: $e');
    return 'Failed to delete group';
  }
}


  // Fetch the group name for a specific group code
  Future<String> fetchGroupNameByCode(String groupCode) async {
    try {
      // Fetch the group document by group code
      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        // Return the group name
        return groupDoc.documents[0].data['groupName'].toString();
      } else {
        return 'Group not found';
      }
    } catch (e) {
      print('Error fetching group name: $e');
      return 'Failed to fetch group name';
    }
  }

}
