import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/storage/localstorage.dart';
import 'package:familygps/constants/appwrite_config.dart';

class GroupDbOperation {
  late Client client;
  late Databases databases;

  GroupDbOperation() {
    client = Client()
        .setEndpoint(END_POINT)
        .setProject(PROJECT_ID)
        .setSelfSigned();
    databases = Databases(client);
  }
Future<String> createGroup(String creatorId, String groupName) async {
  try {
    // Check for duplicate group name
    bool isDuplicate = await isDuplicateGroupName(creatorId, groupName);
    if (isDuplicate) {
      return 'ERROR: A group with the same name already exists for this user.';
    }

    String groupCode = await generateUniqueCode();

    // Check if the group already exists with this code
    Map<String, dynamic>? existingGroup = await LocalStorage.getGroup(groupCode);
    if (existingGroup != null) {
      return 'ERROR: Group with this code already exists. Please try again.';
    }

    Map<String, dynamic> groupData = {
      'creatorId': creatorId,
      'groupName': groupName,
      'groupCode': groupCode,
      'members': [creatorId],
    };

    // Create the group in Appwrite
    Document result = await databases.createDocument(
      databaseId: DATABASE_ID,
      collectionId: GROUP_COLLECTION_ID,
      documentId: 'unique()',
      data: groupData,
    );

    // Update the user's groups in Appwrite
    await addGroupToUserDocument(creatorId, groupCode);

    // Save group data to local storage
    await LocalStorage.saveGroup(groupCode, groupData);

    // Update user's groups in local storage
    Map<String, dynamic>? userData = await LocalStorage.getUser(creatorId);
    if (userData != null) {
      List<dynamic> userGroups = userData['groups'] ?? [];
      if (!userGroups.contains(groupCode)) {
        userGroups.add(groupCode);
        userData['groups'] = userGroups;
        await LocalStorage.saveUser(creatorId, userData);
      }
    } else {
      // If user data doesn't exist in local storage, fetch it from Appwrite
      Document userDoc = await databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: creatorId,
      );
      userData = {
        'userId': creatorId,
        'name': userDoc.data['name'] ?? 'Unknown',
        'email': userDoc.data['email'] ?? 'Unknown',
        'groups': [groupCode],
      };
      await LocalStorage.saveUser(creatorId, userData);
    }

    // Add creator to group members in local storage
    await LocalStorage.addUserToGroup(groupCode, userData!);

    return 'Group created successfully';
  } catch (e) {
    print('ERROR: creating group: $e');
    return 'ERROR: creating group.';
  }
}
Future<void> addGroupToUserDocument(String userId, String groupCode) async {
  try {
    // Update user document in Appwrite
    Document userDocument = await databases.getDocument(
      databaseId: DATABASE_ID,
      collectionId: USERS_COLLECTION_ID,
      documentId: userId,
    );

    List<dynamic> groups = userDocument.data['groups'] ?? [];
    if (!groups.contains(groupCode)) {
      groups.add(groupCode);

      await databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
        data: {'groups': groups},
      );
    }

    // Update user data in local storage
    Map<String, dynamic>? userData = await LocalStorage.getUser(userId);
    if (userData != null) {
      List<dynamic> userGroups = userData['groups'] ?? [];
      if (!userGroups.contains(groupCode)) {
        userGroups.add(groupCode);
        userData['groups'] = userGroups;
        await LocalStorage.saveUser(userId, userData);
      }
    } else {
      userData = {
        'userId': userId,
        'name': userDocument.data['name'] ?? 'Unknown',
        'email': userDocument.data['email'] ?? 'Unknown',
        'groups': [groupCode],
      }; // Fetch user data from Appwrite if it doesn't exist in local storage
      await LocalStorage.saveUser(userId, userData);
    }
  } catch (e) {
    print('ERROR updating user groups in database: $e');
  }
}
 
 Future<Map<String, List<String>>> fetchUserGroups(String userId) async {
  try {
    List<String> groupNames = [];
    List<String> groupCodes = [];

    Map<String, dynamic>? userData = await LocalStorage.getUser(userId);
    if (userData != null && userData['groups'] != null) {
      List<dynamic> userGroups = userData['groups'];
      for (String groupCode in userGroups) {
        Map<String, dynamic>? groupData = await LocalStorage.getGroup(groupCode);
        if (groupData != null && !groupCodes.contains(groupCode)) {
          groupNames.add(groupData['groupName']);
          groupCodes.add(groupCode);
        }
      }
    }

    if (groupNames.isEmpty) {
      Document result = await databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
      );

      List<dynamic> groups = result.data['groups'] ?? [];

      for (String groupCode in groups) {
        if (! groupCodes.contains(groupCode)) {
          DocumentList groupDoc = await databases.listDocuments(
            databaseId: DATABASE_ID,
            collectionId: GROUP_COLLECTION_ID,
            queries: [Query.equal('groupCode', groupCode)],
          );

          if (groupDoc.documents.isNotEmpty) {
            String groupName = groupDoc.documents.first.data['groupName'];
            groupNames.add(groupName);
            groupCodes.add(groupCode);

            await LocalStorage.saveGroup(groupCode, {
              'groupName': groupName,
              'groupCode': groupCode,
              'members': [userId],
            });
          }
        }
      }

      await LocalStorage.saveUser(userId, {
        'id': userId,
        'groups': groups,
      });
    }

    return {'groupNames': groupNames, 'groupCodes': groupCodes};
  } catch (e) {
    print('ERROR fetching user groups: $e');
    return {'groupNames': [], 'groupCodes': []};
  }
}
  Future<bool> isDuplicateGroupName(String creatorId, String groupName) async {
    try {
      final result = await databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [
          Query.equal('creatorId', creatorId),
          Query.equal('groupName', groupName),
        ],
      );

      return result.total > 0;
    } catch (e) {
      print('ERROR checking duplicate group: $e');
      return false;
    }
  }

  Future<String> generateUniqueCode() async {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    Random random = Random();
    String code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return code;
  }
}