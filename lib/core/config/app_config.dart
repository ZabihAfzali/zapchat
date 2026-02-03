class AppConfig {
  // Set this to false when you enable billing
  static const bool useDevStorage = true;

  static const bool useDevChatData = true;
  static const bool useDevStories = true;

  // Toggle features based on environment
  static bool get canUploadMedia => !useDevStorage;
  static bool get canUseRealCamera => false; // Enable when camera package is added
  static bool get canSendRealMessages => false; // Enable when Firestore is ready
}