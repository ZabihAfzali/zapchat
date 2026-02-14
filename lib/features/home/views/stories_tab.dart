import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/features/home/repository/home_repository.dart';
import 'package:zapchat/features/home/widgets/discover_card.dart';
import 'package:zapchat/features/home/widgets/story_circle.dart';

import '../../../core/widgets/custom_appbar.dart';

class StoriesTab extends StatefulWidget {
  final HomeRepository homeRepository;

  const StoriesTab({super.key, required this.homeRepository});

  @override
  State<StoriesTab> createState() => _StoriesTabState();
}

class _StoriesTabState extends State<StoriesTab> {
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      _stories = await widget.homeRepository.getStories();
    } catch (e) {
      print('Error loading stories: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Stories',

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // Add to story
            _buildAddStoryCard(),

            SizedBox(height: 30.h),

            // Friends' stories
            _buildFriendsStories(),

            SizedBox(height: 30.h),

            // Discover
            _buildDiscoverSection(),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.pink, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Add to Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsStories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Friends\' Stories',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        // Stories list
        SizedBox(
          height: 130.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
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

  Widget _buildDiscoverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        // Discover grid
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