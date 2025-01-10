import 'package:familygps/models/users_locations.dart';
import 'package:familygps/providers/locations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeBottomSheetGroupDetail extends ConsumerStatefulWidget {
  const HomeBottomSheetGroupDetail({super.key});

 

  @override
  ConsumerState<HomeBottomSheetGroupDetail> createState() => _HomeBottomSheetGroupDetailState();
}
class _HomeBottomSheetGroupDetailState extends ConsumerState<HomeBottomSheetGroupDetail> {
  @override
  Widget build(BuildContext context) {
    final userLocations = ref.watch(userLocationProvider);
    // Use .notifier to access the provider instance and its properties
    final selectedUser = ref.watch(userLocationProvider.notifier).selectedUser;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.0),
        userLocations.isEmpty
            ? Center(
                child: Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: userLocations.map<Widget>((user) {
                    return Card(
                      color: selectedUser?.userId == user.userId 
                          ? Colors.white
                          : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: selectedUser?.userId == user.userId ? 4.0 : 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: selectedUser?.userId == user.userId 
                            ? BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), width: 2.0)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          backgroundColor: selectedUser?.userId == user.userId 
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            user.name[0],
                            style: TextStyle(
                              color: selectedUser?.userId == user.userId 
                                  ? Colors.white 
                                  : Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: selectedUser?.userId == user.userId 
                                ? Theme.of(context).primaryColor 
                                : Colors.blueGrey[800],
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${user.userId}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: selectedUser?.userId == user.userId 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[600],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16.0,
                          color: selectedUser?.userId == user.userId 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[600],
                        ),
                        onTap: () {
                          ref.read(userLocationProvider.notifier).setSelectedUser(user);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}