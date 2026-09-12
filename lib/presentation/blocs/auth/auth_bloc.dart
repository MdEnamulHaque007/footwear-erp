import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/dev_config.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../domain/usecases/user/check_auth_status_usecase.dart';
import '../../../domain/usecases/user/login_usecase.dart';
import '../../../domain/usecases/user/logout_usecase.dart';
import '../../../domain/usecases/user/register_usecase.dart';
import '../../../domain/usecases/user/reset_password_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required ResetPasswordUseCase resetPassword,
    required CheckAuthStatusUseCase checkStatus,
    required IAuthRepository repository,
  }) : _login = login,
       _register = register,
       _logout = logout,
       _resetPassword = resetPassword,
       _checkStatus = checkStatus,
       super(AuthLoading()) {
    _subscription = repository.authStateChanges.listen(
      (user) => add(AuthStateChanged(user)),
    );
    on<AuthStarted>((event, emit) async => add(CheckAuthStatus()));
    on<CheckAuthStatus>(_onCheckStatus);
    on<AuthStateChanged>((event, emit) {
      if (event.user != null) {
        _devSession = false;
        emit(Authenticated(event.user!));
        return;
      }
      // A real Firebase sign-out emits null; while a dev session is active we
      // ignore it so auto-login / skip-login isn't clobbered on startup.
      if (_devSession) return;
      emit(Unauthenticated());
    });
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ResetPasswordRequested>(_onResetPassword);
    on<DevSkipLoginRequested>(_onDevSkipLogin);
    add(CheckAuthStatus());
  }

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final ResetPasswordUseCase _resetPassword;
  final CheckAuthStatusUseCase _checkStatus;
  StreamSubscription? _subscription;

  /// True while a debug-only dev session (auto-login / skip button) is active,
  /// so `authStateChanges` null events don't kick the dev user out.
  bool _devSession = false;

  Future<void> _onCheckStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _checkStatus();
      if (emit.isDone) return;
      if (user != null) {
        _devSession = false;
        emit(Authenticated(user));
        return;
      }
      if (_devAutoLoginEnabled) {
        _startDevSession(emit);
        return;
      }
      emit(Unauthenticated());
    } catch (error) {
      if (emit.isDone) return;
      // In debug with auto-login on, fall back to the dev user even if the
      // auth check throws (e.g. Firebase offline / misconfigured).
      if (_devAutoLoginEnabled) {
        _startDevSession(emit);
        return;
      }
      emit(AuthError(_message(error)));
    }
  }

  bool get _devAutoLoginEnabled => DevConfig.enabled && DevConfig.autoLogin;

  void _startDevSession(Emitter<AuthState> emit) {
    _devSession = true;
    emit(Authenticated(DevConfig.devUser));
  }

  Future<void> _onDevSkipLogin(
    DevSkipLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!DevConfig.enabled) return;
    _startDevSession(emit);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
    final user = await _login(event.email, event.password);
    if (emit.isDone) return;
    emit(Authenticated(user));
    } catch (error) {
    if (emit.isDone) return;
      emit(AuthError(_message(error)));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _register(event.name, event.email, event.password);
      if (emit.isDone) return;
      emit(RegisterSuccess());
    } catch (error) {
      if (emit.isDone) return;
      emit(AuthError(_message(error)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      _devSession = false;
      await _logout();
      if (emit.isDone) return;
      emit(Unauthenticated());
    } catch (error) {
      if (emit.isDone) return;
      emit(AuthError(_message(error)));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _resetPassword(event.email);
      if (emit.isDone) return;
      emit(ResetPasswordSent());
    } catch (error) {
      if (emit.isDone) return;
      emit(AuthError(_message(error)));
    }
  }

  String _message(Object error) => error is FirebaseAuthException
      ? AuthRepository.messageFor(error)
      : 'Something went wrong. Please try again.';

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
