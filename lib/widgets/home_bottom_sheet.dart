import 'package:familygps/controllers/group_db_operation.dart';
import 'package:familygps/providers/locations_provider.dart';
import 'package:familygps/providers/user_provider.dart';
import 'package:familygps/widgets/home_bottom_sheet_group_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDraggableBottomSheet extends ConsumerStatefulWidget {
  const HomeDraggableBottomSheet({super.key});

  @override
  ConsumerState<HomeDraggableBottomSheet> createState() =>
      _HomeDraggableBottomSheetState();
}

class _HomeDraggableBottomSheetState
    extends ConsumerState<HomeDraggableBottomSheet> {
  List<String> userGroups = [];
  List<String> groupCode = [];
  bool isLoading = true;
  int _currentPage = 0;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    setState(() {
      isLoading = true;
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
          isLoading = false;
        });
      }
    }
  }

  void _navigateToGroupDetails(String groupName) {
    setState(() {
      _selectedGroup = groupName;

      _currentPage = 1;
    });
  }

  void _goBackToListView() {
    setState(() {
      _currentPage = 0;
      _selectedGroup = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                _currentPage == 0
                    ? _buildListView(context)
                    : _buildGroupDetails(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your Groups',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ),
        const SizedBox(height: 16),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: userGroups.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.primaries[index % Colors.primaries.length],
                        child: Text(
                          userGroups[index][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        userGroups[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        String selectedGroupCode = groupCode[index];
                        try {
                          
                          await ref
                              .read(userLocationProvider.notifier)
                              .fetchUserLocations(selectedGroupCode);

                          _navigateToGroupDetails(userGroups[index]);
                        } catch (e) {
                          print('Error fetching group member IDs: $e');
                          // Handle error (e.g., show a snackbar)
                        }
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildGroupDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBackToListView,
            ),
            const SizedBox(width: 30.0),
            Text(
              _selectedGroup ?? '',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ]),
          HomeBottomSheetGroupDetail()
        ],
      ),
    );
  }
}
