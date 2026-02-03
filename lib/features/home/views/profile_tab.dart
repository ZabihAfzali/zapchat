import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/core/widgets/custom_list_tile.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';
import 'package:zapchat/features/home/repository/home_repository.dart';

import '../../../core/widgets/custom_appbar.dart';
import '../../auth/bloc/auth_events.dart';

class ProfileTab extends StatefulWidget {
  final HomeRepository homeRepository;

  const ProfileTab({super.key, required this.homeRepository});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      _userData = await widget.homeRepository.getUserData();
    } catch (e) {
      print('Error loading user data: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.homeRepository.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Profile',
        leading: Icon(Icons.settings, color: Colors.white, size: 28),
        actions: [
          Icon(Icons.logout, color: Colors.white, size: 28),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _buildBody(user),
    );
  }

  Widget _buildBody(User? user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 40.h),

          // Profile header
          Container(
            height: 200.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.pink, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile picture
                      Container(
                        width: 100.w,
                        height: 100.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.yellow,
                        ),
                        child: Center(
                          child: Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 48.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // User info
                      Text(
                        user?.displayName ?? 'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        user?.email ?? 'No email',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Container(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('125', 'Friends'),
                _buildStatItem('45', 'Stories'),
                _buildStatItem('1.2K', 'Snaps'),
              ],
            ),
          ),

          // Menu items
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Column(
              children: [
                CustomListTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.photo_library,
                  title: 'My Stories',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat Settings',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.security_outlined,
                  title: 'Privacy',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {},
                ),
                CustomListTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                  iconColor: Colors.red,
                  textColor: Colors.red,
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 16.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}