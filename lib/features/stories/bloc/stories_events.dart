
import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class StoriesEvent extends Equatable {
  const StoriesEvent();

  @override
  List<Object> get props => [];
}

class LoadStories extends StoriesEvent {
  const LoadStories();
}

class UploadStory extends StoriesEvent {
  final File mediaFile;
  final String? caption;
  final String mediaType;

  const UploadStory({
    required this.mediaFile,
    this.caption,
    required this.mediaType,
  });

  @override
  List<Object> get props => [mediaFile, mediaType];
}

// Add this new event
class MarkStoryAsSeen extends StoriesEvent {
  final String storyId;

  const MarkStoryAsSeen({required this.storyId});

  @override
  List<Object> get props => [storyId];
}