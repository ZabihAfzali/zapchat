// lib/features/chat/widgets/chat_bubble.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zapchat/features/chat/models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: message.type == MessageType.text
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : EdgeInsets.zero,
              decoration: message.type == MessageType.text
                  ? BoxDecoration(
                color: isMe ? CupertinoColors.systemYellow : Colors.grey[800],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
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
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == MessageStatus.read
                          ? CupertinoIcons.check_mark_circled_solid
                          : message.status == MessageStatus.delivered
                          ? CupertinoIcons.check_mark_circled
                          : CupertinoIcons.check_mark,
                      color: message.status == MessageStatus.read
                          ? CupertinoColors.systemBlue
                          : Colors.grey[500],
                      size: 14,
                    ),
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
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.text:
        return _buildTextMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Text(
      message.text ?? '',
      style: TextStyle(
        color: isMe ? Colors.black : Colors.white,
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.mediaUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[800],
                child: const Icon(
                  CupertinoIcons.photo,
                  color: Colors.grey,
                  size: 50,
                ),
              );
            },
          ),
        ),
        if (message.text != null && message.text!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.text!,
            style: TextStyle(
              color: isMe ? Colors.black : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ],
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
}