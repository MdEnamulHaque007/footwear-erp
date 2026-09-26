/// ============================================================================
/// ফাইল: lib/presentation/blocs/auth/auth_state.dart
/// স্তর: Presentation BLoC | মডিউল: Authentication
/// উদ্দেশ্য: Authentication screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: AuthState, AuthInitial, AuthLoading, Authenticated, Unauthenticated, AuthError, RegisterSuccess, ResetPasswordSent
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/user_entity.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  Authenticated(this.user);
  final UserEntity user;
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

class RegisterSuccess extends AuthState {}

class ResetPasswordSent extends AuthState {}
