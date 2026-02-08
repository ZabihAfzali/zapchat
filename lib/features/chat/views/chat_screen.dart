// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapchat/features/chat/bloc/chat_bloc.dart';
import 'package:zapchat/features/chat/bloc/chat_events.dart';
import 'package:zapchat/features/chat/bloc/chat_states.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> user;

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
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Load messages for this chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(LoadMessages(chatId: widget.chatId));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final userName = widget.user['name'] as String? ?? 'Unknown';
    final profilePicture = widget.user['profilePicture'] as String?;
    final isOnline = (widget.user['isOnline'] as bool?) ?? false;
    final userId = widget.user['id'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Profile picture with story ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.yellow, Colors.orange, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                    ? NetworkImage(profilePicture)
                    : null,
                backgroundColor: Colors.grey[800],
                child: profilePicture == null || profilePicture.isEmpty
                    ? const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is MessagesLoaded &&
                          state.chatId == widget.chatId &&
                          state.isTyping) {
                        return Text(
                          'Typing...',
                          style: TextStyle(
                            color: Colors.yellow[300],
                            fontSize: 12,
                          ),
                        );
                      }
                      return Text(
                        isOnline ? 'Online' : 'Tap to view',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is MessagesLoaded && state.chatId == widget.chatId) {
                  final messages = state.messages;

                  // Auto-scroll when new messages come
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final senderId = message['senderId'] as String? ?? '';
                      // TODO: Replace 'user1' with actual current user ID
                      // You should get this from your auth system
                      final currentUserId = 'user1';
                      final isMe = senderId == currentUserId;

                      return ChatBubble(
                        message: message,
                        isMe: isMe,
                        onTap: () {
                          // Show message options
                          _showMessageOptions(message);
                        },
                      );
                    },
                  );
                } else if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
                } else if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          // Message input bar
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black,
      child: Row(
        children: [
          // Camera button
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.yellow),
            onPressed: () {
              // Open camera
              _sendMediaMessage('image');
            },
          ),

          // Gallery button
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.yellow),
            onPressed: () {
              // Open gallery
              _sendMediaMessage('image');
            },
          ),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Send a chat...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (text) {
                        // Update typing status
                        final shouldBeTyping = text.isNotEmpty;
                        if (_isTyping != shouldBeTyping) {
                          _isTyping = shouldBeTyping;
                          context.read<ChatBloc>().add(
                            UpdateTypingStatus(
                              chatId: widget.chatId,
                              isTyping: _isTyping,
                            ),
                          );
                        }
                      },
                      onSubmitted: (text) {
                        _sendTextMessage();
                      },
                    ),
                  ),

                  // Voice message button
                  IconButton(
                    icon: const Icon(Icons.keyboard_voice, color: Colors.yellow),
                    onPressed: () {
                      // Start voice recording
                    },
                  ),
                ],
              ),
            ),
          ),

          // Send button
          IconButton(
            icon: const Icon(Icons.send, color: Colors.yellow),
            onPressed: _sendTextMessage,
          ),
        ],
      ),
    );
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final receiverId = widget.user['id'] as String? ?? '';
      if (receiverId.isEmpty) {
        // Show error or handle missing receiver ID
        return;
      }

      context.read<ChatBloc>().add(
        SendTextMessage(
          chatId: widget.chatId,
          text: text,
          receiverId: receiverId,
        ),
      );
      _messageController.clear();

      // Stop typing status
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(
          UpdateTypingStatus(
            chatId: widget.chatId,
            isTyping: false,
          ),
        );
      }
    }
  }

  void _sendMediaMessage(String mediaType) {
    final receiverId = widget.user['id'] as String? ?? '';
    if (receiverId.isEmpty) {
      // Show error or handle missing receiver ID
      return;
    }

    // In real app, you'd pick an image/video
    // For demo, using a dummy path
    context.read<ChatBloc>().add(
      SendMediaMessage(
        chatId: widget.chatId,
        filePath: 'dummy_path.jpg',
        mediaType: mediaType,
        receiverId: receiverId,
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white),
                title: const Text('Reply', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text('Copy', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  final text = message['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    // Copy to clipboard
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _deleteMessage(Map<String, dynamic> message) {
    final messageId = message['id'] as String?;
    if (messageId == null || messageId.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Delete Message',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Delete for everyone or just for you?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(
                  DeleteMessage(
                    chatId: widget.chatId,
                    messageId: messageId,
                    forEveryone: false,
                  ),
                );
              },
              child: const Text(
                'Delete for me',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(
                  DeleteMessage(
                    chatId: widget.chatId,
                    messageId: messageId,
                    forEveryone: true,
                  ),
                );
              },
              child: const Text(
                'Delete for everyone',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final VoidCallback onTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  DateTime? _parseTime(dynamic time) {
    if (time == null) return null;

    if (time is DateTime) {
      return time;
    } else if (time is Timestamp) {
      return time.toDate();
    } else if (time is String) {
      try {
        return DateTime.parse(time);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final time = _parseTime(message['timestamp']);
    final messageText = message['text'] as String? ?? '';
    final messageType = message['type'] as String? ?? 'text';
    final mediaUrl = message['mediaUrl'] as String?;
    final status = message['status'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Message bubble
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey[900],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: messageType == 'media'
                    ? _buildMediaMessage(mediaUrl, messageText)
                    : Text(
                  messageText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),

              // Time and status
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(time),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        status == 'read' ? Icons.done_all : Icons.done,
                        color: status == 'read' ? Colors.blue : Colors.grey,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaMessage(String? mediaUrl, String messageText) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[800],
            image: mediaUrl != null && mediaUrl.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(mediaUrl),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: mediaUrl == null || mediaUrl.isEmpty
              ? const Center(
            child: Icon(
              Icons.image,
              color: Colors.white,
              size: 50,
            ),
          )
              : null,
        ),
        if (messageText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            messageText,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }
}