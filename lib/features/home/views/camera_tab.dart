import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CameraTab extends StatelessWidget {
  const CameraTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview area
          Container(
            color: Colors.grey[900],
          ),

          // Top controls
          Positioned(
            top: 40.h,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.flash_on, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 16.w),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.timer, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Mode selector
                Container(
                  width: 200.w,
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PHOTO',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'VIDEO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        'DUAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // Camera button and gallery
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(Icons.photo_library, color: Colors.white, size: 24.sp),
                      ),
                    ),

                    // Capture button
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 65.w,
                          height: 65.h,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Flip camera
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 24.sp),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30.h),

                // Bottom menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCameraMenuIcon(Icons.text_fields, 'Text'),
                    _buildCameraMenuIcon(Icons.brush, 'Draw'),
                    _buildCameraMenuIcon(Icons.crop, 'Crop'),
                    _buildCameraMenuIcon(Icons.face, 'Filters'),
                    _buildCameraMenuIcon(Icons.music_note, 'Music'),
                  ],
                ),
              ],
            ),
          ),

          // Right side controls
          Positioned(
            right: 16.w,
            top: 120.h,
            child: Column(
              children: [
                _buildSideControl(Icons.photo_camera, 'Snap'),
                SizedBox(height: 20.h),
                _buildSideControl(Icons.videocam, 'Video'),
                SizedBox(height: 20.h),
                _buildSideControl(Icons.grid_3x3, 'Grid'),
                SizedBox(height: 20.h),
                _buildSideControl(Icons.settings, 'Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraMenuIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildSideControl(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}