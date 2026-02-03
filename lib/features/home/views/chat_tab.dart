import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/features/home/repository/home_repository.dart';

import '../../../core/widgets/custom_appbar.dart';
import '../widgets/chat_items.dart';

class ChatTab extends StatefulWidget {
  final HomeRepository homeRepository;

  const ChatTab({super.key, required this.homeRepository});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      _chats = await widget.homeRepository.getFriends();
    } catch (e) {
      print('Error loading chats: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Chats',
        actions: [
          Icon(Icons.search, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Icon(Icons.more_vert, color: Colors.white, size: 28),
        ],
      ),
      body: Column(
        children: [
          // New Chat button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                minimumSize: Size(double.infinity, 0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, size: 20),
                  SizedBox(width: 8.w),
                  Text(
                    'New Chat',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chats list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
                : _buildChatsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        _buildChatHeader('Recent'),
        ..._chats.where((chat) => chat['hasStory']).map((chat) {
          return ChatItem(
            name: chat['name'],
            lastMessage: chat['lastMessage'],
            time: chat['time'],
            unread: chat['unread'],
            hasStory: chat['hasStory'],
            onTap: () {},
          );
        }).toList(),

        _buildChatHeader('Groups'),
        ChatItem(
          name: 'Friends Forever',
          lastMessage: 'Mike: Party tonight! 🎉',
          time: 'Yesterday',
          unread: true,
          hasStory: false,
          isGroup: true,
          memberCount: 8,
          onTap: () {},
        ),
        ChatItem(
          name: 'Work Team',
          lastMessage: 'Sarah: Meeting at 3 PM',
          time: '2 days ago',
          unread: false,
          hasStory: false,
          isGroup: true,
          memberCount: 5,
          onTap: () {},
        ),

        _buildChatHeader('Archived'),
        ChatItem(
          name: 'Alex Johnson',
          lastMessage: 'See you soon!',
          time: '1 week ago',
          unread: false,
          hasStory: false,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildChatHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}