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
