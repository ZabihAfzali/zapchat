// lib/features/chat/views/new_chat_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/views/chat_screen.dart';
import 'package:zapchat/features/chat/views/group_chat_screen.dart';
import 'package:zapchat/features/chat/views/select_users_screen.dart';

import '../models/chat_model.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<ChatUser> _selectedUsers = [];
  List<ChatUser> _recentUsers = [];
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
      final allUsers = await context.read<ChatBloc>().chatRepository.getAllUsers();
      final recentUsers = await context.read<ChatBloc>().chatRepository.getRecentChatUsers();

      if (mounted) {
        setState(() {
          _allUsers = allUsers;
          _recentUsers = recentUsers;
          _filteredUsers = recentUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load users');
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _recentUsers;
      } else {
        _filteredUsers = _allUsers
            .where((user) =>
        // Search by userName (updated field name)
        user.userName.toLowerCase().contains(query.toLowerCase()) ||
            // Search by email
            (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            // Search by phone number if available
            (user.phoneNumber?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _handleNewGroupTap() async {
    // Navigate to user selection screen first
    final selectedUsers = await Navigator.push<List<ChatUser>>(
      context,
      CupertinoPageRoute(
        builder: (context) => SelectUsersScreen(
          allUsers: _allUsers,
        ),
      ),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty && mounted) {
      // Then show group name dialog
      _showGroupNameDialog(selectedUsers);
    }
  }

  Future<void> _showGroupNameDialog(List<ChatUser> selectedUsers) async {
    final controller = TextEditingController();

    final groupName = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Enter group name',
              placeholderStyle: const TextStyle(color: Colors.grey),
              style: const TextStyle(color: Colors.white),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(
              'Create',
              style: TextStyle(color: CupertinoColors.systemYellow),
            ),
          ),
        ],
      ),
    );

    if (groupName != null && groupName.isNotEmpty && mounted) {
      _createGroup(groupName, selectedUsers);
    }
  }

  Future<void> _createGroup(String groupName, List<ChatUser> selectedUsers) async {
    try {
      final memberIds = selectedUsers.map((u) => u.uid).toList();

      final groupId = await context
          .read<ChatBloc>()
          .chatRepository
          .createGroup(
        name: groupName,
        memberIds: memberIds,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ChatBloc>(),
              child: GroupChatScreen(
                groupId: groupId,
                groupName: groupName,
                members: selectedUsers,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creating group: $e');
      _showErrorDialog('Failed to create group');
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
      print('Error starting chat: $e');
      _showErrorDialog('Failed to start chat');
    }
  }

  Future<void> _startGroupChat() async {
    if (_selectedUsers.length < 2) return;
    _showGroupNameDialog(_selectedUsers);
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
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.systemYellow,
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
        child: Stack(
          children: [
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search name, email or phone',
                      placeholderStyle: TextStyle(color: Colors.grey[500]),
                      style: const TextStyle(color: Colors.white),
                      backgroundColor: Colors.transparent,
                      prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
                      suffixIcon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                      onChanged: _filterUsers,
                    ),
                  ),
                ),

                // New Group Option (only show when no search query)
                if (_searchController.text.isEmpty)
                  GestureDetector(
                    onTap: _handleNewGroupTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
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
                                    color: Colors.grey,
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
                  ),

                // Selected Users Chips
                if (_selectedUsers.isNotEmpty)
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _selectedUsers[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.userName.split(' ').first,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _toggleUserSelection(user),
                                child: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Recents Header
                if (_searchController.text.isEmpty && _recentUsers.isNotEmpty && _selectedUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

                // Users List
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
                          Icon(
                            CupertinoIcons.person,
                            size: 50,
                            color: Colors.grey[600],
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
                        : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isSelected = _selectedUsers.contains(user);
                        final isRecent = _recentUsers.contains(user) &&
                            _searchController.text.isEmpty;

                        return _buildUserTile(user, isSelected, isRecent);
                      },
                    ),
                  ),
              ],
            ),

            // Floating Action Button
            if (_selectedUsers.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: CupertinoButton(
                  onPressed: _selectedUsers.length == 1
                      ? () => _startChat(_selectedUsers.first)
                      : _startGroupChat,
                  color: CupertinoColors.systemYellow,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _selectedUsers.length == 1 ? 'Chat' : 'Chat with group',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user, bool isSelected, bool isRecent) {
    return GestureDetector(
      onTap: () => _toggleUserSelection(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar - FIXED: Pass the correct parameters
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: (user.profileImage == null || user.profileImage!.isEmpty)
                  ? Text(
                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: CupertinoColors.systemYellow,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),

            // User Info - FIXED: Use userName instead of name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ] else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.phoneNumber!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection Indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_alt,
                  color: Colors.black,
                  size: 14,
                ),
              )
            else if (isRecent)
              const Icon(
                CupertinoIcons.checkmark_alt,
                color: CupertinoColors.systemYellow,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}