// lib/features/chat/views/chat_screen.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zapchat/core/utils/svg_utils.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/bloc/chat_states.dart';
import 'package:zapchat/features/chat/models/message.dart';
import 'package:zapchat/features/chat/widgets/chat_bubble.dart';

import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final ChatUser user;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.user,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
      context.read<ChatBloc>().add(LoadMessages(chatId: widget.chatId));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    if (_isTyping) {
      context.read<ChatBloc>().add(
        UpdateTypingStatus(
          chatId: widget.chatId,
          isTyping: false,
        ),
      );
    }

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

  Future<void> _pickAndSendMedia(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() => _isSending = true);

      context.read<ChatBloc>().add(
        SendMediaMessage(
          chatId: widget.chatId,
          file: File(pickedFile.path),
          mediaType: 'image',
          receiverId: widget.user.uid,
        ),
      );

      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: _buildNavigationBar(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listenWhen: (previous, current) {
                  if (current is MessagesLoaded && current.chatId == widget.chatId) {
                    return previous is! MessagesLoaded ||
                        previous.messages.length != current.messages.length;
                  }
                  return false;
                },
                listener: (context, state) {
                  if (state is MessagesLoaded && state.chatId == widget.chatId) {
                    _cachedMessages = state.messages;
                    _scrollToBottom();
                  }
                },
                buildWhen: (previous, current) {
                  if (current is MessagesLoaded && current.chatId == widget.chatId) {
                    return previous is! MessagesLoaded ||
                        previous.messages.hashCode != current.messages.hashCode;
                  }
                  return false;
                },
                builder: (context, state) {
                  List<Message> messages = _cachedMessages;

                  if (state is MessagesLoaded && state.chatId == widget.chatId) {
                    messages = state.messages;
                  }

                  if (state is ChatLoading && messages.isEmpty) {
                    return const Center(
                      child: CupertinoActivityIndicator(
                        radius: 16,
                        color: CupertinoColors.systemYellow,
                      ),
                    );
                  }

                  if (messages.isEmpty) {
                    return _buildEmptyState();
                  }

                  return CupertinoScrollbar(
                    child: ListView.builder(
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
                          onTap: () => _showMessageOptions(message),
                        );
                      },
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

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
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
      middle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {},
            child: SvgUtils.buildAvatar(
              radius: 16,
              hasStory: widget.user.hasStory,
              isOnline: widget.user.isOnline,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (previous, current) {
                  if (current is TypingStatusUpdated && current.chatId == widget.chatId) {
                    return previous is! TypingStatusUpdated ||
                        previous.isTyping != current.isTyping;
                  }
                  return false;
                },
                builder: (context, state) {
                  if (state is TypingStatusUpdated &&
                      state.chatId == widget.chatId &&
                      state.isTyping) {
                    return Text(
                      'Typing...',
                      style: TextStyle(
                        color: CupertinoColors.systemYellow.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return Text(
                    widget.user.isOnline ? 'Online' :
                    widget.user.lastSeen != null
                        ? 'Last seen ${_formatLastSeen(widget.user.lastSeen!)}'
                        : 'Tap to view',
                    style: TextStyle(
                      color: widget.user.isOnline
                          ? Colors.green
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(
              CupertinoIcons.video_camera_solid,
              color: CupertinoColors.systemYellow,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(
              CupertinoIcons.phone_fill,
              color: CupertinoColors.systemYellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showChatOptions,
            child: const Icon(
              CupertinoIcons.ellipsis,
              color: CupertinoColors.systemYellow,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900],
              border: Border.all(
                color: Colors.grey[800]!,
                width: 2,
              ),
            ),
            child: SvgUtils.getPersonIcon(
              width: 50,
              height: 50,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Say hi to ${widget.user.name.split(' ')[0]}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to start the conversation',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _pickAndSendMedia(ImageSource.camera),
            child: const Icon(
              CupertinoIcons.camera_fill,
              color: CupertinoColors.systemYellow,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _pickAndSendMedia(ImageSource.gallery),
            child: const Icon(
              CupertinoIcons.photo_fill,
              color: CupertinoColors.systemYellow,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 100.h,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      placeholder: 'Send a chat...',
                      placeholderStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.transparent,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      onChanged: (text) {
                        final shouldBeTyping = text.isNotEmpty;
                        if (_isTyping != shouldBeTyping) {
                          setState(() => _isTyping = shouldBeTyping);
                          context.read<ChatBloc>().add(
                            UpdateTypingStatus(
                              chatId: widget.chatId,
                              isTyping: _isTyping,
                            ),
                          );
                        }
                      },
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: const Icon(
                      CupertinoIcons.mic_fill,
                      color: CupertinoColors.systemYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _sendTextMessage,
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

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !_isSending) {
      setState(() => _isSending = true);

      context.read<ChatBloc>().add(
        SendTextMessage(
          chatId: widget.chatId,
          text: text,
          receiverId: widget.user.uid,
        ),
      );

      _messageController.clear();
      setState(() => _isSending = false);

      if (_isTyping) {
        setState(() => _isTyping = false);
        context.read<ChatBloc>().add(
          UpdateTypingStatus(
            chatId: widget.chatId,
            isTyping: false,
          ),
        );
      }
    }
  }

  void _showMessageOptions(Message message) {
    final isMe = message.senderId == context.read<ChatBloc>().chatRepository.currentUserId;
    final isDeleted = message.isDeleted;

    if (isDeleted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
            'Message Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            if (isMe) ...[
              _buildActionSheetButton(
                label: 'Reply',
                icon: CupertinoIcons.arrowshape_turn_up_left,
                onPressed: () => Navigator.pop(context),
              ),
              _buildActionSheetButton(
                label: 'Info',
                icon: CupertinoIcons.info_circle,
                onPressed: () => Navigator.pop(context),
              ),
            ],
            _buildActionSheetButton(
              label: 'Copy',
              icon: CupertinoIcons.doc_on_doc,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            _buildActionSheetButton(
              label: 'Share',
              icon: CupertinoIcons.share,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            if (isMe)
              _buildActionSheetButton(
                label: 'Delete',
                icon: CupertinoIcons.delete,
                isDestructive: true,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            if (!isMe)
              _buildActionSheetButton(
                label: 'Report',
                icon: CupertinoIcons.flag,
                isDestructive: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: CupertinoColors.systemYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  CupertinoActionSheetAction _buildActionSheetButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return CupertinoActionSheetAction(
      onPressed: onPressed,
      isDestructiveAction: isDestructive,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive
                ? CupertinoColors.systemRed
                : CupertinoColors.systemYellow,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDestructive
                  ? CupertinoColors.systemRed
                  : Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
            widget.user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            _buildActionSheetButton(
              label: 'Mute',
              icon: CupertinoIcons.bell_slash,
              onPressed: () => Navigator.pop(context),
            ),
            _buildActionSheetButton(
              label: 'Pin',
              icon: CupertinoIcons.pin,
              onPressed: () => Navigator.pop(context),
            ),
            _buildActionSheetButton(
              label: 'Clear chat',
              icon: CupertinoIcons.delete,
              isDestructive: true,
              onPressed: () => Navigator.pop(context),
            ),
            _buildActionSheetButton(
              label: 'Block',
              icon: CupertinoIcons.person_crop_circle_badge_xmark,
              isDestructive: true,
              onPressed: () => Navigator.pop(context),
            ),
            _buildActionSheetButton(
              label: 'Report',
              icon: CupertinoIcons.flag,
              isDestructive: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: CupertinoColors.systemYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteMessage(Message message) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Message'),
          content: const Text(
            'Delete this message for everyone or just for you?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(
                  DeleteMessage(
                    chatId: widget.chatId,
                    messageId: message.id,
                    forEveryone: false,
                  ),
                );
              },
              child: const Text(
                'Delete for me',
                style: TextStyle(color: Colors.white),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(
                  DeleteMessage(
                    chatId: widget.chatId,
                    messageId: message.id,
                    forEveryone: true,
                  ),
                );
              },
              isDestructiveAction: true,
              child: const Text(
                'Delete for everyone',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(lastSeen);
  }
}