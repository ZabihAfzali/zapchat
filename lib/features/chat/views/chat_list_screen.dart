// lib/features/chat/views/chat_list_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zapchat/core/routes/route_names.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/core/widgets/custom_appbar.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/bloc/chat_states.dart';
import 'package:zapchat/features/chat/models/chat.dart';
import 'package:zapchat/features/chat/views/chat_screen.dart';
import 'package:zapchat/features/chat/views/new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Only load once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad) {
        _isFirstLoad = false;
        context.read<ChatBloc>().add(LoadChats());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateHeader(DateTime? date) {
    if (date == null) return 'RECENT';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return 'TODAY';
    } else if (messageDay == yesterday) {
      return 'YESTERDAY';
    } else if (messageDay.difference(today).inDays > -7) {
      return DateFormat('EEEE').format(date).toUpperCase();
    } else {
      return DateFormat('MMM d').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: CustomAppBar(
            title: 'Chat',
            showAddBackground: true,
            onPersonTap: () => Navigator.pushNamed(context, RouteNames.profile),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: CupertinoColors.systemYellow,
              labelColor: CupertinoColors.systemYellow,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Unread"),
                Tab(text: "Birthday"),
              ],
            ),
          ),
          floatingActionButton: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<ChatBloc>(),
                    child: const NewChatScreen(),
                  ),
                ),
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: CupertinoColors.systemYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.pencil,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          body: BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (previous, current) {
              // Only rebuild when chats actually change
              if (current is ChatsLoaded) {
                return true;
              }
              if (current is ChatError) {
                return true;
              }
              return false;
            },
            builder: (context, state) {
              if (state is ChatLoading && _isFirstLoad) {
                return const Center(
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: CupertinoColors.systemYellow,
                  ),
                );
              } else if (state is ChatError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load chats',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: () {
                          context.read<ChatBloc>().add(LoadChats());
                        },
                        color: CupertinoColors.systemYellow,
                        child: const Text(
                          'Try Again',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is ChatsLoaded) {
                final chats = state.chats;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatList(chats),
                    _buildChatList(
                      chats.where((chat) => chat.unreadCount > 0).toList(),
                    ),
                    _buildChatList(
                      chats
                          .where((chat) => chat.otherUser?.isBirthday == true)
                          .toList(),
                    ),
                  ],
                );
              }

              // Return empty container instead of loading spinner
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(List<Chat> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[900],
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No chats yet",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Start chatting with friends!",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, List<Chat>> groupedChats = {};

    for (final chat in chats) {
      final dateKey = _formatDateHeader(chat.lastMessageTime);
      groupedChats.putIfAbsent(dateKey, () => []).add(chat);
    }

    return CupertinoScrollbar(
      child: ListView.builder(
        key: const ValueKey('chat_list'),
        itemCount: groupedChats.length,
        itemBuilder: (context, index) {
          final dateKey = groupedChats.keys.elementAt(index);
          final dateChats = groupedChats[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dateKey.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    dateKey,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ...dateChats.map((chat) => SnapchatChatListItem(
                key: ValueKey(chat.id),
                chat: chat,
                onTap: () {
                  _navigateToChatScreen(chat);
                },
              )),
            ],
          );
        },
      ),
    );
  }

  void _navigateToChatScreen(Chat chat) {
    if (chat.otherUser == null) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: ChatScreen(
            chatId: chat.id,
            user: chat.otherUser!,
          ),
        ),
      ),
    ).then((_) {
      if (chat.unreadCount > 0) {
        context.read<ChatBloc>().add(ClearUnreadCount(chatId: chat.id));
      }
    });
  }
}

class SnapchatChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const SnapchatChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  String _getTimeAgo(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${difference.inDays ~/ 7}w';
    if (difference.inDays < 365) return '${difference.inDays ~/ 30}mo';

    return '${difference.inDays ~/ 365}y';
  }

  @override
  Widget build(BuildContext context) {
    final user = chat.otherUser;
    final userName = user?.name ?? 'Unknown';
    final hasStory = user?.hasStory ?? false;
    final isOnline = user?.isOnline ?? false;
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final unreadCount = chat.unreadCount;
    final isMuted = chat.isMuted;
    final isPinned = chat.isPinned;

    return CupertinoButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: const Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            SvgUtils.buildAvatar(
              radius: 28,
              hasStory: hasStory,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      if (isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            CupertinoIcons.pin,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                      if (isMuted)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            CupertinoIcons.bell_slash_fill,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                      if (chat.lastMessageTime != null)
                        Text(
                          _getTimeAgo(chat.lastMessageTime),
                          style: TextStyle(
                            color: unreadCount > 0
                                ? CupertinoColors.systemYellow
                                : Colors.grey[500],
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
                          lastMessage,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? Colors.white
                                : Colors.grey[500],
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemYellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
}