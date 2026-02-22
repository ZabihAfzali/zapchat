
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> userStories;

  const ProfileLoaded({
    required this.userData,
    required this.userStories,
  });

  ProfileLoaded copyWith({
    Map<String, dynamic>? userData,
    List<Map<String, dynamic>>? userStories,
  }) {
    return ProfileLoaded(
      userData: userData ?? this.userData,
      userStories: userStories ?? this.userStories,
    );
  }

  @override
  List<Object> get props => [userData, userStories];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}