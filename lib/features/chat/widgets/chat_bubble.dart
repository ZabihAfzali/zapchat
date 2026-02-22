// lib/features/chat/widgets/chat_bubble.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:zapchat/features/chat/models/message.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.video && widget.message.mediaUrl != null) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.message.mediaUrl!),
    )..initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.isMe
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemYellow,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.red),
            ),
          );
        },
      );
      setState(() => _isLoading = false);
    }).catchError((e) {
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isDeleted) {
      return _buildDeletedMessage();
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: _showOptions,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: widget.isMe ? 60 : 0,
          right: widget.isMe ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: widget.message.type == MessageType.text
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : EdgeInsets.zero,
              decoration: widget.message.type == MessageType.text
                  ? BoxDecoration(
                color: widget.isMe ? CupertinoColors.systemYellow : Colors.grey[800],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: widget.isMe ? const Radius.circular(4) : null,
                  bottomLeft: !widget.isMe ? const Radius.circular(4) : null,
                ),
              )
                  : null,
              child: _buildMessageContent(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(widget.message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  if (widget.isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.text:
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Text(
      widget.message.content ?? '',
      style: TextStyle(
        color: widget.isMe ? Colors.black : Colors.white,
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageMessage() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.message.mediaUrl!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[900],
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      color: CupertinoColors.systemYellow,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[900],
                  child: const Icon(
                    CupertinoIcons.photo,
                    color: Colors.grey,
                    size: 50,
                  ),
                );
              },
            ),
          ),
          if (widget.message.content != null && widget.message.content!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  widget.message.content!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage() {
    if (_isLoading) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[900],
        child: const Center(
          child: CupertinoActivityIndicator(color: CupertinoColors.systemYellow),
        ),
      );
    }

    if (_chewieController == null) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[900],
        child: const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.red),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 200,
        color: Colors.black,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildAudioMessage() {
    // Simplified audio message without waveforms
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe ? CupertinoColors.systemYellow.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.mic_fill,
            color: widget.isMe ? Colors.black : CupertinoColors.systemYellow,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio message',
                  style: TextStyle(
                    color: widget.isMe ? Colors.black : Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tap to play',
                  style: TextStyle(
                    color: widget.isMe ? Colors.black54 : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isMe ? CupertinoColors.systemYellow.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.doc, color: CupertinoColors.systemYellow, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.metadata?['fileName'] ?? 'File',
                  style: TextStyle(
                    color: widget.isMe ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(widget.message.metadata?['fileSize'] ?? 0),
                  style: TextStyle(
                    color: widget.isMe ? Colors.black54 : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'This message was deleted',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CupertinoActivityIndicator(color: Colors.grey[500]),
        );
      case MessageStatus.sent:
        return Icon(CupertinoIcons.check_mark, color: Colors.grey[500], size: 14);
      case MessageStatus.delivered:
        return Icon(CupertinoIcons.check_mark_circled, color: Colors.grey[500], size: 14);
      case MessageStatus.read:
        return Icon(CupertinoIcons.check_mark_circled_solid,
            color: CupertinoColors.systemBlue, size: 14);
      case MessageStatus.error:
        return Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 14);
      default:
        return const SizedBox();
    }
  }

  void _showFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoView(
                imageProvider: NetworkImage(widget.message.mediaUrl!),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
              Positioned(
                top: 40,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Message Options',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reply'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Copy'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Info'),
          ),
          if (widget.isMe)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                // Handle delete
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}