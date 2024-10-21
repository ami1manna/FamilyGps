import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/storage/localstorage.dart';

class DetailGroupOperation {
  late Client client;
  late Databases _databases;
  late Realtime _realtime;
  late RealtimeSubscription _subscription;

  DetailGroupOperation() {
    client = Client()
        .setEndpoint(END_POINT) // Your Appwrite endpoint
        .setProject(PROJECT_ID) // Your project ID
        .setSelfSigned();

    _databases = Databases(client);
    _realtime = Realtime(client); // Initialize Realtime

    // Initialize subscription for Appwrite changes
    _subscribeToGroupUpdates();
  }

  // Fetch all members of a group (with caching using local storage)
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupCode) async {
    // Check if data is available in local storage
    List<Map<String, dynamic>>? cachedMembers =
        await LocalStorage.getGroupMembersFromLocalStorage(groupCode);
    if (cachedMembers.isNotEmpty) {
      return cachedMembers; // Return cached data if available
    }

    // If no cached data, fetch from Appwrite
    try {
      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        List<dynamic> members = groupDoc.documents[0].data['members'] ?? [];

        // Fetch and store user details (name and email) instead of userIds
        List<Map<String, String>> memberDetails = [];
        for (String userId in members) {
          try {
            Document userDoc = await _databases.getDocument(
              databaseId: DATABASE_ID,
              collectionId: USERS_COLLECTION_ID,
              documentId: userId,
            );
            String userName = userDoc.data['name'] ?? 'Unknown';
            String userEmail = userDoc.data['email'] ?? 'Unknown';

            memberDetails.add({
              'userId': userId,
              'name': userName,
              'email': userEmail,
            });
          } catch (e) {
            print('Error fetching user document for $userId: $e');
          }
        }

        // Store fetched data in local storage
        await LocalStorage.saveGroupMembersToLocalStorage(groupCode, memberDetails);
        return memberDetails; // Return fetched data
      }

      return [];
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  // Subscribe to Appwrite Realtime updates
  void _subscribeToGroupUpdates() {
    // Use Realtime to subscribe to database changes
    _subscription = _realtime.subscribe(
        ['databases.$DATABASE_ID.collections.$GROUP_COLLECTION_ID.documents']);

    _subscription.stream.listen((response) async {
      String groupCode = response.payload['groupCode'];

      // Fetch updated group members and update local storage
      List<Map<String, dynamic>> updatedMembers =
          await fetchGroupMembers(groupCode);
      await LocalStorage.saveGroupMembersToLocalStorage(groupCode, updatedMembers);
    });
  }

  // Add user to group (with local storage update)
  Future<String> addUserToGroup(String groupCode, String userId) async {
    try {
      // Add user to group in local storage first
      await LocalStorage.addUserToGroupLocalStorage(groupCode, {
        'userId': userId,
        'name': 'Unknown',
        'email': 'Unknown',
      });

      // Fetch the group document by group code from the database
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

          // Update the group with the new member in the database
          await _databases.updateDocument(
            databaseId: DATABASE_ID,
            collectionId: GROUP_COLLECTION_ID,
            documentId: groupDoc.documents[0].$id,
            data: {'members': members},
          );

          // Update local storage with new group member
          List<Map<String, dynamic>> updatedMembers = await fetchGroupMembers(groupCode);
          await LocalStorage.saveGroupMembersToLocalStorage(groupCode, updatedMembers);

          return 'User added successfully to database';
        } else {
          return 'User is already a member in the database';
        }
      } else {
        return 'Group not found in database';
      }
    } catch (e) {
      print('Error adding user to group: $e');
      return 'Failed to add user to group in database';
    }
  }

  // Delete user from group (with local storage update)
  Future<String> deleteUserFromGroup(String groupCode, String userId) async {
    try {
      // Remove user from group in local storage first
      await LocalStorage.removeUserFromGroupLocalStorage(groupCode, userId);

      // Fetch the group document by group code from the database
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

          // Update the group document to remove the user in the database
          await _databases.updateDocument(
            databaseId: DATABASE_ID,
            collectionId: GROUP_COLLECTION_ID,
            documentId: groupId,
            data: {'members': members},
          );

          // Fetch the user's document by their userId (document ID)
          Document userDoc = await _databases.getDocument(
            databaseId: DATABASE_ID,
            collectionId: USERS_COLLECTION_ID,
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

          // Update local storage after user is deleted from group
          List<Map<String, dynamic>> updatedMembers = await fetchGroupMembers(groupCode);
          await LocalStorage.saveGroupMembersToLocalStorage(groupCode, updatedMembers);

          return 'User deleted successfully from database';
        } else {
          return 'User is not a member of this group in the database';
        }
      } else {
        return 'Group not found in the database';
      }
    } catch (e) {
      print('Error deleting user from group: $e');
      return 'Failed to delete user from group in database';
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

        // Delete the group document from the database
        await _databases.deleteDocument(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          documentId: groupId,
        );

        // Fetch all users who are part of this group
        List<String> members =
            List<String>.from(groupDoc.documents[0].data['members'] ?? []);

        // Iterate through each member and remove this group code from their 'groups' list
        for (String userId in members) {
          try {
            // Fetch the user's document by their userId (document ID)
            Document userDoc = await _databases.getDocument(
              databaseId: DATABASE_ID,
              collectionId: USERS_COLLECTION_ID,
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
          } catch (e) {
            print('Failed to update user $userId: $e');
          }
        }

        return 'Group deleted successfully from database';
      } else {
        return 'Group not found in database';
      }
    } catch (e) {
      print('Error deleting group: $e');
      return 'Failed to delete group from database';
    }
  }
}
