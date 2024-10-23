import 'package:familygps/controllers/group_db_operation.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDraggableBottomSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeDraggableBottomSheet> createState() =>
      _HomeDraggableBottomSheetState();
}

class _HomeDraggableBottomSheetState
    extends ConsumerState<HomeDraggableBottomSheet> {
  List<String> userGroups = [];
  List<String> groupCode = [];

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  void _fetchUserGroups() async {
    final user = ref.read(userProvider);
    if (user != null && user.userid != null) {
      var result = await GroupDbOperation().fetchUserGroups(user.userid!);
      setState(() {
        userGroups = result['groupNames'];
        groupCode = result['groupCodes'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.05,
      minChildSize: 0.05,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 236, 224, 252),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Column(children: [
           
            Center(
              child: Container(
                width: double.infinity,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(166, 180, 176, 185),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0).copyWith(top: 12),
                itemCount: userGroups.length, // Set the number of items
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.group),
                    title:
                        Text(userGroups[index]), // Display only the group name
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}
