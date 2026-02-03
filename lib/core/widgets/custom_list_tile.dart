import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const CustomListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.white,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          color: textColor ?? Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle!,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[400],
        ),
      )
          : null,
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 24.sp,
      ),
      onTap: onTap,
    );
  }
}