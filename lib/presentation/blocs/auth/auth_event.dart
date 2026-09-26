/// ============================================================================
/// ফাইল: lib/presentation/blocs/auth/auth_event.dart
/// স্তর: Presentation BLoC | মডিউল: Authentication
/// উদ্দেশ্য: Authentication screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: AuthEvent, AuthStarted, LoginRequested, RegisterRequested, LogoutRequested, CheckAuthStatus, DevSkipLoginRequested, ResetPasswordRequested, AuthProfileUpdated, AuthStateChanged
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/user_entity.dart';

sealed class AuthEvent {}

class AuthStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  LoginRequested(this.email, this.password);
  final String email;
  final String password;
}

class RegisterRequested extends AuthEvent {
  RegisterRequested(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

/// Debug-only: authenticate as the in-memory dev user (see `DevConfig`).
class DevSkipLoginRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  ResetPasswordRequested(this.email);
  final String email;
}

class AuthProfileUpdated extends AuthEvent {
  AuthProfileUpdated(this.user);
  final UserEntity user;
}

class AuthStateChanged extends AuthEvent {
  AuthStateChanged(this.user);
  final UserEntity? user;
}
