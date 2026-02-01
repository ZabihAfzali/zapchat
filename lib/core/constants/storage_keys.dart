class StorageKeys {
  // Authentication
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userAvatar = 'user_avatar';
  static const String isFirstLaunch = 'is_first_launch';
  static const String isLoggedIn = 'is_logged_in';

  // App Settings
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String notificationEnabled = 'notification_enabled';
  static const String soundEnabled = 'sound_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String autoSaveMedia = 'auto_save_media';
  static const String dataSaver = 'data_saver';

  // Camera Settings
  static const String cameraFlashMode = 'camera_flash_mode';
  static const String cameraResolution = 'camera_resolution';
  static const String defaultCameraLens = 'default_camera_lens';
  static const String videoQuality = 'video_quality';

  // Privacy Settings
  static const String showReadReceipts = 'show_read_receipts';
  static const String showOnlineStatus = 'show_online_status';
  static const String allowScreenshots = 'allow_screenshots';
  static const String allowReplays = 'allow_replays';
  static const String storyPrivacy = 'story_privacy';

  // Cache Keys
  static const String cachedUsers = 'cached_users';
  static const String cachedChats = 'cached_chats';
  static const String cachedStories = 'cached_stories';
  static const String lastSyncTime = 'last_sync_time';
}