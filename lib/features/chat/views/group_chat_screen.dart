// lib/features/chat/views/group_chat_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/models/message.dart';
import 'package:zapchat/features/chat/widgets/chat_bubble.dart';

import '../bloc/chat_states.dart';
import '../models/chat_model.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<ChatUser> members;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.members,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isSending = false;
  List<Message> _cachedMessages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(LoadGroupMessages(chatId: widget.groupId));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !_isSending) {
      setState(() => _isSending = true);

      context.read<ChatBloc>().add(
        SendGroupMessage(
          chatId: widget.groupId,
          text: text,
        ),
      );

      _messageController.clear();
      setState(() => _isSending = false);
    }
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
        middle: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.group,
                color: CupertinoColors.systemYellow,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.members.length} members',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showGroupInfo,
          child: const Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemYellow,
            size: 22,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is GroupMessagesLoaded && state.chatId == widget.groupId) {
                    final messages = state.messages;

                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId ==
                            context.read<ChatBloc>().chatRepository.currentUserId;

                        return ChatBubble(
                          message: message,
                          isMe: isMe,
                          onTap: () {},
                        );
                      },
                    );
                  }
                  return const Center(
                    child: CupertinoActivityIndicator(
                      color: CupertinoColors.systemYellow,
                    ),
                  );
                },
              ),
            ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CupertinoActivityIndicator(
                  radius: 12,
                  color: CupertinoColors.systemYellow,
                ),
              ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              CupertinoIcons.group,
              size: 40,
              color: CupertinoColors.systemYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to ${widget.groupName}!',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to the group',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              focusNode: _focusNode,
              placeholder: 'Send a message...',
              placeholderStyle: TextStyle(color: Colors.grey[500]),
              style: const TextStyle(color: Colors.white),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              onChanged: (text) {
                setState(() => _isTyping = text.isNotEmpty);
              },
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _sendMessage,
            child: const Icon(
              CupertinoIcons.paperplane_fill,
              color: CupertinoColors.systemYellow,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
        message: Column(
          children: [
            const Text('Members:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ...widget.members.map((member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgUtils.buildAvatar(radius: 16),
                  const SizedBox(width: 8),
                  Text(member.name, style: const TextStyle(color: Colors.white)),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Leave Group'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}