import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor = Colors.black,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: actions,
    );
  }
}

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onSearch;
  final VoidCallback? onAdd;

  const HomeAppBar({
    super.key,
    this.onLogout,
    this.onSearch,
    this.onAdd,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(
        'ZapChat',
        style: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onSearch ?? () {},
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
        ),
        SizedBox(width: 8.w),
        IconButton(
          onPressed: onAdd ?? () {},
          icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 28),
        ),
        SizedBox(width: 8.w),

        SizedBox(width: 12.w),
      ],
    );
  }
}