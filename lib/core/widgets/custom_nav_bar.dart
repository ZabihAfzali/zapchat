import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavItem {
  final String assetPath;
  final String label;
  final String activeLabel;
  final Size size;

  const NavItem({
    required this.assetPath,
    required this.label,
    required this.activeLabel,
    this.size = const Size(25, 25),
  });
}

class NavSvgIcon extends StatelessWidget {
  final NavItem item;
  final bool isActive;

  const NavSvgIcon({
    super.key,
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      item.assetPath,
      colorFilter: ColorFilter.mode(
        isActive ? Colors.yellow : Colors.grey,
        BlendMode.srcIn,
      ),
      width: item.size.width.w,
      height: item.size.height.h,
      fit: BoxFit.contain,
    );
  }
}

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static  final List<NavItem> _navItems = [
    NavItem(
      assetPath: 'assets/zapchat/Map_icon.svg',
      label: 'map',
      activeLabel: 'Map',
      size: Size(28.sp, 28.sp),
    ),
    NavItem(
      assetPath: 'assets/zapchat/Chat_icon.svg',
      label: 'chat',
      activeLabel: 'Chat',
      size: Size(24.sp, 24.sp),
    ),
    NavItem(
      assetPath: 'assets/zapchat/Camera_icon.svg',
      label: 'camera',
      activeLabel: 'Camera',
      size: Size(20.sp, 20.sp ), // Larger camera icon
    ),
    NavItem(
      assetPath: 'assets/zapchat/Vector_friend_icon.svg',
      label: 'friends',
      activeLabel: 'Friends',
      size: Size(18.sp, 18.sp),
    ),
    NavItem(
      assetPath: 'assets/zapchat/Discover_icon.svg',
      label: 'discover',
      activeLabel: 'Discover',
      size: Size(20.sp, 20.sp),
    ),
  ];

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
        currentIndex: currentIndex.clamp(0, _navItems.length - 1),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: onTap,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    return _navItems.map((item) {
      return BottomNavigationBarItem(
        icon: NavSvgIcon(item: item, isActive: false),
        activeIcon: NavSvgIcon(item: item, isActive: true),
        label: item.label,
        tooltip: item.activeLabel,
      );
    }).toList();
  }
}