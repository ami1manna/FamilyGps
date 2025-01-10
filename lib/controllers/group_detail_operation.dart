import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/hive/grp_detail_service.dart';
import 'package:familygps/hive/user_detail_service.dart';
import 'package:familygps/models/hive_models.dart';

class DetailGroupOperation {
  late Client client;
  late Databases _databases;
  final HiveServiceGroupDetails _hiveGroupService = HiveServiceGroupDetails();
  final HiveServiceUserDetails _hiveUserService = HiveServiceUserDetails();

  DetailGroupOperation() {
    client =
        Client().setEndpoint(END_POINT).setProject(PROJECT_ID).setSelfSigned();
    _databases = Databases(client);
  }

  // Centralized method to fetch group document by group code
  Future<Document?> _fetchGroupDocument(String groupCode) async {
    try {
      DocumentList groupDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        queries: [Query.equal('groupCode', groupCode)],
      );

      return groupDoc.total > 0 ? groupDoc.documents[0] : null;
    } catch (e) {
      print('Error fetching group document: $e');
      return null;
    }
  }

  // Centralized method to fetch user document by ID
  Future<Document?> _fetchUserDocument(String userId) async {
    try {
      return await _databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        documentId: userId,
      );
    } catch (e) {
      print('Error fetching user document: $e');
      return null;
    }
  }

  // Centralized method to fetch user document by email
  Future<Document?> _fetchUserDocumentByEmail(String email) async {
    try {
      DocumentList userDoc = await _databases.listDocuments(
        databaseId: DATABASE_ID,
        collectionId: USERS_COLLECTION_ID,
        queries: [Query.equal('email', email)],
      );

      return userDoc.total > 0 ? userDoc.documents[0] : null;
    } catch (e) {
      print('Error fetching user document by email: $e');
      return null;
    }
  }

  Future<List<String>> fetchGroupMemberIds(String groupCode) async {
    try {
      // Check if local data is available
      final localData = _hiveGroupService.getGroupDetails(groupCode);
      if (localData != null && localData.members.isNotEmpty) {
        return localData.members.map((member) => member.toString()).toList();
      }

      // Fetch from database if local data is not available
      Document? groupDoc = await _fetchGroupDocument(groupCode);
      return groupDoc != null
          ? List<String>.from(groupDoc.data['members'] ?? [])
          : [];
    } catch (e) {
      print('Error fetching group member IDs: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchGroupMembers(String groupCode) async {
    try {
      // Check if local data is available
      final localData = _hiveGroupService.getGroupDetails(groupCode);
      if (localData != null && localData.members.isNotEmpty) {
        List<Map<String, String>> memberDetails = [];

        for (String userId in localData.members) {
          // Check if user details are available in Hive
          UserDetailModel? localUserDetails =
              _hiveUserService.getUserDetails(userId);
          if (localUserDetails != null) {
            memberDetails.add({
              'userId': userId,
              'name': localUserDetails.name,
              'email': localUserDetails.email,
              'lat': localUserDetails.lat?.toString() ?? 'Unknown',
              'long': localUserDetails.long?.toString() ?? 'Unknown',
              'status': localUserDetails.status,
            });
          } else {
            // Fetch user details from database if not available in Hive
            Document? userDoc = await _fetchUserDocument(userId);
            if (userDoc != null) {
              // Save fetched user details to Hive for future use
              UserDetailModel newUserDetails = UserDetailModel(
                userId: userId,
                name: userDoc.data['name'] ?? 'Unknown',
                email: userDoc.data['email'] ?? 'Unknown',
                lat: double.tryParse(userDoc.data['lat']?.toString() ?? '0'),
                long: double.tryParse(userDoc.data['long']?.toString() ?? '0'),
                status: userDoc.data['status'] ?? 'offline',
              );
              await _hiveUserService.saveUserDetails(newUserDetails);

              memberDetails.add({
                'userId': userId,
                'name': userDoc.data['name'] ?? 'Unknown',
                'email': userDoc.data['email'] ?? 'Unknown',
                'lat': userDoc.data['lat']?.toString() ?? 'Unknown',
                'long': userDoc.data['long']?.toString() ?? 'Unknown',
                'status': userDoc.data['status'] ?? 'offline',
              });
            }
          }
        }

        return memberDetails;
      }

      // Fetch from database if local data is not available
      Document? groupDoc = await _fetchGroupDocument(groupCode);
      if (groupDoc == null) return [];

      List<dynamic> members = groupDoc.data['members'] ?? [];
      List<Map<String, String>> memberDetails = [];

      for (String userId in members) {
        Document? userDoc = await _fetchUserDocument(userId);
        if (userDoc != null) {
          // Save fetched user details to Hive for future use
          UserDetailModel newUserDetails = UserDetailModel(
            userId: userId,
            name: userDoc.data['name'] ?? 'Unknown',
            email: userDoc.data['email'] ?? 'Unknown',
            lat: double.tryParse(userDoc.data['lat']?.toString() ?? '0'),
            long: double.tryParse(userDoc.data['long']?.toString() ?? '0'),
            status: userDoc.data['status'] ?? 'offline',
          );
          await _hiveUserService.saveUserDetails(newUserDetails);

          memberDetails.add({
            'userId': userId,
            'name': userDoc.data['name'] ?? 'Unknown',
            'email': userDoc.data['email'] ?? 'Unknown',
            'lat': userDoc.data['lat']?.toString() ?? 'Unknown',
            'long': userDoc.data['long']?.toString() ?? 'Unknown',
            'status': userDoc.data['status'] ?? 'offline',
          });
        }
      }

      return memberDetails;
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  // In addUserToGroup method
  Future<String> addUserToGroup(String groupCode, String email) async {
    try {
      // Fetch user by email
      Document? userDoc = await _fetchUserDocumentByEmail(email);
      if (userDoc == null) {
        return 'User not found with the provided email';
      }

      String userId = userDoc.$id;
      Document? groupDoc = await _fetchGroupDocument(groupCode);

      if (groupDoc == null) {
        return 'Group not found';
      }

      // Convert dynamic list to List<String>
      List<String> members = (groupDoc.data['members'] as List<dynamic> ?? [])
          .map((member) => member.toString())
          .toList();

      if (members.contains(userId)) {
        return 'User is already a member of the group';
      }

      // Update group members
      members.add(userId);
      await _databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        documentId: groupDoc.$id,
        data: {'members': members},
      );

      // Update user groups
      List<String> userGroups = (userDoc.data['groups'] as List<dynamic> ?? [])
          .map((group) => group.toString())
          .toList();

      if (!userGroups.contains(groupCode)) {
        userGroups.add(groupCode);
        await _databases.updateDocument(
          databaseId: DATABASE_ID,
          collectionId: USERS_COLLECTION_ID,
          documentId: userId,
          data: {'groups': userGroups},
        );
      }

      // Save updated group details in Hive
      GroupDetailModel updatedGroupDetails = GroupDetailModel(
        groupCode: groupCode,
        groupName: groupDoc.data['groupName'],
        creatorId: groupDoc.data['creatorId'],
        members: members,
      );
      await _hiveGroupService.saveGroupDetails(updatedGroupDetails);

      return 'User added successfully';
    } catch (e) {
      print('Error adding user to group: $e');
      return 'Failed to add user';
    }
  }

// In deleteGroup method
  Future<String> deleteGroup(String groupCode) async {
    try {
      Document? groupDoc = await _fetchGroupDocument(groupCode);
      if (groupDoc == null) {
        return 'Group not found';
      }

      // Convert dynamic list to List<String>
      List<String> members = (groupDoc.data['members'] as List<dynamic> ?? [])
          .map((member) => member.toString())
          .toList();

      // Delete group document
      await _databases.deleteDocument(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        documentId: groupDoc.$id,
      );

      // Batch update user documents
      List<Future<void>> updateFutures = members.map((userId) async {
        try {
          Document? userDoc = await _fetchUserDocument(userId);
          if (userDoc != null) {
            // Convert dynamic list to List<String>
            List<String> userGroups =
                (userDoc.data['groups'] as List<dynamic> ?? [])
                    .map((group) => group.toString())
                    .toList();

            userGroups.remove(groupCode);

            await _databases.updateDocument(
              databaseId: DATABASE_ID,
              collectionId: USERS_COLLECTION_ID,
              documentId: userId,
              data: {'groups': userGroups},
            );
          }
        } catch (e) {
          print('Error updating user document for $userId: $e');
        }
      }).toList();

      await Future.wait(updateFutures);

      // Remove group details from Hive
      await _hiveGroupService.deleteGroupDetails(groupCode);

      return 'Group deleted successfully';
    } catch (e) {
      print('Error deleting group: $e');
      return 'Failed to delete group';
    }
  }

  Future<String> deleteUserFromGroup(String groupCode, String userId) async {
    try {
      Document? groupDoc = await _fetchGroupDocument(groupCode);
      if (groupDoc == null) {
        return 'Group not found';
      }

      // Convert dynamic list to List<String>
      List<String> members = (groupDoc.data['members'] as List<dynamic> ?? [])
          .map((member) => member.toString())
          .toList();

      if (!members.contains(userId)) {
        return 'User is not a member of this group';
      }

      // Remove user from group members
      members.remove(userId);
      await _databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: GROUP_COLLECTION_ID,
        documentId: groupDoc.$id,
        data: {'members': members},
      );

      // Fetch and update user's groups
      Document? userDoc = await _fetchUserDocument(userId);
      if (userDoc != null) {
        // Convert dynamic list to List<String>
        List<String> userGroups =
            (userDoc.data['groups'] as List<dynamic> ?? [])
                .map((group) => group.toString())
                .toList();

        userGroups.remove(groupCode);

        await _databases.updateDocument(
          databaseId: DATABASE_ID,
          collectionId: USERS_COLLECTION_ID,
          documentId: userId,
          data: {'groups': userGroups},
        );
      }

      // Update Hive with the new group details
      GroupDetailModel updatedGroupDetails = GroupDetailModel(
        groupCode: groupCode,
        groupName: groupDoc.data['groupName'],
        creatorId: groupDoc.data['creatorId'],
        members: members,
      );
      await _hiveGroupService.saveGroupDetails(updatedGroupDetails);

      return 'User deleted successfully';
    } catch (e) {
      print('Error deleting user from group: $e');
      return 'Failed to delete user from group';
    }
  }

  Future<String> fetchGroupNameByCode(String groupCode) async {
    try {
      Document? groupDoc = await _fetchGroupDocument(groupCode);
      return groupDoc != null
          ? groupDoc.data['groupName'].toString()
          : 'Group not found';
    } catch (e) {
      print('Error fetching group name: $e');
      return 'Failed to fetch group name';
    }
  }

  Future<String> fetchGroupCreatorId(String groupCode) async {
    try {
      Document? groupDoc = await _fetchGroupDocument(groupCode);
      return groupDoc != null ? groupDoc.data['creatorId'].toString() : '';
    } catch (e) {
      print('Error fetching group creator ID: $e');
      return '';
    }
  }




}
