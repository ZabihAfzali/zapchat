enum MessageType {
  text,
  image,
  video,
  audio,
  sticker,
  location,
  deleted,
}

extension MessageTypeExtension on MessageType {
  String get name {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.audio:
        return 'audio';
      case MessageType.sticker:
        return 'sticker';
      case MessageType.location:
        return 'location';
      case MessageType.deleted:
        return 'deleted';
    }
  }

  bool get isMedia => this == MessageType.image || this == MessageType.video;
  bool get isText => this == MessageType.text;
}