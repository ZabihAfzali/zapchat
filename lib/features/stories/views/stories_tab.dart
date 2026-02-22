import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapchat/features/stories/bloc/stories_bloc.dart';

import '../bloc/stories_events.dart';
import '../bloc/stories_states.dart';
import 'add_story_screen.dart';
import 'story_viewer_screen.dart';

class StoriesTab extends StatefulWidget {
  const StoriesTab({super.key});

  @override
  State<StoriesTab> createState() => _StoriesTabState();
}

class _StoriesTabState extends State<StoriesTab> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Store current context before async operations
    if (!mounted) return;

    // Check and request permissions if needed
    if (await Permission.photos.isDenied) {
      final status = await Permission.photos.request();
      print('Photos permission status: $status');
    }

    if (await Permission.videos.isDenied) {
      final status = await Permission.videos.request();
      print('Videos permission status: $status');
    }

    if (await Permission.camera.isDenied) {
      final status = await Permission.camera.request();
      print('Camera permission status: $status');
    }

    // Ensure we're still mounted and on the same screen
    if (!mounted) return;

    // Refresh stories if needed after permissions are granted
    _loadStories();
  }

  void _loadStories() {
    context.read<StoriesBloc>().add(const LoadStories());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: const Text(
          'Stories',
          style: TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.add_circled,
            color: CupertinoColors.systemYellow,
            size: 20,
          ),
          onPressed: _showAddStoryOptions,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator.adaptive(
          onRefresh: () async => _loadStories(),
          color: CupertinoColors.systemYellow,
          child: BlocConsumer<StoriesBloc, StoriesState>(
            listener: (context, state) {
              if (state is StoriesError) {
                Navigator.popUntil(context, (route) => route.isFirst);
                _showErrorDialog(state.message);
              } else if (state is StoriesLoaded) {
                setState(() => _isUploading = false);
                Navigator.popUntil(context, (route) => route.isFirst);
              } else if (state is StoryUploadLoading) {
                setState(() => _isUploading = true);
              }
            },
            builder: (context, state) {
              if (state is StoriesLoading && !_isUploading) {
                return _buildLoadingShimmer();
              }

              if (state is StoriesLoaded) {
                final hasUserStories = state.userStories != null && state.userStories!.isNotEmpty;
                final hasFriendsStories = state.friendsStories.isNotEmpty;

                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16.h),
                                // My Story Card
                                _buildMyStoryCard(
                                  hasUserStories ? state.userStories! : null,
                                ),
                                SizedBox(height: 32.h),

                                // Friends Stories Section
                                Text(
                                  'Friend Stories',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 16.h),

                                // Friends Stories List
                                if (hasFriendsStories)
                                  SizedBox(
                                    height: 150.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.friendsStories.length,
                                      separatorBuilder: (_, __) => SizedBox(width: 16.w),
                                      itemBuilder: (context, index) {
                                        final friend = state.friendsStories[index];
                                        final friendStories = friend['stories'] as List? ?? [];
                                        final storyCount = friendStories.length;
                                        final firstStory = friendStories.isNotEmpty ? friendStories.first : null;
                                        final isVideo = firstStory?['mediaType'] == 'video';
                                        final isUnseen = friend['isUnseen'] ?? true;

                                        return GestureDetector(
                                          onTap: () => _viewAllFriendStories(friend),
                                          child: SizedBox(
                                            width: 100.w,
                                            child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    // Story Circle with Thumbnail
                                                    Container(
                                                      width: 90.w,
                                                      height: 90.w,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: isUnseen
                                                            ? const LinearGradient(
                                                          colors: [Color(0xFF00FF00), Color(0xFF00AA00)], // Green for unseen
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        )
                                                            : const LinearGradient(
                                                          colors: [Colors.grey, Color(0xFF666666)], // Grey for seen
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        border: Border.all(
                                                          color: isUnseen ? Colors.green : Colors.grey,
                                                          width: 3.w,
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.all(3.w),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.black, width: 2),
                                                          image: firstStory != null && firstStory['mediaUrl'] != null && !isVideo
                                                              ? DecorationImage(
                                                            image: NetworkImage(firstStory['mediaUrl']!),
                                                            fit: BoxFit.cover,
                                                          )
                                                              : null,
                                                          color: Colors.grey[800],
                                                        ),
                                                        child: firstStory == null
                                                            ? Center(
                                                          child: Icon(
                                                            Icons.person,
                                                            color: Colors.white,
                                                            size: 40.sp,
                                                          ),
                                                        )
                                                            : isVideo
                                                            ? Center(
                                                          child: Icon(
                                                            Icons.videocam,
                                                            color: Colors.white,
                                                            size: 40.sp,
                                                          ),
                                                        )
                                                            : null,
                                                      ),
                                                    ),
                                                    // Video indicator
                                                    if (isVideo)
                                                      Positioned(
                                                        bottom: 5,
                                                        right: 5,
                                                        child: Container(
                                                          padding: EdgeInsets.all(4.w),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.black54,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.play_arrow,
                                                            color: Colors.white,
                                                            size: 16.sp,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  friend['name'] ?? 'Unknown',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '$storyCount story${storyCount != 1 ? 's' : ''}',
                                                  style: TextStyle(
                                                    color: isUnseen ? Colors.green : Colors.grey[400],
                                                    fontSize: 10.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                // Empty state for friends stories
                                  SizedBox(
                                    height: 120.h,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.person,
                                            color: Colors.grey[600],
                                            size: 40.sp,
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'No friend stories',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 40.h),

                                // Empty State for No Stories at All
                                if (!hasFriendsStories && !hasUserStories) ...[
                                  SizedBox(height: 100.h),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          CupertinoIcons.photo_on_rectangle,
                                          size: 80.sp,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'No Stories Yet',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Add a story to get started',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 16.sp,
                                          ),
                                        ),
                                        SizedBox(height: 16.h),
                                        CupertinoButton(
                                          color: CupertinoColors.systemYellow,
                                          child: const Text(
                                            'Add Story',
                                            style: TextStyle(color: Colors.black),
                                          ),
                                          onPressed: _showAddStoryOptions,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Upload Progress Overlay
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CupertinoActivityIndicator(radius: 20),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Your story is being published...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'This may take a moment',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMyStoryCard(List<Map<String, dynamic>>? userStories) {
    final hasStories = userStories != null && userStories.isNotEmpty;
    final latestStory = hasStories ? userStories.first : null;
    final isVideo = latestStory?['mediaType'] == 'video';

    return GestureDetector(
      onTap: hasStories
          ? () => _viewAllUserStories(userStories)
          : _showAddStoryOptions,
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: hasStories
              ? const LinearGradient(
            colors: [Color(0xFF1E9600), Color(0xFFFFF200), Color(0xFFFF6B00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background Image if user has stories
            if (hasStories && latestStory != null && latestStory['mediaUrl'] != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: isVideo
                      ? Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.play_circle_fill,
                        color: Colors.white.withOpacity(0.7),
                        size: 60.sp,
                      ),
                    ),
                  )
                      : Image.network(
                    latestStory['mediaUrl']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.black.withOpacity(0.3));
                    },
                  ),
                ),
              ),

            // Dark Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.white.withOpacity(0.95),
                      border: Border.all(
                        color: hasStories
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemYellow,
                        width: 4.w,
                      ),
                    ),
                    child: Icon(
                      hasStories ? CupertinoIcons.eye : CupertinoIcons.plus,
                      color: CupertinoColors.black,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    hasStories ? 'View My Stories' : 'Add to My Story',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (hasStories) ...[
                    SizedBox(height: 4.h),
                    Text(
                      '${userStories.length} story${userStories.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: CupertinoColors.white.withOpacity(0.85),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Video indicator for my story
            if (isVideo)
              Positioned(
                top: 16.h,
                right: 16.w,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewAllUserStories(List<Map<String, dynamic>> stories) {
    if (stories.isEmpty) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => StoryViewerScreen(
          stories: stories,
          initialIndex: 0,
          userName: 'My Story',
          userImage: stories.first['userImage'],
        ),
      ),
    );
  }

  void _viewAllFriendStories(Map<String, dynamic> friend) {
    final stories = friend['stories'] as List? ?? [];
    if (stories.isEmpty) return;

    // Mark as seen when viewed
    for (var story in stories) {
      if (story['id'] != null) {
        context.read<StoriesBloc>().add(MarkStoryAsSeen(storyId: story['id']));
      }
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => StoryViewerScreen(
          stories: List<Map<String, dynamic>>.from(stories),
          initialIndex: 0,
          userName: friend['name'] ?? 'Friend',
          userImage: friend['profileImage'],
        ),
      ),
    ).then((_) {
      // Refresh stories after viewing
      _loadStories();
    });
  }

  void _showAddStoryOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add to Story'),
        message: const Text('Choose how you want to share'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery, isVideo: false);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.photo_on_rectangle),
                SizedBox(width: 12),
                Text('Photo from Gallery'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery, isVideo: true);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.videocam),
                SizedBox(width: 12),
                Text('Video from Gallery'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.camera, isVideo: false);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.camera),
                SizedBox(width: 12),
                Text('Take Photo'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.camera, isVideo: true);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.videocam),
                SizedBox(width: 12),
                Text('Record Video'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    try {
      XFile? pickedFile;

      if (isVideo) {
        pickedFile = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 60),
        );
      } else {
        pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 80,
        );
      }

      if (pickedFile != null) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => AddStoryScreen(
              imageFile: pickedFile,
              isVideo: isVideo,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to pick media: $e');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[600]!,
                  child: Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[600]!,
                  child: Container(
                    width: 150.w,
                    height: 30.h,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 150.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => SizedBox(width: 16.w),
                    itemBuilder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey[800]!,
                      highlightColor: Colors.grey[600]!,
                      child: Container(
                        width: 90.w,
                        height: 130.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}