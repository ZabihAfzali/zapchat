// chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/bloc/chat_states.dart';
import 'package:zapchat/features/chat/views/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(LoadChats());
    });
  }

  String _formatTime(dynamic time) {
    DateTime? dateTime;

    // Handle different time formats
    if (time == null) {
      return 'RECENT';
    } else if (time is DateTime) {
      dateTime = time;
    } else if (time is Timestamp) {
      dateTime = time.toDate();
    } else if (time is String) {
      try {
        dateTime = DateTime.parse(time);
      } catch (e) {
        return 'RECENT';
      }
    } else {
      return 'RECENT';
    }

    if (dateTime == null) return 'RECENT';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDay == today) {
      return 'TODAY';
    } else if (messageDay == yesterday) {
      return 'YESTERDAY';
    } else {
      return DateFormat('EEEE').format(dateTime).toUpperCase();
    }
  }

  DateTime? _parseTime(dynamic time) {
    if (time == null) return null;

    if (time is DateTime) {
      return time;
    } else if (time is Timestamp) {
      return time.toDate();
    } else if (time is String) {
      try {
        return DateTime.parse(time);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new chat functionality
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.yellow,
              ),
            );
          } else if (state is ChatError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (state is ChatsLoaded) {
            final chats = state.chats;

            if (chats.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start a conversation with friends!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group chats by date with null-safe handling
            final Map<String, List<Map<String, dynamic>>> groupedChats = {};

            for (final chat in chats) {
              final time = chat['lastMessageTime'];
              final dateKey = _formatTime(time);

              if (!groupedChats.containsKey(dateKey)) {
                groupedChats[dateKey] = [];
              }
              groupedChats[dateKey]!.add(chat);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: groupedChats.length,
              itemBuilder: (context, index) {
                final dateKey = groupedChats.keys.elementAt(index);
                final dateChats = groupedChats[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      color: Colors.black,
                      child: Text(
                        dateKey,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Chats for this date
                    ...dateChats.map((chat) {
                      final user = chat['user'] as Map<String, dynamic>? ?? {};
                      final time = chat['lastMessageTime'];
                      final lastMessageTime = _parseTime(time);
                      final unreadCount = (chat['unreadCount'] as int?) ?? 0;

                      return SnapchatChatListItem(
                        chat: chat,
                        user: user,
                        lastMessageTime: lastMessageTime,
                        unreadCount: unreadCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: context.read<ChatBloc>(),
                                child: ChatScreen(
                                  chatId: chat['id'] as String? ?? 'unknown',
                                  user: user,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            );
          }

          return const SizedBox(); // Empty state
        },
      ),
    );
  }
}

class SnapchatChatListItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  final Map<String, dynamic> user;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const SnapchatChatListItem({
    super.key,
    required this.chat,
    required this.user,
    this.lastMessageTime,
    required this.unreadCount,
    required this.onTap,
  });

  String _getTimeAgo(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${difference.inDays ~/ 7}w';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = user['name'] as String? ?? 'Unknown';
    final profilePicture = user['profilePicture'] as String?;
    final hasStory = (user['hasStory'] as bool?) ?? false;
    final isOnline = (user['isOnline'] as bool?) ?? false;
    final lastMessage = (chat['lastMessage'] as String?) ?? '';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      tileColor: Colors.black,
      leading: Stack(
        children: [
          // Snapchat-style story ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: hasStory
                ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.yellow,
                width: 2,
              ),
            )
                : null,
            child: CircleAvatar(
              radius: 26,
              backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              backgroundColor: Colors.grey[800],
              child: profilePicture == null || profilePicture.isEmpty
                  ? const Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              )
                  : null,
            ),
          ),

          // Online status indicator
          if (isOnline)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: unreadCount > 0 ? Colors.yellow : Colors.grey,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessageTime != null)
            Text(
              _getTimeAgo(lastMessageTime),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 2),
          if (unreadCount > 0)
            const Icon(
              Icons.circle,
              color: Colors.yellow,
              size: 8,
            ),
        ],
      ),
    );
  }
}