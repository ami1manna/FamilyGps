import 'package:flutter/material.dart';

class HomeDraggableBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.05, // Initial height of the bottom sheet (20% of screen)
      minChildSize: 0.05,     // Minimum height (20%)
      maxChildSize: 0.8,     // Maximum height (80%)
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0), // Add padding for better layout
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('User 1'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('User 2'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('User 3'),
              ),
              // Add more content here
            ],
          ),
        );
      },
    );
  }
}
