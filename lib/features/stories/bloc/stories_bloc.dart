import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapchat/features/stories/bloc/stories_events.dart';
import 'package:zapchat/features/stories/bloc/stories_states.dart';
import 'package:zapchat/features/stories/repository/stories_repository.dart';


class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  final StoriesRepository storiesRepository;

  StoriesBloc({required this.storiesRepository}) : super(StoriesInitial()) {
    on<LoadStories>(_onLoadStories);
    on<UploadStory>(_onUploadStory);
    on<MarkStoryAsSeen>(_onMarkStoryAsSeen); // Add this handler
  }

  Future<void> _onLoadStories(LoadStories event, Emitter<StoriesState> emit) async {
    emit(StoriesLoading());
    try {
      final userStories = await storiesRepository.getUserStories();
      final friendsStories = await storiesRepository.getFriendsStories();

      emit(StoriesLoaded(
        userStories: userStories,
        friendsStories: friendsStories,
      ));
    } catch (e) {
      emit(StoriesError(message: e.toString()));
    }
  }

  Future<void> _onUploadStory(UploadStory event, Emitter<StoriesState> emit) async {
    emit(StoryUploadLoading());
    try {
      await storiesRepository.uploadStory(
        mediaFile: event.mediaFile,
        caption: event.caption,
        mediaType: event.mediaType,
      );

      // Small delay to ensure Firebase updates
      await Future.delayed(const Duration(milliseconds: 500));

      final userStories = await storiesRepository.getUserStories();
      final friendsStories = await storiesRepository.getFriendsStories();

      emit(StoriesLoaded(
        userStories: userStories,
        friendsStories: friendsStories,
      ));

    } catch (e) {
      emit(StoriesError(message: e.toString()));
    }
  }

  // Add this handler for marking stories as seen
  Future<void> _onMarkStoryAsSeen(MarkStoryAsSeen event, Emitter<StoriesState> emit) async {
    try {
      await storiesRepository.markStoryAsSeen(event.storyId);

      // After marking as seen, we don't need to emit a new state
      // The UI will update when we refresh stories on close
    } catch (e) {
      print('Error marking story as seen: $e');
    }
  }
}