// lib/features/chat/views/chat_list_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/core/widgets/custom_appbar.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/bloc/chat_states.dart';
import 'package:zapchat/features/chat/models/chat.dart';
import 'package:zapchat/features/chat/models/group.dart';
import 'package:zapchat/features/chat/models/message.dart';
import 'package:zapchat/features/chat/views/chat_screen.dart';
import 'package:zapchat/features/chat/views/group_chat_screen.dart';
import 'package:zapchat/features/chat/views/new_chat_screen.dart';
import 'package:zapchat/features/chat/views/search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFirstLoad = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _formatDateHeader(DateTime? date) {
    if (date == null) return 'RECENT';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) return 'TODAY';
    if (messageDay == yesterday) return 'YESTERDAY';
    if (messageDay.difference(today).inDays > -7) return DateFormat('EEEE').format(date).toUpperCase();
    return DateFormat('MMM d').format(date).toUpperCase();
  }

  void _startSearch() {
    context.read<ChatBloc>().add(const StartSearch(query: ''));
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    context.read<ChatBloc>().add(StopSearch());
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) {
          if (current is ChatsLoaded || current is ChatError) return true;
          if (current is ChatLoading && _isFirstLoad) return true;
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
            return _buildErrorState();
          } else if (state is ChatsLoaded) {
            if (state.searchState.isSearching) {
              return _buildSearchResults(state);
            }
            return _buildChatTabs(state.chats, state.groups);
          }
          return const SizedBox();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(120.h),
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) {
          if (current is ChatsLoaded) {
            return previous is! ChatsLoaded ||
                previous.searchState.isSearching != current.searchState.isSearching ||
                previous.searchState.query != current.searchState.query;
          }
          return false;
        },
        builder: (context, state) {
          final isSearching = state is ChatsLoaded && state.searchState.isSearching;

          if (isSearching) {
            // Navigate to search screen instead of showing inline search
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<ChatBloc>(),
                    child: const SearchScreen(),
                  ),
                ),
              ).then((_) {
                // Reset search state when returning
                context.read<ChatBloc>().add(StopSearch());
              });
            });
          }

          return CustomAppBar(
            title: 'Chat',
            showAddBackground: true,
            onPersonTap: () => Navigator.pushNamed(context, '/profile'),
            onSearchTap: _startSearch,
            onAddFriendTap: () {
              // Handle add friend
            },
            onSettingsTap: () {
              // Handle settings
            },
            bottom: _buildTabBar(),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
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
    );
  }

  Widget _buildFloatingButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
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
          backgroundColor: CupertinoColors.systemYellow,
          shape: const CircleBorder(),
          child: const Icon(CupertinoIcons.pencil, color: Colors.black, size: 24),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text('Failed to load chats', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: () => context.read<ChatBloc>().add(LoadChats()),
            color: CupertinoColors.systemYellow,
            child: const Text('Try Again', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTabs(List<Chat> chats, List<Group> groups) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildChatList(chats, groups),
        _buildChatList(
          chats.where((chat) => chat.unreadCount > 0).toList(),
          groups.where((group) => group.unreadCount > 0).toList(),
        ),
        _buildChatList(
          chats.where((chat) => chat.otherUser?.isBirthday == true).toList(),
          [], // Groups don't have birthday property
        ),
      ],
    );
  }

  Widget _buildChatList(List<Chat> chats, List<Group> groups) {
    if (chats.isEmpty && groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[900]),
              child: const Icon(CupertinoIcons.chat_bubble, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text("No chats yet", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text("Start chatting with friends!", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final pinnedChats = chats.where((chat) => chat.isPinned).toList();
    final otherChats = chats.where((chat) => !chat.isPinned).toList();

    final Map<String, List<Chat>> groupedChats = {};
    for (final chat in otherChats) {
      final dateKey = _formatDateHeader(chat.lastMessageTime);
      groupedChats.putIfAbsent(dateKey, () => []).add(chat);
    }

    return ListView(
      key: const ValueKey('chat_list'),
      children: [
        // Pinned Chats Section
        if (pinnedChats.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PINNED',
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ),
          ...pinnedChats.map((chat) => SnapchatChatListItem(
            key: ValueKey('pinned_${chat.id}'),
            chat: chat,
            onTap: () => _navigateToChatScreen(chat),
          )),
        ],

        // Groups Section
        if (groups.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'GROUPS',
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ),
          ...groups.map((group) => GroupChatListItem(
            key: ValueKey('group_${group.id}'),
            group: group,
            onTap: () => _navigateToGroupChat(group),
          )),
        ],

        // Regular Chats Grouped by Date
        ...groupedChats.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.key.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  entry.key,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
            ...entry.value.map((chat) => SnapchatChatListItem(
              key: ValueKey(chat.id),
              chat: chat,
              onTap: () => _navigateToChatScreen(chat),
            )),
          ],
        )),
      ],
    );
  }

  void _navigateToChatScreen(Chat chat) {
    if (chat.otherUser == null) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: ChatScreen(chatId: chat.id, user: chat.otherUser!),
        ),
      ),
    ).then((_) {
      if (chat.unreadCount > 0) {
        context.read<ChatBloc>().add(ClearUnreadCount(chatId: chat.id));
      }
    });
  }

  void _navigateToGroupChat(Group group) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: GroupChatScreen(
            groupId: group.id,
            groupName: group.name,
            members: [], // You'll need to fetch members separately
          ),
        ),
      ),
    );
  }

  void _navigateToMessage(Message message) {
    // Navigate to chat containing this message
  }

  Widget _buildSearchResults(ChatsLoaded state) {
    final searchState = state.searchState;
    final query = searchState.query;

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('Search chats and messages', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    if (searchState.chatResults.isEmpty && searchState.messageResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text_search, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('No results found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (searchState.chatResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('CHATS', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          ...searchState.chatResults.map((chat) => SearchChatItem(chat: chat, onTap: () => _navigateToChatScreen(chat))),
        ],
        if (searchState.messageResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('MESSAGES', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          ...searchState.messageResults.map((message) => SearchMessageItem(message: message, onTap: () => _navigateToMessage(message))),
        ],
      ],
    );
  }
}

