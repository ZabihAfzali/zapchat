import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoryCircle extends StatelessWidget {
  final String name;
  final bool hasStory;
  final bool isLive;
  final bool isUnseen;
  final bool isAddButton;
  final VoidCallback? onTap;
  final double size;

  const StoryCircle({
    super.key,
    required this.name,
    this.hasStory = false,
    this.isLive = false,
    this.isUnseen = false,
    this.isAddButton = false,
    this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              // Story ring
              Container(
                width: size.w,
                height: size.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStory && isUnseen
                      ? const LinearGradient(
                    colors: [Colors.pink, Colors.orange, Colors.yellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: (hasStory && !isUnseen) ? Colors.grey[700] : null,
                ),
                padding: EdgeInsets.all(isAddButton ? 0 : 3.sp),
                child: isAddButton
                    ? _buildAddButton()
                    : _buildProfileInitial(),
              ),

              // Live badge
              if (isLive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (!isAddButton) SizedBox(height: 8.h),

          if (!isAddButton)
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: isUnseen ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[900],
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildProfileInitial() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[900],
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Text(
          name.substring(0, 1),
          style: TextStyle(
            color: Colors.white,
            fontSize: (size * 0.3).sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}