import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey[900]!, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        items: _buildNavItems(),
        currentIndex: currentIndex,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        onTap: onTap,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined, size: 28),
        activeIcon: Icon(Icons.home, size: 28),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline, size: 28),
        activeIcon: Icon(Icons.chat_bubble, size: 28),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.camera_alt_outlined, size: 28),
        activeIcon: Icon(Icons.camera_alt, size: 28),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.play_arrow_outlined, size: 28),
        activeIcon: Icon(Icons.play_arrow, size: 28),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline, size: 28),
        activeIcon: Icon(Icons.person, size: 28),
        label: '',
      ),
    ];
  }
}