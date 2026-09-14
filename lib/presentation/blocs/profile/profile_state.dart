import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_entity.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileSaving extends ProfileState {
  const ProfileSaving();
}

class ProfileSaveSuccess extends ProfileState {
  const ProfileSaveSuccess(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class ProfileSaveFailure extends ProfileState {
  const ProfileSaveFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
