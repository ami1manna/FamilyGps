import 'package:familygps/models/hive_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familygps/hive/grp_detail_service.dart';
import 'package:familygps/controllers/group_detail_operation.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/widgets/Toast.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  // Controllers and Services
  final TextEditingController _memberController = TextEditingController();
  final HiveServiceGroupDetails _hiveService = HiveServiceGroupDetails();
  final DetailGroupOperation _groupOperation = DetailGroupOperation();

  // State Variables
  GroupDetailModel? _localGroupDetails;
  bool _isLoading = false;
  late String groupCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    groupCode = ModalRoute.of(context)!.settings.arguments as String;
    _initializeGroupDetails();
  }

  Future<void> _initializeGroupDetails() async {
    setState(() => _isLoading = true);

    // Fetch local data
    final localData = _hiveService.getGroupDetails(groupCode);

    // Determine if network fetch is needed
    if (_hiveService.shouldFetchFromNetwork(localData)) {
      await _fetchGroupDetailsFromNetwork();
    } else {
      setState(() {
        _localGroupDetails = localData;
        _isLoading = false;
      });
    }

    // Trigger background sync
    _backgroundSync();
  }
 // Method to fetch detailed member information
  Future<List<Map<String, String>>> _fetchMemberDetails() async {
    if (_localGroupDetails == null) return [];

    List<Map<String, String>> memberDetails = [];
    
    for (String userId in _localGroupDetails!.members) {
      // Fetch detailed member information using the existing method
      List<Map<String, String>> groupMembers = 
          await _groupOperation.fetchGroupMembers(_localGroupDetails!.groupCode);
      
      // Find the specific member
      final memberDetail = groupMembers.firstWhere(
        (member) => member['userId'] == userId,
        orElse: () => {
          'userId': userId,
          'name': 'Unknown',
          'email': 'Unknown',
          'status': 'Unknown',
          'lat': 'Unknown',
          'long': 'Unknown'
        }
      );

      memberDetails.add(memberDetail);
    }

    return memberDetails;
  }

  // Update background sync method
  Future<void> _backgroundSync() async {
    try {
      // Fetch member IDs using the existing method
      List<String> memberIds = await _groupOperation.fetchGroupMemberIds(groupCode);
      String groupName = await _groupOperation.fetchGroupNameByCode(groupCode);
      String creatorId = await _groupOperation.fetchGroupCreatorId(groupCode);

      final groupDetails = GroupDetailModel(
        groupCode: groupCode,
        groupName: groupName,
        creatorId: creatorId,
        members: memberIds,
        lastUpdated: DateTime.now(),
      );

      // Save to local storage
      await _hiveService.saveGroupDetails(groupDetails);

      // Update UI if different from current state
      if (mounted && (_localGroupDetails == null || 
          _localGroupDetails!.members != groupDetails.members)) {
        setState(() {
          _localGroupDetails = groupDetails;
        });
      }
    } catch (e) {
      print('Background sync error: $e');
    }
  }
  Future<void> _fetchGroupDetailsFromNetwork() async {
    try {
      final currentUser = ref.read(userProvider);
      List<Map<String, String>> members =
          await _groupOperation.fetchGroupMembers(groupCode);
      String groupName = await _groupOperation.fetchGroupNameByCode(groupCode);
      String creatorId = await _groupOperation.fetchGroupCreatorId(groupCode);

      final groupDetails = GroupDetailModel(
        groupCode: groupCode,
        groupName: groupName,
        creatorId: creatorId,
        members: members.map((m) => m['userId']!).toList(),
        lastUpdated: DateTime.now(),
      );

      // Save to local storage
      await _hiveService.saveGroupDetails(groupDetails);

      setState(() {
        _localGroupDetails = groupDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching group details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMember() async {
    String newMember = _memberController.text.trim();
    if (newMember.isEmpty) {
      Toast.show(context, 'Please enter a valid email', ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String result =
          await _groupOperation.addUserToGroup(groupCode, newMember);
      if (result == 'User added successfully') {
        await _backgroundSync();
        _memberController.clear();
        Toast.show(context, result, ToastType.success);
      } else {
        Toast.show(context, result, ToastType.error);
      }
    } catch (e) {
      print('Error adding member: $e');
      Toast.show(context, 'Failed to add member', ToastType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);

    try {
      String result =
          await _groupOperation.deleteUserFromGroup(groupCode, userId);
      if (result == 'User deleted successfully') {
        await _backgroundSync();
        Toast.show(context, result, ToastType.success);
      } else {
        Toast.show(context, result, ToastType.error);
      }
    } catch (e) {
      print('Error deleting user: $e');
      Toast.show(context, 'Failed to delete user', ToastType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGroup() async {
    setState(() => _isLoading = true);

    try {
      String result = await _groupOperation.deleteGroup(groupCode);
      if (result == 'Group deleted successfully') {
        await _hiveService.deleteGroupDetails(groupCode);
        Navigator.pop(context, true);
        Toast.show(context, result, ToastType.success);
      } else {
        Toast.show(context, result, ToastType.error);
      }
    } catch (e) {
      print('Error deleting group: $e');
      Toast.show(context, 'Failed to delete group', ToastType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }
@override
Widget build(BuildContext context) {
  // Get current user ID from provider
  final currentUser = ref.read(userProvider);
  final isUserCreator = _localGroupDetails?.creatorId == currentUser?.userid;

  return Scaffold(
    appBar: AppBar(
      title: Text(_localGroupDetails?.groupName ?? 'Group Details'),
      elevation: 10.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
      ),
      backgroundColor: Colors.purple,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _memberController,
                  decoration: InputDecoration(
                    labelText: 'Enter Email ID to Add',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: isUserCreator ? _addMember : null,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  enabled: isUserCreator,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _localGroupDetails?.members.isEmpty ?? true
                    ? const Center(child: Text('No members found'))
                    : FutureBuilder<List<Map<String, String>>>(
                        future: _fetchMemberDetails(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No members found'));
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final member = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: const Icon(Icons.person,
                                      color: Colors.purple),
                                  title: Text(
                                    member['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    member['email'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  trailing: isUserCreator
                                      ? IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteUser(
                                              member['userId']!),
                                        )
                                      : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              if (isUserCreator)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _deleteGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Delete Group',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
  );
}
}