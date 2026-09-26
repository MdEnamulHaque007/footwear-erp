/// ============================================================================
/// ফাইল: lib/presentation/blocs/profile/profile_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProfileBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
