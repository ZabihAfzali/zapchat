import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DiscoverCard extends StatelessWidget {
  final String title;
  final String? imageUrl; // ADD THIS PARAMETER
  final Color color;
  final VoidCallback onTap;

  const DiscoverCard({
    super.key,
    required this.title,
    this.imageUrl, // ADD THIS
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          // USE THE imageUrl PARAMETER HERE
          image: imageUrl != null && imageUrl!.isNotEmpty
              ? DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          )
              : null,
          gradient: imageUrl == null || imageUrl!.isEmpty
              ? LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 16.h,
              left: 12.w,
              right: 12.w,
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}