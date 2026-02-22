// lib/features/chat/views/select_users_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zapchat/core/utils/svg_utils.dart';

import '../models/chat_model.dart';

class SelectUsersScreen extends StatefulWidget {
  final List<ChatUser> allUsers;

  const SelectUsersScreen({super.key, required this.allUsers});

  @override
  State<SelectUsersScreen> createState() => _SelectUsersScreenState();
}

class _SelectUsersScreenState extends State<SelectUsersScreen> {
  final List<ChatUser> _selectedUsers = [];
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.allUsers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.allUsers;
      } else {
        _filteredUsers = widget.allUsers
            .where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase()) ||
            (user.username?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _toggleUser(ChatUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
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
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.systemYellow),
        ),
        middle: const Text(
          'Select Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          onPressed: _selectedUsers.length < 2  // Require at least 2 users
              ? null
              : () => Navigator.pop(context, _selectedUsers),
          child: Text(
            'Next (${_selectedUsers.length}/10)', // Show count
            style: TextStyle(
              color: _selectedUsers.length < 2 ? Colors.grey : CupertinoColors.systemYellow,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Info message
            if (_selectedUsers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.grey[900],
                child: Text(
                  'Select at least 2 users to create a group',
                  style: TextStyle(
                    color: _selectedUsers.length < 2 ? CupertinoColors.systemYellow : Colors.green,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

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
                  placeholder: 'Search users',
                  placeholderStyle: TextStyle(color: Colors.grey[500]),
                  style: const TextStyle(color: Colors.white),
                  backgroundColor: Colors.transparent,
                  onChanged: _filterUsers,
                ),
              ),
            ),

            // Selected users chips
            if (_selectedUsers.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            user.name.split(' ').first,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _toggleUser(user),
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

            // Users List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final isSelected = _selectedUsers.contains(user);

                  return GestureDetector(
                    onTap: () => _toggleUser(user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgUtils.buildAvatar(
                            radius: 24,
                            hasStory: user.hasStory,
                            isOnline: user.isOnline,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                if (user.username != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    user.username!,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                  ),
                                ],
                              ],
                            ),
                          ),
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
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}