// Group Chat List Item Widget
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
              // context.read<ChatBloc>().chatRepository.leaveGroup(group.id);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
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
}

/// -------------------- Support Widgets --------------------

class SearchChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const SearchChatItem({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
        child: Row(
          children: [
            SvgUtils.buildAvatar(
              radius: 20,
              hasStory: chat.otherUser?.hasStory ?? false,
              isOnline: chat.otherUser?.isOnline ?? false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.otherUser?.name ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(chat.lastMessage ?? 'No messages', style: TextStyle(color: Colors.grey[500], fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchMessageItem extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const SearchMessageItem({super.key, required this.message, required this.onTap});

  String _getMessagePreview() {
    if (message.content != null && message.content!.isNotEmpty) return message.content!;
    switch (message.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 File';
      default:
        return 'Media message';
    }
  }

  IconData _getMessageIcon() {
    switch (message.type) {
      case MessageType.image:
        return CupertinoIcons.photo;
      case MessageType.video:
        return CupertinoIcons.video_camera_solid;
      case MessageType.audio:
        return CupertinoIcons.mic_fill;
      case MessageType.file:
        return CupertinoIcons.doc_fill;
      default:
        return CupertinoIcons.doc_text_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
              child: Icon(_getMessageIcon(), color: CupertinoColors.systemYellow, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getMessagePreview(), style: const TextStyle(color: Colors.white, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM d, HH:mm').format(message.timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SnapchatChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const SnapchatChatListItem({super.key, required this.chat, required this.onTap});

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

  void _showChatOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(chat.otherUser?.name ?? 'Chat Options', style: const TextStyle(color: Colors.white)),
        message: const Text('Choose an option', style: TextStyle(color: Colors.grey)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(TogglePinChat(
                chatId: chat.id,
                isPinned: !chat.isPinned,
              ));
            },
            child: Text(chat.isPinned ? 'Unpin Chat' : 'Pin Chat'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(ToggleMuteChat(
                chatId: chat.id,
                isMuted: !chat.isMuted,
              ));
            },
            child: Text(chat.isMuted ? 'Unmute Chat' : 'Mute Chat'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
            child: const Text('Delete Chat', style: TextStyle(color: CupertinoColors.systemRed)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete the chat with ${chat.otherUser?.name ?? "this user"}?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              // Implement delete chat functionality
              // context.read<ChatBloc>().add(DeleteChat(chatId: chat.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = chat.otherUser;
    final hasStory = user?.hasStory ?? false;
    final isOnline = user?.isOnline ?? false;
    final isPinned = chat.isPinned;
    final isMuted = chat.isMuted;
    final unreadCount = chat.unreadCount;

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showChatOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPinned ? Colors.grey[900]?.withOpacity(0.3) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            // Avatar
            SvgUtils.buildAvatar(
              radius: 28,
              hasStory: hasStory,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12),

            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.name ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(CupertinoIcons.pin_fill, color: CupertinoColors.systemYellow, size: 14),
                        ),
                      if (isMuted)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(CupertinoIcons.bell_slash_fill, color: Colors.grey, size: 14),
                        ),
                      Text(
                        _getTimeAgo(chat.lastMessageTime),
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
                          chat.lastMessage ?? 'No messages yet',
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
}