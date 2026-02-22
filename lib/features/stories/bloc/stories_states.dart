
import 'package:equatable/equatable.dart';

abstract class StoriesState extends Equatable {
  const StoriesState();

  @override
  List<Object> get props => [];
}

class StoriesInitial extends StoriesState {}

class StoriesLoading extends StoriesState {}

class StoryUploadLoading extends StoriesState {}

class StoriesLoaded extends StoriesState {
  final List<Map<String, dynamic>>? userStories; // Changed to List
  final List<Map<String, dynamic>> friendsStories;

  const StoriesLoaded({
    this.userStories,
    required this.friendsStories,
  });

  @override
  List<Object> get props => [friendsStories];
}

class StoriesError extends StoriesState {
  final String message;

  const StoriesError({required this.message});

  @override
  List<Object> get props => [message];
}