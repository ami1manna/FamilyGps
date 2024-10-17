// bottom_nav.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int) onTabChange;

  const BottomNavBar({super.key, required this.onTabChange});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      widget.onTabChange(index);
    });

    // Start the animation when an icon is tapped
    _controller.forward().then((_) => _controller.reverse());
  }

  Widget _buildIcon(IconData icon, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: isSelected ? const EdgeInsets.all(5) : const EdgeInsets.all(0),
      child: Icon(
        icon,
        size: isSelected ? 35 : 30,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        shadows: const [Shadow(color: Colors.black, blurRadius: 1)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.map_outlined, _selectedIndex == 0),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.person_add_outlined, _selectedIndex == 1),
          label: 'Friends',
        ),
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.graphic_eq_rounded, _selectedIndex == 2),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.account_circle_outlined, _selectedIndex == 3),
          label: 'Account',
        ),
      ],
    );
  }
}