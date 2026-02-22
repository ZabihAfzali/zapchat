import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:zapchat/features/stories/bloc/stories_bloc.dart';
import 'package:zapchat/features/stories/bloc/stories_events.dart';

class AddStoryScreen extends StatefulWidget {
  final XFile? imageFile;
  final bool isVideo;

  const AddStoryScreen({
    super.key,
    required this.imageFile,
    required this.isVideo,
  });

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.imageFile != null) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    if (widget.imageFile == null) return;

    _videoController = VideoPlayerController.file(File(widget.imageFile!.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isVideoInitialized = true);
          _videoController!.setLooping(true);
          _videoController!.play();
        }
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageFile == null) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.black,
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          middle: const Text(
            'Error',
            style: TextStyle(color: CupertinoColors.white),
          ),
        ),
        child: const Center(
          child: Text(
            'No media selected',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.white),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
        middle: const Text(
          'Add to Story',
          style: TextStyle(color: CupertinoColors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Share',
            style: TextStyle(
              color: _isUploading ? CupertinoColors.systemGrey : CupertinoColors.systemYellow,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: _isUploading ? null : _uploadStory,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Media Preview
                  widget.isVideo
                      ? _buildVideoPreview()
                      : Image.file(
                    File(widget.imageFile!.path),
                    fit: BoxFit.cover,
                  ),

                  // Caption Overlay
                  if (_captionController.text.isNotEmpty)
                    Positioned(
                      bottom: 20.h,
                      left: 16.w,
                      right: 16.w,
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _captionController.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  // Video Play Indicator
                  if (widget.isVideo && !_isVideoInitialized)
                    const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                ],
              ),
            ),

            // Caption Input
            Container(
              padding: EdgeInsets.all(16.w),
              color: CupertinoColors.systemGrey6.darkColor,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _captionController,
                      placeholder: 'Add a caption...',
                      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
                      style: const TextStyle(color: Colors.white),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5.darkColor,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      onChanged: (value) => setState(() {}),
                      enabled: !_isUploading,
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

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  void _uploadStory() {
    if (widget.imageFile == null) return;

    setState(() => _isUploading = true);

    // Start upload in a separate microtask so UI can pop immediately
    Future.microtask(() {
      context.read<StoriesBloc>().add(
        UploadStory(
          mediaFile: File(widget.imageFile!.path),
          caption: _captionController.text.isEmpty ? null : _captionController.text,
          mediaType: widget.isVideo ? 'video' : 'image',
        ),
      );
    });

    // Navigate back to stories tab immediately
    Navigator.pop(context);

    // Optional: show quick confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isVideo
              ? 'Video upload started in background.'
              : 'Photo upload started in background.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
