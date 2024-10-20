import 'package:familygps/controllers/group_db_operation.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/widgets/Toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  TextEditingController groupNameController = TextEditingController();
  List<String> userGroups = [];
  List<String> groupCodes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  // Function to fetch groups the user is part of
  void _fetchUserGroups() async {
    final user = ref.read(userProvider);
    if (user != null && user.userid != null) {
      setState(() {
        isLoading = true;
      });
      var result = await GroupDbOperation().fetchUserGroups(user.userid!);
      setState(() {
        userGroups = result['groupNames'];
        groupCodes = result['groupCodes'];
        isLoading = false;
      });
    }
  }

  // Function to create a new group
  void _createGroup() async {
    final user = ref.read(userProvider);
    if (user != null && user.userid != null) {
      String groupName = groupNameController.text.trim();

      if (groupName.isEmpty) {
        // Display error if group name is empty
        Toast.show(context, 'Please enter a valid group name.', ToastType.error);
        return;
      }

      // Call the createGroup function and capture the response message
      String result = await GroupDbOperation().createGroup(user.userid!, groupName);

      // Display the message returned by createGroup function
      if (result.startsWith('ERROR')) {
        Toast.show(context, result, ToastType.error); // Display error toast
      } else {
        Toast.show(context, result, ToastType.success); // Display success toast
        groupNameController.clear(); // Clear the text field
        _fetchUserGroups(); // Refresh the group list
      }
    } else {
      Toast.show(context, 'Error: User not found.', ToastType.error);
    }
  }

  // Function to navigate to the Group Detail Screen
 void _openGroupDetail(String groupCode) async {
  final result = await Navigator.pushNamed(context, '/groupDetail', arguments: groupCode);

  // Check if the group was deleted
  if (result == true) {
    _fetchUserGroups(); // Refresh the group list
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(13.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                      hintText: 'Enter Group Name',
                      hintStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.values[1],
                      ),
                      prefixIcon: Icon(Icons.group, color: Theme.of(context).primaryColor),
                      filled: true,
                      fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _createGroup,
                  icon: Icon(
                    Icons.save,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator()) // Show loading spinner
                : userGroups.isEmpty
                    ? const Center(child: Text('No Groups Yet')) // Show message if no groups
                    : ListView.builder(
                        itemCount: userGroups.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _openGroupDetail(groupCodes[index]); // Pass the group code on tap
                            },
                            child: Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                leading: Icon(Icons.group, color: Theme.of(context).primaryColor),
                                title: Text(
                                  userGroups[index],
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
