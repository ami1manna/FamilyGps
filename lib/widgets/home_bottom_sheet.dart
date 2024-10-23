import 'package:familygps/controllers/group_db_operation.dart';
import 'package:familygps/controllers/group_detail_operation.dart';
import 'package:familygps/providers/locations_provider.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDraggableBottomSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeDraggableBottomSheet> createState() => _HomeDraggableBottomSheetState();
}

class _HomeDraggableBottomSheetState extends ConsumerState<HomeDraggableBottomSheet> {
  List<String> userGroups = [];
  List<String> groupCode = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    final user = ref.read(userProvider);
    if (user != null && user.userid != null) {
      try {
        var result = await GroupDbOperation().fetchUserGroups(user.userid!);
        setState(() {
          userGroups = result['groupNames'];
          groupCode = result['groupCodes'];
        });
      } catch (e) {
        print('Error fetching user groups: $e');
        // Handle error (e.g., show a snackbar)
      } finally {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              child: isLoading 
                  ? const Center(child: CircularProgressIndicator()) // Loading indicator
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0).copyWith(top: 12),
                      itemCount: userGroups.length, // Set the number of items
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(userGroups[index]),
                          onTap: () async {
                            String selectedGroupCode = groupCode[index];
                            try {
                              List<String> memberIds = await DetailGroupOperation().fetchGroupMemberIds(selectedGroupCode);
                              
                              // Fetch location data
                              await ref.read(userLocationProvider.notifier).fetchUserLocations(memberIds);
                            } catch (e) {
                              print('Error fetching group member IDs: $e');
                              // Handle error (e.g., show a snackbar)
                            }
                          },     
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
