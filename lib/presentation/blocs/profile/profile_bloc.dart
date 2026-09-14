import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/user/update_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required UpdateProfileUseCase updateProfile})
    : _updateProfile = updateProfile,
      super(const ProfileInitial()) {
    on<SaveProfile>(_onSaveProfile);
  }

  final UpdateProfileUseCase _updateProfile;

  Future<void> _onSaveProfile(
    SaveProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final displayName = event.displayName.trim();
    if (displayName.isEmpty) {
      emit(const ProfileSaveFailure('Please enter your name.'));
      return;
    }

    emit(const ProfileSaving());
    try {
      final user = await _updateProfile(displayName);
      if (emit.isDone) return;
      emit(ProfileSaveSuccess(user));
    } catch (_) {
      if (!emit.isDone) {
        emit(const ProfileSaveFailure('Unable to update your profile.'));
      }
    }
  }
}
