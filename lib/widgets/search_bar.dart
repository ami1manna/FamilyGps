import 'package:familygps/providers/name_email_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class UsersSearchBar extends ConsumerStatefulWidget {
  const UsersSearchBar({super.key});

  @override
  ConsumerState<UsersSearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<UsersSearchBar> {
  TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    // Fetch the initial list of users
    ref.read(nameEmailProvider.notifier).setUsersList();
  }

  @override
  Widget build(BuildContext context) {
    final usersList = ref.watch(nameEmailProvider);

    // Filter the user list based on the search query
    List<String> filterUsers() {
      if (searchText.isEmpty) {
        return usersList;
      } else {
        return usersList
            .where((user) => user.toLowerCase().contains(searchText.toLowerCase()))
            .toList();
      }
    }

    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: (value) {
            // Update searchText with new input
            setState(() {
              searchText = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'Search Users',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: filterUsers().length,
            itemBuilder: (context, index) {
              final user = filterUsers()[index];
              return ListTile(
                title: Text(user),
              );
            },
          ),
        ),
      ],
    );
  }
}
