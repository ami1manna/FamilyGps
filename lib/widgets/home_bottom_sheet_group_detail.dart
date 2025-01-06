import 'package:familygps/providers/locations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeBottomSheetGroupDetail extends ConsumerStatefulWidget {
  HomeBottomSheetGroupDetail({super.key});

 

  @override
  ConsumerState<HomeBottomSheetGroupDetail> createState() => _HomeBottomSheetGroupDetailState();
}

class _HomeBottomSheetGroupDetailState extends ConsumerState<HomeBottomSheetGroupDetail> {
  @override
  Widget build(BuildContext context) {
    // Watch the userLocationProvider to get the latest state
    final userLocations = ref.watch(userLocationProvider);

    return  Column(
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
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              user.name[0], // Display the first letter of the user's name
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${user.userId}',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      
    );
  }
}