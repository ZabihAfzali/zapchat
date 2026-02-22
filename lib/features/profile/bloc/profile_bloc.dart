import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapchat/features/profile/bloc/profile_event.dart';
import 'package:zapchat/features/profile/bloc/profile_state.dart';
import 'package:zapchat/features/profile/repository/profile_repository.dart';


class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(ProfileInitial()) {
    on<LoadUserData>(_onLoadUserData);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<LoadUserStories>(_onLoadUserStories);
  }

  Future<void> _onLoadUserData(LoadUserData event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final userData = await profileRepository.getUserData();
      final userStories = await profileRepository.getUserStories();
      emit(ProfileLoaded(
        userData: userData,
        userStories: userStories,
      ));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfileImage(UpdateProfileImage event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final imageUrl = await profileRepository.uploadProfileImage(event.imageFile);
      await profileRepository.updateProfileData({'profileImage': imageUrl});

      final userData = await profileRepository.getUserData();
      final userStories = await profileRepository.getUserStories();
      emit(ProfileLoaded(
        userData: userData,
        userStories: userStories,
      ));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
      UpdateUserProfile event,
      Emitter<ProfileState> emit,
      ) async {
    emit(ProfileLoading());

    try {
      await profileRepository.updateProfileData(event.profileData);

      final userData = await profileRepository.getUserData();
      final userStories = await profileRepository.getUserStories();

      emit(ProfileLoaded(
        userData: userData,
        userStories: userStories,
      ));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserStories(LoadUserStories event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      try {
        final userStories = await profileRepository.getUserStories();
        emit((state as ProfileLoaded).copyWith(userStories: userStories));
      } catch (e) {
        emit(ProfileError(message: e.toString()));
      }
    }
  }
}