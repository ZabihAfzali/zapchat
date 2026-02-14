import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zapchat/core/constants/asset_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final Color backgroundColor;
  final PreferredSizeWidget? bottom;


  final VoidCallback? onPersonTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAddFriendTap;
  final VoidCallback? onSettingsTap;

  /// NEW PARAMETER
  final bool showAddBackground;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.backgroundColor = Colors.black,
    this.onPersonTap,
    this.onSearchTap,
    this.onAddFriendTap,
    this.onSettingsTap,
    this.bottom,
    this.showAddBackground = true, // default yellow background
  });
  @override
  Size get preferredSize =>
      Size.fromHeight(56.h + (bottom?.preferredSize.height ?? 0));


  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56.h,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onPersonTap,
                    icon: SvgPicture.asset(
                      AssetConstants.personIcon,
                      width: 30.w,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: onSearchTap,
                    icon: SvgPicture.asset(
                      AssetConstants.searchIcon,
                      width: 25.w,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign:
                      centerTitle ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onAddFriendTap,
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: showAddBackground
                          ? const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      )
                          : null,
                      child: SvgPicture.asset(
                        AssetConstants.addFriend,
                        width: 20.w,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onSettingsTap,
                    icon: SvgPicture.asset(
                      AssetConstants.settingsIcon,
                      width: 25.w,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }

}
