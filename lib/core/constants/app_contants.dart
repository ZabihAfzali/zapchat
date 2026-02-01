class AppConstants {
  // App Info
  static const String appName = 'ZapChat';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String storiesCollection = 'stories';
  static const String friendsCollection = 'friends';
  static const String notificationsCollection = 'notifications';

  // Storage Paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String chatMediaPath = 'chat_media';
  static const String storyMediaPath = 'story_media';
  static const String tempPath = 'temp';

  // Time Limits
  static const int maxVideoDuration = 10; // seconds
  static const int storyDuration = 24 * 60 * 60; // 24 hours in seconds
  static const int snapViewTime = 10; // seconds
  static const int otpResendDelay = 30; // seconds

  // Message Limits
  static const int maxMessageLength = 1000;
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 6;

  // Pagination
  static const int messagesPerPage = 20;
  static const int chatsPerPage = 20;
  static const int storiesPerPage = 50;

  // Cache
  static const int cacheDuration = 7; // days
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Debounce & Throttle
  static const Duration debounceDuration = Duration(milliseconds: 300);
  static const Duration throttleDuration = Duration(milliseconds: 1000);

  // Regex Patterns
  static final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$'); // E.164 format
  static final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  // Default Values
  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String defaultStoryBackground = 'assets/images/story_bg.jpg';

  // Feature Flags (for rollout)
  static const bool enableStories = true;
  static const bool enableVoiceMessages = true;
  static const bool enableVideoCalls = false; // For future implementation
  static const bool enableGroupChats = true;
}