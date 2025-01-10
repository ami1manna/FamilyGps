import 'package:familygps/models/hive_models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveServiceGroupDetails {
  static const String _groupBoxName = 'group_details';
Future<void> initHive() async {
  try {
    // Use path_provider to get the application documents directory
    final appDocumentDir = await getApplicationDocumentsDirectory();
    
    // Initialize Hive with the path
    await Hive.initFlutter(appDocumentDir.path);
    
    // Register adapters BEFORE opening any boxes
    _registerAdapters();
    
    // Open the boxes
    await Hive.openBox<GroupDetailModel>(_groupBoxName);
  } catch (e) {
    print('Error initializing Hive: $e');
    // Optionally, you might want to delete the existing Hive database
    await Hive.deleteBoxFromDisk(_groupBoxName);
    // Retry initialization
    await initHive();
  }
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UserDetailModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(GroupDetailModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(StringListAdapter());
  }
}

  // Save group details to the Hive box
  Future<void> saveGroupDetails(GroupDetailModel groupDetails) async {
    try {
      final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
      await box.put(groupDetails.groupCode, groupDetails);
    } catch (e) {
      print('Error saving group details: $e');
      rethrow;
    }
  }

  // Retrieve group details from the Hive box
  GroupDetailModel? getGroupDetails(String groupCode) {
    final box = Hive.box<GroupDetailModel>(_groupBoxName);
    return box.get(groupCode);
  }

  // Delete group details from the Hive box
  Future<void> deleteGroupDetails(String groupCode) async {
    try {
      final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
      await box.delete(groupCode);
    } catch (e) {
      print('Error deleting group details: $e');
      rethrow;
    }
  }

  // Check whether to fetch data from the network based on age of data
  bool shouldFetchFromNetwork(GroupDetailModel? localData) {
    if (localData == null) return true;

    // Refresh data if older than 5 minutes
    return DateTime.now().difference(localData.lastUpdated).inMinutes > 5;
  }

  // Update existing group details
  Future<void> updateGroupDetails(GroupDetailModel updatedGroupDetails) async {
    try {
      final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
      await box.put(updatedGroupDetails.groupCode, updatedGroupDetails);
    } catch (e) {
      print('Error updating group details: $e');
      rethrow;
    }
  }

  // Get all groups
  List<GroupDetailModel> getAllGroups() {
    final box = Hive.box<GroupDetailModel>(_groupBoxName);
    return box.values.toList();
  }

  // Get groups for a specific user
  List<GroupDetailModel> getUserGroups(String userId) {
    final box = Hive.box<GroupDetailModel>(_groupBoxName);
    return box.values.where((group) => group.members.contains(userId)).toList();
  }

  // Check if a group exists
  bool groupExists(String groupCode) {
    final box = Hive.box<GroupDetailModel>(_groupBoxName);
    return box.containsKey(groupCode);
  }

  // Add a member to a group
  Future<void> addMemberToGroup(String groupCode, String userId) async {
    try {
      final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
      GroupDetailModel? groupDetails = box.get(groupCode);
      
      if (groupDetails != null) {
        if (!groupDetails.members.contains(userId)) {
          groupDetails.members.add(userId);
          groupDetails.updateLastUpdated();
          await box.put(groupCode, groupDetails);
        }
      }
    } catch (e) {
      print('Error adding member to group: $e');
      rethrow;
    }
  }

  // Remove a member from a group
  Future<void> removeMemberFromGroup(String groupCode, String userId) async {
    try {
      final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
      GroupDetailModel? groupDetails = box.get(groupCode);
      
      if (groupDetails != null) {
        groupDetails.members.remove(userId);
        groupDetails.updateLastUpdated();
        await box.put(groupCode, groupDetails);
      }
    } catch (e) {
      print('Error removing member from group: $e');
      rethrow;
    }
  }

  // Close the Hive box when it's no longer needed
  Future<void> closeBox() async {
    final box = Hive.box<GroupDetailModel>(_groupBoxName);
    await box.close();
  }
}