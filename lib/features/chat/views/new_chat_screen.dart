// lib/features/chat/views/new_chat_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/views/chat_screen.dart';

import '../models/chat_model.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _recentChats = [];
  List<ChatUser> _allUsers = [];
  List<ChatUser> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await context.read<ChatBloc>().chatRepository.getAllUsers();
      final recentChats = await context.read<ChatBloc>().chatRepository.getRecentChatUsers();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _recentChats = recentChats;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load users');
      }
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
    } else {
      setState(() {
        _filteredUsers = _allUsers
            .where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase()) ||
            (user.username?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      });
    }
  }

  Future<void> _startChat(ChatUser user) async {
    try {
      final chatId = await context
          .read<ChatBloc>()
          .chatRepository
          .getOrCreateChat(user.uid);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ChatBloc>(),
              child: ChatScreen(
                chatId: chatId,
                user: user,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to start chat');
      }
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
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        border: const Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.systemYellow,
            size: 24,
          ),
        ),
        middle: const Text(
          'New Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search',
                  placeholderStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  backgroundColor: Colors.transparent,
                  prefixIcon: const Icon(
                    CupertinoIcons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  suffixIcon: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onChanged: _filterUsers,
                  onSubmitted: _filterUsers,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.group,
                      color: CupertinoColors.systemYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Group',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Chat with up to 200 friends',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.forward,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_recentChats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'RECENTS',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ..._recentChats.map((user) => _buildUserTile(user, isRecent: true)),
            ],
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: CupertinoColors.systemYellow,
                  ),
                ),
              )
            else
              Expanded(
                child: _filteredUsers.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgUtils.getPersonIcon(
                        width: 48,
                        height: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : CupertinoScrollbar(
                  child: ListView.builder(
                    key: const ValueKey('users_list'),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserTile(user);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user, {bool isRecent = false}) {
    final isOnline = user.isOnline;

    return CupertinoButton(
      onPressed: () => _startChat(user),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            SvgUtils.buildAvatar(
              radius: 24,
              hasStory: user.hasStory,
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
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecent)
                        const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: CupertinoColors.systemYellow,
                          size: 20,
                        ),
                    ],
                  ),
                  if (user.username != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.username!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isRecent && isOnline)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: const Icon(
                  CupertinoIcons.circle_fill,
                  color: Colors.green,
                  size: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}