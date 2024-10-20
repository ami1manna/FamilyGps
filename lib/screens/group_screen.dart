import 'package:familygps/controllers/group_db_operation.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/utils/store_data.dart';
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
      }
    } else {
      Toast.show(context, 'Error: User not found.', ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 30),
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
                    style: TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Group Name';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => _createGroup(),
                  icon: Icon(
                    Icons.save,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text('No Groups Yet'),
            ),
          ),
        ],
      ),
    );
  }
}
