import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class SaveProfile extends ProfileEvent {
  const SaveProfile(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}
