enum SnapType { image, text, video }

class SnapMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String? imageUrl;
  final String? text;
  final SnapType type;
  final DateTime timestamp;
  final bool isSeen;
  final bool isOpened;
  final int viewDuration; // in seconds

  SnapMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.imageUrl,
    this.text,
    required this.type,
    required this.timestamp,
    this.isSeen = false,
    this.isOpened = false,
    this.viewDuration = 10,
  });

  factory SnapMessage.fromMap(Map<String, dynamic> map) {
    return SnapMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      imageUrl: map['imageUrl'],
      text: map['text'],
      type: SnapType.values[map['type'] ?? 0],
      timestamp: DateTime.parse(map['timestamp']),
      isSeen: map['isSeen'] ?? false,
      isOpened: map['isOpened'] ?? false,
      viewDuration: map['viewDuration'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'imageUrl': imageUrl,
      'text': text,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'isSeen': isSeen,
      'isOpened': isOpened,
      'viewDuration': viewDuration,
    };
  }

  SnapMessage copyWith({
    bool? isSeen,
    bool? isOpened,
  }) {
    return SnapMessage(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      imageUrl: imageUrl,
      text: text,
      type: type,
      timestamp: timestamp,
      isSeen: isSeen ?? this.isSeen,
      isOpened: isOpened ?? this.isOpened,
      viewDuration: viewDuration,
    );
  }
}