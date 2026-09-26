/// ============================================================================
/// ফাইল: lib/presentation/blocs/security/security_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: SecurityState, SecurityInitial, SecurityLoading, SecuritySuccess, SecurityFailure, SecurityBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/user/reset_password_usecase.dart';

sealed class SecurityState {
  const SecurityState();
}

class SecurityInitial extends SecurityState {
  const SecurityInitial();
}

class SecurityLoading extends SecurityState {
  const SecurityLoading();
}

class SecuritySuccess extends SecurityState {
  const SecuritySuccess(this.message);

  final String message;
}

class SecurityFailure extends SecurityState {
  const SecurityFailure(this.message);

  final String message;
}

class SecurityBloc extends Cubit<SecurityState> {
  SecurityBloc({required ResetPasswordUseCase resetPassword})
    : _resetPassword = resetPassword,
      super(const SecurityInitial());

  final ResetPasswordUseCase _resetPassword;

  Future<void> sendPasswordReset(String email) async {
    emit(const SecurityLoading());
    try {
      await _resetPassword(email);
      emit(const SecuritySuccess('Password reset link sent to your email.'));
    } catch (_) {
      emit(
        const SecurityFailure(
          'Unable to send a password reset email. Please try again.',
        ),
      );
    }
  }
}
