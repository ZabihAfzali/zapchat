import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_events.dart';
import '../models/group.dart';

class GroupChatListItem extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupChatListItem({super.key, required this.group, required this.onTap});

  String _getTimeAgo(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo';
    return '${diff.inDays ~/ 365}y';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = group.unreadCount;
    final isMuted = group.isMuted;

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showGroupOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            // Group Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.group,
                color: CupertinoColors.systemYellow,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),

            // Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMuted)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(CupertinoIcons.bell_slash_fill, color: Colors.grey, size: 14),
                        ),
                      Text(
                        _getTimeAgo(group.lastMessageTime),
                        style: TextStyle(
                          color: unreadCount > 0 ? CupertinoColors.systemYellow : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.lastMessage ?? '${group.members.length} members',
                          style: TextStyle(
                            color: unreadCount > 0 ? Colors.white : Colors.grey[500],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: CupertinoColors.systemYellow,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(group.name, style: const TextStyle(color: Colors.white)),
        message: Text('${group.members.length} members', style: const TextStyle(color: Colors.grey)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(ToggleMuteChat(
                chatId: group.id,
                isMuted: !group.isMuted,
              ));
            },
            child: Text(group.isMuted ? 'Unmute Group' : 'Mute Group'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showLeaveGroupDialog(context);
            },
            child: const Text('Leave Group', style: TextStyle(color: CupertinoColors.systemRed)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              // Implement leave group functionality
              context.read<ChatBloc>().chatRepository.leaveGroup(group.id);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}