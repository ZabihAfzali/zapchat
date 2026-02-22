// lib/features/chat/views/create_group_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/svg_utils.dart';
import '../models/chat_model.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<ChatUser> allUsers;

  const CreateGroupScreen({super.key, required this.allUsers});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<ChatUser> _selectedUsers = [];
  List<ChatUser> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.allUsers;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        leading: CupertinoButton(
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('New Group'),
        trailing: CupertinoButton(
          onPressed: _selectedUsers.isEmpty ? null : _createGroup,
          child: Text(
            'Create',
            style: TextStyle(
              color: _selectedUsers.isEmpty ? Colors.grey : CupertinoColors.systemYellow,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Group name input
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoTextField(
                controller: _groupNameController,
                placeholder: 'Group name',
                style: const TextStyle(color: Colors.white),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Selected users
            if (_selectedUsers.isNotEmpty)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _selectedUsers[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[800],
                            child: const Icon(CupertinoIcons.person_fill),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.name.split(' ').first,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search users',
                onChanged: _filterUsers,
              ),
            ),

            // Users list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final isSelected = _selectedUsers.contains(user);
                  return _buildUserTile(user, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user, bool isSelected) {
    return CupertinoButton(
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedUsers.remove(user);
          } else {
            _selectedUsers.add(user);
          }
        });
      },
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgUtils.buildAvatar(radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(color: Colors.white)),
                  if (user.username != null)
                    Text(user.username!, style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
            if (isSelected)
               Icon(CupertinoIcons.check_mark_circled,
                  color: CupertinoColors.systemYellow),
          ],
        ),
      ),
    );
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.allUsers;
      } else {
        _filteredUsers = widget.allUsers
            .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _createGroup() {
    // Create group in Firestore
    Navigator.pop(context, _selectedUsers);
  }
}