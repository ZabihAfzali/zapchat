import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';
import 'package:zapchat/features/home/repository/home_repository.dart';
import 'package:zapchat/features/home/widgets/discover_card.dart';
import 'package:zapchat/features/home/widgets/story_circle.dart';

import '../../../core/widgets/custom_appbar.dart';
import '../../auth/bloc/auth_events.dart';
import '../widgets/chat_items.dart';

class HomeTab extends StatefulWidget {
  final HomeRepository homeRepository;

  const HomeTab({super.key, required this.homeRepository});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _friends = await widget.homeRepository.getFriends();
      _stories = await widget.homeRepository.getStories();
    } catch (e) {
      print('Error loading home data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.homeRepository.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: HomeAppBar(
        onLogout: () {
         // BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());
        },
        onSearch: () {},
        onAdd: () {},
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _buildBody(user),
    );
  }

  Widget _buildBody(User? user) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // Welcome section
            _buildWelcomeSection(user),

            SizedBox(height: 30.h),

            // Quick Actions
            _buildQuickActions(),

            SizedBox(height: 40.h),

            // Stories
            _buildStoriesSection(),

            SizedBox(height: 40.h),

            // Recent Chats
            _buildRecentChats(),

            SizedBox(height: 40.h),

            // Discover
            _buildDiscoverSection(),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome,',
          style: TextStyle(
            fontSize: 24.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          user?.displayName?.split(' ').first ?? 'User',
          style: TextStyle(
            fontSize: 32.sp,
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),

        Row(
          children: [
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Snap',
              color: Colors.yellow,
              onTap: () {},
            ),
            SizedBox(width: 16.w),
            _buildActionButton(
              icon: Icons.video_call,
              label: 'Video',
              color: Colors.pink,
              onTap: () {},
            ),
            SizedBox(width: 16.w),
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Memories',
              color: Colors.purple,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.black, size: 24.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stories',
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        SizedBox(
          height: 100.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add story button
              StoryCircle(
                name: 'Add',
                isAddButton: true,
                onTap: () {},
              ),
              SizedBox(width: 16.w),

              // Stories list
              ..._stories.map((story) {
                return Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: StoryCircle(
                    name: story['name'],
                    hasStory: true,
                    isLive: story['isLive'],
                    isUnseen: story['isUnseen'],
                    onTap: () {},
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Chats',
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Chat list
        Column(
          children: _friends.take(3).map((friend) {
            return ChatItem(
              name: friend['name'],
              lastMessage: friend['lastMessage'],
              time: friend['time'],
              unread: friend['unread'],
              hasStory: friend['hasStory'],
              onTap: () {},
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscoverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.8,
          children: [
            DiscoverCard(
              title: 'Travel Diaries',
              color: Colors.blue,
              onTap: () {},
            ),
            DiscoverCard(
              title: 'Food Fun',
              color: Colors.orange,
              onTap: () {},
            ),
            DiscoverCard(
              title: 'Tech News',
              color: Colors.green,
              onTap: () {},
            ),
            DiscoverCard(
              title: 'Fashion Week',
              color: Colors.pink,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}