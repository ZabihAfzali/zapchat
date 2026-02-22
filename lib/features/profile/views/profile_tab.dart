import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/core/routes/route_names.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';
import 'package:zapchat/features/auth/bloc/auth_events.dart';
import 'package:zapchat/features/profile/bloc/profile_bloc.dart';
import 'package:zapchat/features/profile/bloc/profile_event.dart';
import 'package:zapchat/features/profile/bloc/profile_state.dart';
import 'package:zapchat/features/profile/repository/profile_repository.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:zapchat/features/stories/views/stories_tab.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  final ProfileRepository profileRepository;

  const ProfileTab({super.key, required this.profileRepository});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadUserData());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text(state.message),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final userData = (state is ProfileLoaded) ? state.userData : {};
          final displayName = userData['displayName'] ?? user?.displayName ?? 'User';
          final profileImageUrl = userData['profileImage'] as String?;
          final email = userData['email'] ?? user?.email ?? 'No email';
          final bio = userData['bio'] as String?;
          final friends = (userData['friends'] ?? 0).toString();
          final stories = (userData['stories'] ?? 0).toString();
          final snaps = (userData['snaps'] ?? 0).toString();

          return CustomScrollView(
            slivers: [
              // Large profile header with background image
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 340.h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Large blurred background profile image
                      if (profileImageUrl != null && profileImageUrl.isNotEmpty)
                        Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.45), // subtle darken + blur simulation
                          colorBlendMode: BlendMode.darken,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: child,
                            );
                          },
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF5E35B1), Color(0xFFD81B60), Color(0xFFFF9800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),

                      // Foreground content
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _pushAndRefresh(EditProfileScreen()),
                              child: Container(
                                width: 140.w,
                                height: 140.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: CupertinoColors.white, width: 4.w),
                                  color: CupertinoColors.systemYellow,
                                  image: profileImageUrl != null && profileImageUrl.isNotEmpty
                                      ? DecorationImage(
                                    image: NetworkImage(profileImageUrl),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                                child: profileImageUrl == null || profileImageUrl.isEmpty
                                    ? Center(
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 64.sp,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: CupertinoColors.white.withOpacity(0.85),
                              ),
                            ),
                            if (bio != null && bio.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40.w),
                                child: Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: CupertinoColors.white.withOpacity(0.75),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats
              SliverToBoxAdapter(
                child: Container(
                  color: CupertinoColors.systemBackground.darkColor,
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(friends, 'Friends'),
                      _buildStatItem(stories, 'Stories'),
                      _buildStatItem(snaps, 'Snaps'),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              // Menu sections
              SliverList(
                delegate: SliverChildListDelegate([
                  CupertinoListSection.insetGrouped(
                    header: const Text('Account'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.person_crop_circle),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () => _pushAndRefresh(EditProfileScreen()),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.rectangle_stack),
                        title: const Text('My Stories'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (_) => const StoriesTab()),
                        ),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('Preferences'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.bubble_left_bubble_right),
                        title: const Text('Chat Settings'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.bell),
                        title: const Text('Notifications'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.lock),
                        title: const Text('Privacy'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.question_circle),                        title: const Text('Help & Support'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.info_circle),
                        title: const Text('About'),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.square_arrow_right),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemRed,
                        ),
                        onTap: () => _showLogoutConfirmation(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 60.h),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.systemYellow,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  void _pushAndRefresh(Widget screen) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => screen),
    ).then((_) {
      context.read<ProfileBloc>().add(LoadUserData());
    });
  }

  void _showLogoutConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Log Out'),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.login,
                    (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}