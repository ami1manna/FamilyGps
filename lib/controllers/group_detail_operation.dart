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
        .setEndpoint(END_POINT)
        .setProject(PROJECT_ID)
        .setSelfSigned();

    _databases = Databases(client);
    _realtime = Realtime(client);

    _subscribeToGroupUpdates();
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupCode) async {
  print('Fetching group members for group code: $groupCode');
  
  List<Map<String, dynamic>>? cachedMembers = await LocalStorage.getGroupMembers(groupCode);
  if (cachedMembers != null && cachedMembers.isNotEmpty) {
    print('Returning cached members: ${cachedMembers.length}');
    return cachedMembers;
  }

  try {
    print('Fetching group document from Appwrite');
    DocumentList groupDoc = await _databases.listDocuments(
      databaseId: DATABASE_ID,
      collectionId: GROUP_COLLECTION_ID,
      queries: [Query.equal('groupCode', groupCode)],
    );

    print('Group documents found: ${groupDoc.total}');

    if (groupDoc.total > 0) {
      List<dynamic> memberIds = groupDoc.documents[0].data['members'] ?? [];
      print('Member IDs found: ${memberIds.length}');

      List<Map<String, dynamic>> memberDetails = [];

      for (String userId in memberIds) {
        print('Fetching details for user: $userId');
        Map<String, dynamic>? userDetails = await LocalStorage.getUser(userId);
        if (userDetails == null) {
          print('User not found in local storage, fetching from Appwrite');
          try {
            Document userDoc = await _databases.getDocument(
              databaseId: DATABASE_ID,
              collectionId: USERS_COLLECTION_ID,
              documentId: userId,
            );
            userDetails = {
              'userId': userId,
              'name': userDoc.data['name'] ?? 'Unknown',
              'email': userDoc.data['email'] ?? 'Unknown',
              'groups': userDoc.data['groups'] ?? [],
            };
            await LocalStorage.saveUser(userId, userDetails);
          } catch (e) {
            print('Error fetching user document: $e');
            userDetails = {
              'userId': userId,
              'name': 'Unknown',
              'email': 'Unknown',
              'groups': [],
            };
          }
        }
        memberDetails.add(userDetails);
      }

      print('Saving ${memberDetails.length} members to local storage');
      await LocalStorage.saveGroupMembers(groupCode, memberDetails);
      return memberDetails;
    } else {
      print('No group found with the given code');
      return [];
    }
  } catch (e) {
    print('Error fetching group members: $e');
    return [];
  }
}
  void _subscribeToGroupUpdates() {
    _subscription = _realtime.subscribe(
        ['databases.$DATABASE_ID.collections.$GROUP_COLLECTION_ID.documents']);

    _subscription.stream.listen((response) async {
      String groupCode = response.payload['groupCode'];
      await fetchGroupMembers(groupCode);
    });
  }

  Future<String> addUserToGroup(String groupCode, String userId) async {
    try {
      Document userDoc = await _databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
      );

      Map<String, dynamic> userData = {
        'userId': userId,
        'name': userDoc.data['name'] ?? 'Unknown',
        'email': userDoc.data['email'] ?? 'Unknown',
        'groups': [...(userDoc.data['groups'] ?? []), groupCode],
      };

      await LocalStorage.saveUser(userId, userData);
      await LocalStorage.addUserToGroup(groupCode, userData);

      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        List<dynamic> members = groupDoc.documents[0].data['members'] ?? []; // Add user to group in Appwrite
        members.add(userId);

        await _databases.updateDocument(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          documentId: groupDoc.documents[0].$id,
          data: {'members': members},
        );

        return 'User  added successfully';
      } else {
        return 'Group not found';
      }
    } catch (e) {
      print('Error adding user to group: $e');
      return 'Failed to add user to group';
    }
  }

  Future<String> deleteUserFromGroup(String groupCode, String userId) async {
    try {
      await LocalStorage.removeUserFromGroup(groupCode, userId);

      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        List<dynamic> members = groupDoc.documents[0].data['members'] ?? [];
        members.remove(userId);

        await _databases.updateDocument(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          documentId: groupDoc.documents[0].$id,
          data: {'members': members},
        );

        Map<String, dynamic>? userData = await LocalStorage.getUser(userId);
        if (userData != null) {
          List<dynamic> userGroups = userData['groups'] ?? [];
          userGroups.remove(groupCode);
          await LocalStorage.saveUser (userId, {'groups': userGroups});
        }

        return 'User  deleted successfully';
      } else {
        return 'Group not found';
      }
    } catch (e) {
      print('Error deleting user from group: $e');
      return 'Failed to delete user from group';
    }
  }

  Future<String> fetchGroupNameByCode(String groupCode) async {
    Map<String, dynamic>? groupData = await LocalStorage.getGroup(groupCode);
    if (groupData != null) {
      return groupData['groupName'] ?? 'Group name not found';
    }

    try {
      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        String groupName = groupDoc.documents[0].data['groupName'].toString();
        await LocalStorage.saveGroup(groupCode, {'groupName': groupName});
        return groupName;
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
      await LocalStorage.deleteGroup(groupCode);

      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      if (groupDoc.total > 0) {
        String groupId = groupDoc.documents[0].$id;

        await _databases.deleteDocument(
          databaseId: DATABASE_ID,
          collectionId: GROUP_COLLECTION_ID,
          documentId: groupId,
        );

        List<String> members = List<String>.from(groupDoc.documents[0].data['members'] ?? []);

        for (String userId in members) {
          Map<String, dynamic>? userData = await LocalStorage.getUser(userId);
          if (userData != null) {
            List<dynamic> userGroups = userData['groups'] ?? [];
            userGroups.remove(groupCode);
            await LocalStorage.saveUser (userId, {'groups': userGroups});
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