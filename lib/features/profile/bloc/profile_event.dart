
import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadUserData extends ProfileEvent {}

class UpdateProfileImage extends ProfileEvent {
  final File imageFile;

  const UpdateProfileImage({required this.imageFile});

  @override
  List<Object> get props => [imageFile];
}

class UpdateUserProfile extends ProfileEvent {
  final Map<String, dynamic> profileData;

  const UpdateUserProfile({required this.profileData});

  @override
  List<Object> get props => [profileData];
}

class LoadUserStories extends ProfileEvent {}