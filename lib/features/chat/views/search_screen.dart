// lib/features/chat/views/search_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/models/chat.dart';
import 'package:zapchat/features/chat/models/message.dart';
import 'package:zapchat/features/chat/views/chat_screen.dart';
import 'package:zapchat/features/chat/views/new_chat_screen.dart';

import '../models/chat_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ChatUser> _allUsers = [];
  List<Chat> _allChats = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final users = await context.read<ChatBloc>().chatRepository.getAllUsers();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getSearchResults() {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    final results = <dynamic>[];

    // Search users
    final userResults = _allUsers.where((user) =>
    user.name.toLowerCase().contains(query) ||
        (user.username?.toLowerCase().contains(query) ?? false)
    ).toList();

    results.addAll(userResults);

    return results;
  }

  void _startChat(ChatUser user) async {
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
      _showErrorDialog('Failed to start chat');
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
    final results = _getSearchResults();

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
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search Bar
// lib/features/chat/views/search_screen.dart
// Update the search bar section:

// Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoTextField( // Changed from TextField to CupertinoTextField
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: 'Search users or messages...',
                  placeholderStyle: TextStyle(color: Colors.grey[500]),
                  style: const TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.search, color: Colors.grey, size: 20),
                  ),
                  suffix: _searchQuery.isNotEmpty
                      ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey, size: 18),
                  )
                      : null,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: CupertinoColors.systemYellow,
                  ),
                ),
              )
            else if (_searchQuery.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.search, size: 50, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Search users or messages',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else if (results.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      if (result is ChatUser) {
                        return _buildUserTile(result);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user) {
    return GestureDetector(
      onTap: () => _startChat(user),
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
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
          ],
        ),
      ),
    );
  }
}