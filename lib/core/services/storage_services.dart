import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

abstract class StorageService {
  Future<String> uploadProfilePicture(String filePath);
  Future<String> uploadChatImage(String filePath, String chatId);
  Future<String> uploadChatVideo(String filePath, String chatId);
  Future<String> uploadStory(String filePath);
  Future<void> deleteFile(String url);
}

// Development implementation (saves locally, simulates upload)
class DevStorageService implements StorageService {
  @override
  Future<String> uploadProfilePicture(String filePath) async {
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 1));
    // Return fake URL for development
    return 'https://dev.zapchat.com/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<String> uploadChatImage(String filePath, String chatId) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://dev.zapchat.com/chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<String> uploadChatVideo(String filePath, String chatId) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'https://dev.zapchat.com/chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  @override
  Future<String> uploadStory(String filePath) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://dev.zapchat.com/story_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<void> deleteFile(String url) async {
    // Simulate deletion
    await Future.delayed(const Duration(milliseconds: 500));
    print('🗑️ DEV: Simulated deletion of file: $url');
  }
}

// Production implementation (uses Firebase Storage)
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadProfilePicture(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('profile_pictures/$fileName');

      print('📤 Uploading profile picture: $fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Profile picture uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadChatImage(String filePath, String chatId) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('chat_media/$chatId/images/$fileName');

      print('📤 Uploading chat image for chat $chatId: $fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Chat image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading chat image: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadChatVideo(String filePath, String chatId) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('chat_media/$chatId/videos/$fileName');

      print('📤 Uploading chat video for chat $chatId: $fileName');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Chat video uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading chat video: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadStory(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('stories/$fileName');

      print('📤 Uploading story: $fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Story uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading story: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String url) async {
    try {
      // Extract the path from the URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Firebase Storage URLs have a specific structure
      // Example: https://firebasestorage.googleapis.com/v0/b/project-id.appspot.com/o/path%2Fto%2Ffile.jpg

      // Get the encoded path after 'o/'
      final encodedPath = uri.path.split('o/').last;

      // Decode the path (URL encoded)
      final decodedPath = Uri.decodeFull(encodedPath);

      print('🗑️ Deleting file from path: $decodedPath');

      final ref = _storage.ref().child(decodedPath);
      await ref.delete();

      print('✅ File deleted successfully');
    } catch (e) {
      print('❌ Error deleting file: $e');
      rethrow;
    }
  }
}