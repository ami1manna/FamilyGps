import 'package:familygps/controllers/group_detail_operation.dart';
import 'package:familygps/widgets/Toast.dart';
import 'package:flutter/material.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final TextEditingController _memberController = TextEditingController();
  List<String> _members = [];
  bool _isLoading = false;
  String _groupName = "Loading...";
  late String groupCode;

  final DetailGroupOperation _groupOperation = DetailGroupOperation();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    groupCode = ModalRoute.of(context)!.settings.arguments as String;
    print('Group code: $groupCode');
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<String> members = await _groupOperation.fetchGroupMembers(groupCode);
      String groupName = await _groupOperation.fetchGroupNameByCode(groupCode);

      setState(() {
        _members = members;
        _groupName = groupName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching group details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addMember() async {
    String newMember = _memberController.text.trim();
    if (newMember.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid user ID')));
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String result = await _groupOperation.addUserToGroup(groupCode, newMember);
      if (result == 'User added successfully') {
        _fetchGroupDetails();
        _memberController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      print('Error adding member: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      String result = await _groupOperation.deleteUserFromGroup(groupCode, userId);
      if (result == 'User deleted successfully') {
        _fetchGroupDetails();
      } else {
       Toast.show(context, result , ToastType.success);
      }
    } catch (e) {
      print('Error deleting user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _deleteGroup() async {
  try {
    setState(() {
      _isLoading = true;
    });

    String result = await _groupOperation.deleteGroup(groupCode);
    if (result == 'Group deleted successfully') {
      Navigator.pop(context, true); // Pass true to indicate the group was deleted
      Toast.show(context,result, ToastType.success);
    } else {
      Toast.show(context,result, ToastType.error);
    }
  } catch (e) {
    print('Error deleting group: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName),
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
                      labelText: 'Enter User ID to Add',
                      hintText: 'e.g., user123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addMember,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _members.isEmpty
                      ? const Center(child: Text('No members found'))
                      : ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: const Icon(Icons.person, color: Colors.purple),
                                title: Text(
                                  _members[index],
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(_members[index]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
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
