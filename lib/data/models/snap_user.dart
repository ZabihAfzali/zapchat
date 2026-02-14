class SnapUser {
  final String uid;
  final String displayName;
  final String username;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  SnapUser({
    required this.uid,
    required this.displayName,
    required this.username,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory SnapUser.fromMap(Map<String, dynamic> map) {
    return SnapUser(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}