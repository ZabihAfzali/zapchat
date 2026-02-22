import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final String userName;
  final String? userImage;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.userName,
    this.userImage,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  late AnimationController _progressAnimationController;

  int _currentIndex = 0;
  bool _isVideoInitialized = false;
  bool _showControls = true;

  final Map<int, double> _storyProgress = {};

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        if (mounted) {
          setState(() {
            _storyProgress[_currentIndex] =
                _progressAnimationController.value;
          });
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextStory();
        }
      });

    _initializeCurrentMedia();
  }

  /* ============================= */
  /* MEDIA INITIALIZATION */
  /* ============================= */

  void _initializeCurrentMedia() {
    final currentStory = widget.stories[_currentIndex];

    _disposeVideoController();

    if (currentStory['mediaType'] == 'video') {
      _videoController =
      VideoPlayerController.network(currentStory['mediaUrl'])
        ..initialize().then((_) {
          if (!mounted) return;

          final videoDuration =
              _videoController!.value.duration;

          _progressAnimationController.duration = videoDuration;

          setState(() {
            _isVideoInitialized = true;
          });

          _videoController!.play();
          _startProgress();
        }).catchError((error) {
          debugPrint('Video error: $error');
        });
    } else {
      // Image → fixed 5 seconds
      _progressAnimationController.duration =
      const Duration(seconds: 5);
      _startProgress();
    }
  }

  void _disposeVideoController() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
  }

  /* ============================= */
  /* PROGRESS CONTROL */
  /* ============================= */

  void _startProgress() {
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  void _pauseProgress() {
    _progressAnimationController.stop();
    _videoController?.pause();
  }

  void _resumeProgress() {
    _progressAnimationController.forward();
    if (_videoController != null &&
        !_videoController!.value.isPlaying) {
      _videoController!.play();
    }
  }

  /* ============================= */
  /* NAVIGATION */
  /* ============================= */

  void _goToNextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _closeViewer();
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _closeViewer() {
    _progressAnimationController.stop();
    _disposeVideoController();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  /* ============================= */
  /* UI */
  /* ============================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _initializeCurrentMedia();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];

                return GestureDetector(
                  onTapDown: (details) {
                    final screenWidth =
                        MediaQuery.of(context).size.width;

                    if (details.localPosition.dx <
                        screenWidth * 0.3) {
                      _goToPreviousStory();
                    } else if (details.localPosition.dx >
                        screenWidth * 0.7) {
                      _goToNextStory();
                    } else {
                      setState(() =>
                      _showControls = !_showControls);
                    }
                  },
                  onLongPressStart: (_) => _pauseProgress(),
                  onLongPressEnd: (_) => _resumeProgress(),
                  child: Center(
                    child: story['mediaType'] == 'video'
                        ? _buildVideoPlayer()
                        : _buildImagePlayer(
                        story['mediaUrl']),
                  ),
                );
              },
            ),

            /* Progress Bars */
            Positioned(
              top: 10.h,
              left: 16.w,
              right: 16.w,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                      (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          right: index <
                              widget.stories.length - 1
                              ? 4.w
                              : 0),
                      height: 3.h,
                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.3),
                        borderRadius:
                        BorderRadius.circular(2.r),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: index <
                                _currentIndex
                                ? 1
                                : index ==
                                _currentIndex
                                ? (_storyProgress[
                            index] ??
                                0)
                                : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(
                                    2.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /* Top Bar */
            if (_showControls)
              Positioned(
                top: 20.h,
                left: 16.w,
                right: 50.w,
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white,
                            width: 2.w),
                        image: widget.userImage !=
                            null &&
                            widget.userImage!
                                .isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(
                              widget.userImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: widget.userImage ==
                            null ||
                            widget.userImage!
                                .isEmpty
                            ? Colors.grey[800]
                            : null,
                      ),
                      child: widget.userImage ==
                          null ||
                          widget.userImage!
                              .isEmpty
                          ? Center(
                        child: Text(
                          widget.userName[0]
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      )
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.userName,
                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /* Close Button */
            if (_showControls)
              Positioned(
                top: 20.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: _closeViewer,
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color:
                      Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlayer(String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder:
            (_, __, ___) => const Icon(
          CupertinoIcons.photo,
          color: Colors.grey,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null ||
        !_isVideoInitialized) {
      return const CupertinoActivityIndicator();
    }

    return AspectRatio(
      aspectRatio:
      _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }
}
