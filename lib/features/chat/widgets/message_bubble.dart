import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showTime;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTime = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final messageType = message['type'] ?? 'text';

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTime) _buildTimestamp(),
        SizedBox(height: 4.h),
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: messageType == 'media'
                ? _buildMediaMessage()
                : _buildTextMessage(),
          ),
        ),
        SizedBox(height: 8.h),
        if (isMe) _buildMessageStatus(),
      ],
    );
  }

  Widget _buildTextMessage() {
    final text = message['text'] ?? '';
    final isDeleted = message['isDeleted'] == true;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFFC00) : Colors.grey[800]!,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: isMe ? Radius.circular(20.r) : Radius.circular(4.r),
          bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(20.r),
        ),
      ),
      child: Text(
        isDeleted ? 'This message was deleted' : text,
        style: TextStyle(
          color: isMe ? Colors.black : Colors.white,
          fontSize: 16.sp,
          fontWeight: isDeleted ? FontWeight.w300 : FontWeight.w400,
          fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildMediaMessage() {
    final mediaType = message['mediaType'] ?? 'image';
    final mediaUrl = message['mediaUrl'] ?? '';
    final text = message['text'] ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
        bottomLeft: isMe ? Radius.circular(20.r) : Radius.circular(4.r),
        bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(20.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isMe ? const Color(0xFFFFFC00) : Colors.grey[700]!,
            width: 2,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: isMe ? Radius.circular(20.r) : Radius.circular(4.r),
            bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(20.r),
          ),
        ),
        child: Stack(
          children: [
            // Media placeholder (will be real image/video later)
            Container(
              width: 200.w,
              height: 250.h,
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mediaType == 'image' ? Icons.photo : Icons.videocam,
                      size: 50.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      text,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play button for videos
            if (mediaType == 'video')
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    final timestamp = message['timestamp'];
    if (timestamp == null) return const SizedBox();

    DateTime time;
    if (timestamp is DateTime) {
      time = timestamp;
    } else if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else {
      return const SizedBox();
    }

    final formattedTime = DateFormat('h:mm a').format(time);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        formattedTime,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    final status = message['status'] ?? 'sent';
    IconData icon;
    Color color;

    switch (status) {
      case 'sent':
        icon = Icons.check;
        color = Colors.grey[500]!;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey[500]!;
        break;
      case 'read':
        icon = Icons.done_all;
        color = const Color(0xFFFFFC00);
        break;
      default:
        icon = Icons.schedule;
        color = Colors.grey[500]!;
    }

    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          if (message['isEdited'] == true)
            Text(
              'Edited',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}